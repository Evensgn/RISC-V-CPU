// Zhekai Zhang's simulation code

`timescale 1ns / 1ps

module sim_memory (
	input EXCLK,
	input RST,
	output Tx,
	input Rx
    );
    
    wire clk;
    clk_wiz_0 clk_wiz_0_0(.clk_out1(clk), .reset(0), .clk_in1(EXCLK));
        
    wire send_flag;
	wire [7:0] send_data;
	wire recv_flag;
	wire [7:0] recv_data;
	
	wire recvable, sendable;
	uart_trans uart(clk, RST, send_flag, send_data, recv_flag, recv_data, sendable, recvable, Tx, Rx);
	
	reg read_flag;
	wire [4:0] read_data_length;
	wire [71:0] read_data;
	reg write_flag;
	reg [4:0] write_data_length;
	reg [71:0] write_data;
	wire readable;
	wire writable;
	
	wire _trash, _trash2;
	
	reg [7:0] memory[10000000:0];
	reg [7:0] memory_stack[10000000:0];
	
	integer i;
	initial begin
		for(i=0;i<2048;i=i+1) begin
			memory[i] = 0;
			memory_stack[i] = 0;
		end
		$readmemh("D:/Files/Progs/RISC-V-CPU/test/example.data", memory);
	end
	
	function [31:0] getDWORD;
		input [31:0] addr;
		getDWORD = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};
	endfunction
	
	function [15:0] getWORD;
		input [31:0] addr;
		getWORD = {memory[addr+1], memory[addr]};
	endfunction
	
	multichan_trans #(.CHANNEL_BIT(1), .MESSAGE_BIT(72)) comm(
		clk, RST, send_flag, send_data, recv_flag, recv_data, sendable, recvable,
		{1'b0, read_flag}, {read_data_length, read_data},
		{1'b0, write_flag}, {write_data_length, write_data},
		{_trash, readable}, {_trash2, writable});
	
	always @(posedge clk or posedge RST) begin
		read_flag <= 0;
		write_flag <= 0;
		if(RST) begin
			write_data <= 0;
		end else begin
			if(readable) begin
				read_flag <= 1;
				if(read_data_length == 5 && read_data[32] == 0) begin	//read
					//$display("GET READ REQUEST, ADDR = 0x%x DATA = %x", read_data[31:0], getDWORD(read_data[31:0]));
					write_flag <= 1;
					write_data <= getDWORD(read_data[31:0]);
					write_data_length <= 4;
				end else begin	//write
					if (read_data[63:32] == 12'h104) 
						$display("%c", read_data[31:0]);
					//$display("GET WRITE REQUEST, ADDR = 0x%x DATA = %x MASK = %d", read_data[63:32], read_data[31:0], read_data[67:64]);
					if(read_data[64])
						memory[read_data[63:32]] <= read_data[7:0];
					if(read_data[65])
						memory[read_data[63:32]+1] <= read_data[15:8];
					if(read_data[66])
						memory[read_data[63:32]+2] <= read_data[23:16];
					if(read_data[67])
						memory[read_data[63:32]+3] <= read_data[31:24];
				end
			end
		end
	end
	
endmodule