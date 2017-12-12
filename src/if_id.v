`include "defines.v"

module if_id (
	input  wire                clk    ,
	input  wire                rst    ,
	input  wire [`InstAddrBus] if_pc  ,
	input  wire [    `InstBus] if_inst,
	output reg  [`InstAddrBus] id_pc  ,
	output reg  [    `InstBus] id_inst
);

	always @ (posedge clk) begin
		if (rst == `True) begin
			id_pc   <= `ZeroWord;
			id_inst <= `ZeroWord;
		end else begin
			id_pc   <= if_pc;
			id_inst <= if_inst;
		end
	end

endmodule // if_id