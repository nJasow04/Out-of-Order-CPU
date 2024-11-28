// `include "/home/mark/Documents/workspace/Out-of-Order-CPU/src/issue_queue.v" 

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
    wire issue_queue_full;

    // Instantiate DUT
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
        .issue_queue_full(issue_queue_full)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test scenarios
    initial begin
        $dumpfile("issue_queue_tb.vcd");
        $dumpvars(0, issue_queue_tb);

        initialize_signals();
        reset_system();

        // Test practical RISC-V instructions
        test_instruction("ADD x1, x2, x3", 7'b0110011, 6'd1, 6'd2, 32'd42, 6'd3, 32'd17, 0);
        test_instruction("SUB x3, x2, x0", 7'b0110011, 6'd3, 6'd2, 32'd25, 6'd0, 32'd0, 0);
        test_instruction("LW x4, 8(x2)",  7'b0000011, 6'd4, 6'd2, 32'd30, 6'b0, 32'd0, 8);
        test_instruction("SW x5, 16(x3)", 7'b0100011, 6'd0, 6'd3, 32'd45, 6'd5, 32'd60, 16);

        // Check issue queue full behavior
        fill_issue_queue();
        check_queue_full_behavior();

        // Reset test
        reset_system();

        $finish;
    end

    // Task to initialize signals
    task initialize_signals;
        begin
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
        end
    endtask

    // Task to apply reset
    task reset_system;
        begin
            reset_n = 0;
            #10 reset_n = 1;
            #10;
        end
    endtask

    // Task to test a single instruction
    task test_instruction(
        input string description,
        input [6:0] test_opcode,
        input [5:0] test_dest,
        input [5:0] test_rs1,
        input [31:0] test_rs1_val,
        input [5:0] test_rs2,
        input [31:0] test_rs2_val,
        input [31:0] test_immediate
    );
        begin
            $display("Testing instruction: %s", description);
            write_enable = 1;
            opcode = test_opcode;
            phys_dest = test_dest;
            phys_rs1 = test_rs1;
            phys_rs1_val = test_rs1_val;
            phys_rs2 = test_rs2;
            phys_rs2_val = test_rs2_val;
            immediate = test_immediate;
            ROB_entry_index = $random % NUM_INSTRUCTIONS;

            #10;
            write_enable = 0;
            #10;

            // Assertions to check correctness
            if (issue_queue_full) $display("Error: Issue queue unexpectedly full during test of %s", description);
            $display("Instruction %s successfully added to issue queue.", description);
        end
    endtask

    // Task to fill the issue queue
    task fill_issue_queue;
        begin
            $display("Filling issue queue...");
            repeat (NUM_INSTRUCTIONS) begin
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
            #10;
        end
    endtask

    // Task to check behavior when queue is full
    task check_queue_full_behavior;
        begin
            $display("Testing issue queue full behavior...");
            if (!issue_queue_full) $display("Error: Issue queue not reported as full when expected!");
            else $display("Issue queue correctly reported as full.");
        end
    endtask

endmodule
