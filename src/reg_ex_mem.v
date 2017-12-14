`include "defines.v"

module reg_ex_mem (
	input  wire               clk          ,
	input  wire               rst          ,
	input  wire [`RegAddrBus] ex_reg_waddr ,
	input  wire               ex_we        ,
	input  wire [    `RegBus] ex_reg_wdata     ,
	output reg  [`RegAddrBus] mem_reg_waddr,
	output reg                mem_we       ,
	output reg  [    `RegBus] mem_reg_wdata
);

	always @ (posedge clk) begin
		if(rst) begin
			mem_reg_waddr <= 0;
			mem_we        <= 0;
			mem_reg_wdata <= 0;
		end else begin
			mem_reg_waddr <= ex_reg_waddr;
			mem_we        <= ex_we;
			mem_reg_wdata <= ex_reg_wdata;
		end
	end

endmodule // reg_ex_mem