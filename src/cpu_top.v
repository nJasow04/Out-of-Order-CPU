module cpu_top
(
    input clk,
    input reset_n
);
  	wire [31:0] instruction_fetch;
	wire stall;

    // Instantiate Fetch Unit
    fetch fetch_unit (
        .clk(clk),
        .reset_n(reset_n),
      	.instruction(instruction_fetch)
    );
    wire [31:0] instruction_fetch_pipelined;

    pipeline_buffer IF_ID_buffer (
        .clk(clk),
        .reset_n(reset_n),
		  .stall(stall),
        .data_in(instruction_fetch),
        .data_out(instruction_fetch_pipelined)
    );

    wire [31:0] instruction;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [6:0] funct7;
    wire [2:0] funct3;
    wire [6:0] opcode;

    decode decode_unit (
        .instruction(instruction_fetch_pipelined),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct7(funct7),
        .funct3(funct3),
        .opcode(opcode)
    );
	 
    wire is_load;
    wire is_store;
    wire is_byte;
    wire is_word;
	wire is_instr;

    // Instance of check_mem_instr
    check_mem_instr check_mem_unit_inst (
        .opcode(opcode),
        .funct3(funct3),
        .is_load(is_load),
        .is_store(is_store),
        .is_byte(is_byte),
        .is_word(is_word),
		.is_instr(is_instr)
    );
	 
	 wire is_mem = is_load | is_store;
	 
	//immeditae gen and control signals to be done after the issue queue
	
    wire [31:0] immediate;

    immediate_generate imm_gen (
        .instruction(instruction_fetch_pipelined),
        .immediate(immediate)
    );
	 
	wire [5:0] phys_rd, phys_rs1, phys_rs2;
	wire free_list_empty, rename_valid;
	wire retire = 1'b0;
	wire [5:0] free_reg;
	wire [5:0] old_phys_rd;
	wire [4:0] arch_reg;
	
	//complete and retire wires:
	reg complete_valid0;
	reg complete_valid1;
	reg complete_valid2;
	reg complete_valid3;
	wire [31:0] result0_pipe;
	wire [31:0] result1_pipe;
	wire [31:0] result2_pipe;
	wire [5:0] dest_reg0_pipe;
	wire [5:0] dest_reg1_pipe;
	wire [5:0] dest_reg2_pipe;
	wire regWrite0_pipe;
	wire regWrite1_pipe;
	wire regWrite2_pipe;
	wire [5:0] rob_index0_pipe;
	wire [5:0] rob_index1_pipe;
	wire [5:0] rob_index2_pipe;
	
	//rob outputs
	
	wire [5:0] rob_entry_num;
	wire alloc_ready;
	wire commit_valid_1;
	wire commit_valid_2;
    wire [5:0] commit_dest_1;
    wire [5:0] free_oldDest_1;
	wire [4:0] commit_archDest_1;
    wire [31:0] commit_value_1;
    wire [5:0] commit_dest_2;
    wire [5:0] free_oldDest_2;
	wire [4:0] commit_archDest_2;
    wire [31:0] commit_value_2;
	wire forward_rs1_valid;
	wire forward_rs2_valid;
	wire [31:0] rob_forward_data_rs1;
	wire [31:0] rob_forward_data_rs2;
	
	rename rename_module (
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .issue_valid(is_instr),
        .reset_n(reset_n),
        .clk(clk),
        .retire_valid1(commit_valid_1), //fill in later  
        .retire_phys_reg1(free_oldDest_1), //later
		.retire_valid2(commit_valid_2),  //later
        .retire_phys_reg2(free_oldDest_2), //later
		.isStore(is_store),
        .phys_rd(phys_rd),
        .phys_rs1(phys_rs1),
        .phys_rs2(phys_rs2),
		.arch_reg(arch_reg),
        .old_phys_rd(old_phys_rd),
        .free_list_empty(free_list_empty)
    );

	wire rob_open = 1'b1;
	wire [31:0] rs1_data, rs2_data;

	reg_file architectural_register_file (
		.clk(clk),
		.reset_n(reset_n),
		.rs1(rs1),
		.rs2(rs2),
		.rd1(commit_archDest_1),    // later
		.rd1_data(commit_value_1), //later
		.rd2(commit_archDest_2),           //later
      	.rd2_data(commit_value_2),   //later
		.RegWrite1(commit_valid_1),  //later
		.RegWrite2(commit_valid_2),		//later
		.rs1_data(rs1_data),
		.rs2_data(rs2_data)
	);
	
	
	//iq outputs
	wire [138:0] issued_funct_unit0;
    wire [138:0] issued_funct_unit1;
    wire [138:0] issued_funct_unit2;

    wire funct0_enable;
    wire funct1_enable;
    wire funct2_enable;
    wire issue_queue_full;
	 
	 wire prev_write = (regWrite2_pipe | regWrite1_pipe | regWrite0_pipe);
	 
	//ls unit outputs
    wire [31:0] load_data;
    wire enable_ROB;
    wire [5:0] rob_entry_num_retire, fwd_phys_rd;
    wire fwd_enable_ls;
	 
	//inputs for forward iq
	reg [5:0] fwd_dest0;
	reg [5:0] fwd_dest1;
	reg [5:0] fwd_dest2;
	reg [5:0] fwd_dest_mem;
	reg [31:0] fwd_val0;
	reg [31:0] fwd_val1;
	reg [31:0] fwd_val2;
	reg [31:0] fwd_val_mem;
	reg fwd_double;

	issue_queue issue_queue_inst(
    	.clk(clk),
    	.reset_n(reset_n),
    	.write_enable(is_instr), // reg read valid
    
    // rename stage: source and destination regs
    	.phys_rd(phys_rd),
    	.phys_rs1(phys_rs1),
    	.phys_rs1_val(rs1_data),
    	.phys_rs2(phys_rs2),
    	.phys_rs2_val(rs2_data),
    	.opcode(opcode),
		.funct7(funct7),
		.funct3(funct3),
   		.immediate(immediate),
    	.ROB_entry_index(rob_entry_num),

    // execute stage: forward and funct unit available
		.fwd_double(fwd_double),
		.fwd_enable((complete_valid0|complete_valid1|complete_valid2|fwd_enable_ls)), //later
		.fwd_rd_funct_unit0(fwd_dest0),
		.fwd_rd_val_funct_unit0(fwd_val0), 
		.fwd_rd_funct_unit1(fwd_dest1), 
		.fwd_rd_val_funct_unit1(fwd_val1),
		.fwd_rd_funct_unit2(fwd_dest2), 
		.fwd_rd_val_funct_unit2(fwd_val2),
		.fwd_rd_mem(fwd_phys_rd),                   //later
		.fwd_rd_val_mem(load_data),                       //later
		.issued_funct_unit0(issued_funct_unit0),
		.issued_funct_unit1(issued_funct_unit1),
		.issued_funct_unit2(issued_funct_unit2),
		.funct0_enable(funct0_enable),
		.funct1_enable(funct1_enable),
		.funct2_enable(funct2_enable),
		.issue_queue_full(issue_queue_full),
		.fwd_rs1_enable(forward_rs1_valid),
		.fwd_rs2_enable(forward_rs2_valid),
		.fwd_rs1_val(rob_forward_data_rs1),
		.fwd_rs2_val(rob_forward_data_rs2)

);

	 
	 reorder_buffer rob(
		.clk(clk),
		.reset_n(reset_n),
		.alloc_valid(is_instr), //regwrite signal used
		.alloc_dest(phys_rd),
		.alloc_oldDest(old_phys_rd), //rd
		.alloc_archDest(arch_reg),
		.rob_entry_num(rob_entry_num),
		.alloc_instr_addr(31'b0), //not using
		.writeback_valid1(complete_valid0),
		.writeback_valid2(complete_valid1), 
		.writeback_valid3(complete_valid2), 
		.writeback_valid4(enable_ROB), //ls
		.writeback_idx1(rob_index0_pipe), 
		.writeback_value1(result0_pipe),
		.writeback_idx2(rob_index1_pipe),
		.writeback_value2(result1_pipe),
		.writeback_idx3(rob_index2_pipe),
		.writeback_value3(result2_pipe),
		.writeback_idx4(rob_entry_num_retire), //ls
		.writeback_value4(load_data), //
		.commit_valid_1(commit_valid_1),
		.commit_valid_2(commit_valid_2),
      	.commit_dest_1(commit_dest_1),
		.commit_archDest_1(commit_archDest_1),
		.free_oldDest_1(free_oldDest_1),
		.commit_value_1(commit_value_1),
		.commit_dest_2(commit_dest_2),
		.free_oldDest_2(free_oldDest_2),
		.commit_archDest_2(commit_archDest_2),
		.commit_value_2(commit_value_2),
		.commit_ready(1),//how to set this? //later
		.phys_rs1(phys_rs1),
		.phys_rs2(phys_rs2),
		.forward_rs1_valid(forward_rs1_valid),
		.forward_rs2_valid(forward_rs2_valid),
		.rob_forward_data_rs1(rob_forward_data_rs1),
		.rob_forward_data_rs2(rob_forward_data_rs2),
		.alloc_ready(rob_open)
	);
	  assign stall = 0;//stall | free_list_empty | (!rob_open);
	 
	 // Functional units
    wire [31:0] result0, result1, result2;
    wire zero_flag0, zero_flag1, zero_flag2;
    wire [5:0] dest_reg0, dest_reg1, dest_reg2;
    wire [5:0] rob_index0, rob_index1, rob_index2;
	wire memWrite0, memWrite1, memWrite2;
	wire memRead0, memRead1, memRead2;
	wire memSize0, memSize1, memSize2;
	wire regWrite0, regWrite1, regWrite2;
	wire [31:0] store_data0, store_data1, store_data2;
	 
    functional_unit funct_unit0 (
        .enable(funct0_enable),
        .issue_queue_entry(issued_funct_unit0),
		.result(result0),
		.dest_reg(dest_reg0),
		.rob_index(rob_index0),
		.zero_flag(zero_flag0),
		.store_data(store_data0),
        .memWrite(memWrite0),
        .memRead(memRead0),
        .memSize(memSize0),
        .regWrite(regWrite0)
    );

    functional_unit funct_unit1 (
        .enable(funct1_enable),
        .issue_queue_entry(issued_funct_unit1),
		.result(result1),
		.dest_reg(dest_reg1),
		.rob_index(rob_index1),
		.zero_flag(zero_flag1),
		.store_data(store_data1),
        .memWrite(memWrite1),
        .memRead(memRead1),
        .memSize(memSize1),
        .regWrite(regWrite1)
    );

    functional_unit funct_unit2 (
        .enable(funct2_enable),
        .issue_queue_entry(issued_funct_unit2),
		.result(result2),
		.dest_reg(dest_reg2),
		.rob_index(rob_index2),
		.zero_flag(zero_flag2),
		.store_data(store_data2),
        .memWrite(memWrite2),
        .memRead(memRead2),
        .memSize(memSize2),
        .regWrite(regWrite2)
    );
	 
	 
	wire [242:0] combined_data_out;
	  

    pipeline_buffer_execute EX_MEM_buffer (
    .clk(clk),
    .reset_n(reset_n),
    .stall(stall),
    .data_in({
        store_data0, result0, zero_flag0, dest_reg0, rob_index0, memWrite0, memRead0, memSize0, regWrite0,
        store_data1, result1, zero_flag1, dest_reg1, rob_index1, memWrite1, memRead1, memSize1, regWrite1,
        store_data2, result2, zero_flag2, dest_reg2, rob_index2, memWrite2, memRead2, memSize2, regWrite2 
    }),
    .data_out(combined_data_out)
	);

	wire [31:0] store_data0_pipe = combined_data_out[242:211];
	wire zero_flag0_pipe = combined_data_out[178];
	
	assign rob_index0_pipe = combined_data_out[171:166];
	wire memWrite0_pipe = combined_data_out[165];
	wire memRead0_pipe = combined_data_out[164];
	wire memSize0_pipe = combined_data_out[163];
	assign regWrite0_pipe = combined_data_out[162];

	wire [31:0] store_data1_pipe = combined_data_out[161:130];
	
	wire zero_flag1_pipe = combined_data_out[97];
	  
	assign rob_index1_pipe = combined_data_out[90:85];
	wire memWrite1_pipe = combined_data_out[84];
	wire memRead1_pipe = combined_data_out[83];
	wire memSize1_pipe = combined_data_out[82];
	assign regWrite1_pipe = combined_data_out[81];
	
	wire [31:0] store_data2_pipe = combined_data_out[80:49];
	
	wire zero_flag2_pipe = combined_data_out[16];
	
	assign rob_index2_pipe = combined_data_out[9:4];
	wire memWrite2_pipe = combined_data_out[3];
	wire memRead2_pipe = combined_data_out[2];
	wire memSize2_pipe = combined_data_out[1];
	assign regWrite2_pipe = combined_data_out[0];
	  
	  

	wire [1:0] instruction_type;
	assign instruction_type = (is_load && is_word) ? 2'b00 :   // LW
				(is_load && is_byte) ? 2'b01 :   // LB
				(is_store && is_word) ? 2'b10 :  // SW
				(is_store && is_byte) ? 2'b11 :  // SB
				2'b00;
						  

	assign result0_pipe = combined_data_out[210:179];
	assign dest_reg0_pipe = combined_data_out[177:172];

	assign dest_reg1_pipe = combined_data_out[96:91];
	assign result1_pipe = combined_data_out[129:98];

	assign result2_pipe = combined_data_out[48:17];
	assign dest_reg2_pipe = combined_data_out[15:10];

    

	reg mem0;
	reg mem1;
	reg mem2;
	always @(*) begin
		complete_valid0 = 1'b0;
		complete_valid1 = 1'b0;
		complete_valid2 = 1'b0;
		fwd_double = 1'b0;
		mem0 = 1'b0;
		mem1 = 1'b0;
		mem2 = 1'b0;
		fwd_dest0 = 6'b0;
		fwd_val0 = 32'b0;
		fwd_dest1 = 6'b0;
		fwd_val1 = 32'b0;
		fwd_dest2 = 6'b0;
		fwd_val2 = 32'b0;
			
		if (memWrite0_pipe || memRead0_pipe) begin
			mem0 = 1'b1;
			fwd_dest0 = dest_reg0_pipe;
			fwd_double = 1'b1;

			fwd_val0 = 32'b0;

		end else if (regWrite0_pipe) begin
			fwd_dest0 = dest_reg0_pipe;
			fwd_val0 = result0_pipe;
			complete_valid0 = 1'b1;
		end
		if (memWrite1_pipe || memRead1_pipe) begin
			mem1 = 1'b1;
			fwd_dest1 = dest_reg1_pipe;
			fwd_double = 1'b1;
			fwd_val1 = 32'b0;
		end else if (regWrite1_pipe) begin
			complete_valid1 = 1'b1;
			fwd_dest1 = dest_reg1_pipe;
			fwd_val1 = result1_pipe;
		end
		if (memWrite2_pipe || memRead2_pipe) begin
			mem2 = 1'b1;
			fwd_dest2 = dest_reg2_pipe;
			fwd_double = 1'b1;
			fwd_val2 = 32'b0;
		end else if (regWrite2_pipe) begin
			complete_valid2 = 1'b1;
			fwd_dest2 = dest_reg2_pipe;
			fwd_val2 = result2_pipe;
		end
	end
	  
	  // Instantiate Load-Store Unit
    ls_unit lsu_inst (
        .clk(clk),
        .reset_n(reset_n),
			
		.load_store_enable(is_load || is_store),
        // Decode stage inputs
		  .instruction_type(instruction_type),
        .phys_rd(phys_rd),
        .rob_entry(rob_entry_num),

        // Functional Unit Address Inputs
		.load_store_enable_funct0(mem0),
		.load_store_enable_funct1(mem1),
		.load_store_enable_funct2(mem2),
		.store_data0(store_data0_pipe),
		.store_data1(store_data1_pipe),
		.store_data2(store_data2_pipe),
        .address_funct0(result0_pipe),  // Using result pipes as computed addresses
        .address_funct1(result1_pipe),
        .address_funct2(result2_pipe),
        .ROB_entry_num_funct0(rob_index0_pipe),
        .ROB_entry_num_funct1(rob_index1_pipe),
        .ROB_entry_num_funct2(rob_index2_pipe),

        // Outputs
		.enable_ROB(enable_ROB),
        .load_data(load_data),
        .rob_entry_num_retire(rob_entry_num_retire),
        .fwd_enable(fwd_enable_ls),
        .fwd_phys_rd(fwd_phys_rd)
    );
	
endmodule