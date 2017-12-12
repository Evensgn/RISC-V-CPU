`include "defines.v"

module reg_pc (
	input  wire                clk,
	input  wire                rst,
	output reg  [`InstAddrBus] pc ,
	output reg                 ce
);

	always @ (posedge clk) begin
		if (rst == `True) begin
			ce <= `False;
		end else begin
			ce <= `True;
		end
	end

	always @ (posedge clk) begin
		if (ce == `False) begin
			pc <= 32'h00000000;
		end else begin
			pc <= pc + 4'h4;
		end
	end

endmodule // reg_pc