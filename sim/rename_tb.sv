`timescale 1ns/1ps

module rename_tb;

    // Inputs for rename module
    reg [4:0] rd;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg issue_valid;
    reg reset_n = 1;
    reg clk;
    reg retire_valid1;
    reg [5:0] retire_phys_reg1;
	 reg [5:0] retire_cur_phys_reg1;
    reg retire_valid2;
    reg [5:0] retire_phys_reg2;
	 reg [5:0] retire_cur_phys_reg2;
	 reg [4:0] arch_reg1;
	 reg [4:0] arch_reg2;

    // Outputs from rename module
    wire [5:0] phys_rd;
    wire [5:0] phys_rs1;
    wire [5:0] phys_rs2;
    wire [5:0] old_phys_rd;
    wire free_list_empty;

    // Inputs for reorder buffer
    reg alloc_valid;
    reg [31:0] alloc_instr_addr;
    reg [5:0] alloc_dest;
    reg [5:0] alloc_oldDest;
	 reg [5:0] rob_entry_num;
    reg writeback_valid1;
    reg writeback_valid2;
    reg writeback_valid3;
    reg writeback_valid4;
    reg [5:0] writeback_idx1;
    reg [31:0] writeback_value1;
    reg [5:0] writeback_idx2;
    reg [31:0] writeback_value2;
    reg [5:0] writeback_idx3;
    reg [31:0] writeback_value3;
    reg [5:0] writeback_idx4;
    reg [31:0] writeback_value4;
    reg commit_ready;

    // Outputs for reorder buffer
    wire alloc_ready;
    wire commit_valid_1;
	 wire commit_valid_2;
    wire [5:0] commit_dest_1;
    wire [5:0] free_oldDest_1;
    wire [31:0] commit_value_1;
    wire [5:0] commit_dest_2;
    wire [5:0] free_oldDest_2;
    wire [31:0] commit_value_2;

    // Inputs for issue queue
    reg [6:0] opcode;
    reg [31:0] immediate;
    reg [5:0] ROB_entry_index;
	 reg fwd_enable;

    // Outputs for issue queue
	 wire [128:0] issued_funct_unit0;
    wire [128:0] issued_funct_unit1;
    wire [128:0] issued_funct_unit2;

    wire funct0_enable;
    wire funct1_enable;
    wire funct2_enable;
    wire issue_queue_full;

    // Outputs from reg_file
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // Inputs for reg_file dual retire
    reg [4:0] rd1;
    reg [31:0] rd1_data;
    reg RegWrite1;
    reg [4:0] rd2;
    reg [31:0] rd2_data;
    reg RegWrite2;

    // Instantiate the rename module
    rename rename_uut (
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .issue_valid(issue_valid),
        .reset_n(reset_n),
        .clk(clk),
        .retire_valid1(retire_valid1),  
        .retire_phys_reg1(retire_phys_reg1),
		  .retire_valid2(retire_valid2),  
        .retire_phys_reg2(retire_phys_reg2),
		  .retire_cur_phys_reg1(retire_cur_phys_reg1),
		  .retire_cur_phys_reg2(retire_cur_phys_reg2),
        .phys_rd(phys_rd),
        .phys_rs1(phys_rs1),
        .phys_rs2(phys_rs2),
		  .arch_reg1(arch_reg1),
		  .arch_reg2(arch_reg2),
        .old_phys_rd(old_phys_rd),
        .free_list_empty(free_list_empty)
    );

    // Instantiate the reorder buffer module
    reorder_buffer rob_uut (
        .clk(clk),
        .reset_n(reset_n),
        .alloc_valid(alloc_valid),
        .alloc_instr_addr(alloc_instr_addr),
        .alloc_dest(alloc_dest),
        .alloc_oldDest(alloc_oldDest),
        .alloc_ready(alloc_ready),
		  .rob_entry_num(rob_entry_num),
        .writeback_valid1(writeback_valid1),
        .writeback_valid2(writeback_valid2),
        .writeback_valid3(writeback_valid3),
        .writeback_valid4(writeback_valid4),
        .writeback_idx1(writeback_idx1),
        .writeback_value1(writeback_value1),
        .writeback_idx2(writeback_idx2),
        .writeback_value2(writeback_value2),
        .writeback_idx3(writeback_idx3),
        .writeback_value3(writeback_value3),
        .writeback_idx4(writeback_idx4),
        .writeback_value4(writeback_value4),
        .commit_valid_1(commit_valid_1),
		  .commit_valid_2(commit_valid_2),
        .commit_dest_1(commit_dest_1),
        .free_oldDest_1(free_oldDest_1),
        .commit_value_1(commit_value_1),
        .commit_dest_2(commit_dest_2),
        .free_oldDest_2(free_oldDest_2),
        .commit_value_2(commit_value_2),
        .commit_ready(commit_ready)
    );

    // Instantiate the issue queue module
    issue_queue iq_uut (
        .clk(clk),
        .reset_n(reset_n),
        .write_enable(issue_valid),
        .phys_rd(phys_rd),
        .phys_rs1(phys_rs1),
        .phys_rs1_val(rs1_data),
        .phys_rs2(phys_rs2),
        .phys_rs2_val(rs2_data),
        .opcode(opcode),
        .immediate(immediate),
        .ROB_entry_index(ROB_entry_index),
        .fwd_enable(fwd_enable),
        .fwd_rd_funct_unit0(writeback_idx1),
        .fwd_rd_val_funct_unit0(writeback_value_1),
        .fwd_rd_funct_unit1(writeback_idx2),
        .fwd_rd_val_funct_unit1(writeback_value2),
        .fwd_rd_funct_unit2(writeback_idx3),
        .fwd_rd_val_funct_unit2(writeback_value3),
        .issued_funct_unit0(issued_funct_unit0),
        .issued_funct_unit1(issued_funct_unit1),
        .issued_funct_unit2(issued_funct_unit2),
        .funct0_enable(funct0_enable),
        .funct1_enable(funct1_enable),
        .funct2_enable(funct2_enable),
        .issue_queue_full(issue_queue_full)
    );

    // Instantiate the reg_file module
    reg_file reg_file_uut (
        .clk(clk),
        .reset_n(reset_n),
        .rs1(rs1),
        .rs2(rs2),
        .rd1(rd1),
        .rd1_data(rd1_data),
        .RegWrite1(RegWrite1),
        .rd2(rd2),
        .rd2_data(rd2_data),
        .RegWrite2(RegWrite2),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10ns period, 100MHz

    // Test procedure
    initial begin
        // Initialize signals
        rd = 0;
        rs1 = 0;
        rs2 = 0;
        issue_valid = 0;
        retire_valid1 = 0;
        retire_phys_reg1 = 0;
        retire_valid2 = 0;
        retire_phys_reg2 = 0;

        rd1 = 0;
        rd1_data = 0;
        RegWrite1 = 0;
        rd2 = 0;
        rd2_data = 0;
        RegWrite2 = 0;

        alloc_valid = 0;
        alloc_instr_addr = 0;
        alloc_dest = 0;
        alloc_oldDest = 0;
        writeback_valid1 = 0;
        writeback_valid2 = 0;
        writeback_valid3 = 0;
        writeback_valid4 = 0;
        writeback_idx1 = 0;
        writeback_value1 = 0;
        writeback_idx2 = 0;
        writeback_value2 = 0;
        writeback_idx3 = 0;
        writeback_value3 = 0;
        writeback_idx4 = 0;
        writeback_value4 = 0;
        commit_ready = 0;

        opcode = 7'b0;
        immediate = 32'b0;
        ROB_entry_index = 6'b0;


        // Reset the modules
        #5;
        reset_n = 1;
        #10;
        reset_n = 0;
        #10;
        reset_n = 1;

        // Test Case 1: Issue instructions and allocate to ROB
        issue_and_allocate(5'b00001, 5'b00010, 5'b00011, 32'hDEADBEEF, 7'b0110011); // R-type
		  issue_and_allocate(5'b00010, 5'b00100, 5'b00001, 32'hCAFEBABE, 7'b0010011); // I-type
		  issue_and_allocate(5'b00101, 5'b00011, 5'b00110, 32'h12345678, 7'b0110011); // R-type
		  issue_and_allocate(5'b00110, 5'b00101, 5'b00001, 32'h87654321, 7'b0010011); // I-type
		  issue_and_allocate(5'b00111, 5'b00011, 5'b00101, 32'hABCD1234, 7'b0110011); // R-type
		  issue_and_allocate(5'b01000, 5'b01001, 5'b01010, 32'h5555AAAA, 7'b0010011); // I-type
		  
		  commit_test();
		  


        // Test Case 2: Writebacks (without committing)
        writeback_test(1, 6'd32, 32'hAABBCCDD, 
                   1, 6'd33, 32'h11223344, 
                   0, 6'd0, 32'h0, 
                   0, 6'd0, 32'h0);
						 
			issue_and_allocate(5'b01001, 5'b00111, 5'b00001, 32'h0000FFFF, 7'b0110011); // R-type
		  issue_and_allocate(5'b01010, 5'b00010, 5'b00100, 32'h33334444, 7'b0010011); // I-type
		  
		  writeback_test(1, 6'd35, 32'hDEADBEEF, 
						 1, 6'd34, 32'hCAFEBABE, 
					 1, 6'd36, 32'h12345678, 
						 1, 6'd37, 32'h87654321);
			/*
        commit_test();
		  
		  // Test Case 5: Additional Allocations for Wraparound/Stress Testing
			issue_and_allocate(5'b01110, 5'b01001, 5'b01010, 32'hF00DBEEF, 7'b0110011); // R-type: Test ROB wraparound
			issue_and_allocate(5'b01111, 5'b01110, 5'b01011, 32'hBEEFCAFE, 7'b0010011); // I-type: Stress dependency
			issue_and_allocate(5'b10000, 5'b01111, 5'b01100, 32'h1234ABCD, 7'b0110011); // R-type: Long chain
			issue_and_allocate(5'b10001, 5'b10000, 5'b01101, 32'hDEADC0DE, 7'b0010011); // I-type: Long dependency chain

			// Final Writebacks and Commit
			writeback_test(
				 1, 6'd39, 32'hF00DFACE, // Port 1
				 1, 6'd40, 32'hBAADF00D, // Port 2
				 1, 6'd41, 32'hCAFEBABE, // Port 3
				 1, 6'd42, 32'hFEEDFACE  // Port 4
			);
			commit_test();

			*/
        // Finish simulation
        #50;
        $finish;
    end

    // Tasks for various operations (issuing seems to work well)
    task issue_and_allocate(input [4:0] in_rd, input [4:0] in_rs1, input [4:0] in_rs2, input [31:0] in_immediate, input [6:0] in_opcode);
        begin

			   issue_valid = 1;
				alloc_valid = 1;
            rd = in_rd;
            rs1 = in_rs1;
            rs2 = in_rs2;
            immediate = in_immediate;
            opcode = in_opcode;
				
				#1
				alloc_dest=phys_rd;
				alloc_oldDest = old_phys_rd;
				ROB_entry_index = rob_entry_num; //doesnt update in time in simulation
				
            #9;
            issue_valid = 0;
				alloc_valid = 0;
        end
    endtask
	
	//need to modify issue queue to take forwarding of 4 writeback values for each alu
    task writeback_test(
		 input valid1, input [5:0] idx1, input [31:0] value1,
		 input valid2, input [5:0] idx2, input [31:0] value2,
		 input valid3, input [5:0] idx3, input [31:0] value3,
		 input valid4, input [5:0] idx4, input [31:0] value4
	);
		 begin
			  // Enable writeback signals conditionally
			  writeback_valid1 = valid1;
			  writeback_idx1 = valid1 ? idx1 : 6'b0;
			  writeback_value1 = valid1 ? value1 : 32'b0;

			  writeback_valid2 = valid2;
			  writeback_idx2 = valid2 ? idx2 : 6'b0;
			  writeback_value2 = valid2 ? value2 : 32'b0;

			  writeback_valid3 = valid3;
			  writeback_idx3 = valid3 ? idx3 : 6'b0;
			  writeback_value3 = valid3 ? value3 : 32'b0;

			  writeback_valid4 = valid4;
			  writeback_idx4 = valid4 ? idx4 : 6'b0;
			  writeback_value4 = valid4 ? value4 : 32'b0;
			  
			  fwd_enable = valid1 | valid2 | valid3 | valid4;

			  #10; // Simulate delay for the writeback

			  // Clear the writeback signals
			  writeback_valid1 = 0;
			  writeback_valid2 = 0;
			  writeback_valid3 = 0;
			  writeback_valid4 = 0;
			  fwd_enable=0;
		 end
	endtask


    task commit_test(); //retire still doesnt finish in time for writing to free list, reg files?
        begin
            commit_ready = 1;
				#1
				retire_valid1 = commit_valid_1;
				retire_valid2 = commit_valid_2;
				retire_phys_reg1 = free_oldDest_1;
				retire_phys_reg2 = free_oldDest_2;
				
				RegWrite1 = commit_valid_1;
				RegWrite2 = commit_valid_2;
				
				retire_cur_phys_reg1 = commit_dest_1;
				retire_cur_phys_reg2 = commit_dest_2;
				#1
				rd1 = arch_reg1;
				rd2 = arch_reg2;
				rd1_data = commit_value_1;
				rd2_data = commit_value_2;
				
            #8;
            commit_ready = 0;
				
				RegWrite1 = 0;
				RegWrite2 = 0;
				retire_valid1 = 0;
				retire_valid2 = 0;

        end
    endtask

endmodule
