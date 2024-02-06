import rv32i_types::*; /* Import types defined in rv32i_types.sv */

//`define STRIDE 'd16


module prefetcher (
    input clk,
    input rst,

    //Some input and output
    // cache to prefetcher
    input rv32i_word cache_address,
    input logic cache_read,

    //prefetcher to cache
    output logic [255:0] prefetch_rdata,
    output logic prefetch_resp,

    //arbiter to prefetch
    input logic [255:0] arbiter_rdata,
    input logic arbiter_resp,

    // prefetcher to arbiter
    output logic prefetch_read,
    output rv32i_word prefetch_address


);


enum int unsigned {
    idle, miss, prefetch
} state, next_state;

logic prefetch_done_in;
logic prefetch_done_out;
rv32i_word buffer_address_in;
rv32i_word buffer_address_out;
logic [255:0] buffer_rdata_in;
logic [255:0] buffer_rdata_out;
rv32i_word stride1;
rv32i_word stride2;
rv32i_word strideFinal;
logic strideFlag;

logic [255:0] miss_counter;
logic [255:0] prevented_misses;


function void set_default();    
    prefetch_rdata = 'd0;
    prefetch_resp = 'd0;
    prefetch_read = 'd0;
    prefetch_address = 'd0;
    prefetch_done_in = prefetch_done_out;
    buffer_address_in = buffer_address_out;
    buffer_rdata_in = buffer_rdata_out;
    
endfunction


always_comb begin : prefetch_control

    set_default();

    // If its a hit just loop in idle, if a miss then go to miss then prefetch
    case(state)
        idle: begin
            if (cache_read == 'd1) begin
                if (prefetch_done_out == 'd1 && cache_address == buffer_address_out) begin
                    prefetch_rdata = buffer_rdata_out;
                    prefetch_resp = 'd1;
                end
                else
                    buffer_address_in = cache_address + strideFinal; //
            end
        end

        miss: begin
            prefetch_read = 'd1;
            prefetch_address = cache_address;
            prefetch_done_in = 'd0;
            if (arbiter_resp == 'd1) begin
                prefetch_resp = 'd1;
                prefetch_rdata = arbiter_rdata;
            end
        end

        prefetch: begin
            prefetch_read = 'd1;
            prefetch_address = buffer_address_out;
            if (arbiter_resp == 'd1) begin
                prefetch_done_in = 'd1;
                buffer_rdata_in = arbiter_rdata;
            end
        end
    endcase
end : prefetch_control

always_comb begin : logic_next_state
    next_state = state;
    case (state)
        idle: begin
            if (cache_read == 'd1) begin
                if (!(prefetch_done_out == 'd1 && cache_address == buffer_address_out))
                    next_state = miss;                    
            end
        end
        miss: begin
            if (arbiter_resp == 'd1) begin
                next_state = prefetch;
            end
        end

        prefetch: begin
            if (arbiter_resp == 'd1) begin
                next_state = idle;
            end
        end 
    endcase
end : logic_next_state

always_ff @(posedge clk) begin: assign_next_state
    if (!rst) begin
        prefetch_done_out <= prefetch_done_in;
        state <= next_state;
        buffer_address_out <= buffer_address_in;
        buffer_rdata_out <= buffer_rdata_in;
        miss_counter <= miss_counter;
        prevented_misses <= prevented_misses;
        case (state)
            idle: begin
                if (cache_read == 'd1) begin
                    if (prefetch_done_out == 'd1 && cache_address == buffer_address_out) begin
                        prevented_misses <= prevented_misses + 'd1;
                    end
                end
            end
            miss: begin
                miss_counter <= miss_counter + 'd1;
            end
            prefetch: begin
                
            end
        endcase       
    end
    else begin
        state <= idle;
        buffer_address_out <= 'd0;
        buffer_rdata_out <= 'd0;
        prefetch_done_out <= 'd0;
        prevented_misses <= 'd0;
        miss_counter <= 'd0;
    end
end : assign_next_state

//Stride for advanced prefetching
always_ff @(posedge clk) begin : strideAssign
    if (!rst) begin
        if (cache_read == 'd1) begin
            strideFlag <= strideFlag ^ 'd1;
            if (strideFlag == 'd1)
                stride1 <= cache_address;
            else
                stride2 <= cache_address;
	    end
        if (stride2 != 'd0 && stride1 != 'd0)
            strideFinal <= stride2 - stride1;
        else
            strideFinal <= 'd32;
    end
    else begin
        strideFlag <= 'd0;
        stride1 <= 'd0;
        stride2 <= 'd0;
        strideFinal <= 'd32;
	 end
end : strideAssign

endmodule : prefetcher