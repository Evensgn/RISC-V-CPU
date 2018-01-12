`include "defines.v"

module reg_mem_wb (
	input  wire               clk          ,
	input  wire               rst          ,
	input  wire [`RegAddrBus] mem_reg_waddr,
	input  wire               mem_we       ,
	input  wire [    `RegBus] mem_reg_wdata,
	input  wire [5:0]         stall        ,
	output reg  [`RegAddrBus] wb_reg_waddr ,
	output reg                wb_we        ,
	output reg  [    `RegBus] wb_reg_wdata
);

	always @ (posedge clk) begin
		if(rst || (stall[4] && !stall[5])) begin
			wb_reg_waddr <= 0;
			wb_we        <= 0;
			wb_reg_wdata <= 0;
		end else if (!stall[4]) begin
			wb_reg_waddr <= mem_reg_waddr;
			wb_we        <= mem_we;
			wb_reg_wdata <= mem_reg_wdata;
		end
	end

endmodule // reg_mem_wb