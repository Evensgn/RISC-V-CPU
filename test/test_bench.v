`timescale 1ns/1ps

module test_bench ();

	reg CLOCK_50;
	reg rst;

	// 50MHz
	initial begin
		CLOCK_50 = 0;
		forever #10 CLOCK_50 = ~CLOCK_50;
	end

	initial begin
		rst = 1;
		#185 rst = 0;
		#2000 $stop;
	end

	riscv_min_sopc riscv_min_sopc0 (
		.clk(CLOCK_50),
		.rst(rst)
	);

endmodule // test_bench