module mux4in #(parameter width = 32)(
    input [1:0] select,
    input [width - 1:0] a,b,c,d,
    output logic [width - 1:0] out
);

always_comb 
begin
if (select == 0) 
    out = a;
else if (select == 1)
    out = b;
else if (select == 2)
    out = c;
else 
    out = d;
end
endmodule : mux4in