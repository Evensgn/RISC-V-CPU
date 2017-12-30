`include "defines.v"

module stage_mem (
	input  wire               rst        ,
	input  wire [`RegAddrBus] reg_waddr_i,
	input  wire               we_i       ,
	input  wire [    `RegBus] reg_wdata_i,
	input  wire [`MemAddrBus] mem_addr   ,
	input  wire [  `AluOpBus] aluop      ,
	input  wire [    `RegBus] rt_data    ,
	output reg  [`RegAddrBus] reg_waddr_o,
	output reg                we_o       ,
	output reg  [    `RegBus] reg_wdata_o
);

	always @ (*) begin
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