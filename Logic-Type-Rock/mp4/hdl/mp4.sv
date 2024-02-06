import rv32i_types::*;

module mp4(
  input clk,
  input rst,
  input mem_resp,
  input [63:0] mem_rdata,
  output logic mem_read,
  output logic mem_write,
  output rv32i_word mem_addr,
  output [63:0] mem_wdata
);

logic resp_a;
rv32i_word rdata_a;
logic resp_b;
rv32i_word rdata_b;
logic read_a;
logic read_b;
rv32i_word address_a;
rv32i_word address_b;
logic write;
logic [3:0] wmask;
rv32i_word wdata;

logic arb_mem_resp;
logic [255:0] arb_mem_rdata;
logic arb_mem_read;
logic arb_mem_write;
rv32i_word arb_mem_addr;
logic [255:0] arb_mem_wdata;

// Instruction Cache
logic arb_instr_read;
rv32i_word arb_instr_address;
logic arb_instr_resp;
logic [255:0] arb_instr_rdata;

// Data Cache 
logic arb_data_read;
rv32i_word arb_data_address;
logic arb_data_write;
logic [255:0] arb_data_wdata;
logic [255:0] arb_data_rdata;
logic arb_data_resp;


//prefetch
logic cache_prefetch_read;
rv32i_word cache_prefetch_address;
logic [255:0] prefetch_rdata;
logic prefetch_resp;

//EWB
logic cache_ewb_read;
rv32i_word cache_ewb_address;
logic cache_ewb_write;
logic [255:0] cache_ewb_wdata;

logic ewb_write;
logic [255:0] ewb_wdata;
logic [255:0] ewb_rdata;
logic ewb_resp;

// hit and tag_load
logic instruction_hit;
logic instruction_tagload;
logic data_hit;
logic data_tagload;

// L2 Cache signals

rv32i_word L2_address_a;
logic [255:0] L2_L1_instr_data;
logic L2_L1_instr_resp;
logic L2_L1_instr_read;

rv32i_word L2_address_b;
logic [255:0] L2_L1_data_wdata;
logic [255:0] L2_L1_data_rdata;
logic L2_L1_data_resp;
logic L2_L1_data_read;
logic L2_L1_data_write;



/************Signals Needed for RVFI Monitor************/


/*******************************************************/

/********************Signals********************/


/***********************************************/

/* Instantiate top level blocks here */

//Datapath
pipeline_datapath datapath(
  .clk(clk),
  .rst(rst),
  .resp_a(resp_a),
  .rdata_a(rdata_a),
  .resp_b(resp_b),
  .rdata_b(rdata_b),

  // Outputs
  .read_a(read_a),
  .read_b(read_b),
  .address_a(address_a),
  .address_b(address_b),
  .write(write),
  .wmask(wmask),
  .wdata(wdata)
);

