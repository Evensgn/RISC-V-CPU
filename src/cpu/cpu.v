`timescale 1ns/1ps

`include "defines.v"

module cpu (
	input  wire EXCLK  ,
	input  wire button ,
	output wire rst_led,
	output wire Tx     ,
	input  wire Rx
);

	reg rst;
	assign rst_led = rst;
	reg rst_delay;

	wire clk;
	clk_wiz_0 clk_wiz_0_0(.clk_out1(clk), .reset(0), .clk_in1(EXCLK));

	always @ (posedge clk or negedge button) begin
		if (!button) begin
			rst       <= 1;
			rst_delay <= 1;
		end else begin
			rst_delay <= 0;
			rst       <= rst_delay;
		end
	end

	wire       UART_send_flag ;
	wire [7:0] UART_send_data ;
	wire       UART_recv_flag ;
	wire [7:0] UART_recv_data ;
	wire       UART_sendable  ;
	wire       UART_receivable;

	uart_trans uart_trans0 (
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

	multichan_trans #(.MESSAGE_BIT(MESSAGE_BIT), .CHANNEL_BIT(CHANNEL_BIT)) multichan_trans0 (
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

	wire [ 2*2-1:0] mem_rwe   ;
	wire [2*32-1:0] mem_addr  ;
	wire [2*32-1:0] mem_r_data;
	wire [2*32-1:0] mem_w_data;
	wire [ 2*4-1:0] mem_sel   ;
	wire [     1:0] mem_busy  ;
	wire [     1:0] mem_done  ;

	mem_ctrl mem_ctrl0 (
		clk, rst,
		COMM_write_flag[0], COMM_write_data[0], COMM_write_length[0],
		COMM_read_flag[0], COMM_read_data[0], COMM_read_length[0],
		COMM_writable[0], COMM_readable[0],
		mem_rwe, mem_addr,
		mem_r_data, mem_w_data, mem_sel,
		mem_busy, mem_done
	);

	riscv_cpu riscv_cpu0 (
		// input
		.clk       (clk       ),
		.rst       (rst       ),
		.mem_data_i(mem_r_data),
		.mem_busy_i(mem_busy  ),
		.mem_done_i(mem_done  ),
		// output
		.mem_rwe_o (mem_rwe   ),
		.mem_addr_o(mem_addr  ),
		.mem_sel_o (mem_sel   ),
		.mem_data_o(mem_w_data)
	);

endmodule // cpu