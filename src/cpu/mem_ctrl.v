// This file is based on Zhekai Zhang's code

`timescale 1ns / 1ps

`include "utility.v"

module mem_ctrl
	#(
	parameter PORT_COUNT = 2,
	parameter DATA_WIDTH_BYTE = 4,
	parameter ADDR_WIDTH_BYTE = 4
	)
	(
	CLK, RST,
	
	send_flag, send_data, send_length,
	recv_flag, recv_data, recv_length,
	
	sendable, receivable,
	
	rw_flag_,		//1 for read, 2 for write
	addr_, 
	read_data_, write_data_, write_mask_,
	busy, done
    );
    
    // read request packet format: (MSB -> LSB) (length = 4 byte)
    //  0 addr
    // write request packet format:
    //  1 length(in byte) addr data
    // read response packet format:
    //  data
    
    localparam DATA_WIDTH = 	8 * DATA_WIDTH_BYTE;
    localparam ADDR_WIDTH = 	8 * ADDR_WIDTH_BYTE;
    localparam LENGTH_WIDTH = 	`CLOG2(DATA_WIDTH_BYTE) + 1;
    localparam PORT_COUNT_BIT = `CLOG2(PORT_COUNT);
    localparam SEND_BYTE = 		DATA_WIDTH_BYTE + ADDR_WIDTH_BYTE + DATA_WIDTH_BYTE / 8 + 1;
	
	input CLK, RST;
	
	output reg send_flag;
	output reg [SEND_BYTE*8-1:0] send_data;
	output reg [4:0] send_length;
	
	output reg recv_flag;
	input [SEND_BYTE*8-1:0] recv_data;
	input [4:0] recv_length;
	
	input sendable, receivable;
	
	input [PORT_COUNT*2-1:0] 					rw_flag_;
	input [PORT_COUNT * ADDR_WIDTH-1:0] 		addr_;
	//input [PORT_COUNT * LENGTH_WIDTH-1:0] 	length_;
	output [PORT_COUNT * DATA_WIDTH-1:0] 		read_data_;
	input [PORT_COUNT * DATA_WIDTH-1:0] 		write_data_;
	input [PORT_COUNT * DATA_WIDTH_BYTE-1:0]	write_mask_;
	output reg [PORT_COUNT-1:0]					busy;
	output reg [PORT_COUNT-1:0] 				done;
	
	wire [1:0] 					rw_flag[PORT_COUNT-1:0];
	wire [ADDR_WIDTH-1:0] 		addr[PORT_COUNT-1:0];
	//wire [LENGTH_WIDTH-1:0] length[PORT_COUNT-1:0];
	reg [DATA_WIDTH-1:0] 		read_data[PORT_COUNT-1:0];
	wire [DATA_WIDTH-1:0] 		write_data[PORT_COUNT-1:0];
	wire [DATA_WIDTH_BYTE-1:0]	write_mask[PORT_COUNT-1:0];
	
	genvar j;
	generate
		for(j=0; j<PORT_COUNT; j=j+1) begin
			assign rw_flag[j] 		= rw_flag_[(j+1)*2-1:j*2];
			assign addr[j] 			= addr_[(j+1)*ADDR_WIDTH-1:j*ADDR_WIDTH];
			//assign length[j] 		= length_[(j+1)*LENGTH_WIDTH-1:j*LENGTH_WIDTH];
			assign read_data_[(j+1)*DATA_WIDTH-1:j*DATA_WIDTH] = read_data[j];
			assign write_data[j] 	= write_data_[(j+1)*DATA_WIDTH-1:j*DATA_WIDTH];
			assign write_mask[j]	= write_mask_[(j+1)*DATA_WIDTH_BYTE-1:j*DATA_WIDTH_BYTE];
		end
	endgenerate
	
	localparam NO_PORT = (1 << (PORT_COUNT_BIT + 1)) - 1;
	wire [PORT_COUNT_BIT:0] wait_port;
	reg [PORT_COUNT_BIT:0] serv_port;
	
	reg [1:0] 					pending_flag[PORT_COUNT-1:0];
	reg [ADDR_WIDTH-1:0] 		pending_addr[PORT_COUNT-1:0];
	//reg [LENGTH_WIDTH-1:0]	pending_length[PORT_COUNT-1:0];
	reg [DATA_WIDTH-1:0]		pending_write_data[PORT_COUNT-1:0];
	reg [DATA_WIDTH_BYTE-1:0]	pending_write_mask[PORT_COUNT-1:0];
	
	localparam STATE_IDLE = 0;
	localparam STATE_WAIT_FOR_RECV = 1;
	
	reg state;
	
	wire [PORT_COUNT_BIT:0] wait_port_tmp[PORT_COUNT-1:0];
	assign wait_port = wait_port_tmp[PORT_COUNT-1];
	
	generate
		assign wait_port_tmp[0] = (rw_flag[0] == 0 && pending_flag[0] == 0) ? NO_PORT : 0;
		for(j=1; j<PORT_COUNT; j=j+1) begin
			assign wait_port_tmp[j] = (wait_port_tmp[j-1] != NO_PORT || (rw_flag[j] == 0 && pending_flag[j] == 0)) ? wait_port_tmp[j-1] : j;
		end
	endgenerate
	
	task set_pending;
		input [PORT_COUNT_BIT:0] port_id;
		begin
			if(rw_flag[port_id] != 0 && busy[port_id] == 0) begin
				pending_flag[port_id] <= rw_flag[port_id];
				pending_addr[port_id] <= addr[port_id];
				//pending_length[port_id] <= length[port_id];
				pending_write_data[port_id] <= write_data[port_id];
				pending_write_mask[port_id] <= write_mask[port_id];
				busy[port_id] <= 1;
			end
		end
	endtask
	
	task send_request;
		input [1:0] 				in_flag;
		input [ADDR_WIDTH-1:0] 		in_addr;
		//input [LENGTH_WIDTH-1:0] 	in_length;
		input [DATA_WIDTH-1:0] 		in_write_data;
		input [DATA_WIDTH_BYTE-1:0]	in_write_mask;
		begin
			if(in_flag == 1) begin
				send_data <= {1'b0, in_addr};
				send_length <= ADDR_WIDTH_BYTE + 1;
				send_flag <= 1;
			end else if(in_flag == 2) begin
				send_data <= {1'b1, in_write_mask, in_addr, in_write_data};
				send_length <= SEND_BYTE;
				send_flag <= 1;
			end
		end
	endtask
	
	integer i;
	always @(posedge CLK or posedge RST) begin
		send_flag <= 0;
		recv_flag <= 0;
		done <= 0;
		if(RST) begin
			state <= STATE_IDLE;
			send_data <= 0;
			send_length <= 0;
			serv_port <= NO_PORT;
			busy <= 0;
			for(i=0; i<PORT_COUNT; i=i+1) begin
				read_data[i] <= 0;
				pending_flag[i] <= 0;
				pending_addr[i] <= 0;
				//pending_length[i] <= 0;
				pending_write_data[i] <= 0;
				pending_write_mask[i] <= 0;
			end
		end else begin
			if(state != STATE_IDLE) begin
				for(i=0; i<PORT_COUNT; i=i+1)
					set_pending(i);
			end
			case(state)
			STATE_IDLE: begin
				for(i=0; i<PORT_COUNT; i=i+1)
					if(i != wait_port)
						set_pending(i);
				if(wait_port != NO_PORT) begin
					if(sendable) begin
						if(pending_flag[wait_port] != 0) begin
							send_request(pending_flag[wait_port], pending_addr[wait_port], pending_write_data[wait_port], pending_write_mask[wait_port]);
							if(pending_flag[wait_port] == 2) begin
								pending_flag[wait_port] <= 0;
								busy[wait_port] <= 0;
								done[wait_port] <= 1;
							end else begin
								serv_port <= wait_port;
								busy[wait_port] <= 1;
								state <= STATE_WAIT_FOR_RECV;
							end
						end else begin
							send_request(rw_flag[wait_port], addr[wait_port], write_data[wait_port], write_mask[wait_port]);
							if(rw_flag[wait_port] == 2) begin
								busy[wait_port] <= 0;
								done[wait_port] <= 1;
							end else begin
								serv_port <= wait_port;
								busy[wait_port] <= 1;
								state <= STATE_WAIT_FOR_RECV;
							end
						end
					end else begin
						if(rw_flag[wait_port] != 0)
							set_pending(wait_port);
					end
				end
			end
			
			STATE_WAIT_FOR_RECV: begin
				if(receivable) begin
					recv_flag <= 1;
					read_data[serv_port] <= recv_data[DATA_WIDTH-1:0];
					done[serv_port] <= 1;
					busy[serv_port] <= 0;
					pending_flag[serv_port] <= 0;
					serv_port <= NO_PORT;
					state <= STATE_IDLE;
				end
			end
			endcase
		end
	end
endmodule