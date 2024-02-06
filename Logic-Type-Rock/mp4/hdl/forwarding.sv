import rv32i_types::*;

// IMPORTANT: GOING TO HAVE TO ADD FORWARDING LOGIC INTO CONTROL ALSO

typedef logic [4:0] rv32i_reg;

module forwarding (
    // INPUTS to forwarding unit and forwardA/B mux?
    
    // Outputs from forwarding unit
    
    
    input id_output control_id, 
    input ex_output control_ex, 
    input mem_output control_mem,
    input rv32i_word memmux_out,
    
    output logic [1:0] forwardB_sel,
    output logic [1:0] forwardA_sel,
    output logic memForwardMux_sel
    //output logic load_stall
);

// ForwardA Mux inputs are write_data (comes from regfilemux), exmem.wb, rs1_out

// ForwardB mux inputs are rs2_out, write_data (comes from regfilemux). exmem.wb


always_comb
begin

    //set default values for forward select
    forwardA_sel = 2'b00;
    forwardB_sel = 2'b00;
    memForwardMux_sel = 1'b0;
    //load_stall = 1'b0;
    // Ex Hazard. ex/mem stage
    // ex_output_out.control_output.load_regfile? if so how to use that
    if (control_ex.control_word.load_regfile == 1'b1 && (control_ex.rd == control_id.control_word.rs1) && control_ex.rd != 'b0) 
        forwardA_sel = 2'b01;
    else if (control_mem.control_word.load_regfile == 1'b1 && control_mem.rd != 'b0 && control_mem.rd == control_id.control_word.rs1)
        forwardA_sel = 2'b11; //not sure but comes from data path regfilemux out

    if (control_ex.control_word.load_regfile == 1'b1 && (control_ex.rd == control_id.control_word.rs2) && control_ex.rd != 'b0)
        forwardB_sel = 2'b01;
    else if (control_mem.control_word.load_regfile == 1'b1 && control_mem.rd != 'b0 && control_mem.rd == control_id.control_word.rs2)
        forwardB_sel = 2'b11; //not sure but comes from data path regfilemux out

    if (control_mem.control_word.load_regfile == 1'b1 && control_mem.rd != 'b0 && control_mem.rd == control_ex.control_word.rs2) //(control_mem.rd == control_ex.control_word.rs1 || 
        memForwardMux_sel = 1'b1;

    //if (control_mem.control_word.load_regfile == 1'b1 && control_mem.rd != 'b0 && control_mem.rd == control_ex.control_word.rs2)
    //    forwardB_sel = 2'b11;


    // Mem Hazard. mem/wb stage
    // mem_output_out.control_output.load_regfile?
    
    
    //if (control_ex.control_word.load_regfile == 1'b1 && control_ex.rd != 'b0 && !(control_mem.control_word.load_regfile == 1'b1 && (control_mem.rd != 'b0) && control_mem.rd != control_id.control_word.rs1) && control_mem.rd == control_ex.control_word.rs1)
    //    forwardA_sel = 2'b11;

    //if (control_ex.control_word.load_regfile == 1'b1 && control_ex.rd != 'b0 && !(control_mem.control_word.load_regfile == 1'b1 && (control_mem.rd != 'b0) && control_mem.rd != control_id.control_word.rs2) && control_mem.rd == control_ex.control_word.rs2)
    //    forwardB_sel = 2'b11;


    //mem -> ex
    //if (control_ex.control_word.load_regfile == 1'b1 && (control_ex.rd == control_id.rs1_out) && control_ex.rd != 'b0) begin
    //    if (control_ex.control_word.regfilemux_sel == )

    // if (control_mem.control_word.load_regfile == 1'b1 && control_mem.rd != 'b0 && !(control_ex.control_word.load_regfile == 1'b1 && (control_ex.rd != 'b0) && control_ex.rd != control_id.control_word.rs1) && control_mem.rd == control_id.control_word.rs1)
    //    forwardA_sel = 2'b01; //not sure but comes from data path regfilemux out

    //if (control_mem.control_word.load_regfile == 1'b1 && control_mem.rd != 'b0 && !(control_ex.control_word.load_regfile == 1'b1 && (control_ex.rd != 'b0) && control_ex.rd != control_id.control_word.rs2) && control_mem.rd == control_id.control_word.rs2)
    //    forwardB_sel = 2'b01; //not sure but comes from data path regfilemux out

end

endmodule : forwarding