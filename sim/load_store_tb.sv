`include "/home/mark/Documents/workspace/Out-of-Order-CPU/src/load_store.v"

module lsq_tb;

    // Parameters (adjust based on your module's requirements)
    parameter MEM_SIZE_BYTES = 64;
    parameter WRITE_LATENCY = 10;
    parameter READ_LATENCY = 10;

    // Signals for the DUT
    reg clk;
    reg reset_n;

    // Inputs to DUT
    reg load_store_enable;
    reg [1:0] instruction_type;
    reg [5:0] phys_rd;
    reg [5:0] rob_entry;

    reg load_store_enable_funct0;
    reg [31:0] address_funct0;
    reg [31:0] value_funct0;
    reg [5:0] ROB_entry_num_funct0;

    reg load_store_enable_funct1;
    reg [31:0] address_funct1;
    reg [31:0] value_funct1;
    reg [5:0] ROB_entry_num_funct1;

    reg load_store_enable_funct2;
    reg [31:0] address_funct2;
    reg [31:0] value_funct2;
    reg [5:0] ROB_entry_num_funct2;

    // Outputs from DUT
    wire fwd_enable;
    wire [5:0] fwd_phys_rd;
    wire [31:0] fwd_value;
    
    wire enable_ROB;
    wire [31:0] value;

    // DUT instantiation
    load_store_unit dut (
        .clk(clk),
        .reset_n(reset_n),

        .load_store_enable(load_store_enable),
        .instruction_type(instruction_type),
        .phys_rd(phys_rd),
        .rob_entry(rob_entry),

        .load_store_enable_funct0(load_store_enable_funct0),
        .address_funct0(address_funct0),
        .value_funct0(value_funct0),
        .ROB_entry_num_funct0(ROB_entry_num_funct0),

        .load_store_enable_funct1(load_store_enable_funct1),
        .address_funct1(address_funct1),
        .value_funct1(value_funct1),
        .ROB_entry_num_funct1(ROB_entry_num_funct1),

        .load_store_enable_funct2(load_store_enable_funct2),
        .address_funct2(address_funct2),
        .value_funct2(value_funct2),
        .ROB_entry_num_funct2(ROB_entry_num_funct2),

        .fwd_enable(fwd_enable),
        .fwd_phys_rd(fwd_phys_rd),
        .fwd_value(fwd_value),

        .enable_ROB(enable_ROB),
        .value(value)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns clock period

    // Test sequence
    initial begin
        // Initialize signals
        reset_n = 0;
        load_store_enable = 0;
        instruction_type = 0;
        phys_rd = 0;
        rob_entry = 0;

        load_store_enable_funct0 = 0;
        address_funct0 = 0;
        value_funct0 = 0;
        ROB_entry_num_funct0 = 0;

        load_store_enable_funct1 = 0;
        address_funct1 = 0;
        value_funct1 = 0;
        ROB_entry_num_funct1 = 0;

        load_store_enable_funct2 = 0;
        address_funct2 = 0;
        value_funct2 = 0;
        ROB_entry_num_funct2 = 0;

        @(posedge clk);
        reset_n = 1;

        // Test case: Functional verification
        @(posedge clk);
        load_store_enable_funct0 = 1;
        address_funct0 = 32'h0000_0004;
        value_funct0 = 32'hAAAA_BBBB;
        ROB_entry_num_funct0 = 6'd1;

        @(posedge clk);
        load_store_enable_funct0 = 0;

        @(posedge clk);
        load_store_enable_funct1 = 1;
        address_funct1 = 32'h0000_0008;
        value_funct1 = 32'hCCCC_DDDD;
        ROB_entry_num_funct1 = 6'd2;

        @(posedge clk);
        load_store_enable_funct1 = 0;

        @(posedge clk);
        load_store_enable_funct2 = 1;
        address_funct2 = 32'h0000_000C;
        value_funct2 = 32'hEEEE_FFFF;
        ROB_entry_num_funct2 = 6'd3;

        @(posedge clk);
        load_store_enable_funct2 = 0;

        // Wait and monitor outputs
        repeat (10) @(posedge clk);

        // Finish simulation
        $finish;
    end

endmodule
