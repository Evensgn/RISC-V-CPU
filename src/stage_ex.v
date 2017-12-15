`include "defines.v"

module stage_ex (
	input  wire               rst    ,
	input  wire [  `AluOpBus] aluop  ,
	input  wire [ `AluSelBus] alusel ,
	input  wire [    `RegBus] opv1   ,
	input  wire [    `RegBus] opv2   ,
	input  wire [`RegAddrBus] reg_waddr_i,
	input  wire               we_i   ,
	output reg  [`RegAddrBus] reg_waddr_o,
	output reg                we_o   ,
	output reg  [    `RegBus] reg_wdata
);

	reg[`RegBus] logic_out;

	always @ (*) begin
		if(rst || alusel != `EXE_RES_LOGIC) begin
			logic_out <= 0;
		end else begin
			case (aluop)
				`EXE_OR_OP : begin
					logic_out <= opv1 | opv2;
				end
				default : begin
					logic_out <= 0;
				end
			endcase // aluop
		end // end else
	end // always @ (*)

	always @ (*) begin
		reg_waddr_o   <= reg_waddr_i;
		we_o <= we_i;
		case (alusel)
			`EXE_RES_LOGIC : begin
				$display("EXE_RES_LOGIC");
				reg_wdata <= logic_out;
			end
			default : begin
				reg_wdata <= 0;
			end
		endcase // alusel
	end // always @ (*)

endmodule // stage_ex