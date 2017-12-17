`include "defines.v"

module inst_rom (
	input  wire                ce  ,
	input  wire [`InstAddrBus] addr,
	output reg  [    `InstBus] inst
);

	reg[`InstBus]  inst_mem[0:`InstMemNum-1];

	initial $readmemh("D:/Files/Progs/RISC-V-CPU/test/inst.data", inst_mem);

	always @ (*) begin
		if (!ce) begin
			inst <= 0;
		end else begin
			// divide addr by 4
			inst <= {inst_mem[addr >> 2][7:0], inst_mem[addr >> 2][15:8], 
					 inst_mem[addr >> 2][23:16], inst_mem[addr >> 2][31:24]};
		end
	end

endmodule // inst_rom