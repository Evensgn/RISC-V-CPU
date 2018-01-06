`timescale 1ns/1ps

`include "defines.v"

module cpu (
	input  wire EXCLK ,
	input  wire button,
	output wire Tx    ,
	input  wire Rx
);

	reg rst      ;
	reg rst_delay;

	wire clk;
	clk_wiz_0 clk(clk, 1'b0, EXCLK);

	always @(posedge rst or posedge button) begin
		if(button) begin
			rst       <= 1;
			rst_delay <= 1;
		end else begin
			rst_delay <= 0;
			rst       <= RST_delay;
		end
	end

	wire       UART_send_flag ;
	wire [7:0] UART_send_data ;
	wire       UART_recv_flag ;
	wire [7:0] UART_recv_data ;
	wire       UART_sendable  ;
	wire       UART_receivable;

	uart_comm #(.BAUDRATE(5000000/*115200*/), .CLOCKRATE(66667000)) UART (
		clk, rst,
		UART_send_flag, UART_send_data,
		UART_recv_flag, UART_recv_data,
		UART_sendable, UART_receivable,
		Tx, Rx
	);

	localparam CHANNEL_BIT = 1               ;
	localparam MESSAGE_BIT = 72              ;
	localparam CHANNEL     = 1 << CHANNEL_BIT;

	wire                   COMM_read_flag   [CHANNEL-1:0];
	wire [MESSAGE_BIT-1:0] COMM_read_data   [CHANNEL-1:0];
	wire [            4:0] COMM_read_length [CHANNEL-1:0];
	wire                   COMM_write_flag  [CHANNEL-1:0];
	wire [MESSAGE_BIT-1:0] COMM_write_data  [CHANNEL-1:0];
	wire [            4:0] COMM_write_length[CHANNEL-1:0];
	wire                   COMM_readable    [CHANNEL-1:0];
	wire                   COMM_writable    [CHANNEL-1:0];

	multchan_comm #(.MESSAGE_BIT(MESSAGE_BIT), .CHANNEL_BIT(CHANNEL_BIT)) COMM (
		clk, rst,
		UART_send_flag, UART_send_data,
		UART_recv_flag, UART_recv_data,
		UART_sendable, UART_receivable,
		{COMM_read_flag[1], COMM_read_flag[0]},
		{COMM_read_length[1], COMM_read_data[1], COMM_read_length[0], COMM_read_data[0]},
		{COMM_write_flag[1], COMM_write_flag[0]},
		{COMM_write_length[1], COMM_write_data[1], COMM_write_length[0], COMM_write_data[0]},
		{COMM_readable[1], COMM_readable[0]},
		{COMM_writable[1], COMM_writable[0]}
	);

	wire [ 2*2-1:0] MEM_rw_flag   ;
	wire [2*32-1:0] MEM_addr      ;
	wire [2*32-1:0] MEM_read_data ;
	wire [2*32-1:0] MEM_write_data;
	wire [ 2*4-1:0] MEM_write_mask;
	wire [     1:0] MEM_busy      ;
	wire [     1:0] MEM_done      ;

	memory_controller MEM_CTRL (
		clk, rst,
		COMM_write_flag[0], COMM_write_data[0], COMM_write_length[0],
		COMM_read_flag[0], COMM_read_data[0], COMM_read_length[0],
		COMM_writable[0], COMM_readable[0],
		MEM_rw_flag, MEM_addr,
		MEM_read_data, MEM_write_data, MEM_write_mask,
		MEM_busy, MEM_done
	);

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

endmodule // cpu