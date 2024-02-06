module L2_cache (
  input clk,

  /* Physical memory signals */
  input logic pmem_resp,
  input logic [255:0] pmem_rdata,
  output logic [31:0] pmem_address,
  output logic [255:0] pmem_wdata,
  output logic pmem_read,
  output logic pmem_write,

  /* CPU memory signals */
  input logic mem_read,
  input logic mem_write,
  input logic [3:0] mem_byte_enable_cpu,
  input logic [31:0] mem_address,
  input logic [255:0] mem_wdata,
  output logic mem_resp,
  output logic [255:0] mem_rdata,

  output logic hit_o,
  output logic tag_load_o
);

logic tag_load;
logic valid_load;
logic dirty_load;
logic dirty_in;
logic dirty_out;

logic hit;
logic [1:0] writing;

logic [31:0] mem_byte_enable;

cache_control control(.*);
cache_datapath datapath(.*);

assign hit_o = hit;
assign tag_load_o = tag_load;
assign mem_byte_enable = 32'hFFFFFFFF;

/*
line_adapter bus (
    .mem_wdata_line(),
    .mem_rdata_line(mem_rdata),
    .mem_wdata(),
    .mem_rdata(),
    .mem_byte_enable(),
    .mem_byte_enable_line(),
    .address(mem_address)
);
*/

endmodule : L2_cache
