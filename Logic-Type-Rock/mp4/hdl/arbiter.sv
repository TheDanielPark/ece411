import rv32i_types::*;

module arbiter(
    input logic clk,
    input logic rst,
    
    // Instruction Cache
    input logic arb_instr_read,
    input rv32i_word arb_instr_address,
    output logic arb_instr_resp,
    output logic [255:0] arb_instr_rdata,

    // Data Cache
    input logic arb_data_read,
    input rv32i_word arb_data_address,
    input logic arb_data_write,
    input logic [255:0] arb_data_wdata,
    output logic [255:0] arb_data_rdata,
    output logic arb_data_resp,


    // From Memory
    input logic arb_mem_resp,
    input logic [255:0] arb_mem_rdata,
    output logic arb_mem_read,
    output logic arb_mem_write,
    output rv32i_word arb_mem_addr,
    output logic [255:0] arb_mem_wdata
);

//insert states and state logic here
enum int unsigned {
    idle = 0,
    instr_mem = 1,
    data_mem = 2
} state, next_state;

function void defaults();
    arb_mem_wdata = 'd0;
    arb_mem_addr = 'd0;
    arb_mem_write = 'd0;
    arb_mem_read = 'd0;
    arb_data_rdata = 'd0;
    arb_data_resp = 'd0;
    arb_instr_rdata = 'd0;
    arb_instr_resp = 'd0;
endfunction

always_comb
begin : arbitration
    defaults();
    unique case (state)
        idle: begin

        end
        instr_mem: begin
            arb_mem_read = 1'b1;
            arb_mem_addr = arb_instr_address;
            arb_instr_rdata = arb_mem_rdata;
            arb_instr_resp = arb_mem_resp;
        end
        data_mem: begin
            if (arb_data_write) begin
                arb_mem_write = 1'b1;
                arb_mem_addr = arb_data_address;
                arb_mem_wdata = arb_data_wdata;
                arb_data_resp = arb_mem_resp;
            end else if (arb_data_read) begin
                arb_mem_read = 1'b1;
                arb_mem_addr = arb_data_address;
                arb_data_rdata = arb_mem_rdata;
                arb_data_resp = arb_mem_resp;
            end
        end
        default: defaults();
    endcase
end

always_comb
begin : FSM
    unique case (state)
        idle: begin
            if (arb_instr_read) next_state = instr_mem;
            else if (arb_data_read || arb_data_write) next_state = data_mem;
            else next_state = idle;
        end
        instr_mem: begin
            if (arb_mem_resp == 'd0) next_state = instr_mem;
            else if (arb_data_read || arb_data_write) next_state = data_mem;
            else next_state = idle;
        end
        data_mem: begin
            if (arb_mem_resp == 'd0) next_state = data_mem;
            else if (arb_instr_read) next_state = instr_mem;
            else next_state = idle;
        end
        default: next_state = idle;
    endcase
end


always_ff @(posedge clk)
begin
    if (rst) begin
        state <= idle;
    end
    else begin
        state <= next_state;
    end
end

endmodule:arbiter