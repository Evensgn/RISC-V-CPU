`include "defines.v"

module stage_id (
	input  wire                rst          ,
	input  wire [`InstAddrBus] pc           ,
	input  wire [    `InstBus] inst         ,
	input  wire [     `RegBus] reg_data1    ,
	input  wire [     `RegBus] reg_data2    ,
	// forwarding
	input  wire                ex_we        ,
	input  wire [     `RegBus] ex_reg_wdata ,
	input  wire [ `RegAddrBus] ex_reg_waddr ,
	input  wire                mem_we       ,
	input  wire [     `RegBus] mem_reg_wdata,
	input  wire [ `RegAddrBus] mem_reg_waddr,
	output reg                 re1          ,
	output reg                 re2          ,
	output reg  [ `RegAddrBus] reg_addr1    ,
	output reg  [ `RegAddrBus] reg_addr2    ,
	output reg  [   `AluOpBus] aluop        ,
	output reg  [  `AluSelBus] alusel       ,
	output reg  [     `RegBus] opv1         ,
	output reg  [     `RegBus] opv2         ,
	output reg  [ `RegAddrBus] reg_waddr    ,
	output reg                 we
);

	wire[6:0] opcode = inst[6:0];
	wire[2:0] funct3 = inst[14:12];
	wire[6:0] funct7 = inst[31:25];
	wire[11:0] imm12 = inst[31:20];
	reg inst_valid;

	wire[`RegBus] rd = inst[11:7];
	wire[`RegBus] rs = inst[19:15];
	wire[`RegBus] rt = inst[24:20];

	`define SET_INST(i_alusel, i_aluop, i_inst_valid, i_re1, i_reg_addr1, i_re2, i_reg_addr2, i_we, i_reg_waddr, i_imm) \
		aluop <= i_aluop; \
		alusel <= i_alusel; \
		inst_valid <= i_inst_valid; \
		re1 <= i_re1; \
		reg_addr1 <= i_reg_addr1; \
		re2 <= i_re2; \
		reg_addr2 <= i_reg_addr2; \
		we <= i_we; \
		reg_waddr <= i_reg_waddr; \
		imm <= i_imm
	
	always @ (*) begin
		if (rst) begin
			`SET_INST(`EXE_NOP_OP, `EXE_RES_NOP, 1, 0, rs, 0, rt, 0, rd, 0);
		end else begin
			`SET_INST(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
			case (opcode)
				`OP_OP_IMM : begin
					case (funct3)
						`FUNCT3_XORI : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_XOR_OP, 1, 1, rs, 0, 0, 1, rd, ({20'h0, imm12}));
						end
						`FUNCT3_ORI : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_OR_OP, 1, 1, rs, 0, 0, 1, rd, ({20'h0, imm12}));
						end
						`FUNCT3_ANDI : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_AND_OP, 1, 1, rs, 0, 0, 1, rd, ({20'h0, imm12}));
						end
						`FUNCT3_SLLI : begin
							`SET_INST(`EXE_RES_SHIFT, `EXE_SLL_OP, 1, 1, rs, 0, 0, 1, rd, rt);
						end
						`FUNCT3_SRLI_SRAI : begin
							case (funct7)
								`FUNCT7_SRLI : begin
									`SET_INST(`EXE_RES_SHIFT, `EXE_SRL_OP, 1, 1, rs, 0, 0, 1, rd, rt);
								end
								`FUNCT7_SRAI : begin
									`SET_INST(`EXE_RES_SHIFT, `EXE_SRA_OP, 1, 1, rs, 0, 0, 1, rd, rt);
								end
								default : begin
								end
							endcase
						end
						default : begin
						end
					endcase // funct3
				end
				`OP_OP : begin
					case (funct3)
						`FUNCT3_XOR : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_XOR_OP, 1, 1, rs, 1, rt, 1, rd, 0);
						end
						`FUNCT3_OR : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_OR_OP, 1, 1, rs, 1, rt, 1, rd, 0);
						end
						`FUNCT3_AND : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_AND_OP, 1, 1, rs, 1, rt, 1, rd, 0);
						end
						default : begin
						end
					endcase // funct3
				end
				default : begin
				end
			endcase // op
		end // end else
	end // always @ (*)

	always @ (*) begin
		if(rst) begin
			opv1 <= 0;
		end else if (re1 && ex_we && (ex_reg_waddr == reg_addr1)) begin
			opv1 <= ex_reg_wdata;
		end else if (re1 && mem_we && (mem_reg_waddr == reg_addr1)) begin
			opv1 <= mem_reg_wdata;
		end else if(re1) begin
			opv1 <= reg_data1;
		end else if(!re1) begin
			opv1 <= imm;
		end else begin
			opv1 <= 0;
		end
	end

	always @ (*) begin
		if(rst) begin
			opv2 <= 0;
		end else if (re2 && ex_we && (ex_reg_waddr == reg_addr2)) begin
			opv2 <= ex_reg_wdata;
		end else if (re2 && mem_we && (mem_reg_waddr == reg_addr2)) begin
			opv2 <= mem_reg_wdata;
		end else if(re2) begin
			opv2 <= reg_data2;
		end else if(!re2) begin
			opv2 <= imm;
		end else begin
			opv2 <= 0;
		end
	end

endmodule // stage_id