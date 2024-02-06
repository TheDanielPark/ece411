module ks_adder
#(
    parameter int LEN=16
)
(
    input        [LEN-1:0] a_i,
    input        [LEN-1:0] b_i,
    input                  c_i,
    output logic [LEN-1:0] s_o,
    output logic           c_o
);

ks_types::gp_t GP [LEN][LEN]; // generate-propagate signals
logic C [LEN];                // Carry bits

// P[x][y] = &{p[x][x], ..., p[y][y]};
// (G[x][y], P[x][y]) dot (G[y+1][w], P[y+1][w]) = (G[x][w], P[x][w])
//                                               = (G[y+1][w] + G[x][y]P[y+1][w],
//                                                  P[x][y]P[y+1][w])
// C[x]    = G[0][x] | (P[0][x] & c_i)

// Sum and Carry-Out
assign s_o[0] = ^{ a_i[0], b_i[0], c_i };
assign c_o = C[LEN-1];
for (genvar i = 1; i < LEN; ++i) begin : sum
    assign s_o[i] = ^{ a_i[i], b_i[i], C[i-1]};
end

// Carry Assignments
for (genvar i = 0; i < LEN; ++i) begin : carries
    assign C[i] = GP[0][i].G | (GP[0][i].P & c_i);
end

for (genvar i = 0; i < LEN; ++i) begin : base_case // (layer_0)
    assign GP[i][i].G = a_i[i] & b_i[i];
    assign GP[i][i].P = a_i[i] ^ b_i[i];
    assign GP[i][i].lidx = i;
    assign GP[i][i].ridx = i;
end

if (LEN < 4) begin
    initial
        assert(1'b0 && "Kogge-Stone adder with LEN < 4 makes no sense");
end
for (genvar i = 1; i < LEN; ++i) begin : layer_1
    ks_dot l1dot(GP[i-1][i-1], GP[i][i], GP[i-1][i]);
end

ks_dot l2specdot(GP[0][0], GP[1][2], GP[0][2]);
for (genvar i = 3; i < LEN; ++i) begin : layer_2
    ks_dot l2gendot(GP[i-3][i-2], GP[i-1][i], GP[i-3][i]);
end

if (LEN >= 8) begin
ks_dot l3spec1dot(GP[0][0], GP[1][4], GP[0][4]);
ks_dot l3spec2dot(GP[0][1], GP[2][5], GP[0][5]);
for (genvar i = 4+2; i < 8; ++i) begin : layer_3_minor
    ks_dot l3gendot1(GP[0][i-4], GP[i-3][i], GP[0][i]);
end
for (genvar i = 8; i < LEN; ++i) begin : layer_3_major
    ks_dot l3gendot2(GP[i-7][i-7+3], GP[i-7+4][i], GP[i-7][i]);
end
end

if (LEN >= 16) begin
ks_dot l4spec1dot(GP[0][0], GP[1][8], GP[0][8]);
ks_dot l4spec2dot(GP[0][1], GP[2][9], GP[0][9]);
ks_dot l4spec3dot(GP[0][2], GP[3][10], GP[0][10]);
for (genvar i = 8+3; i < 16; ++i) begin : layer_4_minor
    ks_dot l4gendot1(GP[0][i-8], GP[i-7][i], GP[0][i]);
end
for (genvar i = 16; i < LEN; ++i) begin : layer_4_major
    ks_dot l4gendot2(GP[i-15][i-15+7], GP[i-15+8][i], GP[i-15][i]);
end
end

if (LEN >= 32) begin
ks_dot l5spec1dot(GP[0][0], GP[1][16], GP[0][16]);
ks_dot l5spec2dot(GP[0][1], GP[2][17], GP[0][17]);
ks_dot l5spec3dot(GP[0][2], GP[3][18], GP[0][18]);
ks_dot l5spec4dot(GP[0][3], GP[4][19], GP[0][19]);
for (genvar i = 16+4; i < 32; ++i) begin : layer_5_minor
    ks_dot l5gendot1(GP[0][i-16], GP[i-15][i], GP[0][i]);
end
for (genvar i = 32; i < LEN; ++i) begin : layer_5_major
    ks_dot l5gendot2(GP[i-31][i-31+15], GP[i-31+16][i], GP[i-31][i]);
end
end

if (LEN >= 64) begin
ks_dot l6spec1dot(GP[0][0], GP[1][32], GP[0][32]);
ks_dot l6spec2dot(GP[0][1], GP[2][33], GP[0][33]);
ks_dot l6spec3dot(GP[0][2], GP[3][34], GP[0][34]);
ks_dot l6spec4dot(GP[0][3], GP[4][35], GP[0][35]);
ks_dot l6spec5dot(GP[0][4], GP[5][36], GP[0][36]);
for (genvar i = 32+5; i < 64; ++i) begin : layer_6_minor
    ks_dot l6gendot1(GP[0][i-32], GP[i-31][i], GP[0][i]);
end
end

endmodule
