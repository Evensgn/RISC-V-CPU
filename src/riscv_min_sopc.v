`timescale 1ns/1ps

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
		.clk       (clk       ),
		.rst       (rst       ),
		.mem_data_i(mem_data_i),
		.mem_busy_i(mem_busy_i),
		.mem_done_i(mem_done_i),
		// output
		.mem_rwe_o (mem_rwe_o ),
		.mem_addr_o(mem_addr_o),
		.mem_sel_o (mem_sel_o ),
		.mem_data_o(mem_data_o)
	);


	/*inst_rom inst_rom0 (
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
	);*/

endmodule // riscv_min_sopc