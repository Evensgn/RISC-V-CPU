module riscv_min_sopc (
	input wire clk,
	input wire rst
);

	wire[`InstAddrBus] rom_addr;
	wire[`InstBus] rom_inst;
	wire rom_ce;

	wire[`MemAddrBus] mem_addr;
	wire mem_we;
	wire[`RegBus] mem_data_read;
	wire[`RegBus] mem_data_write;
	wire[3:0] mem_sel;
	wire mem_ce;

	riscv_cpu riscv_cpu0 (
		// input
		.clk       (clk           ),
		.rst       (rst           ),
		.rom_inst  (rom_inst      ),
		.mem_data_i(mem_data_read ),
		// output
		.rom_addr  (rom_addr      ),
		.rom_ce    (rom_ce        ),
		.mem_ce    (mem_ce        ),
		.mem_addr  (mem_addr      ),
		.mem_data_o(mem_data_write),
		.mem_sel   (mem_sel       ),
		.mem_we    (mem_we        )
	);

	inst_rom inst_rom0 (
		// input
		.ce  (rom_ce  ),
		.addr(rom_addr),
		// output
		.inst(rom_inst)
	);

	ram ram0 (
		// input
		.clk   (clk           ),
		.ce    (mem_ce        ),
		.we    (mem_we        ),
		.addr  (mem_addr      ),
		.sel   (mem_sel       ),
		.data_i(mem_data_write),
		// output
		.data_o(mem_data_read )
	);

endmodule // riscv_min_sopc