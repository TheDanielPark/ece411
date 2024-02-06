module ks_dot
(
    input  var ks_types::gp_t \[x:y] ,
    input  var ks_types::gp_t \[w:z] ,
    output var ks_types::gp_t \[x:z]
);


always_comb begin
    aligned_idx: assert ( \[x:y] .ridx + 1 == \[w:z] . lidx);
    lidx1: assert ( \[x:y] .lidx <= \[x:y] .ridx);
    lidx2: assert ( \[w:z] .lidx <= \[w:z] .ridx);
end

assign \[x:z] .lidx = \[x:y] .lidx;
assign \[x:z] .ridx = \[w:z] .ridx;

assign \[x:z] .G = \[w:z] .G | ( \[x:y] . G & \[w:z] .P);
assign \[x:z] .P = \[x:y] .P & \[w:z] .P;

endmodule
