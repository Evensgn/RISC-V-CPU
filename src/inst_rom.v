`include "defines.v"

module inst_rom (
	input  wire                ce  ,
	input  wire [`InstAddrBus] addr,
	output reg  [    `InstBus] inst
);

	reg[`InstBus]  inst_mem[0:`InstMemNum-1];

	initial $readmemh("D:/Files/Progs/RISC-V-CPU/src/inst_rom.data", inst_mem);

	always @ (*) begin
		if (!ce) begin
			inst <= 0;
		end else begin
			// divide addr by 4
			inst <= inst_mem[addr >> 2];
		end
	end

endmodule // inst_rom