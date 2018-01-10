`include "defines.v"

module reg_pc (
	input  wire                clk        ,
	input  wire                rst        ,
	input  wire [         5:0] stall      ,
	input  wire                br         ,
	input  wire [`InstAddrBus] br_addr    ,
	output reg  [`InstAddrBus] pc_o       ,
	output reg                 right_one_o
);

	reg [`InstAddrBus] pc       ;
	reg                right_one;

	always @ (posedge clk) begin
		if (!rst && br) begin
			pc <= br_addr;
			right_one <= 1;
		end else if (!rst && !stall[0]) begin
			pc <= pc + 4;
			right_one <= 0;
		end
		if (rst) begin
			pc_o      <= 0;
			right_one <= 0;
			pc        <= 4;
		end else if (!stall[0]) begin
			//$display("PC now: %h", pc);
			pc_o <= pc;
			right_one_o <= right_one;
		end
	end

	/*always @ (posedge clk) begin
		if (rst) begin
			pc_o <= 0;
		end else if (!stall[0]) begin
			if (br) pc_o <= br_addr;
			else pc_o <= pc_o + 4;
		end
	end*/

endmodule // reg_pc