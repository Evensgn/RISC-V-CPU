`include "defines.v"

module regfile (
	input  wire               clk   ,
	input  wire               rst   ,
	input  wire               we    ,
	input  wire [`RegAddrBus] waddr ,
	input  wire [    `RegBus] wdata ,
	input  wire               re1   ,
	input  wire [`RegAddrBus] raddr1,
	output reg  [    `RegBus] rdata1,
	input  wire               re2   ,
	input  wire [`RegAddrBus] raddr2,
	output reg  [    `RegBus] rdata2
);

	reg[`RegBus]  regs[0:`RegNum-1];

	// write
	always @ (posedge clk) begin
		if (rst == `False) begin
			// $0 cannot be written
			if ((we == `True) && (waddr != `RegNumLog2'h0)) begin
				regs[waddr] <= wdata;
			end
		end
	end

	// read 1
	always @ (*) begin
		if (rst == `True) begin
			rdata1 <= `ZeroWord;
		end else if (raddr1 == `RegNumLog2'h0) begin
			rdata1 <= `ZeroWord;
		end else if ((re1 == `True) && (we == `True) && (raddr1 == waddr)) begin
			rdata1 <= wdata;
		end else if (re1 == `True) begin
			rdata1 <= regs[raddr1];
		end else begin
			rdata1 <= `ZeroWord;
		end
	end

	// read 2
	always @ (*) begin
		if(rst == `True) begin
			rdata2 <= `ZeroWord;
		end else if (raddr2 == `RegNumLog2'h0) begin
			rdata2 <= `ZeroWord;
		end else if ((re2 == `True) && (we == `True) && (raddr2 == waddr)) begin
			rdata2 <= wdata;
		end else if (re2 == `True) begin
			rdata2 <= regs[raddr2];
		end else begin
			rdata2 <= `ZeroWord;
		end
	end

endmodule // regfile