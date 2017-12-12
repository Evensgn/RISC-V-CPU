`ifndef DEFINES_V
`define DEFINES_V

//****************** Instruction opcode in RISC-V ******************
`define OPCODE_ORI 7'b0010011

//****************** Instruction funct3 in RISC-V ******************
`define FUNCT3_ORI 3'b110

//****************** Constants ******************
`define True 1'b1
`define False 1'b0
`define ZeroWord 32'h00000000

//****************** Hardware Properties ******************

// Instruction ROM
`define InstAddrBus 31:0 
`define InstBus 31:0
`define InstMemSize 131072 // 128kB
`define InstMemSizeLog2 17


`endif