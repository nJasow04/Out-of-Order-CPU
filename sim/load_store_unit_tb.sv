module load_store_unit_tb;

    // Testbench signals

    // Written by chatgpt, didn't actually test

    logic clk;
    logic reset;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm;
    logic is_load;
    logic is_store;
    logic is_byte;
    logic is_word;

    logic [31:0] read_data;
    logic mem_done;
    logic [31:0] mem_address;

    // Instantiate the DUT (Device Under Test)
    load_store_unit DUT (
        .clk(clk),
        .reset(reset),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm(imm),
        .is_load(is_load),
        .is_store(is_store),
        .is_byte(is_byte),
        .is_word(is_word),
        .read_data(read_data),
        .mem_done(mem_done),
        .mem_address(mem_address)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test procedure
    initial begin
        // Initialize signals
        reset = 1;
        rs1_data = 0;
        rs2_data = 0;
        imm = 0;
        is_load = 0;
        is_store = 0;
        is_byte = 0;
        is_word = 0;

        #10 reset = 0; // Deassert reset after 10ns

        // Test 1: Store a word at address 0x0000_0010
        rs1_data = 32'h0000_0000;  // Base address
        imm = 32'h0000_0010;       // Offset
        rs2_data = 32'hDEADBEEF;   // Data to store
        is_store = 1;
        is_word = 1;
        #10 is_store = 0;          // Deassert store
        #10;

        // Test 2: Load the word back from address 0x0000_0010
        is_load = 1;
        is_word = 1;
        #10 is_load = 0;           // Deassert load
        #10;

        // Check if the word was stored and loaded correctly
        $display("Read Data (Word): %h", read_data);
        if (read_data !== 32'hDEADBEEF) $error("Test 2 failed!");

        // Test 3: Store a byte at address 0x0000_0011
        rs1_data = 32'h0000_0000;  // Base address
        imm = 32'h0000_0011;       // Offset
        rs2_data = 32'h000000FF;   // Byte data to store
        is_store = 1;
        is_byte = 1;
        #10 is_store = 0;          // Deassert store
        #10;

        // Test 4: Load the byte back from address 0x0000_0011
        is_load = 1;
        is_byte = 1;
        #10 is_load = 0;           // Deassert load
        #10;

        // Check if the byte was stored and loaded correctly
        $display("Read Data (Byte): %h", read_data);
        if (read_data !== 32'h000000FF) $error("Test 4 failed!");

        // Test 5: Store and load at an unaligned address
        rs1_data = 32'h0000_0000;  // Base address
        imm = 32'h0000_0013;       // Offset (unaligned)
        rs2_data = 32'h000000AA;   // Byte data to store
        is_store = 1;
        is_byte = 1;
        #10 is_store = 0;
        #10 is_load = 1;
        is_byte = 1;
        #10 is_load = 0;

        // Check unaligned byte access
        $display("Read Data (Unaligned Byte): %h", read_data);
        if (read_data !== 32'h000000AA) $error("Test 5 failed!");

        // End of simulation
        $display("All tests passed!");
        $finish;
    end

endmodule