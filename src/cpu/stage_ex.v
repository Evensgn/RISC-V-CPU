`include "defines.v"

module stage_ex (
	input  wire                rst        ,
	input  wire [   `AluOpBus] aluop      ,
	input  wire [  `AluSelBus] alusel     ,
	input  wire [     `RegBus] opv1       ,
	input  wire [     `RegBus] opv2       ,
	input  wire [ `RegAddrBus] reg_waddr_i,
	input  wire                we_i       ,
	input  wire [`InstAddrBus] link_addr  ,
	input  wire [     `RegBus] mem_offset ,
	output reg  [ `RegAddrBus] reg_waddr_o,
	output reg                 we_o       ,
	output reg  [     `RegBus] reg_wdata  ,
	output reg                 stallreq   ,
	output reg  [ `MemAddrBus] mem_addr   ,
	output wire [   `AluOpBus] ex_aluop   ,
	output wire [     `RegBus] rt_data
);

	assign ex_aluop = aluop;
	assign rt_data  = opv2;

	reg[`RegBus] logic_out;
	reg[`RegBus] shift_out;
	reg[`RegBus] arith_out;
	reg[`RegBus] mem_out;

	// EXE_RES_LOGIC
	always @ (*) begin
		if(rst || alusel != `EXE_RES_LOGIC) begin
			logic_out = 0;
		end else begin
			case (aluop)
				`EXE_XOR_OP : begin
					logic_out = opv1 ^ opv2;
				end
				`EXE_OR_OP : begin
					logic_out = opv1 | opv2;
				end
				`EXE_AND_OP : begin
					logic_out = opv1 & opv2;
				end
				default : begin
					logic_out = 0;
				end
			endcase // aluop
		end // end else
	end // always @ (*)

	// EXE_RES_SHIFT
	always @ (*) begin
		if(rst || alusel != `EXE_RES_SHIFT) begin
			shift_out = 0;
		end else begin
			case (aluop)
				`EXE_SLL_OP : begin
					shift_out = opv1 << opv2[4:0];
				end
				`EXE_SRL_OP : begin
					shift_out = opv1 >> opv2[4:0];
				end
				`EXE_SRA_OP : begin
					shift_out = ({32{opv1[31]}} << {6'd32 - {1'b0, opv2[4:0]}}) |
								 (opv1 >> opv2[4:0]);
				end
				default : begin
					shift_out = 0;
				end
			endcase // aluop
		end // end else
	end // always @ (*)

	// EXE_RES_ARITH
	always @ (*) begin
		if(rst || alusel != `EXE_RES_ARITH) begin
			arith_out = 0;
		end else begin
			case (aluop)
				`EXE_ADD_OP : begin
					arith_out = opv1 + opv2;
				end
				`EXE_SUB_OP : begin
					arith_out = opv1 - opv2;
				end
				`EXE_SLT_OP : begin
					arith_out = $signed(opv1) < $signed(opv2);
				end
				`EXE_SLTU_OP : begin
					arith_out = opv1 < opv2;
				end
				default : begin
					arith_out = 0;
				end
			endcase // aluop
		end // end else
	end // always @ (*)

	// EXE_RES_LOAD_STORE
	always @ (*) begin
		if(rst || alusel != `EXE_RES_LOAD_STORE) begin
			mem_out = 0;
		end else begin
			mem_out = opv1 + mem_offset;
		end // end else
	end // always @ (*)

	always @ (*) begin
		stallreq    = 0;
		reg_waddr_o = reg_waddr_i;
		we_o        = we_i;
		mem_addr    = 0;
		case (alusel)
			`EXE_RES_LOGIC : begin
				//$display("EXE_RES_LOGIC");
				reg_wdata = logic_out;
			end
			`EXE_RES_SHIFT : begin
				//$display("EXE_RES_SHIFT");
				reg_wdata = shift_out;
			end
			`EXE_RES_ARITH : begin
				//$display("EXE_RES_ARITH");
				reg_wdata = arith_out;
			end
			`EXE_RES_JUMP_BRANCH : begin
				//$display("EXE_RES_JUMP_BRANCH: %d", link_addr);
				reg_wdata = link_addr;
			end
			`EXE_RES_LOAD_STORE : begin
				//$display("EXE_RES_LOAD_STORE");
				reg_wdata = 0;
				mem_addr  = mem_out;
			end
			default : begin
				reg_wdata = 0;
			end
		endcase // alusel
	end // always @ (*)

endmodule // stage_ex