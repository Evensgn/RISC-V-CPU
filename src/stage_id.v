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
	output reg                 we           ,
	output wire                stallreq
);

	wire[6:0] opcode = inst[6:0];
	wire[2:0] funct3 = inst[14:12];
	wire[6:0] funct7 = inst[31:25];
	wire[11:0] imm12 = inst[31:20];
	wire[19:0] imm20 = inst[31:12];
	reg[31:0] imm1;
	reg[31:0] imm2;
	reg inst_valid;

	wire[`RegBus] rd = inst[11:7];
	wire[`RegBus] rs = inst[19:15];
	wire[`RegBus] rt = inst[24:20];

	reg stallreq1;
	reg stallreq2;
	assign stallreq = stallreq1 || stallreq2;

	`define SET_INST(i_alusel, i_aluop, i_inst_valid, i_re1, i_reg_addr1, i_re2, i_reg_addr2, i_we, i_reg_waddr, i_imm1, i_imm2) \
		aluop <= i_aluop; \
		alusel <= i_alusel; \
		inst_valid <= i_inst_valid; \
		re1 <= i_re1; \
		reg_addr1 <= i_reg_addr1; \
		re2 <= i_re2; \
		reg_addr2 <= i_reg_addr2; \
		we <= i_we; \
		reg_waddr <= i_reg_waddr; \
		imm1 <= i_imm1; \
		imm2 <= i_imm2
	
	always @ (*) begin
		if (rst) begin
			`SET_INST(`EXE_NOP_OP, `EXE_RES_NOP, 1, 0, rs, 0, rt, 0, rd, 0, 0);
		end else begin
			`SET_INST(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
			case (opcode)
				`OP_LUI : begin
					`SET_INST(`EXE_RES_ARITH, `EXE_ADD_OP, 1, 0, 0, 0, 0, 1, rd, ({imm20, 12'b0}), 0);
				end
				`OP_AUIPC : begin
					`SET_INST(`EXE_RES_ARITH, `EXE_ADD_OP, 1, 0, 0, 0, 0, 1, rd, ({imm20, 12'b0}), pc);
				end
				`OP_OP_IMM : begin
					case (funct3)
						`FUNCT3_ADDI : begin
							`SET_INST(`EXE_RES_ARITH, `EXE_ADD_OP, 1, 1, rs, 0, 0, 1, rd, 0, ({{20{imm12[11]}}, imm12}));
						end
						`FUNCT3_SLTI : begin
							`SET_INST(`EXE_RES_ARITH, `EXE_SLT_OP, 1, 1, rs, 0, 0, 1, rd, 0, ({{20{imm12[11]}}, imm12}));
						end
						`FUNCT3_SLTIU : begin
							`SET_INST(`EXE_RES_ARITH, `EXE_SLTU_OP, 1, 1, rs, 0, 0, 1, rd, 0, ({{20{imm12[11]}}, imm12}));
						end
						`FUNCT3_XORI : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_XOR_OP, 1, 1, rs, 0, 0, 1, rd, 0, ({20'h0, imm12}));
						end
						`FUNCT3_ORI : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_OR_OP, 1, 1, rs, 0, 0, 1, rd, 0, ({20'h0, imm12}));
						end
						`FUNCT3_ANDI : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_AND_OP, 1, 1, rs, 0, 0, 1, rd, 0, ({20'h0, imm12}));
						end
						`FUNCT3_SLLI : begin
							`SET_INST(`EXE_RES_SHIFT, `EXE_SLL_OP, 1, 1, rs, 0, 0, 1, rd, 0, rt);
						end
						`FUNCT3_SRLI_SRAI : begin
							case (funct7)
								`FUNCT7_SRLI : begin
									`SET_INST(`EXE_RES_SHIFT, `EXE_SRL_OP, 1, 1, rs, 0, 0, 1, rd, 0, rt);
								end
								`FUNCT7_SRAI : begin
									`SET_INST(`EXE_RES_SHIFT, `EXE_SRA_OP, 1, 1, rs, 0, 0, 1, rd, 0, rt);
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
						`FUNCT3_ADD_SUB : begin
							case (funct7)
								`FUNCT7_ADD : begin
									`SET_INST(`EXE_RES_ARITH, `EXE_ADD_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
								end
								`FUNCT7_SUB : begin
									`SET_INST(`EXE_RES_ARITH, `EXE_SUB_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
								end
								default : begin
								end
							endcase // funct7
						end
						`FUNCT3_SLL : begin
							`SET_INST(`EXE_RES_SHIFT, `EXE_SLL_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
						end
						`FUNCT3_SLT : begin
							`SET_INST(`EXE_RES_ARITH, `EXE_SLT_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
						end
						`FUNCT3_SLTU : begin
							`SET_INST(`EXE_RES_ARITH, `EXE_SLTU_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
						end
						`FUNCT3_XOR : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_XOR_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
						end
						`FUNCT3_SRL_SRA : begin
							case (funct7)
								`FUNCT7_SRL : begin
									`SET_INST(`EXE_RES_SHIFT, `EXE_SRL_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
								end
								`FUNCT7_SRA : begin
									`SET_INST(`EXE_RES_SHIFT, `EXE_SRA_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
								end
								default : begin
								end
							endcase // funct7
						end
						`FUNCT3_OR : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_OR_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
						end
						`FUNCT3_AND : begin
							`SET_INST(`EXE_RES_LOGIC, `EXE_AND_OP, 1, 1, rs, 1, rt, 1, rd, 0, 0);
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

	`define SET_OPV(opv, re, reg_addr, reg_data, imm, stallreq) \
		stallreq <= 0; \
		if(rst) begin \
			opv <= 0; \
		end else if (re && ex_we && (ex_reg_waddr == reg_addr)) begin \
			opv <= ex_reg_wdata; \
		end else if (re && mem_we && (mem_reg_waddr == reg_addr)) begin \
			opv <= mem_reg_wdata; \
		end else if(re) begin \
			opv <= reg_data; \
		end else if(!re) begin \
			opv <= imm; \
		end else begin \
			opv <= 0; \
		end

	always @ (*) begin
		`SET_OPV(opv1, re1, reg_addr1, reg_data1, imm1, stallreq1)
	end

	always @ (*) begin
		`SET_OPV(opv2, re2, reg_addr2, reg_data2, imm2, stallreq2)
	end

endmodule // stage_id