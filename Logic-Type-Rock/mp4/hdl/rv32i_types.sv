package rv32i_types;
// Mux types are in their own packages to prevent identiier collisions
// e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
// for seperate enumerated types
import pcmux::*;
import marmux::*;
import cmpmux::*;
import alumux::*;
import regfilemux::*;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops;

// Control word signals
typedef struct packed {
    rv32i_opcode opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic br_en;
    rv32i_reg rs1;
    rv32i_reg rs2;
    rv32i_reg rd;
    logic valid;
} rv32i_control_input;

typedef struct packed {
    rv32i_opcode opcode;
    
    logic [1:0] pcmux_sel;
    logic alumux1_sel;
    logic [2:0] alumux2_sel;
    logic cmpmux_sel;
    regfilemux::regfilemux_sel_t regfilemux_sel;
    
    alu_ops aluop;
    branch_funct3_t cmpop;
    
    logic load_regfile;
    logic load_pc;
    logic load_data_out;

    logic read;
    logic write;

    logic [2:0] memmux_sel;
    
    logic [3:0] wmask;
    rv32i_word i_imm;
    rv32i_word u_imm;
    rv32i_word b_imm;   
    rv32i_word s_imm;
    rv32i_word j_imm; 

    rv32i_reg rs1;
    rv32i_reg rs2;
    rv32i_word rdata_a;
    logic valid;

} rv32i_control_output;

typedef struct packed {
    rv32i_word pc;
    rv32i_control_input control_input;
    rv32i_word rdata_a;
    // rd signal
    rv32i_word i_imm;
    rv32i_word u_imm;
    rv32i_word b_imm;   
    rv32i_word s_imm;
    rv32i_word j_imm;

} if_output;

typedef struct packed {
    rv32i_control_output control_word; 
    rv32i_word rs1_out;
    rv32i_word rs2_out;
    rv32i_word pc;
    rv32i_reg rd;
} id_output;

typedef struct packed {
    rv32i_control_output control_word; 
    rv32i_word rs1_out;
    rv32i_word rs2_out;
    logic cmp_out;
    rv32i_word alu_out;
    rv32i_word pc;
    rv32i_reg rd;
} ex_output;

typedef struct packed {
    rv32i_control_output control_word;
    rv32i_word pc;
    rv32i_word rdata_b;
    rv32i_word alu_out;
    rv32i_reg rd;
    logic br_en;
    rv32i_word memmux_out;
} mem_output;

endpackage : rv32i_types

