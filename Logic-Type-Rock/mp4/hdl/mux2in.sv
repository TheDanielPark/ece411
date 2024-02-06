module mux2in #(parameter width = 32)(
    input select,
    input [width - 1:0] a,b,
    output logic [width - 1:0] out
);

always_comb 
begin
if (select == 0) 
    out = a;
else
    out = b;
end
endmodule : mux2in