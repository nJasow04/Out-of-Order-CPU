module load_store_unit (
    input clk,
    input reset_n,
    input load_store_enable,
    input [31:0] address,
    input [31:0] value,
    input [1:0] instruction_type, // 00: LW 01: LB 10: SW 11: SB

    // forwarding
    input [31:0] forward_address,
    output [31:0] forward_value,
    output forward_valid
);
    // memory parameters
    parameter MEM_SIZE_BYTES = 8192;
    parameter WRITE_LATENCY = 10;
    parameter READ_LATENCY = 10;

    // load store queue parameters
    parameter NUM_INSTRUCTIONS = 16; 
    parameter ENTRY_SIZE = 66;

    parameter INVALID_ENTRY = 4'b1111;

    // load store queue
    reg [NUM_INSTRUCTIONS-1] load_store_queue [ENTRY_SIZE-1];
    
    
    // forwarding
    reg [3:0] forward_entry;
    assign forward_valid = (forward_entry == INVALID_ENTRY) ? 1'b0 : 1'b1;

    // memory 

    // Memory Instantiation
    data_memory #(
        .MEM_SIZE_BYTES(MEM_SIZE_BYTES),
        .WRITE_LATENCY(WRITE_LATENCY),
        .READ_LATENCY(READ_LATENCY)
    ) memory (
        .clk(clk),
        .reset_n(reset_n),
        .write_enable(),
        .write_address(),
        .write_value(),
        .store_byte(),
        .load_byte(),
        .read_enable(),
        .read_address(),
        .read_value(),
        .write_valid),
        .read_valid()
    );

    // forward entry logic
    always @(*) begin

        forward_entry = INVALID_ENTRY;
        forward_value = 32'd0;

        // Priority encoder to find first entry
        for (i = NUM_INSTRUCTIONS-1; i >= 0; i = i - 1) begin
            if (load_store_queue[i][[63:32]] == forward_address && forward_entry == INVALID_ENTRY) begin
                forward_entry = i;
                forward_value = load_store_queue[i][31:0];
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            
        end
        else begin
            
        end
    end


    
endmodule