module riscv_min_sopc (
	input wire clk,
	input wire rst
);

	wire[`InstAddrBus] rom_addr;
	wire[`InstBus] rom_inst;
	wire rom_ce;

	riscv_cpu riscv_cpu0 (
		// input
		.clk(clk),
		.rst(rst),
		.rom_inst(rom_inst),
		// output
		.rom_addr(rom_addr),
		.rom_ce(rom_ce)
	);

	inst_rom inst_rom0 (
		// input
		.ce(rom_ce),
		.addr(rom_addr),
		// output
		.inst(rom_inst)
	);

endmodule // riscv_min_sopc