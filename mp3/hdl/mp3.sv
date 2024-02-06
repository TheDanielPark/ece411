/* DO NOT MODIFY. WILL BE OVERRIDDEN BY THE AUTOGRADER. */

import rv32i_types::*;

module mp3
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

/*************************** CPU <-> Cache Signals ****************************/
rv32i_word mem_address, mem_rdata, mem_wdata;
logic mem_read, mem_write, mem_resp;
logic [3:0] mem_byte_enable;
/******************************************************************************/

/******************** Cache <-> Cacheline Adapter Signals *********************/
rv32i_word cline_address;
logic [255:0] cline_rdata, cline_wdata;
logic cline_read, cline_write, cline_resp;
/******************************************************************************/

cpu_golden cpu(
    .clk(clk),
    .rst(rst),
    .mem_address(mem_address),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .mem_resp(mem_resp)
);

cache cache(
    .clk(clk),
    .rst(rst),
    .mem_address(mem_address),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .mem_resp(mem_resp),
    .pmem_address(cline_address),
    .pmem_rdata(cline_rdata),
    .pmem_wdata(cline_wdata),
    .pmem_read(cline_read),
    .pmem_write(cline_write),
    .pmem_resp(cline_resp)
);

cacheline_adaptor cacheline_adaptor
(
    .clk(clk),
    .reset_n(~rst),
    .line_i(cline_wdata),
    .line_o(cline_rdata),
    .address_i(cline_address),
    .read_i(cline_read),
    .write_i(cline_write),
    .resp_o(cline_resp),
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : mp3
