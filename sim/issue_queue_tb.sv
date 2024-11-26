`include "/home/mark/Documents/workspace/Out-of-Order-CPU/src/issue_queue.v" 

module issue_queue_tb;

    // Constants
    parameter NUM_FUNCTIONAL_UNITS = 3;
    parameter NUM_PHYSICAL_REGS = 64;
    parameter NUM_INSTRUCTIONS = 64;
    parameter ENTRY_SIZE = 131;

    // Signals
    reg clk = 0;
    reg reset_n = 1;
    reg write_enable;
    reg [5:0] phys_dest;
    reg [5:0] phys_rs1;
    reg [31:0] phys_rs1_val;
    reg [5:0] phys_rs2;
    reg [31:0] phys_rs2_val;
    reg [6:0] opcode;
    reg [31:0] immediate;
    reg [5:0] ROB_entry_index;
    reg [31:0] fwd_rs1;
    reg [31:0] fwd_rs2;
    wire valid;

    issue_queue uut (
        .clk(clk),
        .reset_n(reset_n),
        .write_enable(write_enable),
        .phys_dest(phys_dest),
        .phys_rs1(phys_rs1),
        .phys_rs1_val(phys_rs1_val),
        .phys_rs2(phys_rs2),
        .phys_rs2_val(phys_rs2_val),
        .opcode(opcode),
        .immediate(immediate),
        .ROB_entry_index(ROB_entry_index),
        .fwd_rs1(fwd_rs1),
        .fwd_rs2(fwd_rs2),
        .valid(valid)
    );


	initial begin
    	$dumpfile("dump.vcd"); 
      	$dumpvars(0, issue_queue_tb);
    end

    always #5 clk = ~clk;
  
    initial begin

        write_enable = 0;
        phys_dest = 0;
        phys_rs1 = 0;
        phys_rs1_val = 0;
        phys_rs2 = 0;
        phys_rs2_val = 0;
        opcode = 0;
        immediate = 0;
        ROB_entry_index = 0;
        fwd_rs1 = 0;
        fwd_rs2 = 0;

        // Apply reset
        #10 
        reset_n = 0;
        #10;

        // Test case 1: Add an instruction
        reset_n = 1;
        write_enable = 1;
        opcode = 7'b0000001; // Example opcode
        phys_dest = 6'd10;
        phys_rs1 = 6'd5;
        phys_rs1_val = 32'd5;
        phys_rs2 = 6'd8;
        phys_rs2_val = 32'd6;
        immediate = 32'd10;
        ROB_entry_index = 6'd15;

        #10 
        write_enable = 0; // Stop writing
        #10;

        // Test case 2: Check if entry was created
        // You can optionally add assertions to verify the contents of issue_queue

        // Test case 3: Add multiple instructions
        repeat (3) begin
            write_enable = 1;
            phys_dest = $random % NUM_PHYSICAL_REGS;
            phys_rs1 = $random % NUM_PHYSICAL_REGS;
            phys_rs1_val = $random;
            phys_rs2 = $random % NUM_PHYSICAL_REGS;
            phys_rs2_val = $random;
            opcode = $random % 128;
            immediate = $random;
            ROB_entry_index = $random % NUM_INSTRUCTIONS;
            #10;
        end
        write_enable = 0;

        // Test case 4: Verify priority encoder's `valid` signal
        if (!valid) $fatal("Error: Priority encoder failed to find a free entry!");

        // Test case 5: Reset test
        reset_n = 0;
        #10 reset_n = 1;
        #10;

        $finish;
    end

endmodule
