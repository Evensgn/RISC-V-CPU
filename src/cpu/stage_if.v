`include "defines.v"

module stage_if (
	input  wire               rst       ,
	input  wire [`MemAddrBus] pc_i      ,
	input  wire [    `RegBus] mem_data_i,
	input  wire               mem_busy  ,
	input  wire               mem_done  ,
	input  wire               br        ,
	input  wire               right_one ,
	output reg                mem_re    ,
	output reg  [`MemAddrBus] mem_addr_o,
	output reg  [`MemAddrBus] pc_o      ,
	output reg  [   `InstBus] inst_o    ,
	output reg                stallreq
);

	reg mem_taking;
	reg waiting_one;

	always @ (*) begin
		if (right_one) begin
			waiting_one = 0;
			//$display("Right one is here, %h", pc_i);
		end
		if (rst) begin
			stallreq    = 0;
			mem_taking  = 0;
			pc_o        = 0;
			inst_o      = 0;
			mem_re      = 0;
			mem_addr_o  = 0;
			waiting_one = 0;
		end else if (br) begin
			//$display("br");
			pc_o        = 0;
			inst_o      = 0;
			mem_taking  = 0;
			stallreq    = 0;
			waiting_one = 1;
		end else if (!waiting_one && !mem_busy && !mem_taking) begin
			//$display("!mem_busy && !mem_taking");
			stallreq   = 1;
			mem_taking = 1;
			mem_re     = 1;
			mem_addr_o = pc_i;
		end else if (!waiting_one && !mem_busy && mem_taking) begin
			//$display("!mem_busy && mem_taking");
			stallreq   = 0;
			mem_taking = 0;
			pc_o       = pc_i;
			inst_o     = mem_data_i;
			//$display("IF Get Inst: %h\n", inst_o);
		end else if (!waiting_one && mem_busy) begin
			//$display("mem_busy, %h", pc_i);
			stallreq = 1;
		end else if (!waiting_one) begin
			stallreq    = 0;
			mem_taking  = 0;
			pc_o        = 0;
			inst_o      = 0;
			mem_re      = 0;
			mem_addr_o  = 0;
			waiting_one = 0;
		end
	end

endmodule // stage_if