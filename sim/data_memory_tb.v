`include "/home/mark/Documents/workspace/Out-of-Order-CPU/src/data_memory.v" 

module data_memory_tb;

    // Design note: when you make things parameterizable testing gets easier (eg: 32 bytes of memory vs 1MB)

    // Parameters
    parameter MEM_SIZE_BYTES = 32;
    parameter WRITE_LATENCY = 10;          
    parameter READ_LATENCY = 10;

    // Testbench signals
    reg clk;
    reg reset_n;
    reg write_enable;
    reg [31:0] write_address;
    reg [31:0] write_value;
    reg store_byte;
    reg load_byte;
    reg read_enable;
    reg [31:0] read_address;
    wire [31:0] read_value;
    wire write_valid;
    wire read_valid;

    // DUT instantiation
    data_memory #(
        .MEM_SIZE_BYTES(MEM_SIZE_BYTES),
        .WRITE_LATENCY(WRITE_LATENCY),
        .READ_LATENCY(READ_LATENCY)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_value(write_value),
        .store_byte(store_byte),
        .load_byte(load_byte),
        .read_enable(read_enable),
        .read_address(read_address),
        .read_value(read_value),
        .write_valid(write_valid),
        .read_valid(read_valid)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns period

    // Test sequence
    initial begin
        // Initialize signals
        reset_n = 0;
        write_enable = 0;
        write_address = 0;
        write_value = 0;
        store_byte = 0;
        read_enable = 0;
        read_address = 0;
        load_byte = 0;

        // Apply reset
        #10 reset_n = 1;

        // Test write operation (4-byte store)
        write_enable = 1;
        write_address = 32'h00000010; // 16 in decimal
        write_value = 32'hDEADBEEF;
        store_byte = 0;
        #100;
        write_enable = 0;

        read_enable = 1;
        read_address = 32'h00000010; // 16 in decimal
        load_byte = 0;
        #100;
        read_enable = 0;

        read_enable = 1;
        read_address = 32'h00000012; // 16 in decimal
        load_byte = 1;
        #100;
        read_enable = 0;

        #10;

        $finish();

    end


endmodule