`ifndef DEFINES_V
`define DEFINES_V

//==================  Instruction opcode in RISC-V ================== 
`define OP_IMM 7'b0010011

//================== Instruction funct3 in RISC-V ================== 
`define FUNCT3_ORI 3'b110

//================== AluOp ==================
`define EXE_AND_OP  8'b00100100
`define EXE_OR_OP   8'b00100101
`define EXE_XOR_OP  8'b00100110
`define EXE_NOR_OP  8'b00100111
`define EXE_NOP_OP  8'b00000000

`define EXE_SLL_OP  8'b01111100
`define EXE_SLLV_OP 8'b00000100
`define EXE_SRL_OP  8'b00000010
`define EXE_SRLV_OP 8'b00000110
`define EXE_SRA_OP  8'b00000011
`define EXE_SRAV_OP 8'b00000111

`define EXE_MOVZ_OP 8'b00001010
`define EXE_MOVN_OP 8'b00001011
`define EXE_MFHI_OP 8'b00010000
`define EXE_MTHI_OP 8'b00010001
`define EXE_MFLO_OP 8'b00010010
`define EXE_MTLO_OP 8'b00010011

`define EXE_SLT_OP   8'b00101010
`define EXE_SLTU_OP  8'b00101011
`define EXE_SLTI_OP  8'b01010111
`define EXE_SLTIU_OP 8'b01011000   
`define EXE_ADD_OP   8'b00100000
`define EXE_ADDU_OP  8'b00100001
`define EXE_SUB_OP   8'b00100010
`define EXE_SUBU_OP  8'b00100011
`define EXE_ADDI_OP  8'b01010101
`define EXE_ADDIU_OP 8'b01010110
`define EXE_CLZ_OP   8'b10110000
`define EXE_CLO_OP   8'b10110001

`define EXE_MULT_OP  8'b00011000
`define EXE_MULTU_OP 8'b00011001
`define EXE_MUL_OP   8'b10101001
`define EXE_DIV_OP   8'b00011010
`define EXE_DIVU_OP  8'b00011011

`define EXE_J_OP      8'b01001111
`define EXE_JAL_OP    8'b01010000
`define EXE_JALR_OP   8'b00001001
`define EXE_JR_OP     8'b00001000
`define EXE_BEQ_OP    8'b01010001
`define EXE_BGEZ_OP   8'b01000001
`define EXE_BGEZAL_OP 8'b01001011
`define EXE_BGTZ_OP   8'b01010100
`define EXE_BLEZ_OP   8'b01010011
`define EXE_BLTZ_OP   8'b01000000
`define EXE_BLTZAL_OP 8'b01001010
`define EXE_BNE_OP    8'b01010010

`define EXE_LB_OP  8'b11100000
`define EXE_LBU_OP 8'b11100100
`define EXE_LH_OP  8'b11100001
`define EXE_LHU_OP 8'b11100101
`define EXE_LL_OP  8'b11110000
`define EXE_LW_OP  8'b11100011
`define EXE_LWL_OP 8'b11100010
`define EXE_LWR_OP 8'b11100110
`define EXE_SB_OP  8'b11101000
`define EXE_SC_OP  8'b11111000
`define EXE_SH_OP  8'b11101001
`define EXE_SW_OP  8'b11101011
`define EXE_SWL_OP 8'b11101010
`define EXE_SWR_OP 8'b11101110

//================== AluSel ================== 
`define EXE_RES_LOGIC       3'b001
`define EXE_RES_SHIFT       3'b010
`define EXE_RES_MOVE        3'b011
`define EXE_RES_NOP         3'b000
`define EXE_RES_ARITH       3'b100
`define EXE_RES_MUL         3'b101
`define EXE_RES_JUMP_BRANCH 3'b110
`define EXE_RES_LOAD_STORE  3'b111

//==================  Constants ================== 

//==================  Hardware Properties ================== 

// Instruction Memory
`define InstAddrBus 31:0 
`define InstBus 31:0
`define InstMemNum 131072
`define InstMemNumLog2 17

// Register File
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegNum 32
`define RegNumLog2 5

// ALU
`define AluOpBus 7:0
`define AluSelBus 2:0

`endif