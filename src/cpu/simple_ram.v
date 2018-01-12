module simple_ram #(
	parameter AddrBusWidth     = 16,
	parameter DataBusByteWidth = 4
) (
	input  wire                          clk   ,
	input  wire                          rst   ,
	input  wire                          re    ,
	input  wire [      AddrBusWidth-1:0] r_addr,
	input  wire                          we    ,
	input  wire [8*DataBusByteWidth-1:0] w_data,
	input  wire [      AddrBusWidth-1:0] w_addr,
	input  wire [  DataBusByteWidth-1:0] w_sel ,
	output reg  [8*DataBusByteWidth-1:0] r_data
);

	reg [8*DataBusByteWidth-1:0] data[(1<<AddrBusWidth)-1:0];

	always @ (posedge clk) begin
		if (!rst && we) begin
			if(w_sel[0]) data[w_addr][7:0] <= w_data[7:0];
			if(w_sel[1]) data[w_addr][15:8] <= w_data[15:8];
			if(w_sel[2]) data[w_addr][23:16] <= w_data[23:16];
			if(w_sel[3]) data[w_addr][31:24] <= w_data[31:24];
		end
	end

	always @ (posedge clk) begin
		if (rst) begin
			r_data <= 0;
		end else if (re) begin
			r_data <= data[r_addr];
		end else begin
			r_data <= 0;
		end
	end

endmodule // simple_ram