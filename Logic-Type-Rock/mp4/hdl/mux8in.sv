module mux8in #(parameter width = 32)(
    input [2:0] select,
    input [width - 1:0] a,b,c,d,e,f,g,h,
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
else if (select == 3)
    out = d;
else if (select == 4)
    out = e;
else if (select == 5)
    out = f;
else if (select == 6)
    out = g;
else
    out = h;
end
endmodule : mux8in