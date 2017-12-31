`include "defines.v"

module reg_pc (
	input  wire                clk    ,
	input  wire                rst    ,
	input  wire [         5:0] stall  ,
	input  wire                br     ,
	input  wire [`InstAddrBus] br_addr,
	output reg  [`InstAddrBus] pc     ,
	output reg                 ce
);

	always @ (posedge clk) begin
		if (rst == 1) begin
			ce <= 0;
		end else begin
			ce <= 1;
		end
	end

	always @ (posedge clk) begin
		if (ce == 0) begin
			pc <= 0;
		end else if (!stall[0]) begin
			if (br) pc <= br_addr;
			else pc <= pc + 4'h4;
		end
	end

endmodule // reg_pc