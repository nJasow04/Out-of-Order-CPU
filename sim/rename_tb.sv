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
    wire free_list_empty;

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
        .free_list_empty(free_list_empty)
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

        // Reset the module to start fresh
        #10 
        #10 reset_n = 0;
        #10 
        
        reset_n = 1;
        // Test Case 1: Issue three renaming requests in a row
        #20;
        issue_rename_request(5'b00001, 5'b00010, 5'b00011); // rd = 1, rs1 = 2, rs2 = 3
        issue_rename_request(5'b00010, 5'b00100, 5'b00001); // rd = 2, rs1 = 4, rs2 = 1
        issue_rename_request(5'b00011, 5'b00101, 5'b00010); // rd = 3, rs1 = 5, rs2 = 2
        #10;

        // Reset before next test case
        #10 reset_n = 0;
        #10 reset_n = 1;

        // Test Case 2: Retire a physical register and then issue a rename
        #20;
        retire_register(6'b000010); // Retire physical register 2
        issue_rename_request(5'b00100, 5'b00011, 5'b00001); // rd = 4, rs1 = 3, rs2 = 4
        #10;

        // Reset before next test case
        #10 reset_n = 0;
        #10 reset_n = 1;

        // Test Case 3: Fill the free list to trigger the free list empty condition
        #10;
        fill_free_list();

        // Retire a physical register and try issuing a new instruction after free list is full
        #20;
        retire_register(6'b000011); // Retire physical register 3
        issue_rename_request(5'b01000, 5'b01001, 5'b01010); // Try issuing rd = 8, rs1 = 9, rs2 = 10 (new instruction)
        #10;

        // Finish simulation
        #50;
        $finish;
    end

    // Task to issue a rename request
    task issue_rename_request(input [4:0] in_rd, input [4:0] in_rs1, input [4:0] in_rs2);
        begin
			#5
            rd = in_rd;
            rs1 = in_rs1;
            rs2 = in_rs2;
            // Set issue_valid on the positive edge of the clock
             issue_valid = 1;  // Set issue_valid
            #5 issue_valid = 0;  // Reset issue_valid after one cycle
        end
    endtask

    // Task to retire a physical register
    task retire_register(input [5:0] in_retire_phys_reg);
        begin
            retire_phys_reg = in_retire_phys_reg;
            retire_valid = 1;
            #10;
            retire_valid = 0;
        end
    endtask

    // Task to fill the free list to trigger the free list empty condition
    task fill_free_list();
        integer i;
        begin
            // Exhaust the free list by issuing rename requests
            for (i = 0; i < 64; i = i + 1) begin
                issue_rename_request(i[4:0], i[4:0], i[4:0]);
                #10;
            end
        end
    endtask

    // Monitor to display output and relevant signals
    initial begin
        $monitor("Time=%0t | rd=%0d, rs1=%0d, rs2=%0d | phys_rd=%0d, phys_rs1=%0d, phys_rs2=%0d | free_list_empty=%0b",
                 $time, rd, rs1, rs2, phys_rd, phys_rs1, phys_rs2, free_list_empty);
    end

endmodule
