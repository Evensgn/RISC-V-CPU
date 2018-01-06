`include "defines.v"

module stage_if (
	input  wire               rst       ,
	input  wire [`MemAddrBus] pc_i      ,
	input  wire [    `RegBus] mem_data_i,
	input  wire               mem_busy  ,
	input  wire               mem_done  ,
	output wire               mem_re    ,
	output wire [`MemAddrBus] mem_addr_o,
	output reg  [`MemAddrBus] pc_o      ,
	output reg  [   `InstBus] inst_o    ,
	output reg                stallreq
);

	reg mem_taking;

	always @ (*) begin
		if (rst) begin
			stallreq <= 0;
			mem_taking <= 0;
			pc_o <= 0;
			inst_o <= 0;
			mem_re <= 0;
			mem_addr_o <= 0;
		end else if (!mem_busy && !mem_taking) begin
			stallreq <= 1;
			mem_taking <= 1;
			mem_re <= 1;
			mem_addr_o <= pc_i;
		end else if (!mem_busy && mem_taking) begin
			stallreq <= 0;
			mem_taking <= 0;
			pc_o <= pc_i;
			inst_o <= mem_data_i;
		end else if (mem_busy) begin
			stallreq <= 1;
		end
	end

endmodule // stage_if