// Zhekai Zhang's simulation code

`timescale 1ns / 1ps

module sim_cpu();
	reg  clk;
	reg  rst;
	wire button = ~rst;
	wire Rx, Tx;

    wire rst_led;
    
	cpu cpu0(clk,button, rst_led, Tx,Rx);
	sim_memory sim_memory0(clk,rst,Rx,Tx);

	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial begin
		rst = 1;
		#1000 rst = 0;
		//#10000000 $stop;
		#10000000 $stop;
	end

endmodule