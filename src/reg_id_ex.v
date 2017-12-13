`include "defines.v"

module reg_id_ex (
	input  wire               clk      ,
	input  wire               rst      ,
	input  wire [  `AluOpBus] id_aluop ,
	input  wire [ `AluSelBus] id_alusel,
	input  wire [    `RegBus] id_opv1  ,
	input  wire [    `RegBus] id_opv2  ,
	input  wire [`RegAddrBus] id_we    ,
	input  wire               id_wreg  ,
	output reg  [  `AluOpBus] ex_aluop ,
	output reg  [ `AluSelBus] ex_alusel,
	output reg  [    `RegBus] ex_opv1  ,
	output reg  [    `RegBus] ex_opv2  ,
	output reg  [`RegAddrBus] ex_we    ,
	output reg                ex_wreg
);

	always @ (posedge clk) begin
		if (rst) begin
			ex_aluop  <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_opv1   <= 0;
			ex_opv2   <= 0;
			ex_we     <= 0;
			ex_wreg   <= 0;
		end else begin
			ex_aluop  <= id_aluop;
			ex_alusel <= id_alusel;
			ex_opv1   <= id_opv1;
			ex_opv2   <= id_opv2;
			ex_we     <= id_we;
			ex_wreg   <= id_wreg;
		end
	end

endmodule // reg_id_ex