// COMMENT OUT PREFETCHER AND USE GENERAL IF JUST RAW 
// COMMENT OUT GENERAL AND USE PREFETCHER TO USE PREFETCHING

 // Instruction Cache for prefetching
 cache instr_cache (
   .clk(clk),
     // Physical memory signals 
   .pmem_resp(prefetch_resp),
   .pmem_rdata(prefetch_rdata),
   .pmem_address(cache_prefetch_address),
   .pmem_wdata(),
   .pmem_read(cache_prefetch_read),
   .pmem_write(),

   // CPU memory signals 
   .mem_read(read_a),
   .mem_write(1'b0),
   .mem_byte_enable_cpu(4'b1111),
   .mem_address(address_a),
   .mem_wdata_cpu(32'b0),
   .mem_resp(resp_a),
   .mem_rdata_cpu(rdata_a),
   .hit_o(instruction_hit),
   .tag_load_o(instruction_tagload)
 );

/*
 // L2_instr_Cache Prefetching 
   L2_cache L2_instr_cache (
   .clk(clk),
     // Physical memory signals 
   .pmem_resp(prefetch_resp),
   .pmem_rdata(prefetch_rdata),
   .pmem_address(cache_prefetch_address),
   .pmem_wdata(),
   .pmem_read(cache_prefetch_read),
   .pmem_write(),

   // CPU memory signals 
   .mem_read(L2_L1_instr_read),              
   .mem_write(1'b0),
   .mem_byte_enable_cpu(4'b1111),
   .mem_address(L2_address_a),        
   .mem_wdata('d0),          
   .mem_resp(L2_L1_instr_resp),
   .mem_rdata(L2_L1_instr_data),        
   .hit_o(),
   .tag_load_o()
   );
*/
/*
// L2  inst Cache general 
L2_cache L2_instr_cache (
  .clk(clk),
    // Physical memory signals 
  .pmem_resp(arb_instr_resp),
  .pmem_rdata(arb_instr_rdata),
  .pmem_address(arb_instr_address),
  .pmem_wdata(),
  .pmem_read(arb_instr_read),
  .pmem_write(),

  // CPU memory signals 
  .mem_read(L2_L1_instr_read),              
  .mem_write(1'b0),
  .mem_byte_enable_cpu(4'b1111),
  .mem_address(L2_address_a),        
  .mem_wdata('d0),          
  .mem_resp(L2_L1_instr_resp),
  .mem_rdata(L2_L1_instr_data),        
  .hit_o(),
  .tag_load_o()
);
*/

/*
cache instr_cache (
  // Physical memory signals
  .clk(clk),
  .pmem_resp(L2_L1_instr_resp),
  .pmem_rdata(L2_L1_instr_data),
  .pmem_address(L2_address_a),
  .pmem_wdata(),
  .pmem_read(L2_L1_instr_read),
  .pmem_write(),


  .mem_read(read_a),
  .mem_write(1'b0),
  .mem_byte_enable_cpu(4'b1111),
  .mem_address(address_a),
  .mem_wdata_cpu(32'b0),
  .mem_resp(resp_a),
  .mem_rdata_cpu(rdata_a),
  .hit_o(instruction_hit),
  .tag_load_o(instruction_tagload)
);
*/

// Arbiter EWB
arbiter arbiter_U (
  .clk(clk),
  .rst(rst),
  // Instruction Cache
  .arb_instr_read(arb_instr_read),
  .arb_instr_address(arb_instr_address),
  .arb_instr_resp(arb_instr_resp),
  .arb_instr_rdata(arb_instr_rdata),

  // Data Cache
  .arb_data_read(arb_data_read),
  .arb_data_address(arb_data_address),
  .arb_data_write(arb_data_write),
  .arb_data_wdata(arb_data_wdata),
  .arb_data_rdata(arb_data_rdata),
  .arb_data_resp(arb_data_resp),


  // From Memory
  .arb_mem_resp(arb_mem_resp),
  .arb_mem_rdata(arb_mem_rdata),
  .arb_mem_read(arb_mem_read),
  .arb_mem_write(arb_mem_write),
  .arb_mem_addr(arb_mem_addr),
  .arb_mem_wdata(arb_mem_wdata)
);
/*
// L2 data cache EWB
L2_cache L2_data_cache (
  .clk(clk),
    // Physical memory signals 
  .pmem_resp(ewb_resp),
  .pmem_rdata(ewb_rdata),
  .pmem_address(cache_ewb_address),
  .pmem_wdata(cache_ewb_wdata),
  .pmem_read(cache_ewb_read),
  .pmem_write(cache_ewb_write),

  // From L1 / to L2
  .mem_read(L2_L1_data_read),
  .mem_write(L2_L1_data_write),
  .mem_byte_enable_cpu(wmask),
  .mem_address(L2_address_b),
  .mem_wdata(L2_L1_data_wdata),
  .mem_resp(L2_L1_data_resp),
  .mem_rdata(L2_L1_data_rdata),
  .hit_o(),
  .tag_load_o()
);
*/
/*
// L2 data cache General
L2_cache L2_data_cache (
  .clk(clk),
    // Physical memory signals 
  .pmem_resp(arb_data_resp),
  .pmem_rdata(arb_data_rdata),
  .pmem_address(arb_data_address),
  .pmem_wdata(arb_data_wdata),
  .pmem_read(arb_data_read),
  .pmem_write(arb_data_write),

  // From L1 / to L2
  .mem_read(L2_L1_data_read),
  .mem_write(L2_L1_data_write),
  .mem_byte_enable_cpu(wmask),
  .mem_address(L2_address_b),
  .mem_wdata(L2_L1_data_wdata),
  .mem_resp(L2_L1_data_resp),
  .mem_rdata(L2_L1_data_rdata),
  .hit_o(),
  .tag_load_o()
);
*/

/*
// Data Cache for L2 cache
 cache data_cache (
  // Physical memory signals
  .clk(clk),
  .pmem_resp(L2_L1_data_resp),
  .pmem_rdata(L2_L1_data_rdata),
  .pmem_address(L2_address_b),
  .pmem_wdata(L2_L1_data_wdata),
  .pmem_read(L2_L1_data_read),
  .pmem_write(L2_L1_data_write),

  // From CPU
  .mem_read(read_b),
  .mem_write(write),
  .mem_byte_enable_cpu(wmask),
  .mem_address(address_b),
  .mem_wdata_cpu(wdata),
  .mem_resp(resp_b),
  .mem_rdata_cpu(rdata_b),
  .hit_o(data_hit),
  .tag_load_o(data_tagload)
);
*/


/*
// Data Cache GENERAL
cache data_cache (
  .clk(clk),
    // Physical memory signals 
  .pmem_resp(arb_data_resp),
  .pmem_rdata(arb_data_rdata),
  .pmem_address(arb_data_address),
  .pmem_wdata(arb_data_wdata),
  .pmem_read(arb_data_read),
  .pmem_write(arb_data_write),

  // CPU memory signals 
  .mem_read(read_b),
  .mem_write(write),
  .mem_byte_enable_cpu(wmask),
  .mem_address(address_b),
  .mem_wdata_cpu(wdata),
  .mem_resp(resp_b),
  .mem_rdata_cpu(rdata_b),
  .hit_o(data_hit),
  .tag_load_o(data_tagload)
);
*/

// Data Cache for EWB
cache data_cache (
  .clk(clk),
    // Physical memory signals 
  .pmem_resp(ewb_resp),
  .pmem_rdata(ewb_rdata),
  .pmem_address(cache_ewb_address),
  .pmem_wdata(cache_ewb_wdata),
  .pmem_read(cache_ewb_read),
  .pmem_write(cache_ewb_write),

  // CPU memory signals 
  .mem_read(read_b),
  .mem_write(write),
  .mem_byte_enable_cpu(wmask),
  .mem_address(address_b),
  .mem_wdata_cpu(wdata),
  .mem_resp(resp_b),
  .mem_rdata_cpu(rdata_b),
  .hit_o(data_hit),
  .tag_load_o(data_tagload)
);


// Cacheline Adaptor
cacheline_adaptor U_cacheline_adaptor (
  .clk(clk),
  .reset_n(~rst),

  // Port to LLC (Lowest Level Cache)
  .line_i(arb_mem_wdata),
  .line_o(arb_mem_rdata),
  .address_i(arb_mem_addr),
  .read_i(arb_mem_read),
  .write_i(arb_mem_write),
  .resp_o(arb_mem_resp),

  // Port to memory
  .burst_i(mem_rdata),
  .burst_o(mem_wdata),
  .address_o(mem_addr),
  .read_o(mem_read),
  .write_o(mem_write),
  .resp_i(mem_resp)
);


 //prefetching
 prefetcher prefetcher_thing (
     .clk(clk),
     .rst(rst),

     // cache to prefetcher
     .cache_address(cache_prefetch_address),
     .cache_read(cache_prefetch_read),

     //prefetcher to cache
     .prefetch_rdata(prefetch_rdata),
     .prefetch_resp(prefetch_resp),

     //arbiter to prefetch
     .arbiter_rdata(arb_instr_rdata),
     .arbiter_resp(arb_instr_resp),

     // prefetcher to arbiter
     .prefetch_read(arb_instr_read),
     .prefetch_address(arb_instr_address)

 );



ewb ewb_thing (
    .clk,
    .rst,

    // cache to ewb
    .cache_address(cache_ewb_address),
    .cache_read(cache_ewb_read),
    .cache_write(cache_ewb_write),
    .cache_wdata(cache_ewb_wdata),

    //ewb to cache
    .ewb_rdata(ewb_rdata),
    .ewb_resp(ewb_resp),

    //arbiter to ewb
    .arbiter_rdata(arb_data_rdata),
    .arbiter_resp(arb_data_resp),

    // ewb to arbiter
    .ewb_read(arb_data_read),
    .ewb_address(arb_data_address),
    .ewb_write(arb_data_write),
    .ewb_wdata(arb_data_wdata)
);



logic [255:0] counter_iHit;
logic [255:0] counter_iMiss;
logic [255:0] counter_dHit;
logic [255:0] counter_dMiss;

//Counters

//Cache instruction hit
always_ff @(posedge clk) begin: cache_iHit

  if (rst) begin
    counter_iHit <= 0;
    counter_iMiss <= 0;
    counter_dHit <= 0;
    counter_dMiss <= 0;
  end
  if (instruction_hit == 'd1)
    counter_iHit <= counter_iHit + 'd1;
  if (instruction_tagload == 'd1)
    counter_iMiss <= counter_iMiss + 'd1;
  
  if (data_hit == 'd1)
    counter_dHit <= counter_dHit + 'd1;
  if (data_tagload == 'd1)
    counter_dMiss <= counter_dMiss + 'd1;
end : cache_iHit

//Cache instruction miss

//Cache data hit

//Cache data miss




endmodule : mp4
