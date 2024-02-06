import rv32i_types::*; /* Import types defined in rv32i_types.sv */


module ewb (
    input clk,
    input rst,

    //Some input and output
    // cache to ewb
    input rv32i_word cache_address,
    input logic cache_read,
    input logic cache_write,
    input logic [255:0] cache_wdata,

    //ewb to cache
    output logic [255:0] ewb_rdata,
    output logic ewb_resp,

    //arbiter to ewb
    input logic [255:0] arbiter_rdata,
    input logic arbiter_resp,

    // ewb to arbiter
    output logic ewb_read,
    output rv32i_word ewb_address,
    output logic ewb_write,
    output logic [255:0] ewb_wdata
);

enum int unsigned {
    idle, read, write
}state, next_state;

logic write_flag;
logic load_write;
rv32i_word buffer_address_in;
rv32i_word buffer_address_out;
logic [255:0] buffer_rdata_in;
logic [255:0] buffer_rdata_out;
logic [255:0] ewb_hit_counter;
logic [255:0] data_eviction_counter;

function void set_default();    
    ewb_rdata = 'd0;
    ewb_resp = 'd0;
    ewb_read = 'd0;
    ewb_address = 'd0;
    ewb_write = 'd0;
    ewb_wdata = 'd0;
    load_write = 'd0;
    //prefetch_done_in = prefetch_done_out;
    buffer_address_in = buffer_address_out;
    buffer_rdata_in = buffer_rdata_out;
endfunction

always_comb begin: control_logic
    set_default();

    case(state)
        idle: begin
            if (cache_read == 'd1 && (buffer_address_out == cache_address))  begin // Hit occurs so service the cache
                ewb_rdata = buffer_rdata_out;
                ewb_resp = 'd1;
            end
            if (cache_write == 'd1) begin
                buffer_address_in = cache_address;
                buffer_rdata_in = cache_wdata;
                ewb_resp = 'd1;
                load_write = 'd1;
            end
		  end
        
        read: begin // Without a hit read
            ewb_rdata = arbiter_rdata;
            ewb_address = cache_address;
            ewb_read = 'd1;
            ewb_resp = arbiter_resp;
        end

        write: begin
            ewb_address = buffer_address_out;
            ewb_wdata = buffer_rdata_out;
            ewb_write = 'd1;
        end

    endcase
end : control_logic

always_comb begin: logic_next_state
    next_state = state;
    case(state)
        idle: begin
            if (cache_read == 'd1 && (buffer_address_out == cache_address)) begin
                next_state = idle;
            end
            else if (cache_read == 'd1)
                next_state = read;
        end

        read: begin
            if (arbiter_resp == 'd1) begin
                if (!write_flag)
                    next_state = idle;
                else
                    next_state = write;
            end
        end

        write: begin
            if (arbiter_resp == 'd1)
                next_state = idle;
        end

    endcase
end : logic_next_state

always_ff @(posedge clk) begin : assign_next_state
    if (!rst) begin
        buffer_address_out <= buffer_address_in;
        buffer_rdata_out <= buffer_rdata_in;
        state <= next_state;
        if (load_write == 'd1)
            write_flag <= 'd1;
        if (state == write && arbiter_resp == 'd1)
            write_flag <= 'd0;
        if (cache_read == 'd1 && (buffer_address_out == cache_address)) begin
            ewb_hit_counter <= ewb_hit_counter + 1'd1;
        end else 
            ewb_hit_counter <= ewb_hit_counter;
	end
    else begin
        buffer_address_out <= 'd0;
        buffer_rdata_out <= 'd0;
        state <= idle;
        write_flag <= 'd0;
        ewb_hit_counter <= 'd0;
        data_eviction_counter <= 'd0;
	 end

end : assign_next_state

always_ff @(posedge load_write) begin : data_eviction
    data_eviction_counter <= data_eviction_counter + 'd1;
end : data_eviction

endmodule: ewb