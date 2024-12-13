`timescale 1ns/1ps

module cache_tb();

    // Parameters for test
    localparam CACHE_SIZE_BYTES = 1024;
    localparam LINE_SIZE = 4;

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

    // Memory interface
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
    cache #(
        .CACHE_SIZE_BYTES(CACHE_SIZE_BYTES),
        .LINE_SIZE(LINE_SIZE)
    ) dut (
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

    // Simple model of memory (backing store)
    // This will simulate the data memory that the cache talks to
    localparam MEM_SIZE = 8192;
    reg [31:0] backing_memory[0:(MEM_SIZE/4)-1];

    // initialize backing memory
    initial begin
        integer i;
        for(i=0; i<(MEM_SIZE/4); i=i+1) begin
            backing_memory[i] = 32'hdeadbeef + i; // just some pattern
        end
    end

    // Memory response logic
    // When mem_read_enable is asserted, after some delay, set mem_read_valid and return data
    // When mem_write_enable is asserted, after some delay, set mem_write_valid
    // Add some artificial latency
    logic [2:0] mem_latency_counter;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            mem_read_valid <= 1'b0;
            mem_write_valid <= 1'b0;
            mem_latency_counter <= 3'd0;
        end else begin
            // Default, no response
            mem_read_valid <= 1'b0;
            mem_write_valid <= 1'b0;

            if (mem_read_enable) begin
                if (mem_latency_counter < 3) begin
                    mem_latency_counter <= mem_latency_counter + 1;
                end else begin
                    mem_latency_counter <= 3'd0;
                    // Return data from memory
                    mem_read_data <= backing_memory[mem_address[31:2]];
                    mem_read_valid <= 1'b1;
                end
            end else if (mem_write_enable) begin
                if (mem_latency_counter < 3) begin
                    mem_latency_counter <= mem_latency_counter + 1;
                end else begin
                    mem_latency_counter <= 3'd0;
                    // Write to memory
                    if (mem_store_byte) begin
                        // Just write the relevant byte
                        reg [31:0] temp_word = backing_memory[mem_address[31:2]];
                        case (mem_address[1:0])
                            2'b00: temp_word[7:0]   = mem_write_data[7:0];
                            2'b01: temp_word[15:8]  = mem_write_data[7:0];
                            2'b10: temp_word[23:16] = mem_write_data[7:0];
                            2'b11: temp_word[31:24] = mem_write_data[7:0];
                        endcase
                        backing_memory[mem_address[31:2]] = temp_word;
                    end else begin
                        backing_memory[mem_address[31:2]] = mem_write_data;
                    end
                    mem_write_valid <= 1'b1;
                end
            end else begin
                mem_latency_counter <= 3'd0;
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
        reset_n = 0; read_enable = 0; write_enable = 0; address = 32'd0; store_byte = 0; load_byte = 0;
        write_data = 32'd0;
        @(posedge clk);
        reset_n = 1;

        // Wait one cycle after reset
        @(posedge clk);

        // Test 1: Load from address 0 (expect a miss)
        $display("TEST 1: LOAD MISS at address 0");
        load_byte = 0;
        read_enable = 1; write_enable = 0; address = 32'd0;
        @(posedge clk);
        read_enable = 0; // remove after one cycle
        // Wait until read_valid
        wait(read_valid);
        $display("Data returned: %h (expected %h)", read_data, backing_memory[0]);

        // Test 2: Load from address 0 again (expect a hit now)
        $display("TEST 2: LOAD HIT at address 0");
        @(posedge clk);
        read_enable = 1; address = 32'd0;
        @(posedge clk);
        read_enable = 0;
        // should be immediate hit this time (or at least next cycle without memory access)
        wait(read_valid);
        $display("Data returned: %h (expected %h)", read_data, backing_memory[0]);

        // Test 3: Store to address 4 (not in cache, write miss)
        // Our policy: no-write-allocate, so it should just write through
        $display("TEST 3: STORE MISS at address 4");
        @(posedge clk);
        write_enable = 1; write_data = 32'h12345678; address = 32'd4; store_byte = 0; load_byte = 0;
        @(posedge clk);
        write_enable = 0;
        wait(write_valid);
        $display("Store complete. Memory at 4: %h (expected 12345678)", backing_memory[1]);

        // Test 4: Load from address 4 (should be miss, then load new data)
        $display("TEST 4: LOAD MISS at address 4");
        @(posedge clk);
        read_enable = 1; address = 32'd4;
        @(posedge clk);
        read_enable = 0;
        wait(read_valid);
        $display("Data returned: %h (expected %h)", read_data, backing_memory[1]);

        // End of tests
        $display("All tests completed.");
        $stop;
    end

endmodule