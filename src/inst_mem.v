`include "defines.v"

module inst_mem (
	input  wire                ce  ,
	input  wire [`InstAddrBus] addr,
	output reg  [    `InstBus] inst
);

	reg[`InstBus]  inst_mem[0:`InstMemNum-1];

	initial $readmemh("inst_mem.data", inst_mem);

	always @ (*) begin
		if (ce == `False) begin
			inst <= `ZeroWord;
		end else begin
			// divide addr by 4
			inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
		end
	end

endmodule // inst_mem