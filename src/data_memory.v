module data_memory #( 
    parameter MEM_SIZE_BYTES = 8192,          // memory size (bytes)
    parameter WRITE_LATENCY = 10,            // Write latency (cycles)
    parameter READ_LATENCY = 10             // Read latency (cycles)
    ) (
    input clk,
    input reset_n,
    // write
    input write_enable,
    input [31:0] write_address,
    input [31:0] write_value,
    input store_byte,
    // read
    input load_byte,
    input read_enable,
    input [31:0] read_address,
    output reg [31:0] read_value,
    output reg write_valid,
    output reg read_valid
);

    parameter BYTE_WIDTH = 8;  // 8 bits in a byte     

    // Latency parameters
    parameter WRITE_COUNTER_BITS = $clog2(WRITE_LATENCY);
    parameter READ_COUNTER_BITS = $clog2(READ_LATENCY);

    // Memory array: TOTAL_ADDRESS addresses, each BYTE_WIDTH wide (byte-addressable)
    reg [BYTE_WIDTH-1:0] data_memory [MEM_SIZE_BYTES-1:0];

    // Counters for latency
    reg [WRITE_COUNTER_BITS-1:0] write_counter;
    reg [READ_COUNTER_BITS-1:0] read_counter;

    integer i;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < MEM_SIZE_BYTES; i = i + 1) 
                data_memory[i] <= {BYTE_WIDTH{1'b0}};
            
            write_counter <= {WRITE_COUNTER_BITS{1'b0}}; 
            read_counter <= {READ_COUNTER_BITS{1'b0}};
            write_valid <= 1'b0;
            read_valid <= 1'b0;
            read_value <= 32'd0;
        end
        else begin

            // reset valid bits on next clock cycle
            write_valid <= 1'b0;
            read_valid <= 1'b0;

            if (write_enable) begin
                
                if (write_counter < WRITE_LATENCY-1) begin
                    write_counter <= write_counter + 1;
                end
                // latency finished
                else begin
                    // write one byte of data
                    if (store_byte) begin
                        data_memory[write_address] <= write_value[7:0];
                    end
                    else begin
                        // write four bytes of data
                        data_memory[write_address + 0] <= write_value[7:0];
                        data_memory[write_address + 1] <= write_value[15:8];
                        data_memory[write_address + 2] <= write_value[23:16];
                        data_memory[write_address + 3] <= write_value[31:24];
                    end
                    write_valid <= 1'b1;
                    write_counter <= 0;
                end
            end
            else if (read_enable) begin
                
                if (read_counter < READ_LATENCY-1) begin
                    read_counter <= read_counter + 1;
                end
                else begin
                    if (load_byte) begin
                        read_value <= { 24'b0, data_memory[read_address] };
                    end
                    else begin
                        read_value[7:0] <= data_memory[read_address + 0];
                        read_value[15:8] <= data_memory[read_address + 1];
                        read_value[23:16] <= data_memory[read_address + 2];
                        read_value[31:24] <= data_memory[read_address + 3];
                    end
                    read_valid <= 1'b1;
                    read_counter <= 0;
                end
            end
        end
    end

endmodule