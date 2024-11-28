`timescale 1ns/1ps
`include "/home/mark/Documents/workspace/Out-of-Order-CPU/src/rename.v" 

module rename_tb;

    // Inputs
    reg [4:0] rd;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg issue_valid;
    reg reset_n = 1;
    reg clk;
    reg retire_valid;
    reg [5:0] retire_phys_reg;

    // Outputs
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
    reg writeback_valid;
    reg [5:0] writeback_idx;
    reg [31:0] writeback_value;
    reg commit_ready;

    // Outputs for reorder buffer
    wire alloc_ready;
    wire commit_valid;
    wire [5:0] commit_dest;
	 wire [5:0] free_dest;
    wire [31:0] commit_value;

    // Instantiate the rename module
    rename uut (
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .issue_valid(issue_valid),
        .reset_n(reset_n),
        .clk(clk),
        .retire_valid(retire_valid),
        .retire_phys_reg(retire_phys_reg),
        .phys_rd(phys_rd),
        .phys_rs1(phys_rs1),
        .phys_rs2(phys_rs2),
		  .old_phys_rd(old_phys_rd),
        .free_list_empty(free_list_empty)
    );
	 reorder_buffer rob_uut (
        .clk(clk),
        .reset_n(reset_n),
        .alloc_valid(alloc_valid),
        .alloc_instr_addr(alloc_instr_addr),
        .alloc_dest(alloc_dest),
        .alloc_oldDest(alloc_oldDest),
        .alloc_ready(alloc_ready),
        .writeback_valid(writeback_valid),
        .writeback_idx(writeback_idx),
        .writeback_value(writeback_value),
        .commit_valid(commit_valid),
        .commit_dest(commit_dest),
		  .free_oldDest(free_dest),
        .commit_value(commit_value),
        .commit_ready(commit_ready)
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
        retire_valid = 0;
        retire_phys_reg = 0;
        reset_n = 0;
		  
		  alloc_valid = 0;
        alloc_instr_addr = 0;
        alloc_dest = 0;
        alloc_oldDest = 0;
        writeback_valid = 0;
        writeback_idx = 0;
        writeback_value = 0;
        commit_ready = 0;
		  

        // Reset the module to start fresh
		  #5;
        #10 reset_n = 1;
        #10 reset_n = 0;
        #10 reset_n = 1;
        issue_and_allocate(5'b00001, 5'b00010, 5'b00011, 32'hDEADBEEF); // Allocate rd = 1
        
        issue_and_allocate(5'b00010, 5'b00100, 5'b00001, 32'hCAFEBABE); // Allocate rd = 2
        
        issue_and_allocate(5'b00011, 5'b00101, 5'b00010, 32'h12345678); // Allocate rd = 3
        #10;


        // Test Case 2: Retire a physical register and then issue a rename
        write_back_to_rob(6'b000001, 32'hFACECAFE); // Writeback ROB index 1
        commit_instruction();
		  write_back_to_rob(6'b000000, 32'hFACECAFA); // Writeback ROB index 1
        commit_instruction();
		  issue_and_allocate(5'b00001, 5'b00011, 5'b00100, 32'h12345678);
		  write_back_to_rob(6'b000010, 32'hFACECAFB);
		  commit_instruction();
		  issue_and_allocate(5'b00000, 5'b00111, 5'b00011, 32'h12345679);
        #10;

        // Reset before next test case
		  writeback_idx = 0;
        writeback_value = 0;
        #10 reset_n = 0;
        #10 reset_n = 1;
		  

		  
		  // Test Case 3: Fill ROB and free lists, retire, and allocate
        //#20;
        //fill_rob_and_free_list();
        //#20;
        //retire_and_free_space();
        //#20;
        //issue_and_allocate(5'b00001, 5'b10001, 5'b10010, 32'hFEEDBEEF); // Allocate after retiring
        //#10;

        // Finish simulation
        #50;
        $finish;
    end
	
	task issue_and_allocate(input [4:0] in_rd, input [4:0] in_rs1, input [4:0] in_rs2, input [31:0] instr_addr);
        begin
				
            issue_rename_request(in_rd, in_rs1, in_rs2);
				alloc_valid = 1;
				#5;
				
            if (alloc_ready) begin
                
                alloc_instr_addr = instr_addr;
                alloc_dest = phys_rd; // Physical destination register
                alloc_oldDest = old_phys_rd; // Original destination register
                #5 ;
					 
            end
				issue_valid = 0;
				alloc_valid = 0;
        end
    endtask
    // Task to issue a rename request
    task issue_rename_request(input [4:0] in_rd, input [4:0] in_rs1, input [4:0] in_rs2);
        begin
            rd = in_rd;
            rs1 = in_rs1;
            rs2 = in_rs2;
            // Set issue_valid on the positive edge of the clock
             issue_valid = 1;  // Set issue_valid
              // Reset issue_valid after one cycle
        end
    endtask
	 
	 task write_back_to_rob(input [5:0] rob_idx, input [31:0] value);
        begin
            writeback_valid = 1;
            writeback_idx = rob_idx;
            writeback_value = value;
            #5 writeback_valid = 0;
				commit_ready = 1;
				#5;
        end
    endtask

    // Task to commit an instruction from the ROB
    task commit_instruction();
        begin
				retire_valid = commit_valid;
				retire_phys_reg = free_dest;
				#10;
				commit_ready = 0;
				retire_valid = 0; //not sure how retirement and freeing can happen in one clock cycle???
        end
    endtask

    task fill_rob_and_free_list();
        integer i;
        begin
            for (i = 0; i < 64; i = i + 1) begin
                issue_and_allocate(i[4:0], i[4:0], i[4:0], i); // Allocate to ROB
                #10;
            end
        end
    endtask

    task retire_and_free_space();
        begin
            write_back_to_rob(6'b000000, 32'hAABBCCDD); // Writeback ROB index 0
            commit_instruction();                      // Commit ROB index 0
        end
    endtask

    // Monitor to display output and relevant signals
       initial begin
        $monitor("Time=%0t | rd=%0d, rs1=%0d, rs2=%0d | phys_rd=%0d, phys_rs1=%0d, phys_rs2=%0d | ROB Head=%0d, ROB Tail=%0d | Commit_Valid=%0b, Commit_Dest=%0d | Writeback_Idx=%0d, Writeback_Value=%0h | Free_List_Empty=%0b, ROB_Full=%0b",
                 $time, rd, rs1, rs2, phys_rd, phys_rs1, phys_rs2, 
                 rob_uut.head, rob_uut.tail, commit_valid, commit_dest, 
                 writeback_idx, writeback_value, 
                 free_list_empty, alloc_ready);
    end



endmodule
