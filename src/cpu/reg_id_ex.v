`include "defines.v"

module reg_id_ex (
	input  wire                clk          ,
	input  wire                rst          ,
	input  wire [   `AluOpBus] id_aluop     ,
	input  wire [  `AluSelBus] id_alusel    ,
	input  wire [     `RegBus] id_opv1      ,
	input  wire [     `RegBus] id_opv2      ,
	input  wire [ `RegAddrBus] id_reg_waddr ,
	input  wire                id_we        ,
	input  wire [         5:0] stall        ,
	input  wire [`InstAddrBus] id_link_addr ,
	input  wire [     `RegBus] id_mem_offset,
	output reg  [   `AluOpBus] ex_aluop     ,
	output reg  [  `AluSelBus] ex_alusel    ,
	output reg  [     `RegBus] ex_opv1      ,
	output reg  [     `RegBus] ex_opv2      ,
	output reg  [ `RegAddrBus] ex_reg_waddr ,
	output reg                 ex_we        ,
	output reg  [`InstAddrBus] ex_link_addr ,
	output reg  [     `RegBus] ex_mem_offset
);

	always @ (posedge clk) begin
		if (rst || (stall[2] && !stall[3])) begin
			ex_aluop      <= `EXE_NOP_OP;
			ex_alusel     <= `EXE_RES_NOP;
			ex_opv1       <= 0;
			ex_opv2       <= 0;
			ex_reg_waddr  <= 0;
			ex_we         <= 0;
			ex_link_addr  <= 0;
			ex_mem_offset <= 0;
		end else if (!stall[2]) begin
			ex_aluop      <= id_aluop;
			ex_alusel     <= id_alusel;
			ex_opv1       <= id_opv1;
			ex_opv2       <= id_opv2;
			ex_reg_waddr  <= id_reg_waddr;
			ex_we         <= id_we;
			ex_link_addr  <= id_link_addr;
			ex_mem_offset <= id_mem_offset;
		end
	end

endmodule // reg_id_ex