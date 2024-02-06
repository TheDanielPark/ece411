import rv32i_types::*;

module hazard_detection (
    //inputs
    input if_output if_output_out,
    input id_output id_output_out,
    input logic     stall,


    //outputs
    output logic    hazard_stall
);

always_comb begin : hazard_detection
    if(id_output_out.control_word.read == 1'b1 && ((id_output_out.rd == if_output_out.control_input.rs1 && id_output_out.rd != 0) || (id_output_out.rd == if_output_out.control_input.rs2 && id_output_out.rd != 0))) begin
        hazard_stall = 1'b1;
    end
    else begin
        hazard_stall = 1'b0;
    end

end


endmodule


