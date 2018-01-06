// This file is Zhekai Zhang's code

`timescale 1ns / 1ps

module multichan_trans
	#(
	parameter PACKET_SIZE = 8,
	parameter MESSAGE_BIT = 256,
	parameter CHANNEL_BIT = 1,
	parameter [5*(1<<CHANNEL_BIT)-1:0] CHANNEL_PRIORITY = {(1<<CHANNEL_BIT){5'd8}}
	)
	(
	input CLK,
	input RST,
	
	output reg send_flag,
	output reg [PACKET_SIZE-1:0] send_data,
	output reg recv_flag,
	input [PACKET_SIZE-1:0] recv_data,
	
	input sendable,
	input receivable,
	
	input [(1<<CHANNEL_BIT)-1:0] read_flags,
	output [(1<<CHANNEL_BIT)*(MESSAGE_BIT+5)-1:0] read_datas,
	input [(1<<CHANNEL_BIT)-1:0] write_flags,
	input [(1<<CHANNEL_BIT)*(MESSAGE_BIT+5)-1:0] write_datas,
	
	output [(1<<CHANNEL_BIT)-1:0] readable,
	output [(1<<CHANNEL_BIT)-1:0] writable
	);
	
	localparam WIDTH = MESSAGE_BIT + 5;
	localparam CHANNEL = 1 << CHANNEL_BIT;
	
	reg read_buffer_write_flag;
	reg [CHANNEL_BIT-1:0] read_buffer_select;
	reg [MESSAGE_BIT+5-1:0] read_buffer_write_data;
	wire [CHANNEL-1:0] read_buffer_empty;
	wire [CHANNEL-1:0] read_buffer_full;
	simo_fifo #(.CHANNEL_BIT(CHANNEL_BIT), .WIDTH(WIDTH)) read_buffer(
		CLK, RST, read_flags, read_datas, 
		read_buffer_write_flag, read_buffer_select, read_buffer_write_data, read_buffer_empty, read_buffer_full);
	
	reg write_buffer_read_flag;
	wire [CHANNEL_BIT-1:0] write_buffer_select;
	wire [MESSAGE_BIT+5-1:0] write_buffer_read_data;
	reg [MESSAGE_BIT+5-1:0] write_buffer_read_data_buf;
	wire [CHANNEL-1:0] write_buffer_empty;
	wire [CHANNEL-1:0] write_buffer_full;
	miso_fifo #(.CHANNEL_BIT(CHANNEL_BIT), .WIDTH(WIDTH)) write_buffer(
		CLK, RST, write_buffer_read_flag, write_buffer_select, write_buffer_read_data,
		write_flags, write_datas, write_buffer_empty, write_buffer_full);
	
	assign readable = ~read_buffer_empty;
	assign writable = ~write_buffer_full;
	
	reg [4:0] priority[CHANNEL-1:0];
	reg [2:0] skip_read[CHANNEL-1:0];
	
	//wire [4:0] max_priority[CHANNEL-1:0];
	//wire [CHANNEL_BIT-1:0] current_read[CHANNEL-1:0];
	
//	assign max_priority[0] = write_buffer_empty[0] ? 0 : priority[0];
//	assign current_read[0] = 0;
	
//	genvar i;
//	generate
//		for(i=1; i < CHANNEL; i=i+1) begin
//			assign max_priority[i] = !write_buffer_empty[i] && priority[i] > max_priority[i-1] ? priority[i] : max_priority[i-1];
//			assign current_read[i] = !write_buffer_empty[i] && 
//				(priority[i] > max_priority[i-1] || (priority[i] == max_priority[i-1] && skip_read[i] > skip_read[current_read[i-1]])) ? i : current_read[i-1];
//		end
//	endgenerate

	reg [4:0] max_priority_array[CHANNEL-1:0];
	reg [CHANNEL_BIT-1:0] current_read_array[CHANNEL-1:0];
	//wire [CHANNEL_BIT-1:0] current_read;
	
	assign write_buffer_select = current_read_array[CHANNEL-1];
	
	integer i;
	always @(negedge CLK or posedge RST) begin
		if(RST) begin
			for(i=0; i < CHANNEL; i=i+1) begin
				max_priority_array[i] <= 0;
				current_read_array[i] <= 0;
			end
		end else begin
			max_priority_array[0] <= write_buffer_empty[0] ? 0 : priority[0];
			current_read_array[0] <= 0;
			for(i=1; i < CHANNEL; i=i+1) begin
				if(!write_buffer_empty[i] && 
					(priority[i] > max_priority_array[i-1] || (priority[i] == max_priority_array[i-1] && skip_read[i] > skip_read[current_read_array[i-1]]))) begin
					max_priority_array[i] <= priority[i];
					current_read_array[i] <= i;
				end else begin
					max_priority_array[i] <= max_priority_array[i-1];
					current_read_array[i] <= current_read_array[i-1];
				end
			end
		end
	end
	
	localparam STATUS_IDLE = 0;
	//localparam STATUS_HEAD = 1;
	localparam STATUS_CHANNEL = 1;
	localparam STATUS_LENGTH = 2;
	localparam STATUS_DATA = 4;
	localparam STATUS_END = 8;
	reg [3:0] send_status;
	reg [8:0] send_bit;
	reg [4:0] packet_id;
	
	reg [CHANNEL_BIT-1:0] send_channel;
	
	wire [4:0] length;
	assign length = write_buffer_read_data_buf[WIDTH-1:WIDTH-5];
	
	wire [MESSAGE_BIT+6:0] data;
	assign data[MESSAGE_BIT-1:0] = write_buffer_read_data_buf[MESSAGE_BIT-1:0];
	assign data[MESSAGE_BIT+6:MESSAGE_BIT] = 0;
	
	wire [4:0] next_packet_id;
	assign next_packet_id = packet_id + 1;
	
	integer j;
	always @(posedge CLK or posedge RST) begin
		send_flag <= 0;
		write_buffer_read_flag <= 0;
		if(RST) begin
			write_buffer_read_data_buf <= 0;
			send_channel <= 0;
			send_data <= 0;
			send_status <= STATUS_IDLE;
			send_bit <= 0;
			packet_id <= 0;
			for(j=0; j < CHANNEL; j=j+1) begin
				priority[j] <= CHANNEL_PRIORITY[j*5 +: 5];
				skip_read[j] <= 0;
			end
		end else if(sendable) begin
			case(send_status)
			STATUS_IDLE: begin
				if(!write_buffer_empty[write_buffer_select]) begin
					write_buffer_read_data_buf <= write_buffer_read_data;
					write_buffer_read_flag <= 1;
					send_bit <= 0;
					send_channel <= write_buffer_select;
					
					skip_read[write_buffer_select] <= 0;
					priority[write_buffer_select] <= CHANNEL_PRIORITY[write_buffer_select*5 +: 5];
					for(j=0; j < CHANNEL; j=j+1)
						if(j != write_buffer_select && !write_buffer_empty[j]) begin
							if(skip_read[j] == 7) begin
								skip_read[j] <= 0;
								if(priority[j][3:0] != 4'hf)
									priority[j] <= priority[j] + 1;
							end else
								skip_read[j] <= skip_read[j] + 1;
						end
					
					packet_id <= next_packet_id;
					
					if(PACKET_SIZE-3-5 > 0)
						send_data <= {3'b100, {(PACKET_SIZE-3-5){1'b0}}, next_packet_id};
					else
						send_data <= {3'b100, next_packet_id};
					send_flag <= 1;
					send_status <= STATUS_CHANNEL;
				end
			end
			
			STATUS_CHANNEL: begin
				if(PACKET_SIZE-3-CHANNEL_BIT > 0)
					send_data <= {3'b101, {(PACKET_SIZE-3-CHANNEL_BIT){1'b0}}, send_channel};
				else
					send_data <= {3'b101, send_channel};
				send_flag <= 1;
				send_status <= STATUS_LENGTH;
			end
			
			STATUS_LENGTH: begin
				if(PACKET_SIZE-3-5 > 0)
					send_data <= {3'b110, {(PACKET_SIZE-3-5){1'b0}}, length};
				else
					send_data <= {3'b110, length};
				send_flag <= 1;
				send_status <= STATUS_DATA;
			end
			
			STATUS_DATA: begin
				send_data <= {1'b0, data[send_bit +: PACKET_SIZE-1]};
				send_flag <= 1;
				send_bit <= send_bit + PACKET_SIZE - 1;
				if(send_bit + PACKET_SIZE - 1 >= (length << 3))
					send_status <= STATUS_END;
			end
			
			STATUS_END: begin
				if(PACKET_SIZE-3-5 > 0)
					send_data <= {3'b111, {(PACKET_SIZE-3-5){1'b0}}, packet_id};
				else
					send_data <= {3'b111, packet_id};
				send_flag <= 1;
				send_status <= STATUS_IDLE;
			end
			endcase
		end
	end
	
	reg [4:0] recv_status;
	reg [8:0] recv_bit;
	reg [4:0] recv_packet_id;
	reg [4:0] recv_length;
	
	always @(posedge CLK or posedge RST) begin
		read_buffer_write_flag <= 0;
		recv_flag <= 0;
		if(RST) begin
			recv_status <= STATUS_IDLE;
			recv_bit <= 0;
			recv_packet_id <= 0;
			recv_length <= 0;
			read_buffer_select <= 0;
			read_buffer_write_data <= 0;
		end else begin
			if(receivable) begin
				recv_flag <= 1;
				case(recv_status)
				STATUS_IDLE: begin
					if(recv_data[PACKET_SIZE-1:PACKET_SIZE-3] == 3'b100) begin
						recv_packet_id <= recv_data[4:0];
						recv_bit <= 0;
						recv_length <= 0;
						recv_status <= STATUS_CHANNEL;
					end
				end
				
				STATUS_CHANNEL: begin
					if(recv_data[PACKET_SIZE-1:PACKET_SIZE-3] == 3'b101) begin
						read_buffer_select <= recv_data[CHANNEL_BIT-1:0];
						recv_status <= STATUS_LENGTH;
					end else
						recv_status <= STATUS_IDLE;
				end
				
				STATUS_LENGTH: begin
					if(recv_data[PACKET_SIZE-1:PACKET_SIZE-3] == 3'b110) begin
						recv_length <= recv_data[4:0];
						recv_status <= STATUS_DATA;
					end else
						recv_status <= STATUS_IDLE;
				end
				
				STATUS_DATA: begin
					if(recv_data[PACKET_SIZE-1] == 0) begin
						read_buffer_write_data[recv_bit +: PACKET_SIZE-1] <= recv_data[PACKET_SIZE-2:0];
						recv_bit <= recv_bit + PACKET_SIZE - 1;
						if(recv_bit + PACKET_SIZE - 1 >= (recv_length << 3)) 
							recv_status <= STATUS_END;
					end else
						recv_status <= STATUS_IDLE;
				end
				
				STATUS_END: begin
					if(recv_data[PACKET_SIZE-1:PACKET_SIZE-3] == 3'b111)
						if(recv_packet_id == recv_data[4:0] && !read_buffer_full) begin
							read_buffer_write_data[WIDTH-1:WIDTH-5] <= recv_length;
							read_buffer_write_flag <= 1;
						end
					recv_status <= STATUS_IDLE;
				end
				endcase
			end
		end
	end
endmodule