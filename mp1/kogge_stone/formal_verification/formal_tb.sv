module formal_tb
#(parameter LEN=64)
(
    input                  CLK,
    input        [LEN-1:0] a_i,
    input        [LEN-1:0] b_i,
    input                  c_i,
    output logic [LEN-1:0] s_o,
    output logic           c_o
);

// Create model of adder:
logic [LEN:0] msum;
assign msum = {1'b0, a_i} + {1'b0, b_i} + c_i;

// Instantiate Kogge-Stone adder as design-under-test
ks_adder #(LEN) dut(.*);

// Check equivalence of model and DUT
as_correct: assert property(
    @(CLK)
    disable iff (1'b0)
    msum == {c_o, s_o}
);

endmodule
