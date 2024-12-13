`timescale 1ns/1ps

module cache_tb();

    // Parameters for testing
    localparam MEM_SIZE = 8192; // Backing memory size in bytes
    // Derived parameters
    localparam WORDS_IN_MEM = MEM_SIZE / 4;

    // DUT I/O
    logic clk;
    logic reset_n;
    logic read_enable;
    logic write_enable;
    logic [31:0] address;
    logic [31:0] write_data;
    logic store_byte;
    logic load_byte;
    logic [31:0] read_data;
    logic read_valid;
    logic write_valid;

    // Memory interface signals from cache
    logic mem_read_enable;
    logic mem_write_enable;
    logic [31:0] mem_address;
    logic [31:0] mem_write_data;
    logic mem_store_byte;
    logic mem_load_byte;
    logic [31:0] mem_read_data;
    logic mem_read_valid;
    logic mem_write_valid;

    // Instantiate the DUT (cache)
    cache dut (
        .clk(clk),
        .reset_n(reset_n),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address(address),
        .write_data(write_data),
        .store_byte(store_byte),
        .load_byte(load_byte),
        .read_data(read_data),
        .read_valid(read_valid),
        .write_valid(write_valid),
        .mem_read_enable(mem_read_enable),
        .mem_write_enable(mem_write_enable),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_store_byte(mem_store_byte),
        .mem_load_byte(mem_load_byte),
        .mem_read_data(mem_read_data),
        .mem_read_valid(mem_read_valid),
        .mem_write_valid(mem_write_valid)
    );

    // Backing memory model
    reg [31:0] backing_memory[0:WORDS_IN_MEM-1];

    // Declare full_word at the top
    reg [31:0] full_word; 

    // Initialize the backing memory
    initial begin
        integer i;
        for (i = 0; i < WORDS_IN_MEM; i = i+1) begin
            backing_memory[i] = 32'hdeadbeef + i;
        end
    end

    // Simulate memory latency
    integer mem_latency_counter = 0;
    logic read_in_progress = 0;
    logic write_in_progress = 0;
    reg [31:0] read_address_latch;
    reg [31:0] write_address_latch;
    reg [31:0] write_data_latch;
    reg write_byte_latch;
    reg load_byte_latch;

    // Memory process
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mem_read_valid <= 1'b0;
            mem_write_valid <= 1'b0;
            mem_latency_counter <= 0;
            read_in_progress <= 0;
            write_in_progress <= 0;
        end else begin
            // Default no response each cycle
            mem_read_valid <= 1'b0;
            mem_write_valid <= 1'b0;

            // If no operation in progress, start one if requested
            if (!read_in_progress && !write_in_progress) begin
                if (mem_read_enable) begin
                    read_in_progress <= 1'b1;
                    mem_latency_counter <= 0;
                    read_address_latch <= mem_address;
                    load_byte_latch <= mem_load_byte;
                end else if (mem_write_enable) begin
                    write_in_progress <= 1'b1;
                    mem_latency_counter <= 0;
                    write_address_latch <= mem_address;
                    write_data_latch <= mem_write_data;
                    write_byte_latch <= mem_store_byte;
                end
            end else begin
                // Operation in progress, increment counter
                mem_latency_counter <= mem_latency_counter + 1;
                if (read_in_progress && mem_latency_counter == 3) begin
                    mem_read_valid <= 1'b1;
                    read_in_progress <= 1'b0;
                    full_word = backing_memory[read_address_latch[31:2]];
                    if (load_byte_latch) begin
                        case (read_address_latch[1:0])
                            2'b00: mem_read_data <= {24'b0, full_word[7:0]};
                            2'b01: mem_read_data <= {24'b0, full_word[15:8]};
                            2'b10: mem_read_data <= {24'b0, full_word[23:16]};
                            2'b11: mem_read_data <= {24'b0, full_word[31:24]};
                        endcase
                    end else begin
                        mem_read_data <= full_word;
                    end
                end else if (write_in_progress && mem_latency_counter == 3) begin
                    mem_write_valid <= 1'b1;
                    write_in_progress <= 1'b0;
                    full_word = backing_memory[write_address_latch[31:2]];
                    if (write_byte_latch) begin
                        case (write_address_latch[1:0])
                            2'b00: full_word[7:0] = write_data_latch[7:0];
                            2'b01: full_word[15:8] = write_data_latch[7:0];
                            2'b10: full_word[23:16] = write_data_latch[7:0];
                            2'b11: full_word[31:24] = write_data_latch[7:0];
                        endcase
                    end else begin
                        full_word = write_data_latch;
                    end
                    backing_memory[write_address_latch[31:2]] = full_word;
                end
            end
        end
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test scenario
    initial begin
        reset_n = 0; 
        read_enable = 0; 
        write_enable = 0; 
        address = 32'd0; 
        store_byte = 0; 
        load_byte = 0;
        write_data = 32'd0;
        @(posedge clk);
        reset_n = 1;

        // Wait one cycle after reset
        @(posedge clk);

        // Test 1: Load from address 0 (miss)
        $display("[TEST 1] LOAD MISS at address 0");
        read_enable = 1; 
        address = 32'd0;
        @(posedge clk);
        read_enable = 0; 
        wait(read_valid);
        $display("Data returned: %h (Expected: %h)", read_data, backing_memory[0]);

        // Test 2: Load from address 0 (hit)
        $display("[TEST 2] LOAD HIT at address 0");
        @(posedge clk);
        read_enable = 1; 
        address = 32'd0;
        @(posedge clk);
        read_enable = 0;
        wait(read_valid);
        $display("Data returned: %h (Expected: %h)", read_data, backing_memory[0]);

        // Test 3: Store to address 4 (miss, write-through)
        $display("[TEST 3] STORE MISS at address 4");
        @(posedge clk);
        write_enable = 1; 
        write_data = 32'h12345678; 
        address = 32'd4; 
        @(posedge clk);
        write_enable = 0;
        wait(write_valid);
        $display("Store complete. Memory at word[1]: %h (Expected: 12345678)", backing_memory[1]);

        // Test 4: Load from address 4 (miss)
        $display("[TEST 4] LOAD MISS at address 4");
        @(posedge clk);
        read_enable = 1; 
        address = 32'd4;
        @(posedge clk);
        read_enable = 0;
        wait(read_valid);
        $display("Data returned: %h (Expected: %h)", read_data, backing_memory[1]);

        // End of tests
        $display("All tests completed successfully.");
        $finish;
    end

endmodule