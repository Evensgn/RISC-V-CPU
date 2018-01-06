// This file is Zhekai Zhang's code

`timescale 1ns / 1ps

//Multiple FIFO with single input port and multiple output port
module simo_fifo
	#(
	parameter CHANNEL_BIT = 1,
	parameter SIZE_BIT = 3,
	parameter WIDTH = 8
	)
	(
	input CLK,
	input RST,
	
	input [(1<<CHANNEL_BIT)-1:0] read_flags,
	output [(1<<CHANNEL_BIT)*WIDTH-1:0] read_datas,
	
	input write_flag,
	input [CHANNEL_BIT-1:0] write_select,
	input [WIDTH-1:0] write_data,
	
	output [(1<<CHANNEL_BIT)-1:0] empty,
	output [(1<<CHANNEL_BIT)-1:0] full
    );
    
    localparam CHANNEL = 1 << CHANNEL_BIT;
	genvar i;
	generate 
		for(i=0; i < CHANNEL; i=i+1) begin
			wire write_current;
			assign write_current = write_select == i ? write_flag : 0; 
			fifo #(.SIZE_BIT(SIZE_BIT), .WIDTH(WIDTH)) buffer(CLK, RST, read_flags[i], read_datas[(i+1)*WIDTH-1:i*WIDTH], write_current, write_data, empty[i], full[i]); 
		end
	endgenerate
	
endmodule


module miso_fifo
	#(
	parameter CHANNEL_BIT = 1,
	parameter SIZE_BIT = 3,
	parameter WIDTH = 8
	)
	(
	input CLK,
	input RST,
	
	input read_flag,
	input [CHANNEL_BIT-1:0] read_select,
	output [WIDTH-1:0] read_data,
	
	input [(1<<CHANNEL_BIT)-1:0] write_flags,
	input [(1<<CHANNEL_BIT)*WIDTH-1:0] write_datas,
	
	output [(1<<CHANNEL_BIT)-1:0] empty,
	output [(1<<CHANNEL_BIT)-1:0] full
	);
	
	localparam CHANNEL = 1 << CHANNEL_BIT;
	wire [WIDTH-1:0] read_datas[CHANNEL-1:0];
	
	genvar i;
	generate
		for(i=0; i < CHANNEL; i=i+1) begin
			wire read_current;
			assign read_current = read_select == i ? read_flag : 0;
			fifo #(.SIZE_BIT(SIZE_BIT), .WIDTH(WIDTH)) buffer(CLK, RST, read_current, read_datas[i], write_flags[i], write_datas[(i+1)*WIDTH-1:i*WIDTH], empty[i], full[i]);
		end
	endgenerate
	
	assign read_data = read_datas[read_select];
endmodule