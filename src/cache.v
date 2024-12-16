module cache #(
    parameter CACHE_SIZE = 32768, // Cache size in bytes (32KB)
    parameter BLOCK_SIZE = 32,    // Block size in bytes
    parameter WAYS = 4,           // 4-way set associative
    parameter WRITE_LATENCY = 1,
    parameter READ_LATENCY = 1
) (
    input clk,
    input reset_n,
    input read_enable,
    input write_enable,
    input [31:0] address,
    input [31:0] write_value,
    output reg [31:0] read_value,
    output reg hit,
    output reg valid,

    // Memory interface
    output reg mem_read_enable,
    output reg mem_write_enable,
    output reg [31:0] mem_address,
    output reg [31:0] mem_write_value,
    input [31:0] mem_read_value,
    input mem_valid
);

    // Cache parameters
    localparam NUM_SETS = CACHE_SIZE / (WAYS * BLOCK_SIZE);
    localparam OFFSET_BITS = $clog2(BLOCK_SIZE);
    localparam INDEX_BITS = $clog2(NUM_SETS);
    localparam TAG_BITS = 32 - OFFSET_BITS - INDEX_BITS;

    // Cache storage and metadata
    reg [31:0] cache_data[WAYS-1:0][NUM_SETS-1:0][BLOCK_SIZE/4-1:0];
    reg [TAG_BITS-1:0] tags[WAYS-1:0][NUM_SETS-1:0];
    reg valid_bits[WAYS-1:0][NUM_SETS-1:0];
    reg lru[WAYS-1:0][NUM_SETS-1:0];

    // Address decoding
    wire [TAG_BITS-1:0] tag = address[31:32-TAG_BITS];
    wire [INDEX_BITS-1:0] index = address[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [OFFSET_BITS-1:0] offset = address[OFFSET_BITS-1:0];

    integer i, j;
	 integer replace_way;

    // Main logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset all metadata
            for (i = 0; i < WAYS; i = i + 1) begin
                for (j = 0; j < NUM_SETS; j = j + 1) begin
                    valid_bits[i][j] <= 0;
                    lru[i][j] <= 0;
                end
            end
            valid <= 0;
            hit <= 0;
            mem_read_enable <= 0;
            mem_write_enable <= 0;
        end else begin
            hit <= 0;
            valid <= 0;
            mem_read_enable <= 0;
            mem_write_enable <= 0;

            // Check for cache hit
            for (i = 0; i < WAYS; i = i + 1) begin
                if (valid_bits[i][index] && tags[i][index] == tag) begin
                    hit <= 1;
                    valid <= 1;

                    // Read from cache
                    if (read_enable) begin
                        read_value <= cache_data[i][index][offset / 4];
                    end

                    // Write to cache
                    if (write_enable) begin
                        cache_data[i][index][offset / 4] <= write_value;
                    end

                    // Update LRU
                    lru[i][index] <= 1;
                end
            end

            // Handle cache miss
            if (!hit && (read_enable || write_enable)) begin
                // Find a replacement way using pseudo-LRU
                replace_way = -1;
                for (i = 0; i < WAYS; i = i + 1) begin
                    if (replace_way == -1 && !valid_bits[i][index] || !lru[i][index]) begin
                        replace_way = i;
                    end
                end

                // If no invalid or LRU way, reset LRU and select first way
                if (replace_way == -1) begin
                    for (i = 0; i < WAYS; i = i + 1) begin
                        lru[i][index] <= 0;
                    end
                    replace_way = 0;
                end

                // Handle memory fetch
                if (read_enable) begin
                    mem_read_enable <= 1;
                    mem_address <= {tag, index, offset};
                    if (mem_valid) begin
                        cache_data[replace_way][index][offset / 4] <= mem_read_value;
                        tags[replace_way][index] <= tag;
                        valid_bits[replace_way][index] <= 1;
                        lru[replace_way][index] <= 1;
                        read_value <= mem_read_value;
                        valid <= 1;
                    end
                end

                // Handle memory write
                if (write_enable) begin
                    mem_write_enable <= 1;
                    mem_address <= {tag, index, offset};
                    mem_write_value <= write_value;
                end
            end
        end
    end
endmodule