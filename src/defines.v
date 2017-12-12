`ifndef DEFINES_V
`define DEFINES_V

//==================  Instruction opcode in RISC-V ================== 
`define OPCODE_ORI 7'b0010011

//================== Instruction funct3 in RISC-V ================== 
`define FUNCT3_ORI 3'b110

//================== EXE_RES ================== 
`define EXE_RES_LOGIC       3'b001
`define EXE_RES_SHIFT       3'b010
`define EXE_RES_MOVE        3'b011
`define EXE_RES_NOP         3'b000
`define EXE_RES_ARITH       3'b100
`define EXE_RES_MUL         3'b101
`define EXE_RES_JUMP_BRANCH 3'b110
`define EXE_RES_LOAD_STORE  3'b111

//==================  Constants ================== 
`define True 1'b1
`define False 1'b0

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

`endif