`include "defines.v"

module stage_id (
	input  wire                rst        ,
	input  wire [`InstAddrBus] pc_i       ,
	input  wire [    `InstBus] inst_i     ,
	input  wire [     `RegBus] reg1_data_i,
	input  wire [     `RegBus] reg2_data_i,

	output reg                 reg1_read_o,
	output reg                 reg2_read_o,
	output reg  [ `RegAddrBus] reg1_addr_o,
	output reg  [ `RegAddrBus] reg2_addr_o,
	
	output reg  [   `AluOpBus] aluop_o    ,
	output reg  [  `AluSelBus] alusel_o   ,
	output reg  [     `RegBus] reg1_o     ,
	output reg  [     `RegBus] reg2_o     ,
	output reg  [ `RegAddrBus] wd_o       ,
	output reg                 wreg_o
);

	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];
	reg[`RegBus]	imm;
	reg instvalid;


	always @ (*) begin
		if (rst == `RstEnable) begin
			aluop_o     <= `EXE_NOP_OP;
			alusel_o    <= `EXE_RES_NOP;
			wd_o        <= `NOPRegAddr;
			wreg_o      <= `WriteDisable;
			instvalid   <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm         <= 32'h0;
		end else begin
			aluop_o     <= `EXE_NOP_OP;
			alusel_o    <= `EXE_RES_NOP;
			wd_o        <= inst_i[15:11];
			wreg_o      <= `WriteDisable;
			instvalid   <= `InstInvalid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
			reg2_addr_o <= inst_i[20:16];
			imm         <= `ZeroWord;
			case (op)
				`EXE_ORI : begin                        //ORIÖ¸Áî
					wreg_o    <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
					alusel_o  <= `EXE_RES_LOGIC; reg1_read_o <= 1'b1;	reg2_read_o <= 1'b0;
					imm       <= {16'h0, inst_i[15:0]};		wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
				end
				default : begin
				end
			endcase		  //case op
		end       //if
	end         //always


	always @ (*) begin
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end else if(reg1_read_o == 1'b1) begin
			reg1_o <= reg1_data_i;
		end else if(reg1_read_o == 1'b0) begin
			reg1_o <= imm;
		end else begin
			reg1_o <= `ZeroWord;
		end
	end

	always @ (*) begin
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(reg2_read_o == 1'b1) begin
			reg2_o <= reg2_data_i;
		end else if(reg2_read_o == 1'b0) begin
			reg2_o <= imm;
		end else begin
			reg2_o <= `ZeroWord;
		end
	end

endmodule // stage_id