`include "defines.v"

module reg_pc (
	input  wire                clk,
	input  wire                rst,
	output reg  [`InstAddrBus] pc ,
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
		end else begin
			pc <= pc + 4'h4;
		end
	end

endmodule // reg_pc