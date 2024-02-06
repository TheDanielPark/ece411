module adder (
    input [31:0] a,
    input [31:0] b,
    output logic [31:0] c
);
always_comb
begin
    c = a+b;
end

endmodule: adder