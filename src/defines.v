`ifndef DEFINES_V
`define DEFINES_V

//****************** Instruction opcode in RISC-V ******************
`define OPCODE_ORI 7'b0010011

//****************** Instruction funct3 in RISC-V ******************
`define FUNCT3_ORI 3'b110

//****************** Constants ******************
`define True 1'b1
`define False 1'b0

//****************** Hardware Properties ******************

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