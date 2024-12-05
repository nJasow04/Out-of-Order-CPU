`include "/home/mark/Documents/workspace/Out-of-Order-CPU/src/issue_queue.v" 

`timescale 1ns/1ps

module issue_queue_tb;

    // Clock and reset
    reg clk;
    reg reset_n;

    // Rename stage inputs
    reg write_enable;
    reg [5:0] phys_rd;
    reg [5:0] phys_rs1;
    reg [31:0] phys_rs1_val;
    reg [5:0] phys_rs2;
    reg [31:0] phys_rs2_val;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [6:0] opcode;
    reg [31:0] immediate;
    reg [5:0] ROB_entry_index;

    // Execute stage inputs
    reg fwd_enable;

    reg [5:0] fwd_rd_funct_unit0;
    reg [31:0] fwd_rd_val_funct_unit0;

    reg [5:0] fwd_rd_funct_unit1;
    reg [31:0] fwd_rd_val_funct_unit1;

    reg [5:0] fwd_rd_funct_unit2;
    reg [31:0] fwd_rd_val_funct_unit2;

    reg [5:0] fwd_rd_mem;
    reg [31:0] fwd_rd_val_mem;

    // Outputs
    wire [138:0] issued_funct_unit0;
    wire [138:0] issued_funct_unit1;
    wire [138:0] issued_funct_unit2;

    wire funct0_enable;
    wire funct1_enable;
    wire funct2_enable;

    wire issue_queue_full;

    // Instantiate the DUT
    issue_queue uut (
        .clk(clk),
        .reset_n(reset_n),
        .write_enable(write_enable),
        .phys_rd(phys_rd),
        .phys_rs1(phys_rs1),
        .phys_rs1_val(phys_rs1_val),
        .phys_rs2(phys_rs2),
        .phys_rs2_val(phys_rs2_val),
        .funct3(funct3),
        .funct7(funct7),
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
        .fwd_rd_mem(fwd_rd_mem),
        .fwd_rd_val_mem(fwd_rd_val_mem),
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
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Testbench logic
    initial begin
        // Initialize signals
        reset_n = 0;
        write_enable = 0;
        phys_rd = 0;
        phys_rs1 = 0;
        phys_rs1_val = 0;
        phys_rs2 = 0;
        phys_rs2_val = 0;
        funct3 = 0;
        funct7 = 0;
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
        fwd_rd_mem = 0;
        fwd_rd_val_mem = 0;
        // Apply reset
        #10 reset_n = 1;

        // Test case 2: Forwarding enabled
        #10;
        fwd_enable = 1;
        fwd_rd_funct_unit0 = 6'd5;
        fwd_rd_val_funct_unit0 = 32'hCAFEBABE;
        fwd_rd_funct_unit1 = 6'd7;
        fwd_rd_val_funct_unit1 = 32'hDEADBEEF;
        fwd_rd_funct_unit2 = 6'd9;
        fwd_rd_val_funct_unit2 = 32'hFFFFFFFF;

        // Test case 1: Write operation
        #10;
        write_enable = 1;
        phys_rd = 6'd10;
        phys_rs1 = 6'd5;
        phys_rs1_val = 32'd0;
        phys_rs2 = 6'd5;
        phys_rs2_val = 32'd0;
        funct3 = 3'b101;
        funct7 = 7'b0101010;
        opcode = 7'b1100110;
        immediate = 32'h12345678;
        ROB_entry_index = 6'd20;

        #10 write_enable = 0;

        //Test case 3: No write or forwarding
        #100;
        write_enable = 0;
        fwd_enable = 0;

        // End simulation
        #100 $finish;
    end

    // Monitor signals
    initial begin
        $monitor($time, 
            " clk=%b, reset_n=%b, write_enable=%b, fwd_enable=%b, issue_queue_full=%b",
            clk, reset_n, write_enable, fwd_enable, issue_queue_full);
    end

endmodule
