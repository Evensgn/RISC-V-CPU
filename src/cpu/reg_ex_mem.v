`include "defines.v"

module reg_ex_mem (
	input  wire               clk          ,
	input  wire               rst          ,
	input  wire [`RegAddrBus] ex_reg_waddr ,
	input  wire               ex_we        ,
	input  wire [    `RegBus] ex_reg_wdata ,
	input  wire [        5:0] stall        ,
	input  wire [`MemAddrBus] ex_mem_addr  ,
	input  wire [  `AluOpBus] ex_aluop     ,
	input  wire [    `RegBus] ex_rt_data   ,
	output reg  [`RegAddrBus] mem_reg_waddr,
	output reg                mem_we       ,
	output reg  [    `RegBus] mem_reg_wdata,
	output reg  [`MemAddrBus] mem_mem_addr ,
	output reg  [  `AluOpBus] mem_aluop    ,
	output reg  [    `RegBus] mem_rt_data
);

	always @ (posedge clk) begin
		if(rst || (stall[3] && !stall[4])) begin
			mem_reg_waddr <= 0;
			mem_we        <= 0;
			mem_reg_wdata <= 0;
			mem_mem_addr  <= 0;
			mem_aluop     <= 0;
			mem_rt_data   <= 0;
		end else if (!stall[3]) begin
			mem_reg_waddr <= ex_reg_waddr;
			mem_we        <= ex_we;
			mem_reg_wdata <= ex_reg_wdata;
			mem_mem_addr  <= ex_mem_addr;
			mem_aluop     <= ex_aluop;
			mem_rt_data   <= ex_rt_data;
		end
	end

endmodule // reg_ex_mem