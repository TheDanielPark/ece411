`timescale 1ns/100ps

module mp1_tb;

bit clk = 1'b0;
always #5 clk = ~clk;

bit rst, load;
bit [31:0] in, reg_a, reg_b;
bit [4:0] src_a, src_b, dest;

mp1 mp1(.*);

default clocking cb @(posedge clk);
    input reg_a, reg_b;
    output rst, load, in, src_a, src_b, dest;
endclocking

function void print_reg(int i);
    $display("reg %2x: %x", i, mp1.rf.data[i]);
endfunction

function void print_regfile();
    for (int i = 1; i < 32; i++) begin
        print_reg(i);
    end
endfunction

task reset();
    cb.rst <= 1'b1;
    cb.load <= 1'b0;
    cb.in <= 32'b0;
    cb.src_a <= 5'b0;
    cb.src_b <= 5'b0;
    cb.dest <= 5'b0;
    #10;
    cb.rst <= 1'b0;
    #10;
endtask

task regfile_write(bit [4:0] dest, bit [31:0] data);
    cb.load <= 1'b1;
    cb.in <= data;
    cb.dest <= dest;
    #10;
    cb.load <= 1'b0;
endtask

task sequential_write();
    for (int i = 1; i < 32; i++) begin
        regfile_write(i, i);
    end
endtask

initial begin
    $display("Starting simulation.");
    reset();
    print_regfile();
    $display("Writing to regfile...");
    sequential_write();
    #10;
    $display("Wrote to regfile.");
    print_regfile();
    $finish;
end

final begin
    $display("Ending simulation.");
end

endmodule : mp1_tb
