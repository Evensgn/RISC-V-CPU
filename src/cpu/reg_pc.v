`include "defines.v"

module reg_pc (
	input  wire                clk    ,
	input  wire                rst    ,
	input  wire [         5:0] stall  ,
	input  wire                br     ,
	input  wire [`InstAddrBus] br_addr,
	output reg  [`InstAddrBus] pc
);

	always @ (posedge clk) begin
		if (rst) begin
			//$display("PC: not good");
			pc <= 0;
		end else if (!stall[0]) begin
			//$display("PC: oh?");
			if (br) pc <= br_addr;
			else pc <= pc + 4'h4;
		end
	end

endmodule // reg_pc