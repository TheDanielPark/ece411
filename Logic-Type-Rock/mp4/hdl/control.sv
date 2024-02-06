import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input clk,
    input rst,
    //input logic mem_resp,
	input rv32i_word mem_address,
	input if_output if_output_out,
//	input rv32i_control_input control_input,
	output rv32i_control_output control_output
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask;
rv32i_control_input control_input;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;
rv32i_opcode opcode;

assign control_input = if_output_out.control_input;

assign control_output.i_imm = if_output_out.i_imm;
assign control_output.u_imm = if_output_out.u_imm;
assign control_output.b_imm = if_output_out.b_imm;
assign control_output.s_imm = if_output_out.s_imm;
assign control_output.j_imm = if_output_out.j_imm;

assign control_output.opcode = control_input.opcode;
assign control_output.rdata_a = if_output_out.rdata_a;

assign arith_funct3 = arith_funct3_t'(control_input.funct3);
assign branch_funct3 = branch_funct3_t'(control_input.funct3);
assign load_funct3 = load_funct3_t'(control_input.funct3);
assign store_funct3 = store_funct3_t'(control_input.funct3);
assign rs1_addr = control_input.rs1;
assign rs2_addr = control_input.rs2;
assign opcode = control_input.opcode;

assign control_output.rs1 = control_input.rs1;
assign control_output.rs2 = control_input.rs2;
assign control_output.valid = control_input.valid;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    control_output.wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011 << mem_address[1:0]; /* Modify for MP1 Final */ 
                lb, lbu: rmask = 4'b0001 << mem_address[1:0]; /* Modify for MP1 Final */ 
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: control_output.wmask = 4'b1111;
                sh: control_output.wmask = 4'b0011 << mem_address[1:0]; /* Modify for MP1 Final */ 
                sb: control_output.wmask = 4'b0001 << mem_address[1:0]; /* Modify for MP1 Final */ 
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end


