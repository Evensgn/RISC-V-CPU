// This file is Zhekai Zhang's code

`timescale 1ns / 1ps

module fifo
	#(
	parameter SIZE_BIT	= 3,
	parameter WIDTH 	= 8
	)
	(
	input CLK,
	input RST,
	input read_flag,
	output [WIDTH-1:0] read_data,
	input write_flag,
	input [WIDTH-1:0] write_data,
	output empty,
	output full
    );
    
    localparam SIZE = 1 << SIZE_BIT;
    reg [WIDTH-1:0] buffer[SIZE-1:0];
    reg [SIZE_BIT-1:0] read_ptr;
    reg [SIZE_BIT-1:0] write_ptr;
    reg [SIZE_BIT:0] buffer_size;
    
    assign empty = buffer_size == 0;
    assign full  = buffer_size == SIZE;
    
    wire read, write;
    assign read  = read_flag && !empty;
    assign write = write_flag && !full;
    
    assign read_data = buffer[read_ptr];
    
    integer i;
    always @(negedge CLK or posedge RST) begin
    	if(RST) begin
    		read_ptr <= 0;
    		write_ptr <= 0;
    		buffer_size <= 0;
    		for(i=0; i<SIZE; i=i+1)
    			buffer[i] <= 0;
    	end else begin
    		if(read && write) begin
    			buffer[write_ptr] <= write_data;
    			read_ptr <= read_ptr + 1;
    			write_ptr <= write_ptr + 1;
    		end else if(read) begin
    			read_ptr <= read_ptr + 1;
    			buffer_size <= buffer_size - 1;
    		end else if(write) begin
    			buffer[write_ptr] <= write_data;
    			write_ptr <= write_ptr + 1;
    			buffer_size <= buffer_size + 1;
    		end
    	end
    end
endmodule