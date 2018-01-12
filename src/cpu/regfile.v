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
		if (!rst) begin
			// x0 cannot be written
			if (we && waddr != 0) begin
				//$display("WRITE REGISTER FILE: x%d = %h", waddr, wdata);
				regs[waddr] <= wdata;
			end
		end
	end

	// read 1
	always @ (*) begin
		if (rst || !re1 || raddr1 == 0) begin
			rdata1 <= 0;
		end else if (we && raddr1 == waddr) begin
			rdata1 <= wdata;
		end else begin
			rdata1 <= regs[raddr1];
		end
	end

	// read 2
	always @ (*) begin
		if (rst || !re2 || raddr2 == 0) begin
			rdata2 <= 0;
		end else if (we && raddr2 == waddr) begin
			rdata2 <= wdata;
		end else begin
			rdata2 <= regs[raddr2];
		end
	end

endmodule // regfile