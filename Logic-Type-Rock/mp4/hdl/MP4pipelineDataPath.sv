import rv32i_types::*;
module pipeline_datapath (
    //inputs to datapath
    input clk,
    input rst,
    input logic resp_a,
    input rv32i_word rdata_a,
    input logic resp_b,
    input rv32i_word rdata_b,

    // Outputs
    output logic read_a,
    output logic read_b,
    output rv32i_word address_a,
    output rv32i_word address_b,
    output logic write,
    output [3:0] wmask,
    output rv32i_word wdata

    // input mem_rdata,
    // input logic mem_resp,
	// input rv32i_word mem_address,
    // output mem_wdata,
    // output mem_address,
    // output mem_read,
	// output mem_write,    
);

assign read_a = 1'b1;

// TODO:
/*
*/

logic stall;
logic hazard_stall;
logic [31:0] jump_address;
logic [31:0] jal_address;
logic [31:0] jalr_address;


//Insert Datapath connections

//IF
rv32i_word pcmux_out;
rv32i_word pc_out;
rv32i_word pc_plus4;

//ID

//EX

//NOT 100% SURE IF ITS WORD OR LOGIC HERE.

logic [1:0] forwardA_sel;
logic [1:0] forwardB_sel;
rv32i_word forwardA_out;
rv32i_word forwardB_out;
logic memForwardMux_sel;



rv32i_word memmux_out_before_fwd;


rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word cmpmux_out;
rv32i_word memmux_out;
rv32i_word regfilemux_prep;
// rv32i_word regfilemux_out;

//ORGANIZE IMMEADIATES
// rv32i_word i_imm, u_imm, b_imm, s_imm, j_imm;

// Register values in
if_output if_output_in;
id_output id_output_in;
ex_output ex_output_in;
mem_output mem_output_in;

// Register values out
if_output if_output_out;
id_output id_output_out;
ex_output ex_output_out;
mem_output mem_output_out;

logic jump;

assign stall = (read_a & ~resp_a) | ((read_b | write) & ~resp_b);


// Control input
rv32i_control_input control_input;
assign control_input.opcode = rv32i_opcode'(rdata_a[6:0]);
assign control_input.funct3 = rdata_a[14:12];
assign control_input.funct7 = rdata_a[31:25];

