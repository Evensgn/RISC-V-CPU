`include "defines.v"

module stage_mem (
	input  wire               rst        ,
	input  wire [`RegAddrBus] reg_waddr_i,
	input  wire               we_i       ,
	input  wire [    `RegBus] reg_wdata_i,
	input  wire [`MemAddrBus] mem_addr_i ,
	input  wire [  `AluOpBus] aluop      ,
	input  wire [    `RegBus] rt_data    ,
	input  wire [    `RegBus] mem_data_i ,
	input  wire               mem_busy   ,
	input  wire               mem_done   ,
	output reg  [`RegAddrBus] reg_waddr_o,
	output reg                we_o       ,
	output reg  [    `RegBus] reg_wdata_o,
	output reg  [`MemAddrBus] mem_addr_o ,
	output reg                mem_re     ,
	output reg                mem_we     ,
	output reg  [        3:0] mem_sel    ,
	output reg  [    `RegBus] mem_data_o ,
	output reg                stallreq
);

	reg mem_taking;

	`define SET_MEM_INST(i_stallreq, i_mem_taking, i_mem_re, i_mem_we, i_mem_addr_o, i_mem_data_o) \
		stallreq = i_stallreq; \
		mem_taking = i_mem_taking; \
		mem_re = i_mem_re; \
		mem_we = i_mem_we; \
		mem_addr_o = i_mem_addr_o; \
		mem_data_o = i_mem_data_o;

	always @ (*) begin
		if(rst) begin
			`SET_MEM_INST(0, 0, 0, 0, 0, 0)
			reg_waddr_o = 0;
			we_o        = 0;
			reg_wdata_o = 0;
			mem_sel     = 4'b0000;
			mem_taking  = 0;
		end else if (!mem_busy && !mem_taking) begin
			reg_waddr_o = reg_waddr_i;
			we_o        = we_i;
			case (aluop)
				`EXE_LB_OP, `EXE_LH_OP, `EXE_LW_OP, `EXE_LBU_OP, `EXE_LHU_OP : begin
					`SET_MEM_INST(1, 1, 1, 0, {mem_addr_i[31:2], 2'b0}, 0)
					mem_sel = 4'b0000;
				end
				`EXE_SB_OP : begin
					`SET_MEM_INST(0, 0, 0, 1, mem_addr_i, {4{rt_data[7:0]}})
					reg_wdata_o = 0;
					case (mem_addr_i[1:0])
						2'b00   : mem_sel = 4'b0001;
						2'b01   : mem_sel = 4'b0010;
						2'b10   : mem_sel = 4'b0100;
						2'b11   : mem_sel = 4'b1000;
						default : mem_sel = 4'b0000;
					endcase // mem_addr_i[1:0]
				end
				`EXE_SH_OP : begin
					`SET_MEM_INST(0, 0, 0, 1, mem_addr_i, {2{rt_data[15:0]}})
					reg_wdata_o = 0;
					case (mem_addr_i[1:0])
						2'b00   : mem_sel = 4'b0011;
						2'b10   : mem_sel = 4'b1100;
						default : mem_sel = 4'b0000;
					endcase // mem_addr_i[1:0]
				end
				`EXE_SW_OP : begin
					`SET_MEM_INST(0, 0, 0, 1, mem_addr_i, rt_data)
					reg_wdata_o = 0;
					case (mem_addr_i[1:0])
						2'b00   : mem_sel = 4'b1111;
						default : mem_sel = 4'b0000;
					endcase // mem_addr_i[1:0]
				end
				default : begin
					stallreq    = 0;
					mem_taking  = 0;
					`SET_MEM_INST(0, 0, 0, 0, 0, 0)
					mem_sel     = 4'b0000;
					reg_wdata_o = reg_wdata_i;
				end
			endcase // aluop
		end else if (!mem_busy && mem_taking) begin
			stallreq   = 0;
			mem_taking = 0;
			case (aluop)
				`EXE_LB_OP : begin
					case (mem_addr_i[1:0])
						2'b00   : reg_wdata_o = {{24{mem_data_i[7]}}, mem_data_i[7:0]};
						2'b01   : reg_wdata_o = {{24{mem_data_i[15]}}, mem_data_i[15:8]};
						2'b10   : reg_wdata_o = {{24{mem_data_i[23]}}, mem_data_i[23:16]};
						2'b11   : reg_wdata_o = {{24{mem_data_i[31]}}, mem_data_i[31:24]};
						default : reg_wdata_o = 0;
					endcase // mem_addr_i[1:0]
				end
				`EXE_LH_OP : begin
					case (mem_addr_i[1:0])
						2'b00   : reg_wdata_o = {{16{mem_data_i[15]}}, mem_data_i[15:0]};
						2'b10   : reg_wdata_o = {{16{mem_data_i[15]}}, mem_data_i[31:16]};
						default : reg_wdata_o = 0;
					endcase // mem_addr_i[1:0]
				end
				`EXE_LW_OP : begin
					case (mem_addr_i[1:0])
						2'b00   : reg_wdata_o = mem_data_i;
						default : reg_wdata_o = 0;
					endcase // mem_addr_i[1:0]
				end
				`EXE_LBU_OP : begin
					case (mem_addr_i[1:0])
						2'b00   : reg_wdata_o = {{24{1'b0}}, mem_data_i[7:0]};
						2'b01   : reg_wdata_o = {{24{1'b0}}, mem_data_i[15:8]};
						2'b10   : reg_wdata_o = {{24{1'b0}}, mem_data_i[23:16]};
						2'b11   : reg_wdata_o = {{24{1'b0}}, mem_data_i[31:24]};
						default : reg_wdata_o = 0;
					endcase // mem_addr_i[1:0]
				end
				`EXE_LHU_OP : begin
					case (mem_addr_i[1:0])
						2'b00   : reg_wdata_o = {{16{1'b0}}, mem_data_i[15:0]};
						2'b10   : reg_wdata_o = {{16{1'b0}}, mem_data_i[31:16]};
						default : reg_wdata_o = 0;
					endcase // mem_addr_i[1:0]
				end
				default : begin
					reg_wdata_o = reg_wdata_i;
				end
			endcase // aluop
		end else if (mem_busy) begin
			stallreq = 1;
		end else begin
			`SET_MEM_INST(0, 0, 0, 0, 0, 0)
			reg_waddr_o = 0;
			we_o        = 0;
			reg_wdata_o = 0;
			mem_sel     = 4'b0000;
			mem_taking  = 0;
		end
	end

endmodule // stage_mem