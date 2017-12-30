`include "defines.v"

module stage_mem (
	input  wire               rst        ,
	input  wire [`RegAddrBus] reg_waddr_i,
	input  wire               we_i       ,
	input  wire [    `RegBus] reg_wdata_i,
	input  wire [`MemAddrBus] mem_addr_i ,
	input  wire [  `AluOpBus] aluop      ,
	input  wire [    `RegBus] rt_data    ,
	input  wire [    `RegBus] mem_data_i ,
	output reg  [`RegAddrBus] reg_waddr_o,
	output reg                we_o       ,
	output reg  [    `RegBus] reg_wdata_o,
	output reg  [`MemAddrBus] mem_addr_o ,
	output reg                mem_we     ,
	output reg  [        3:0] mem_sel    ,
	output reg  [    `RegBus] mem_data_o ,
	output reg                mem_ce     ,
	output reg                stall_req
);

	always @ (*) begin
		stall_req <= 0;
		if(rst) begin
			reg_waddr_o <= 0;
			we_o        <= 0;
			reg_wdata_o <= 0;
		end else begin
			reg_waddr_o <= reg_waddr_i;
			we_o        <= we_i;
			reg_wdata_o <= reg_wdata_i;
		end
	end

endmodule // stage_mem