always_comb begin
    if (ex_output_out.control_word.opcode == 7'b1100011) control_input.br_en  =  ex_output_out.cmp_out; // We are anding it with the branch opcode to make sure it only branches on a branch
    else control_input.br_en = 'b0;
    if ((id_output_in.control_word.opcode == 7'b1101111) || (id_output_in.control_word.opcode == 7'b1100111)) jump = 1'b1;
    else jump = 'b0;
end

assign control_input.rs1 = rdata_a[19:15];
assign control_input.rs2 = rdata_a[24:20]; 
assign control_input.rd = rdata_a[11:7];
assign control_input.valid = 1'b1;


//Assign values for each register/mux here
assign if_output_in.control_input = control_input;
assign if_output_in.rdata_a = rdata_a;
assign if_output_in.i_imm = {{21{rdata_a[31]}}, rdata_a[30:20]};
assign if_output_in.u_imm = {rdata_a[31:12], 12'h000};
assign if_output_in.b_imm = {{20{rdata_a[31]}}, rdata_a[7], rdata_a[30:25], rdata_a[11:8], 1'b0};
assign if_output_in.s_imm = {{21{rdata_a[31]}}, rdata_a[30:25], rdata_a[11:7]};
assign if_output_in.j_imm = {{12{rdata_a[31]}}, rdata_a[19:12], rdata_a[20], rdata_a[30:21], 1'b0};
assign if_output_in.pc = pc_out;
// ID Assignments
assign id_output_in.pc = if_output_out.pc;
assign id_output_in.rd = if_output_out.control_input.rd;

//assign id_output_in.control_word.opcode = if_output_out.control_input.opcode; //rv32i_opcode'(rdata_a[6:0]);

//assign id_output_in.control_word.i_imm = if_output_out.i_imm;
//assign id_output_in.control_word.u_imm = if_output_out.u_imm;
//assign id_output_in.control_word.b_imm = if_output_out.b_imm;
//assign id_output_in.control_word.s_imm = if_output_out.s_imm;
//assign id_output_in.control_word.j_imm = if_output_out.j_imm;

//assign id_output_in.control_word.rs1 = if_output_out.control_input.rs1;
//assign id_output_in.control_word.rs2 = if_output_out.control_input.rs2;

// EX Assignments
assign ex_output_in.control_word = id_output_out.control_word; 
assign ex_output_in.rs1_out = forwardA_out;
assign ex_output_in.rs2_out = forwardB_out;
assign ex_output_in.pc = id_output_out.pc;
assign ex_output_in.rd = id_output_out.rd;


// MEM Assignments
assign mem_output_in.alu_out = ex_output_out.alu_out;
assign mem_output_in.control_word = ex_output_out.control_word;
assign mem_output_in.rd = ex_output_out.rd;
assign mem_output_in.br_en = ex_output_out.cmp_out;
assign mem_output_in.rdata_b = rdata_b;
assign mem_output_in.pc = ex_output_out.pc;
assign mem_output_in.memmux_out = memmux_out;

// Output assignments
assign wdata = ex_output_out.rs2_out;
assign read_b = ex_output_out.control_word.read;
assign write = ex_output_out.control_word.write;
assign address_b = {ex_output_out.alu_out[31:2], 2'b0};
assign address_a = pc_out;
assign wmask = ex_output_out.control_word.wmask;

mux4in pcmux (
    .select({jump, (ex_output_out.control_word.pcmux_sel && control_input.br_en)}), // && ex_output_out.cmp_out. Need to change for later
    .a(pc_plus4), //pc + 4
    .b(ex_output_out.alu_out), //alu_mem
    .c(jump_address), //target addr
    .d(ex_output_out.alu_out), // If there is a jump in ID and BR in EX, take BR
    .out(pcmux_out)
);

pc_register pc (
    .clk(clk),
    .rst(rst ),
    .load( ~stall & ~hazard_stall), // ex_output_out.control_word.load_pc &
    .in(pcmux_out), //output of pcmux
    .out(pc_out)
);

adder pc_adder (
    .a(pc_out), //pc
    .b(4),
    .c(pc_plus4)
);

register #(.width($bits(if_output))) if_id
(
    .clk(clk),
    .rst(rst | control_input.br_en | (jump & ~stall)), // hazard_stall | control_input.br_en |  jump
    .load(~stall & ~hazard_stall),        // For CP1 this is permenantly 1
    .in(if_output_in),
    .out(if_output_out)
);

register #(.width($bits(id_output))) id_ex 
(
    .clk(clk),
    .rst(rst  | control_input.br_en | (hazard_stall && ~stall)), // | control_input.br_en, | hazard_stall
    .load(~stall ),        // For CP1 this is permenantly 1 & hazard_stall
    .in(id_output_in),
    .out(id_output_out)
);

register #(.width($bits(ex_output))) ex_mem
(
    .clk(clk),
    .rst(rst | control_input.br_en),     // 
    .load(~stall),        // For CP1 this is permenantly 1 & hazard_stall  && ~control_input.br_en
    .in(ex_output_in),
    .out(ex_output_out)
);

register #(.width($bits(mem_output))) mem_wb
(
    .clk(clk),
    .rst(rst ),
    .load(~stall),        // For CP1 this is permenantly 1 & hazard_stall
    .in(mem_output_in),
    .out(mem_output_out)
);


control control(
    .clk(clk),
    .rst(rst),
    //.mem_resp(mem_resp),
    .mem_address(address_a),
	.if_output_out(if_output_out),
//    .control_input(if_output_out.control_input),
    .control_output(id_output_in.control_word)
);

hazard_detection hazard_detection(
    //Inputs
    .if_output_out,
    .id_output_out,
    .stall(stall),
    //Outputs
    .hazard_stall

);

regfile regfile (
    //input
    .clk(clk), 
    .rst(rst), 
    .load(mem_output_out.control_word.load_regfile),  //& ~stall
    .in(mem_output_out.memmux_out),    //writeback mux out?
    .src_a(if_output_out.control_input.rs1),
    .src_b(if_output_out.control_input.rs2),
    .dest(mem_output_out.rd), // MISSING rd FROM MEM/WB

    //output
    .reg_a(id_output_in.rs1_out),
    .reg_b(id_output_in.rs2_out)
);

alu ALU (
    .aluop(id_output_out.control_word.aluop), //From control
    .a(alumux1_out), //I'm pretty sure these are supposed  to be alumux out not forward based on what TA said
    .b(alumux2_out),
    .f(ex_output_in.alu_out)
);

cmp CMP (
    .cmpop(id_output_out.control_word.cmpop),
    .a(forwardA_out), //id_output_out.rs1_out
    .b(cmpmux_out),
    .out(ex_output_in.cmp_out)
);

/*
mux2in controlMux (
    .select, //from hazard
    .a, //all the input signals
    .b(0), //should be zero for flush
    .out
);
*/

mux2in alumux1 (
    .select(id_output_out.control_word.alumux1_sel), //From control
    .a(forwardA_out), //change to forwardA_out
    .b(id_output_out.pc), //pc idk the logic
    .out(alumux1_out)
);

mux8in alumux2 (
    .select(id_output_out.control_word.alumux2_sel), //From control
    .a(id_output_out.control_word.i_imm), // all imm values. 
    .b(id_output_out.control_word.u_imm),
    .c(id_output_out.control_word.b_imm),
    .d(id_output_out.control_word.s_imm),
    .e(id_output_out.control_word.j_imm),
    .f(forwardB_out), //change to forwardB_out
    .g(0),
    .h(0), 
    .out(alumux2_out)
);


mux4in forwardA (
    .select(forwardA_sel),
    .a(id_output_out.rs1_out),
    .b(memmux_out), //Ex/Mem signal
    .c(32'hffffffff), //ex_output_out.alu_out
    .d(mem_output_out.memmux_out),
    .out(forwardA_out)
);

mux4in forwardB ( // I think this one is different from what i put cause it is before alumux2
    .select(forwardB_sel),
    .a(id_output_out.rs2_out),
    .b(memmux_out), //Ex/Mem signal
    .c(32'hffffffff), //ex_output_out.alu_out
    .d(mem_output_out.memmux_out),
    .out(forwardB_out)
);
/*
mux2in memForwardMux (
    .select(memForwardMux_sel),
    .a(memmux_out_before_fwd),
    .b(mem_output_out.memmux_out),
    .out(memmux_out)
);
*/

mux2in cmpMux (
    .select(id_output_out.control_word.cmpmux_sel), // from control
    .a(forwardB_out), //id_output_out.rs2_out
    .b(id_output_out.control_word.i_imm),
    .out(cmpmux_out) 
);

mux9in WB_mux (
    .select(mem_output_in.control_word.regfilemux_sel),
    .a(mem_output_in.alu_out),
    .b({31'd0, mem_output_in.br_en}),
    .c(mem_output_in.control_word.u_imm),
    .d(mem_output_in.rdata_b),
    .e(mem_output_in.pc + 'd4),
    .f(regfilemux_prep),
    .g(regfilemux_prep),
    .h(regfilemux_prep),
    .i(regfilemux_prep),
    .out(memmux_out)          // Check that it is supposed to be saved like this, _before_fwd
); 

always_comb begin : regfilemux
//	regfilemux_prep = mem_output_out.rdata_b;

    case (mem_output_in.control_word.regfilemux_sel)
        regfilemux::lb:         begin
            case (mem_output_in.alu_out[1:0])
                2'b00:          regfilemux_prep = ({{24{mem_output_in.rdata_b[7]}}, mem_output_in.rdata_b[7:0]});
                2'b01:          regfilemux_prep = ({{24{mem_output_in.rdata_b[15]}}, mem_output_in.rdata_b[15:8]});
                2'b10:          regfilemux_prep = ({{24{mem_output_in.rdata_b[23]}}, mem_output_in.rdata_b[23:16]});
                2'b11:          regfilemux_prep = ({{24{mem_output_in.rdata_b[31]}}, mem_output_in.rdata_b[31:24]});
            endcase
        end
        regfilemux::lbu:        begin
            case (mem_output_in.alu_out[1:0])
                2'b00:          regfilemux_prep = ({24'd0, mem_output_in.rdata_b[7:0]});
                2'b01:          regfilemux_prep = ({24'd0, mem_output_in.rdata_b[15:8]});
                2'b10:          regfilemux_prep = ({24'd0, mem_output_in.rdata_b[23:16]});
                2'b11:          regfilemux_prep = ({24'd0, mem_output_in.rdata_b[31:24]});
            endcase
        end
        regfilemux::lh:         begin
            case(mem_output_in.alu_out[1])
                1'b0:          regfilemux_prep = ({{16{mem_output_in.rdata_b[15]}}, mem_output_in.rdata_b[15:0]});
                1'b1:          regfilemux_prep = ({{16{mem_output_in.rdata_b[31]}}, mem_output_in.rdata_b[31:16]});
            endcase
        end
        regfilemux::lhu:        begin
            case(mem_output_in.alu_out[1])
                1'b0:          regfilemux_prep = ({16'd0, mem_output_in.rdata_b[15:0]});
                1'b1:          regfilemux_prep = ({16'd0, mem_output_in.rdata_b[31:16]});
            endcase
        end 
        default: regfilemux_prep = mem_output_in.rdata_b;
    endcase
