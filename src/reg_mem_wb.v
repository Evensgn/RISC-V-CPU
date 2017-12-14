`include "defines.v"

module reg_mem_wb (
	input  wire               clk          ,
	input  wire               rst          ,
	input  wire [`RegAddrBus] mem_reg_waddr,
	input  wire               mem_we       ,
	input  wire [    `RegBus] mem_reg_wdata,
	output reg  [`RegAddrBus] wb_reg_waddr ,
	output reg                wb_we        ,
	output reg  [    `RegBus] wb_reg_wdata
);

	always @ (posedge clk) begin
		if(rst) begin
			wb_reg_waddr <= 0;
			wb_we        <= 0;
			wb_wdata     <= 0;
		end else begin
			wb_reg_waddr <= mem_reg_waddr;
			wb_we        <= mem_we;
			wb_reg_wdata <= mem_reg_wdata;
		end
	end

endmodule // reg_mem_wb