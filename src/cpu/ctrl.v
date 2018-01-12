`include "defines.v"

module ctrl (
	input  wire       rst         ,
	input  wire       stallreq_if ,
	input  wire       stallreq_id ,
	input  wire       stallreq_ex ,
	input  wire       stallreq_mem,
	output reg  [5:0] stall
);

// stall[0] PC
// stall[1] IF
// stall[2] ID
// stall[3] EX
// stall[4] MEM
// stall[5] WB

	always @ (*) begin
		if(rst) begin
			stall <= 6'b000000;
		end else if (stallreq_mem) begin
			stall <= 6'b011111;
		end else if (stallreq_ex) begin
			stall <= 6'b001111;
		end else if (stallreq_id) begin
			stall <= 6'b000111;
		end else if (stallreq_if) begin
			stall <= 6'b000011;
		end else begin
			stall <= 6'b000000;
		end
	end // always @ (*)

endmodule