end : regfilemux

always_comb begin : jump_addition
    jal_address = id_output_in.pc + id_output_in.control_word.j_imm;            //  + 'd4 
    if (ex_output_out.control_word.load_regfile == 1'b1 && (ex_output_out.rd == if_output_out.control_input.rs1) && ex_output_out.rd != 'b0)
        jalr_address = ex_output_out.alu_out + id_output_in.control_word.i_imm + 'd4;
    // else if (id_output_out.control_word.load_regfile == 1'b1 && (id_output_out.rd == if_output_out.control_input.rs1) && id_output_out.rd != 'b0)
    //     jalr_address = ex_output_in.alu_out + id_output_in.control_word.i_imm + 'd4;
    else
        jalr_address = id_output_in.rs1_out + id_output_in.control_word.i_imm;
    case (id_output_in.control_word.opcode)
        op_jal: begin
            jump_address = {jal_address[31:1], 1'b0};
        end
        op_jalr: begin
            jump_address = {jalr_address[31:1], 1'b0};
        end
        default: jump_address = 'h60;
    endcase
end : jump_addition

forwarding forward_connections (
    

    .control_id(id_output_out),
    .control_ex(ex_output_out),
    .control_mem(mem_output_out),
    .memmux_out,
    .forwardB_sel,
    .forwardA_sel,
    .memForwardMux_sel

);


endmodule : pipeline_datapath