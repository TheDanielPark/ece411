import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module control
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
	 
	 input logic mem_resp,
	 input rv32i_word mem_address,
	 output logic mem_write,
	 output logic [3:0] mem_byte_enable,
	 output logic mem_read,
	 
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
	 output branch_funct3_t cmpop
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

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
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011 << mem_address[1:0]; /* Modify for MP1 Final */ 
                sb: wmask = 4'b0001 << mem_address[1:0]; /* Modify for MP1 Final */ 
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
	 fetch1,
	 fetch2, 
	 fetch3,
	 decode,
	 imm,
	 lui,
	 sw_calc_addr,
	 lw_calc_addr,
	 auipc,
	 br,
	 ldr1,
	 ldr2,
	 str1,
	 str2,
	 jal,
	 jalr,
	 register
	 
} state, next_states;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
	load_pc = 1'b0;
	load_ir = 1'b0;
	load_regfile = 1'b0;
	load_mar = 1'b0;
	load_mdr = 1'b0;
	load_data_out = 1'b0;
	pcmux_sel = pcmux::pc_plus4;
	regfilemux_sel = regfilemux::alu_out;
	cmpop = beq;
	alumux1_sel = alumux::rs1_out;
	alumux2_sel = alumux::i_imm;
	marmux_sel = marmux::pc_out;
	cmpmux_sel = cmpmux::rs2_out;
	aluop = alu_add;
	mem_write = 1'b0;
	mem_read = 1'b0;
	mem_byte_enable = 4'b1111;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
function void loadPC(pcmux::pcmux_sel_t sel);
    load_pc = 1'b1;
    pcmux_sel = sel;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
	load_regfile = 1'b1;
	regfilemux_sel = sel;
endfunction

function void loadMAR(marmux::marmux_sel_t sel);
	load_mar = 1'b1;
	marmux_sel = sel;
endfunction

function void loadMDR();
	load_mdr = 1'b1;
endfunction

