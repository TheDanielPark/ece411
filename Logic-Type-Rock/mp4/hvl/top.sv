module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;

/****************************** End do not touch *****************************/
//
///************************ Signals necessary for monitor **********************/
//// This section not required until CP2
//

logic [31:0] inst_delayed;
logic [31:0] rs1_rdata_delayed;
logic [31:0] rs2_rdata_delayed;
logic [31:0] rd_wdata_delayed;
logic [31:0] mem_addr_delayed;
logic [3:0] mem_wmask_delayed;
logic [31:0] mem_wdata_delayed;
logic [31:0] pc_rdata_delayed;
logic [31:0] pc_wdata_delayed;
// logic br_en_delayed;
logic valid_delayed;



always_ff @(posedge itf.clk) begin
    if(~dut.datapath.stall) begin
        inst_delayed        <= 'd0; 
        rs1_rdata_delayed   <= dut.datapath.ex_output_out.rs1_out;
        rs2_rdata_delayed   <= dut.datapath.ex_output_out.rs2_out;
        rd_wdata_delayed    <= dut.datapath.memmux_out;
        mem_addr_delayed    <= dut.datapath.address_b;
        mem_wmask_delayed   <= dut.datapath.wmask;
        mem_wdata_delayed   <= dut.datapath.wdata;
        // br_en_delayed       <= dut.datapath.control_input.br_en;
        pc_rdata_delayed    <= dut.datapath.ex_output_out.pc;
        pc_wdata_delayed    <= (dut.datapath.control_input.br_en) ? dut.datapath.ex_output_out.alu_out : dut.datapath.ex_output_out.pc + 4;
        valid_delayed       <= dut.datapath.ex_output_out.control_word.valid;
    end
end


initial rvfi.order = 'd0;
assign rvfi.commit = 'd0; // Set high when a valid instruction is modifying regfile or PC (valid_delayed)
assign rvfi.halt = (rvfi.pc_wdata == rvfi.pc_rdata) && rvfi.commit;   // Set high when you detect an infinite loop
// // // Instruction and trap:
assign rvfi.inst = dut.datapath.mem_output_out.control_word.rdata_a;
assign rvfi.trap = 'd0;
// // Regfile:
assign rvfi.rs1_addr = dut.datapath.mem_output_out.control_word.rs1;
assign rvfi.rs2_addr = dut.datapath.mem_output_out.control_word.rs2;
assign rvfi.rs1_rdata = rs1_rdata_delayed;
assign rvfi.rs2_rdata = rs2_rdata_delayed;
assign rvfi.load_regfile = dut.datapath.mem_output_out.control_word.load_regfile;
assign rvfi.rd_addr = dut.datapath.mem_output_out.rd;
assign rvfi.rd_wdata = rd_wdata_delayed;
// // // PC:
assign rvfi.pc_rdata = pc_rdata_delayed;
assign rvfi.pc_wdata = pc_wdata_delayed;
// // // Memory:
assign rvfi.mem_addr = mem_addr_delayed;
assign rvfi.mem_rmask = 4'bxxxx;
assign rvfi.mem_wmask = dut.datapath.mem_output_out.control_word.wmask;
assign rvfi.mem_rdata = dut.datapath.mem_output_out.rdata_b;
assign rvfi.mem_wdata = mem_wdata_delayed;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*


The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/

// icache signals:
assign itf.inst_read = dut.read_a;
assign itf.inst_addr = dut.address_a;
assign itf.inst_resp = dut.resp_a;
assign itf.inst_rdata = dut.rdata_a;

// dcache signals:
assign itf.data_read = dut.read_b;
assign itf.data_write = dut.write;
assign itf.data_mbe = dut.wmask;
assign itf.data_addr = dut.address_b;
assign itf.data_wdata = dut.wdata;
assign itf.data_resp = dut.resp_b;
assign itf.data_rdata = dut.rdata_b;

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.datapath.regfile.data;

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    // Inputs
    .clk(itf.clk),
    .rst(itf.rst),
    // .resp_a(itf.inst_resp),
    // .rdata_a(itf.inst_rdata),
    // .resp_b(itf.data_resp),
    // .rdata_b(itf.data_rdata),

    // // Outputs
    // .read_a(itf.inst_read),
    // .read_b(itf.data_read),
    // .address_a(itf.inst_addr),
    // .address_b(itf.data_addr),
    // .write(itf.data_write),
    // .wmask(itf.data_mbe),
    // .wdata(itf.data_wdata)

    .mem_resp(itf.mem_resp),
    .mem_rdata(itf.mem_rdata),
    .mem_read(itf.mem_read),
    .mem_write(itf.mem_write),
    .mem_addr(itf.mem_addr),
    .mem_wdata(itf.mem_wdata)
);
/***************************** End Instantiation *****************************/

endmodule
