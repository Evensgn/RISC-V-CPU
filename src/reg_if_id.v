`include "defines.v"

module reg_if_id (
	input  wire                clk    ,
	input  wire                rst    ,
	input  wire [`InstAddrBus] if_pc  ,
	input  wire [    `InstBus] if_inst,
	input  wire [         5:0] stall  ,
	input  wire                br     ,
	output reg  [`InstAddrBus] id_pc  ,
	output reg  [    `InstBus] id_inst
);

	always @ (posedge clk) begin
		if (rst || br || (stall[1] && !stall[2])) begin
			id_pc   <= 0;
			id_inst <= 0;
		end else if (!stall[1]) begin
			id_pc   <= if_pc;
			id_inst <= if_inst;
		end
	end

endmodule // reg_if_id