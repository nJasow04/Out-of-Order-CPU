`include "/home/mark/Documents/workspace/Out-of-Order-CPU/src/issue_queue.v" 

module issue_queue_tb;
    // Parameters from the issue_queue module
    parameter NUM_FUNCTIONAL_UNITS = 3;
    parameter NUM_PHYSICAL_REGS = 64;
    parameter NUM_INSTRUCTIONS = 64;
    parameter ENTRY_SIZE = 129;

    // Clock and Reset
    reg clk;
    reg reset_n;

    // Inputs to the issue_queue
    reg write_enable;
    reg [5:0] phys_rd, phys_rs1, phys_rs2, ROB_entry_index;
    reg [31:0] phys_rs1_val, phys_rs2_val, immediate;
    reg [6:0] opcode;
    
    // Forwarding inputs
    reg fwd_enable;
    reg [5:0] fwd_rd_funct_unit0;
    reg [31:0] fwd_rd_val_funct_unit0;
    reg [5:0] fwd_rd_funct_unit1;
    reg [31:0] fwd_rd_val_funct_unit1;
    reg [5:0] fwd_rd_funct_unit2;
    reg [31:0] fwd_rd_val_funct_unit2;

    // Outputs from the issue_queue
    wire [ENTRY_SIZE-1:0] issued_funct_unit0;
    wire [ENTRY_SIZE-1:0] issued_funct_unit1;
    wire [ENTRY_SIZE-1:0] issued_funct_unit2;
    wire funct0_enable;
    wire funct1_enable;
    wire funct2_enable;
    wire issue_queue_full;

    // Instantiate the issue_queue module
    issue_queue uut (
        .clk(clk),
        .reset_n(reset_n),
        .write_enable(write_enable),
        .phys_rd(phys_rd),
        .phys_rs1(phys_rs1),
        .phys_rs1_val(phys_rs1_val),
        .phys_rs2(phys_rs2),
        .phys_rs2_val(phys_rs2_val),
        .opcode(opcode),
        .immediate(immediate),
        .ROB_entry_index(ROB_entry_index),
        .fwd_enable(fwd_enable),
        .fwd_rd_funct_unit0(fwd_rd_funct_unit0),
        .fwd_rd_val_funct_unit0(fwd_rd_val_funct_unit0),
        .fwd_rd_funct_unit1(fwd_rd_funct_unit1),
        .fwd_rd_val_funct_unit1(fwd_rd_val_funct_unit1),
        .fwd_rd_funct_unit2(fwd_rd_funct_unit2),
        .fwd_rd_val_funct_unit2(fwd_rd_val_funct_unit2),
        .issued_funct_unit0(issued_funct_unit0),
        .issued_funct_unit1(issued_funct_unit1),
        .issued_funct_unit2(issued_funct_unit2),
        .funct0_enable(funct0_enable),
        .funct1_enable(funct1_enable),
        .funct2_enable(funct2_enable),
        .issue_queue_full(issue_queue_full)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize all inputs
        reset_n = 0;
        write_enable = 0;
        phys_rd = 0;
        phys_rs1 = 0;
        phys_rs1_val = 0;
        phys_rs2 = 0;
        phys_rs2_val = 0;
        opcode = 0;
        immediate = 0;
        ROB_entry_index = 0;
        fwd_enable = 0;
        fwd_rd_funct_unit0 = 0;
        fwd_rd_val_funct_unit0 = 0;
        fwd_rd_funct_unit1 = 0;
        fwd_rd_val_funct_unit1 = 0;
        fwd_rd_funct_unit2 = 0;
        fwd_rd_val_funct_unit2 = 0;

        // Reset sequence
        #20 reset_n = 1;

        // Test 1: Add instruction that needs forwarding from FU0
        #10 write_enable = 1;
        phys_rd = 6'd10;
        phys_rs1 = 6'd5;  // Will need forwarding
        phys_rs1_val = 32'hA5A5A5A5;
        phys_rs2 = 6'd15; // Will need forwarding
        phys_rs2_val = 32'h5A5A5A5A;
        opcode = 7'b0101010;
        immediate = 32'hDEADBEEF;
        ROB_entry_index = 6'd20;
        
        #10 write_enable = 0;

        // Test 2: Forward from FU0
        #10 fwd_enable = 1;
        fwd_rd_funct_unit0 = 6'd5;
        fwd_rd_val_funct_unit0 = 32'hCAFEBABE;
        
        #10 fwd_enable = 0;

        // Test 3: Forward from FU1
        #10 fwd_enable = 1;
        fwd_rd_funct_unit1 = 6'd15;
        fwd_rd_val_funct_unit1 = 32'hFEEDFACE;
        
        #10 fwd_enable = 0;

        // Test 4: Fill up the queue
        repeat (NUM_INSTRUCTIONS) begin
            #10 write_enable = 1;
            phys_rd = $random % 64;
            phys_rs1 = $random % 64;
            phys_rs1_val = $random;
            phys_rs2 = $random % 64;
            phys_rs2_val = $random;
            opcode = $random % 128;
            immediate = $random;
            ROB_entry_index = $random % 64;
        end
        
        #10 write_enable = 0;

        // Test 5: Multiple forwards in same cycle
        #20 fwd_enable = 1;
        fwd_rd_funct_unit0 = 6'd30;
        fwd_rd_val_funct_unit0 = 32'hAAAAAAAA;
        fwd_rd_funct_unit1 = 6'd31;
        fwd_rd_val_funct_unit1 = 32'hBBBBBBBB;
        fwd_rd_funct_unit2 = 6'd32;
        fwd_rd_val_funct_unit2 = 32'hCCCCCCCC;
        
        #10 fwd_enable = 0;

        // Test 6: Reset during operation
        #20 reset_n = 0;
        #20 reset_n = 1;

        // Wait for final observations
        #100 $finish;
    end

    // Monitor results
    initial begin
        $monitor("Time=%0t reset_n=%b write_enable=%b fwd_enable=%b queue_full=%b\n\tFU0_enable=%b FU1_enable=%b FU2_enable=%b",
                 $time, reset_n, write_enable, fwd_enable, issue_queue_full,
                 funct0_enable, funct1_enable, funct2_enable);
    end

    // Additional monitoring for important events
    always @(posedge clk) begin
        if (funct0_enable)
            $display("Time=%0t: Instruction issued to FU0: %h", $time, issued_funct_unit0);
        if (funct1_enable)
            $display("Time=%0t: Instruction issued to FU1: %h", $time, issued_funct_unit1);
        if (funct2_enable)
            $display("Time=%0t: Instruction issued to FU2: %h", $time, issued_funct_unit2);
        if (issue_queue_full)
            $display("Time=%0t: Issue queue is full!", $time);
    end

endmodule