/**
 * SystemVerilog allows for default argument values in a way similar to
 *   C++.
**/
function void setALU(alumux::alumux1_sel_t sel1,
                               alumux::alumux2_sel_t sel2,
                               logic setop = 1'b0, alu_ops op = alu_add);
    /* Student code here */
	

    if (setop) begin
        aluop = op; // else default value
		  alumux1_sel = sel1;
		  alumux2_sel = sel2;
	 end
endfunction

function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
	 case (state)
		 fetch1: begin
			loadMAR(marmux::pc_out);
		 end
		 
		 fetch2: begin
			loadMDR();
			mem_read = 1'b1;
		 end
		 
		 fetch3: begin
			load_ir = 1'b1;
		 end
		 
		 decode: begin
			;
		 end 
		 
		 imm: begin
			case (arith_funct3)
				slt: begin
					loadRegfile(regfilemux::br_en);
					loadPC(pcmux::pc_plus4);
					cmpop = blt;
					cmpmux_sel = cmpmux::i_imm;
				end
				sltu: begin
					loadRegfile(regfilemux::br_en);
					loadPC(pcmux::pc_plus4);
					cmpop = bltu;
					cmpmux_sel = cmpmux::i_imm;
				end
				sr: begin
					loadRegfile(regfilemux::alu_out);
					loadPC(pcmux::pc_plus4);
					if (funct7[5]) begin
						setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_sra);
					end
					else begin
						setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_srl);
					end
				end
				default: begin
					loadRegfile(regfilemux::alu_out);
					loadPC(pcmux::pc_plus4);
					setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_ops'(arith_funct3));
				end
			endcase
		end
		
		br: begin
			loadPC(pcmux::pcmux_sel_t'({{1'b0}, br_en}));
			setALU(alumux::pc_out, alumux::b_imm, 1'b1, alu_add);
			cmpop = branch_funct3;
			cmpmux_sel = cmpmux::rs2_out;
		end
		
		lw_calc_addr: begin
			loadMAR(marmux::alu_out);
			setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
		end
		
		ldr1: begin
			load_mdr = 1'b1;
			mem_read = 1'b1;
		end
		
		ldr2: begin
			loadPC(pcmux::pc_plus4);
			case (load_funct3)
				lb: loadRegfile(regfilemux::lb);
				lh: loadRegfile(regfilemux::lh);
				lw: loadRegfile(regfilemux::lw);
				lbu: loadRegfile(regfilemux::lbu);
				lhu: loadRegfile(regfilemux::lhu);
				default: ;
			endcase
		end

		sw_calc_addr: begin
			loadMAR(marmux::alu_out);
			setALU(alumux::rs1_out, alumux::s_imm, 1'b1, alu_add);
			load_data_out = 1'b1;
		end
		
		str1: begin
			mem_write = 1'b1;
			case (store_funct3)
				sb: begin
					case (mem_address[1:0])
						2'b00: mem_byte_enable = 4'b0001;
						2'b01: mem_byte_enable = 4'b0010;
						2'b10: mem_byte_enable = 4'b0100;
						2'b11: mem_byte_enable = 4'b1000;
					endcase
				end
				sh: begin
					case (mem_address[1])
						1'b0: mem_byte_enable = 4'b0011;
						1'b1: mem_byte_enable = 4'b1100;
					endcase
				end
				sw: begin
					mem_byte_enable = 4'b1111;
				end
			endcase
		end
		
		str2: begin
			loadPC(pcmux::pc_plus4);
		end
		
		auipc: begin
			loadRegfile(regfilemux::alu_out);
			loadPC(pcmux::pc_plus4);
			setALU(alumux::pc_out, alumux::u_imm, 1'b1, alu_add);
		end
		
		lui: begin
			loadRegfile(regfilemux::u_imm);
			loadPC(pcmux::pc_plus4);
		end
		
		// shamt == shift amount
				
		// Add register stuff here, use arith_funct3 as case, go through the table
				
		// Add jal jalr here
				
		jal: begin
			loadRegfile(regfilemux::pc_plus4);
			loadPC(pcmux::alu_mod2);
			setALU(alumux::pc_out, alumux::j_imm, 1'b1, alu_add);
		end
			
		jalr: begin
			loadRegfile(regfilemux::pc_plus4);
			loadPC(pcmux::alu_mod2);
			setALU(alumux::rs1_out, alumux::i_imm, 1'b1, alu_add);
		end
		
		register: begin
			loadPC(pcmux::pc_plus4);
			case (arith_funct3) 
				add: begin
					loadRegfile(regfilemux::alu_out);
					if (funct7[5]) begin
						setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sub);
					end
					else begin
						setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_add);
					end
				end 
				slt: begin
					loadRegfile(regfilemux::br_en);
					cmpop = blt;
					cmpmux_sel = cmpmux::rs2_out;
				end 
				sltu: begin
					loadRegfile(regfilemux::br_en);
					cmpop = bltu;
					cmpmux_sel = cmpmux::rs2_out;
				end 
				sr: begin
					loadRegfile(regfilemux::alu_out);
						if (funct7[5]) begin
							setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_sra);
						end
						else begin
							setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_srl);
						end
				end
				default: begin
					loadRegfile(regfilemux::alu_out);
					setALU(alumux::rs1_out, alumux::rs2_out, 1'b1, alu_ops'(arith_funct3));
				end
			endcase
		end 
		
	endcase
	
	
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	if(rst) begin
		next_states = fetch1;
	end
		else begin
			case (state)
				fetch1: next_states = fetch2;
				fetch2: begin
					if (mem_resp == 1'b0) begin
						next_states = fetch2;
					end
					else begin
						next_states = fetch3;
					end
				end
				fetch3: next_states = decode;
				
				decode: begin
					case(opcode)
						op_auipc: next_states = auipc;
						op_lui: next_states = lui;
						op_br: next_states = br;
						op_load: next_states = lw_calc_addr;
						op_store: next_states = sw_calc_addr;
						op_imm: next_states = imm;
						op_jal: next_states = jal;
						op_jalr: next_states = jalr;
						op_reg: next_states = register;
						default: next_states = fetch1;
					endcase
				end
				
				imm: next_states = fetch1;
				auipc: next_states = fetch1;
				lui: next_states = fetch1;
				br: next_states = fetch1;
				lw_calc_addr: next_states = ldr1;
				sw_calc_addr: next_states = str1;
				ldr1: begin
					if (mem_resp == 1'b0) begin
						next_states = ldr1;
					end
					else begin
						next_states = ldr2;
					end
				end
				ldr2: next_states = fetch1;
				str1: begin
					if (mem_resp == 1'b0) begin
						next_states = str1;
					end
					else begin
						next_states = str2;
					end
				end
				str2: next_states = fetch1;
				
				jal: next_states = fetch1;
				
				jalr: next_states = fetch1;
				
				register: next_states = fetch1;
				
				default: ;
			endcase
		end
	 
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_states;
end

endmodule : control
