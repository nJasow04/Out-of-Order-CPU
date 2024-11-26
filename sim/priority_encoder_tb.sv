module priority_encoder_tb;

    parameter ENTRY_COUNT = 64;

    reg [ENTRY_COUNT-1:0] free_table;
    wire [$clog2(ENTRY_COUNT)-1:0] free_index;
    wire valid;

    priority_encoder #(.ENTRY_COUNT(ENTRY_COUNT)) pe_inst (
    .free_table(free_table),
    .free_index(free_index),
    .valid(valid)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, priority_encoder_tb);
    end

    initial begin
        // Full
        free_table = {ENTRY_COUNT{1'b1}}; 
        #10;

        // All entries are free
        free_table = {ENTRY_COUNT{1'b0}}; 
        #10;
        assert(valid && free_index == 0) else $fatal("Test Case 1 Failed!");

        // 15 is free
        free_table = {ENTRY_COUNT{1'b1}}; // All entries in use
        free_table[15] = 1'b0; // Set entry 15 as free
        #10;
        assert(valid && free_index == 15) else $fatal("Test Case 2 Failed!");

        // Multiple entries free, first one prioritized
        free_table = {ENTRY_COUNT{1'b1}};
        free_table[3] = 1'b0; 
        free_table[7] = 1'b0; 
        #10;
        assert(valid && free_index == 3) else $fatal("Test Case 3 Failed!");

        // No entries are free
        free_table = {ENTRY_COUNT{1'b1}}; 
        #10;
        assert(!valid) else $fatal("Test Case 4 Failed!");

        // Randomized Testing
        repeat (10) begin
        free_table = $random; // Randomize free_table
        #10;
        $display("Free Table: %b, Free Index: %d, Valid: %b", free_table, free_index, valid);
        end

        $finish;
    end

endmodule
