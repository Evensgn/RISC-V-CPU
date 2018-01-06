// Zhekai Zhang's simulation code

`timescale 1ns / 1ps

module sim_cpu();
	reg CLK;
	reg RST;
	wire Rx, Tx;
	
	cpu CPU(CLK, RST, Tx, Rx);
	sim_memory sm(CLK, RST, Rx, Tx);
	
	initial begin
		CLK = 0;
		RST = 0;
		RST = #1 1;
		repeat(1000) #1 CLK = !CLK;
		RST = 0;
		forever #1 CLK = !CLK;
	end
	
endmodule