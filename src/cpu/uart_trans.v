// This file is based on Zhekai Zhang's code

module uart_trans #(
	parameter BAUDRATE  = 2304000 ,
	parameter CLOCKRATE = 40000000
) (
	input            CLK       ,
	input            RST       ,
	input            send_flag ,
	input      [7:0] send_data ,
	input            recv_flag ,
	output     [7:0] recv_data ,
	output           sendable  ,
	output           receivable,
	output reg       Tx        ,
	input            Rx
);

	reg recv_write_flag;
	reg [7:0] recv_write_data;
	wire recv_empty, recv_full;
	fifo #(.WIDTH(8)) recv_buffer(CLK, RST, recv_flag, recv_data, recv_write_flag, recv_write_data, recv_empty, recv_full);

	reg send_read_flag;
	wire [7:0] send_read_data;
	reg [7:0] send_read_data_buf;
	wire send_empty, send_full;
	fifo #(.WIDTH(8)) send_buffer(CLK, RST, send_read_flag, send_read_data, send_flag, send_data, send_empty, send_full);

	assign receivable = !recv_empty;
	assign sendable = !send_full;
	
	localparam SAMPLE_INTERVAL = CLOCKRATE / BAUDRATE;
	
	localparam STATUS_IDLE = 0;
	localparam STATUS_BEGIN = 1;
	localparam STATUS_DATA = 2;
	localparam STATUS_VALID = 4;
	localparam STATUS_END = 8;
	reg [3:0] recv_status;
	reg [2:0] recv_bit;
	reg recv_parity;
	
	integer recv_counter;
	reg recv_clock;
	
	wire sample = recv_counter == SAMPLE_INTERVAL / 2;
	
	always @(posedge CLK or posedge RST) begin
		if(RST) begin
			recv_write_flag <= 0;
			recv_write_data <= 0;
			recv_status <= STATUS_IDLE;
			recv_bit <= 0;
			recv_parity <= 0;
			recv_counter <= 0;
			recv_clock <= 0;
		end else begin
			recv_write_flag <= 0;
			if(recv_clock) begin
				if(recv_counter == SAMPLE_INTERVAL - 1)
					recv_counter <= 0;
				else
					recv_counter <= recv_counter + 1;
			end
			if(recv_status == STATUS_IDLE) begin
				if(!Rx) begin
					recv_status <= STATUS_BEGIN;
					recv_counter <= 0;
					recv_clock <= 1;
				end
			end else if(sample) begin
				case(recv_status)
				STATUS_BEGIN:begin
					if(!Rx) begin
						recv_status <= STATUS_DATA;
						recv_bit <= 0;
						recv_parity <= 0;
					end else begin
						recv_status <= STATUS_IDLE;
						recv_clock <= 0;
					end
				end
				
				STATUS_DATA:begin
					recv_parity <= recv_parity ^ Rx;
					recv_write_data[recv_bit] <= Rx;
					recv_bit <= recv_bit + 1;
					if(recv_bit == 7)
						recv_status <= STATUS_VALID;
				end
				
				STATUS_VALID:begin
					if(recv_parity == Rx && !recv_full)
						recv_write_flag <= 1;
					recv_status <= STATUS_END;
				end
				
				STATUS_END: begin
					recv_status <= STATUS_IDLE;
					recv_clock <= 0;
				end
				endcase
			end
		end
	end
	
	integer counter;
	always @(posedge CLK or posedge RST) begin
		if(RST) begin
			counter <= 0;
		end else begin
			counter <= counter + 1;
			if(counter == SAMPLE_INTERVAL - 1)
				counter <= 0;
		end
	end
	
	reg [3:0] send_status;
	reg [2:0] send_bit;
	reg send_parity;
	reg tosend;
	
	always @(posedge CLK or posedge RST) begin
		if(RST) begin
			send_read_flag <= 0;
			send_read_data_buf <= 0;
			send_status <= STATUS_IDLE;
			send_bit <= 0;
			send_parity <= 0;
			tosend <= 0;
			Tx <= 1;
		end else begin
			send_read_flag <= 0;
			
			if(counter == 0) begin
				case(send_status)
				STATUS_IDLE:begin
					if(!send_empty) begin
						send_read_data_buf <= send_read_data;
						send_read_flag <= 1;
						Tx <= 0;
						send_status <= STATUS_DATA;
						send_bit <= 0;
						send_parity <= 0;
					end
				end
				
				STATUS_DATA:begin
					Tx <= send_read_data_buf[send_bit];
					send_parity <= send_parity ^ send_read_data_buf[send_bit];
					send_bit <= send_bit + 1;
					if(send_bit == 7)
						send_status <= STATUS_VALID;
				end
				
				STATUS_VALID:begin
					Tx <= send_parity;
					send_status <= STATUS_END;
				end
				
				STATUS_END:begin
					Tx <= 1;
					send_status <= STATUS_IDLE;
					tosend = 0;
				end
				endcase
			end
		end
	end

endmodule // uart_trans