/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb begin
	// Set the default control word signals
	control_output.pcmux_sel = 'd0;
	control_output.regfilemux_sel = regfilemux::alu_out;
	control_output.alumux1_sel = 'd0;
	control_output.alumux2_sel = 'd0;
	control_output.cmpmux_sel = 'd0;

	control_output.memmux_sel = 'd0;

	control_output.aluop = alu_ops'(control_input.funct3);
	control_output.cmpop = branch_funct3_t'(control_input.funct3);

	control_output.load_regfile = 'd0;
	control_output.load_pc = 'd1;
	control_output.load_data_out = 'd0;
	control_output.read = 1'b0;
	control_output.write = 1'b0;
	//control_output.forward_rs2 = 1'b0;
	//control_output.forward_stall = 1'b0;


    /* Actions for each state */
	case (opcode)
		 op_lui: begin
			control_output.load_regfile = 1'b1;
			control_output.regfilemux_sel = regfilemux::u_imm;
		 end
		 
		 op_auipc: begin
			control_output.load_regfile = 1'b1;
			control_output.alumux1_sel = alumux::pc_out;
			control_output.alumux2_sel = alumux::u_imm;
			control_output.aluop = alu_add;
		 end
		 
		op_jal: begin
			control_output.pcmux_sel = pcmux::alu_out;
			control_output.alumux1_sel = alumux::pc_out;
			control_output.alumux2_sel = alumux::j_imm;
			control_output.load_regfile = 1'b1;
			control_output.regfilemux_sel = regfilemux::pc_plus4;
			control_output.aluop = alu_add;
		end

		 op_jalr: begin
			control_output.pcmux_sel = pcmux::alu_out;
			control_output.alumux1_sel = alumux::rs1_out;
			control_output.alumux2_sel = alumux::i_imm;
			control_output.load_regfile = 1'b1;
			control_output.regfilemux_sel = regfilemux::pc_plus4;
			control_output.aluop = alu_add;
		 end
		 
		 op_br: begin
			control_output.cmpmux_sel = cmpmux::rs2_out;
			control_output.pcmux_sel = pcmux::alu_out;
			control_output.aluop = alu_add;
			control_output.alumux1_sel = alumux::pc_out;
			control_output.alumux2_sel = alumux::b_imm;
			//control_output.forward_rs2 = 1'b1;
		 end 

		 op_load: begin
			control_output.load_regfile = 1'b1;
			control_output.read = 1'b1;
			control_output.aluop = alu_add;
			case (load_funct3)
				lb: control_output.regfilemux_sel = regfilemux::lb;
				lh: control_output.regfilemux_sel = regfilemux::lh;
				lw: control_output.regfilemux_sel = regfilemux::lw;
				lbu: control_output.regfilemux_sel = regfilemux::lbu;
				lhu: control_output.regfilemux_sel = regfilemux::lhu;
				default: ;
			endcase
		 end
		 
		 op_store: begin
		 	control_output.write = 1'b1;
			control_output.alumux1_sel = alumux::rs1_out;
			control_output.alumux2_sel = alumux::s_imm;
			control_output.aluop = alu_add;
			//control_output.forward_rs2 = 1'b1; 
			case (store_funct3)
				sb: control_output.memmux_sel = sb; 
				sh: control_output.memmux_sel = sh;
				sw: control_output.memmux_sel = sw;
			default: ;
			endcase
		 end

		 op_imm: begin
		 	case (arith_funct3)
			 	slt: begin
				 	control_output.cmpmux_sel = cmpmux::i_imm;
					control_output.cmpop = blt;
					control_output.regfilemux_sel = regfilemux::br_en;
					control_output.load_regfile = 1'b1;
				end

				sltu: begin
					control_output.cmpmux_sel = cmpmux::i_imm;
					control_output.cmpop = bltu;
					control_output.regfilemux_sel = regfilemux::br_en;
					control_output.load_regfile = 1'b1;
				end
		
				sr: begin
					control_output.regfilemux_sel = regfilemux::alu_out;
					control_output.load_regfile = 1'b1;
					control_output.alumux1_sel = alumux::rs1_out;
					control_output.alumux2_sel = alumux::i_imm;
					if (control_input.funct7[5]) begin
						control_output.aluop = alu_sra;
					end else
					begin
						control_output.aluop = alu_srl;
					end
				end

				default: begin
					control_output.regfilemux_sel = regfilemux::alu_out;
					control_output.load_regfile = 1'b1;
					control_output.alumux1_sel = alumux::rs1_out;
					control_output.alumux2_sel = alumux::i_imm;
					control_output.aluop = alu_ops'(arith_funct3);
				end
			endcase
		 end

		op_reg: begin
			control_output.pcmux_sel = pcmux::pc_plus4;
			//control_output.forward_rs2 = 1'b1;
			case (arith_funct3)
				add: begin
					control_output.regfilemux_sel = regfilemux::alu_out;
					control_output.alumux1_sel = alumux::rs1_out;
					control_output.alumux2_sel = alumux::rs2_out;
					control_output.load_regfile = 1'b1;
					if (control_input.funct7[5]) begin
						control_output.aluop = alu_sub;
					end
					else begin
						control_output.aluop = alu_add;
					end
				end

				slt: begin
					control_output.load_regfile = 1'b1;
					control_output.regfilemux_sel = regfilemux::br_en;
					control_output.cmpmux_sel = cmpmux::rs2_out;
					control_output.cmpop = blt;
				end

				sltu: begin
					control_output.load_regfile = 1'b1;
					control_output.regfilemux_sel = regfilemux::br_en;
					control_output.cmpmux_sel = cmpmux::rs2_out;
					control_output.cmpop = bltu;
				end

				sr: begin
					control_output.regfilemux_sel = regfilemux::alu_out;
					control_output.alumux1_sel = alumux::rs1_out;
					control_output.alumux2_sel = alumux::rs2_out;
					control_output.load_regfile = 1'b1;
					if (control_input.funct7[5]) begin
						control_output.aluop = alu_sra;
					end
					else begin
						control_output.aluop = alu_srl;
					end
				end

				default: begin
					control_output.regfilemux_sel = regfilemux::alu_out;
					control_output.load_regfile = 1'b1;
					control_output.alumux1_sel = alumux::rs1_out;
					control_output.alumux2_sel = alumux::rs2_out;
					control_output.aluop = alu_ops'(arith_funct3);
				end

			endcase

		end //op_csr: begin 
		
		default: begin
			control_output.pcmux_sel = 'd0;
			control_output.regfilemux_sel = regfilemux::alu_out;
			control_output.alumux1_sel = 'd0;
			control_output.alumux2_sel = 'd0;
			control_output.cmpmux_sel = 'd0;

			control_output.memmux_sel = 'd0;

			control_output.aluop = alu_ops'(control_input.funct3);
			control_output.cmpop = branch_funct3_t'(control_input.funct3);

			control_output.load_regfile = 'd0;
			control_output.load_pc = 'd1;
			control_output.load_data_out = 'd0;
		end
		
	endcase
end

endmodule : control
