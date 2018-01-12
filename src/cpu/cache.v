// This file is based on Zhekai Zhang's code

`include "utility.v"
`include "simple_ram.v"

//Address (32-bit):
//	TAG INDEX WORD_SELECT 00
module cache #(
	parameter WORD_SELECT_BIT = 3, //block size: 2^3 * 4 = 32 bytes
	parameter INDEX_BIT       = 2, //block count: 2^2 = 4
	parameter NASSOC          = 4
) (
	input             clk           ,
	input             rst           ,
	//from cpu core
	input      [ 1:0] rw_flag_      , //[0] for read, [1] for write
	input      [31:0] addr_         ,
	output     [31:0] read_data     ,
	input      [31:0] write_data_   ,
	input      [ 3:0] write_mask_   ,
	output reg        busy          ,
	output reg        done          ,
	input             flush_flag    ,
	input      [31:0] flush_addr    ,
	//to memory
	output reg [ 1:0] mem_rw_flag   ,
	output reg [31:0] mem_addr      ,
	input      [31:0] mem_read_data ,
	output reg [31:0] mem_write_data,
	output reg [ 3:0] mem_write_mask,
	input             mem_busy      ,
	input             mem_done
);

	localparam TAG_BIT			= 32 - 2 - INDEX_BIT - WORD_SELECT_BIT;
	localparam BYTE_SELECT_BIT	= WORD_SELECT_BIT + 2;
	localparam SET_SELECT_BIT	= `CLOG2(NASSOC);
	localparam NBLOCK 			= 1 << INDEX_BIT;
	localparam NWORD			= 1 << WORD_SELECT_BIT;
	localparam BLOCK_SIZE 		= (1 << WORD_SELECT_BIT) * 4 * 8;
	
	reg [1:0]	pending_rw_flag;
	reg [31:0]	pending_addr;
	reg [31:0]	pending_write_data;
	reg [3:0]	pending_write_mask;
	
	wire [1:0]	rw_flag			= busy ? pending_rw_flag	: rw_flag_;
	wire [31:0]	addr			= busy ? pending_addr		: addr_;
	wire [31:0]	write_data_in	= busy ? pending_write_data : write_data_;
	wire [3:0]	write_mask_in	= busy ? pending_write_mask : write_mask_;
	
	wire [TAG_BIT-1:0] 			addr_tag 	= addr[31:31-TAG_BIT+1];
	wire [INDEX_BIT-1:0]		addr_index	= addr[BYTE_SELECT_BIT+INDEX_BIT-1:BYTE_SELECT_BIT];
	wire [WORD_SELECT_BIT-1:0]	addr_ws		= addr[WORD_SELECT_BIT+2-1:2];
	
	wire [TAG_BIT-1:0]			addr_flush_tag		= flush_addr[31:31-TAG_BIT+1];
	wire [INDEX_BIT-1:0]		addr_flush_index	= flush_addr[BYTE_SELECT_BIT+INDEX_BIT-1:BYTE_SELECT_BIT];
	
	//reg [7:0]					data[3:0][NASSOC-1:0][NBLOCK-1:0][NWORD-1:0];
	//(*ramstyle = "block"*) reg [31:0]	data[NASSOC-1:0][NBLOCK*NWORD-1:0];
	reg [TAG_BIT-1:0]			tag[NASSOC-1:0][NBLOCK-1:0];
	reg 						valid[NASSOC-1:0][NBLOCK-1:0];
	reg [SET_SELECT_BIT-1:0]	recuse[NASSOC-1:0][NBLOCK-1:0];
	
	reg [SET_SELECT_BIT-1:0]	recent_use_counter[NBLOCK-1:0];
	
	wire [NASSOC-1:0]			found_in_cache, found_in_cache_flush;
	wire [SET_SELECT_BIT-1:0]	one_hot_lookup[(1<<NASSOC)-1:0];
	
	wire [SET_SELECT_BIT-1:0]	lru_tmp[(1<<SET_SELECT_BIT)*2-1:1];
	wire [SET_SELECT_BIT-1:0]	mru_tmp[(1<<SET_SELECT_BIT)*2-1:1];
	wire [SET_SELECT_BIT-1:0]	lru_id_tmp[(1<<SET_SELECT_BIT)*2-1:1];
	wire [SET_SELECT_BIT-1:0]	mru_id_tmp[(1<<SET_SELECT_BIT)*2-1:1];
	
	genvar i;
	generate
		for(i=0; i<(1<<NASSOC); i=i+1) begin
			assign one_hot_lookup[i] = `CLOG2(i);
		end
		for(i=0; i<NASSOC; i=i+1) begin
			assign found_in_cache[i] 		= valid[i][addr_index] && tag[i][addr_index] == addr_tag;
			assign found_in_cache_flush[i]	= valid[i][addr_flush_index] && tag[i][addr_flush_index] == addr_flush_tag;
		end
		for(i=0; i<NASSOC; i=i+1) begin
			assign lru_tmp[i+(1<<SET_SELECT_BIT)]		= recent_use_counter[addr_index] - recuse[i][addr_index];
			assign mru_tmp[i+(1<<SET_SELECT_BIT)]		= recent_use_counter[addr_index] - recuse[i][addr_index];
			assign lru_id_tmp[i+(1<<SET_SELECT_BIT)]	= i;
			assign mru_id_tmp[i+(1<<SET_SELECT_BIT)]	= i;
		end
		for(i=NASSOC; i<(1<<SET_SELECT_BIT); i=i+1) begin
			assign lru_tmp[i+(1<<SET_SELECT_BIT)]		= {SET_SELECT_BIT{1'b1}};
			assign mru_tmp[i+(1<<SET_SELECT_BIT)]		= 0;
			assign lru_id_tmp[i+(1<<SET_SELECT_BIT)]	= 0;
			assign mru_id_tmp[i+(1<<SET_SELECT_BIT)]	= 0;
		end
		for(i=1; i<(1<<SET_SELECT_BIT); i=i+1) begin
			assign lru_tmp[i]		= lru_tmp[i*2] >= lru_tmp[i*2+1] ? lru_tmp[i*2]		: lru_tmp[i*2+1];
			assign mru_tmp[i]		= mru_tmp[i*2] <  mru_tmp[i*2+1] ? mru_tmp[i*2]		: mru_tmp[i*2+1];
			assign lru_id_tmp[i]	= lru_tmp[i*2] >= lru_tmp[i*2+1] ? lru_id_tmp[i*2]	: lru_id_tmp[i*2+1];
			assign mru_id_tmp[i]	= mru_tmp[i*2] <  mru_tmp[i*2+1] ? mru_id_tmp[i*2]	: mru_id_tmp[i*2+1];
		end
	endgenerate
	
	wire [SET_SELECT_BIT-1:0]	lru_id, mru_id;
	
	assign lru_id = lru_id_tmp[1];
	assign mru_id = mru_id_tmp[1];
	
	task use_cache;
		input [NASSOC-1:0]		cache_id;
		
		if(cache_id != mru_id) begin
			recent_use_counter[addr_index] <= recent_use_counter[addr_index] + 1;
			recuse[cache_id][addr_index] <= recent_use_counter[addr_index] + 1;
		end else if(recuse[cache_id][addr_index] != recent_use_counter[addr_index])
			$display("Assertion Failed: recuse[cache_id][addr_index] == recent_use_counter");
	endtask
	
	localparam STATE_IDLE					= 0;
	localparam STATE_WAIT_FOR_READ_PHASE_1	= 1;	//Before Critical Word Reach
	localparam STATE_WAIT_FOR_READ_PHASE_2	= 2;	//After Critical Word Reach
	localparam STATE_WAIT_FOR_WRITE			= 4;
	
	reg [2:0] state;
	reg [2:0] next_state;
	
	reg [SET_SELECT_BIT-1:0]	current_cache;
	reg [TAG_BIT-1:0]			current_tag;
	reg [INDEX_BIT-1:0]			current_block;
	reg [WORD_SELECT_BIT-1:0]	current_word;
	reg [WORD_SELECT_BIT-1:0]	critical_word;
	
	reg signed [SET_SELECT_BIT:0]	write_cache;	//set to -1 if not write
	reg [INDEX_BIT-1:0]				write_block;
	reg [WORD_SELECT_BIT-1:0]		write_word;
	reg [31:0]						write_data;
	//reg 						write_flag;
	reg [3:0]						write_mask;
	
	reg signed [SET_SELECT_BIT:0]	read_cache;		//set to -1 if not read
	reg [INDEX_BIT-1:0]				read_block;
	reg [WORD_SELECT_BIT-1:0]		read_word;
	//reg						read_flag;
	
	reg [SET_SELECT_BIT-1:0]	valid_cache;
	reg [INDEX_BIT-1:0]			valid_block;
	reg 						valid_flag;
	reg [TAG_BIT-1:0]			valid_tag;
	
	reg 						next_done;
	reg [NASSOC-1:0]			next_current_cache;
	reg [TAG_BIT-1:0]			next_current_tag;
	reg [INDEX_BIT-1:0]			next_current_block;
	reg [WORD_SELECT_BIT-1:0]	next_current_word;
	reg [WORD_SELECT_BIT-1:0]	next_critical_word;
	
	wire [31:0]					RAM_read_data[NASSOC-1:0];
	reg [SET_SELECT_BIT-1:0]	RAM_read_select;
	
	assign read_data = RAM_read_data[RAM_read_select];
	
	generate
		for(i=0; i<NASSOC; i=i+1) begin
			wire RAM_read_flag = read_cache == i;
			wire RAM_write_flag = write_cache == i;
			simple_ram #(.AddrBusWidth(INDEX_BIT+WORD_SELECT_BIT), .DataBusByteWidth(4)) RAM(
				clk, rst, RAM_read_flag,  {read_block, read_word}, 
				RAM_write_flag, write_data, {write_block, write_word}, write_mask, RAM_read_data[i]); 
		end
	endgenerate
	
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			busy <= 0;
			pending_rw_flag		<= 0;
			pending_addr		<= 0;
			pending_write_data	<= 0;
			pending_write_mask 	<= 0;
		end else if (!busy) begin
			if(!next_done && rw_flag_ != 0) begin
				busy <= 1;
				pending_rw_flag		<= rw_flag_;
				pending_addr		<= addr_;
				pending_write_data	<= write_data_;
				pending_write_mask	<= write_mask_;
			end
		end else if (next_done)
			busy <= 0;
	end
	
	integer j, k;
	always @(posedge clk/* or posedge rst*/) begin
		if(rst) begin
			done <= 0;
			for(j=0; j<NASSOC; j=j+1)
				for(k=0; k<NBLOCK; k=k+1) begin
					recuse[j][k] <= 0;
					valid[j][k] <= 0;
				end
			for(j=0; j<NBLOCK; j=j+1)
				recent_use_counter[j] <= 0;
			state <= STATE_IDLE;
			current_cache <= 0;
			current_block <= 0;
			current_block <= 0;
			current_word <= 0;
			critical_word <= 0;
			RAM_read_select <= 0;
					
			//TODO
		end else begin
			if(!read_cache[SET_SELECT_BIT]) begin
				if(read_block != addr_index)
					$display("Assertion Failed: read_block == addr_index");
				RAM_read_select <= read_cache[SET_SELECT_BIT-1:0];
				use_cache(read_cache);
			end
			if(valid_flag) begin
				valid[valid_cache][valid_block] <= 1;
				tag[valid_cache][valid_block] <= valid_tag;
			end
			if(flush_flag)
				valid[one_hot_lookup[found_in_cache_flush]][addr_flush_index] <= 0;
			state <= next_state;
			done <= next_done;
			current_cache <= next_current_cache;
			current_tag <= next_current_tag;
			current_block <= next_current_block;
			current_word <= next_current_word;
			critical_word <= next_critical_word;
		end
	end
	
	always @(*) begin
		next_state = state;
		next_current_cache = current_cache;
		next_current_tag = current_tag;
		next_current_block = current_block;
		next_current_word = current_word;
		next_critical_word = critical_word;
		next_done = 0;
		
		read_cache = -1;
		read_block = 0;
		read_word = 0;
		
		write_cache = -1;
		write_block = 0;
		write_word = 0;
		write_mask = 0;
		write_data = 0;
		
		valid_cache = 0;
		valid_block = 0;
		valid_flag = 0;
		valid_tag = 0;
		
		mem_rw_flag = 0;
		mem_addr = 0;
		mem_write_data = 0;
		mem_write_mask = 0;
		
		case(state)
		STATE_IDLE: begin
			case(1'b1)
			rw_flag[0]: begin
				if(found_in_cache != 0) begin
					read_cache = one_hot_lookup[found_in_cache];
					read_block = addr_index;
					read_word = addr_ws;
					//read_flag = 1;
					next_done = 1;
				end else begin
					mem_rw_flag = 1;
					mem_addr = {addr_tag, addr_index, addr_ws, 2'b00};
					next_current_cache = lru_id;
					next_current_tag = addr_tag;
					next_current_block = addr_index;
					next_current_word = addr_ws;
					next_critical_word = addr_ws;
					next_state = STATE_WAIT_FOR_READ_PHASE_1;
					valid_cache = lru_id;
					valid_block = addr_index;
					valid_flag = 1;
					valid_tag = addr_tag;
				end
			end
			
			rw_flag[1]: begin
				if(found_in_cache != 0) begin
					write_cache = one_hot_lookup[found_in_cache];
					write_block = addr_index;
					write_word = addr_ws;
					write_data = write_data_in;
					write_mask = write_mask_in;
				end
				mem_rw_flag = 2;
				mem_addr = {addr_tag, addr_index, addr_ws, 2'b00};
				mem_write_data = write_data_in;
				mem_write_mask = write_mask_in;
				next_state = STATE_WAIT_FOR_WRITE;
				next_done = 1;
			end
			endcase
		end
		
		STATE_WAIT_FOR_READ_PHASE_1: begin
			if(mem_done) begin
				write_cache = current_cache;
				write_block = current_block;
				write_word = current_word;
				write_data = mem_read_data;
				write_mask = 4'b1111;
				//write_flag = 1;
				
				//next_done = 1;
				
				next_current_word = critical_word == 0 ? 1 : 0;
				mem_rw_flag = 1;
				mem_addr = {current_tag, current_block, next_current_word, 2'b00};
				next_state = STATE_WAIT_FOR_READ_PHASE_2;
			end
		end
		
		STATE_WAIT_FOR_READ_PHASE_2: begin
			if(mem_done) begin
				write_cache = current_cache;
				write_block = current_block;
				write_word = current_word;
				write_data = mem_read_data;
				write_mask = 4'b1111;
				//write_flag = 1;
				
				next_current_word = critical_word == current_word + 1 ? current_word + 2 : current_word + 1;
				if(next_current_word != 0) begin
					mem_rw_flag = 1;
					mem_addr = {current_tag, current_block, next_current_word, 2'b00};
				end else 
					next_state = STATE_IDLE;
			end
			if(rw_flag[0]) begin
				if(found_in_cache != 0) begin
					if(one_hot_lookup[found_in_cache] == current_cache && addr_index == current_block) begin
						if(addr_ws < current_word) begin
							read_cache = current_cache;
							read_block = current_block;
							read_word = addr_ws;
							//read_flag = 1;
							next_done = 1;
						end
					end else begin
						read_cache = one_hot_lookup[found_in_cache];
						read_block = addr_index;
						read_word = addr_ws;
						//read_flag = 1;
						next_done = 1;
					end
				end
			end
		end
		
		STATE_WAIT_FOR_WRITE: begin
			if(mem_done) begin
				next_state <= STATE_IDLE;
			end
		end
		endcase
	end
	
endmodule // cache