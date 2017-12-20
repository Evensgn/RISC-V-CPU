`include "defines.v"

module riscv_cpu (
	input  wire                clk     ,
	input  wire                rst     ,
	input  wire [    `InstBus] rom_inst,
	output wire [`InstAddrBus] rom_addr,
	output wire                rom_ce
);

	// stall
	wire[5:0] stall;
	wire stallreq_id;
	wire stallreq_ex;

	// PC_Reg -> IF/ID
	wire[`InstAddrBus] pc;

	// IF/ID -> ID
	wire[`InstAddrBus] id_pc;
	wire[`InstBus] id_inst;

	// ID -> Regfile
	wire id_re1;
	wire id_re2;
	wire[`RegBus] id_reg_data1;
	wire[`RegBus] id_reg_data2;
	wire[`RegAddrBus] id_reg_addr1;
	wire[`RegAddrBus] id_reg_addr2;

	// ID -> ID/EX
	wire[`AluOpBus] id_aluop;
	wire[`AluSelBus] id_alusel;
	wire[`RegBus] id_opv1;
	wire[`RegBus] id_opv2;
	wire id_we;
	wire[`RegAddrBus] id_reg_waddr;

	// ID/EX -> EX
	wire[  `AluOpBus] ex_aluop;
	wire[ `AluSelBus] ex_alusel;
	wire[    `RegBus] ex_opv1;
	wire[    `RegBus] ex_opv2;
	wire[`RegAddrBus] ex_reg_waddr_i;
	wire ex_we_i;

	// EX -> EX/MEM
	wire[`RegAddrBus] ex_reg_waddr_o;
	wire ex_we_o;
	wire[    `RegBus] ex_reg_wdata;

	// EX/MEM -> MEM
	wire[`RegAddrBus] mem_reg_waddr_i;
	wire mem_we_i;
	wire[    `RegBus] mem_reg_wdata_i;

	// MEM -> MEM/WB
	wire[`RegAddrBus] mem_reg_waddr_o;
	wire mem_we_o;
	wire[    `RegBus] mem_reg_wdata_o;

	// MEM/WB -> Regfile
	wire[`RegAddrBus] wb_reg_waddr;
	wire wb_we;
	wire[    `RegBus] wb_reg_wdata;

	assign rom_addr = pc;

	ctrl ctrl0 (
		// input
		.rst (rst),        
		.stallreq_id (stallreq_id),
		.stallreq_ex (stallreq_ex),
		// output
		.stall (stall)
	);

	reg_pc reg_pc0 (
		// input
		.clk  (clk   ),
		.rst  (rst   ),
		.stall(stall ),
		// output
		.pc   (pc    ),
		.ce   (rom_ce)
	);

	reg_if_id reg_if_id0 (
		// input
		.clk    (clk     ),
		.rst    (rst     ),
		.if_pc  (pc      ),
		.if_inst(rom_inst),
		.stall  (stall   ),
		// output
		.id_pc  (id_pc   ),
		.id_inst(id_inst )
	);

	stage_id stage_id0 (
		// input
		.rst          (rst            ),
		.pc           (id_pc          ),
		.inst         (id_inst        ),
		.reg_data1    (id_reg_data1   ),
		.reg_data2    (id_reg_data2   ),
		
		.ex_we        (ex_we_o        ),
		.ex_reg_waddr (ex_reg_waddr_o ),
		.ex_reg_wdata (ex_reg_wdata   ),
		.mem_we       (mem_we_o       ),
		.mem_reg_waddr(mem_reg_waddr_o),
		.mem_reg_wdata(mem_reg_wdata_o),
		
		// output
		.re1          (id_re1         ),
		.re2          (id_re2         ),
		.reg_addr1    (id_reg_addr1   ),
		.reg_addr2    (id_reg_addr2   ),
		.aluop        (id_aluop       ),
		.alusel       (id_alusel      ),
		.opv1         (id_opv1        ),
		.opv2         (id_opv2        ),
		.we           (id_we          ),
		.reg_waddr    (id_reg_waddr   ),
		.stallreq     (stallreq_id    )
	);

	regfile regfile0 (
		// input
		.clk   (clk         ),
		.rst   (rst         ),
		.we    (wb_we       ),
		.waddr (wb_reg_waddr),
		.wdata (wb_reg_wdata),
		.re1   (id_re1      ),
		.re2   (id_re2      ),
		.raddr1(id_reg_addr1),
		.raddr2(id_reg_addr2),
		// output
		.rdata1(id_reg_data1),
		.rdata2(id_reg_data2)
	);

	reg_id_ex reg_id_ex0 (
		// input
		.clk         (clk           ),
		.rst         (rst           ),
		.id_aluop    (id_aluop      ),
		.id_alusel   (id_alusel     ),
		.id_opv1     (id_opv1       ),
		.id_opv2     (id_opv2       ),
		.id_reg_waddr(id_reg_waddr  ),
		.id_we       (id_we         ),
		.stall       (stall         ),
		// output
		.ex_aluop    (ex_aluop      ),
		.ex_alusel   (ex_alusel     ),
		.ex_opv1     (ex_opv1       ),
		.ex_opv2     (ex_opv2       ),
		.ex_reg_waddr(ex_reg_waddr_i),
		.ex_we       (ex_we_i       )
	);

	stage_ex stage_ex0 (
		// input
		.rst        (rst           ),
		.aluop      (ex_aluop      ),
		.alusel     (ex_alusel     ),
		.opv1       (ex_opv1       ),
		.opv2       (ex_opv2       ),
		.reg_waddr_i(ex_reg_waddr_i),
		.we_i       (ex_we_i       ),
		// output
		.reg_waddr_o(ex_reg_waddr_o),
		.we_o       (ex_we_o       ),
		.reg_wdata  (ex_reg_wdata  ),
		.stallreq   (stallreq_ex   )
	);

	reg_ex_mem reg_ex_mem0 (
		// input
		.clk          (clk            ),
		.rst          (rst            ),
		.ex_reg_waddr (ex_reg_waddr_o ),
		.ex_we        (ex_we_o        ),
		.ex_reg_wdata (ex_reg_wdata   ),
		.stall        (stall          ),
		// output
		.mem_reg_waddr(mem_reg_waddr_i),
		.mem_we       (mem_we_i       ),
		.mem_reg_wdata(mem_reg_wdata_o)
	);

	stage_mem stage_mem0 (
		// input
		.rst        (rst            ),
		.reg_waddr_i(mem_reg_waddr_i),
		.we_i       (mem_we_i       ),
		.reg_wdata_i(mem_reg_wdata_i),
		// output
		.reg_waddr_o(mem_reg_waddr_o),
		.we_o       (mem_we_o       ),
		.reg_wdata_o(mem_reg_wdata_o)
	);

	reg_mem_wb reg_mem_wb0 (
		// input
		.clk          (clk            ),
		.rst          (rst            ),
		.mem_reg_waddr(mem_reg_waddr_o),
		.mem_we       (mem_we_o       ),
		.mem_reg_wdata(mem_reg_wdata_o),
		.stall        (stall          ),
		// output
		.wb_reg_waddr (wb_reg_waddr   ),
		.wb_we        (wb_we          ),
		.wb_reg_wdata (wb_reg_wdata   )
	);

endmodule // riscv_cpu