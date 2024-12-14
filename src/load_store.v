module load_store_unit (
    input clk,
    input reset_n,

    input load_store_enable,
    input [1:0] instruction_type,
    input [5:0] phys_rd,
    input [5:0] rob_entry,

    input load_store_enable_funct0,
    input [31:0] address_funct0,
    input [31:0] value_funct0,
    input [5:0] ROB_entry_num_funct0, // 00:LW 01:LB 10: SW 11:SB

    input load_store_enable_funct1,
    input [31:0] address_funct1,
    input [31:0] value_funct1,
    input [5:0] ROB_entry_num_funct1,

    input load_store_enable_funct2,
    input [31:0] address_funct2,
    input [31:0] value_funct2,
    input [5:0] ROB_entry_num_funct2,

    // wake up issue queue
    output reg fwd_enable,
    output reg [5:0] fwd_phys_rd,
    output reg [31:0] fwd_value,

    // ROB
    output reg enable_ROB,
    output reg [31:0] value
);
    // memory parameters
    parameter MEM_SIZE_BYTES = 8192;
    parameter WRITE_LATENCY = 10;
    parameter READ_LATENCY = 10;

    parameter LOAD_WORD = 2'b00;
    parameter LOAD_BYTE = 2'b01;
    parameter STORE_WORD = 2'b10;
    parameter STORE_BYTE = 2'b11;

    // load store queue parameters
    parameter NUM_INSTRUCTIONS = 16; 
    parameter ENTRY_SIZE = 78;
    parameter INVALID_ADDRESS = {32{1'b1}};
    parameter INVALID_VALUE = {32{1'b1}};
    parameter INVALID_ENTRY = 6'b111111;
    parameter LSQ_INDEX_BITS = $clog2(NUM_INSTRUCTIONS);

    // load store queue
    reg [NUM_INSTRUCTIONS-1:0] load_store_queue [ENTRY_SIZE-1:0];
    reg [NUM_INSTRUCTIONS-1:0] load_store_ready;
    reg [LSQ_INDEX_BITS-1:0] new_entry;
    reg [LSQ_INDEX_BITS-1:0] head_entry;

    // Memory 
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

    reg mem_op_in_progress;

    // Memory Instantiation
    data_memory #(
        .MEM_SIZE_BYTES(MEM_SIZE_BYTES),
        .WRITE_LATENCY(WRITE_LATENCY),
        .READ_LATENCY(READ_LATENCY)
    ) memory (
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

    // load store queue
    reg [LSQ_INDEX_BITS-1:0] LSQ_entry0, LSQ_entry1, LSQ_entry2;
    reg [NUM_INSTRUCTIONS-1:0] load_store_ready_comb;
    reg LSQ_found;
    reg [LSQ_INDEX_BITS-1:0] LSQ_found_index;
    integer i;

    // combination logic to match correct load store queue entry to address computed by the functional unit
    always @(*) begin

        LSQ_entry0 = INVALID_ENTRY;
        LSQ_entry1 = INVALID_ENTRY;
        LSQ_entry2 = INVALID_ENTRY;

        load_store_ready_comb = load_store_ready;

        if (load_store_enable_funct0) begin
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                if (load_store_queue[i][75:70] == ROB_entry_num_funct0) begin
                    LSQ_entry0 = i;
                    load_store_ready_comb[i] = 1'b1;
                end
            end
        end

        if (load_store_enable_funct1) begin
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                if (load_store_queue[i][75:70] == ROB_entry_num_funct1) begin
                    LSQ_entry1 = i;
                    load_store_ready_comb[i] = 1'b1;
                end
            end
        end

        if (load_store_enable_funct2) begin
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                if (load_store_queue[i][75:70] == ROB_entry_num_funct2) begin
                    LSQ_entry2 = i;
                    load_store_ready_comb[i] = 1'b1;
                end
            end
        end
    end

    integer current_index;
    // forward from LSQ or memory
    always @(*) begin
        // flag set high if found in the load store queue
        LSQ_found = 1'b0;
        LSQ_found_index = INVALID_ENTRY;

        // iterator starts at most recent entry in the load store queue
        current_index = (new_entry == 0) ? NUM_INSTRUCTIONS-1 : new_entry -1;

        if (load_store_ready[head_entry] == 1'b1) begin
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                if (load_store_queue[head_entry][77] == 1'b1 && load_store_queue[head_entry][63:32] == load_store_queue[current_index][63:32] && !LSQ_found) begin
                    LSQ_found = 1'b1;
                    LSQ_found_index = current_index;
                end
            // wrap around when at 0
            current_index = (current_index == 0) ? NUM_INSTRUCTIONS -1: current_index-1;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                load_store_queue[i] <= { ENTRY_SIZE{1'b0} };
            end

            load_store_ready <= { NUM_INSTRUCTIONS{1'b0} };
            new_entry <= { LSQ_INDEX_BITS{1'b0}};
            head_entry <= { LSQ_INDEX_BITS{1'b0}};

            mem_op_in_progress <= 1'b0;
            write_enable <= 1'b0;
            write_address <= 32'd0;
            write_value <= 32'd0;
            store_byte <= 1'b0;
            load_byte <= 1'b0;
            read_enable <= 1'b0;
            read_address <= 32'd0;
        end
        else begin

            // create entry from decoded instruction
            if (load_store_enable) begin
                
                // create entry on decode but wait for computed offset
                load_store_queue[new_entry] <= {
                    instruction_type,
                    phys_rd,
                    rob_entry,
                    64'b0
                };
                // set entry next in queue
                new_entry <= new_entry + 1;
            end

            // update issue queue entry with address computed and value
            if (load_store_enable_funct0) begin
                load_store_queue[LSQ_entry0][63:0] <= {address_funct0, value_funct0};
                load_store_ready[LSQ_entry0] <= 1'b1;
            end
            if (load_store_enable_funct1) begin
                load_store_queue[LSQ_entry1][63:0] <= {address_funct1, value_funct1};
                load_store_ready[LSQ_entry1] <= 1'b1;
            end
            if (load_store_enable_funct2) begin
                load_store_queue[LSQ_entry2][63:0] <= {address_funct2, value_funct2};
                load_store_ready[LSQ_entry2] <= 1'b1;
            end

            // clear fwd_enable
            fwd_enable <= 1'b0;

            // handle memory reads and writes 
            if (load_store_ready[head_entry] == 1'b1) begin
                case (load_store_queue[head_entry][77:76])
                    LOAD_WORD : 
                    begin
                        if (LSQ_found) begin
                            fwd_enable <= 1'b1;
                            fwd_phys_rd <= load_store_queue[LSQ_found_index][75:70];
                            fwd_value <= load_store_queue[LSQ_found_index][31:0];
                        end 
                        // load word from memory (10 cycles)
                        else if (!mem_op_in_progress) begin
                            mem_op_in_progress <= 1'b1;
                            
                            read_enable <= 1'b1;
                            read_address <= load_store_queue[head_entry][63:32];
                            load_byte <= 1'b0; // load word
                        end        
                        else if (read_valid) begin
                            mem_op_in_progress <= 1'b0; // finish mem op
                            read_enable <= 1'b0;

                            // forward value
                            fwd_enable <= 1'b1;
                            fwd_phys_rd <= load_store_queue[head_entry][75:70];
                            fwd_value <= read_value;

                            // enable rob: TODO: make sure it works
                            enable <= 1'b1;
                            value <= read_value;
                            head_entry <= (head_entry + 1) % NUM_INSTRUCTIONS;
                        end
                    end
                    LOAD_BYTE : 
                    begin
                        if (LSQ_found) begin
                            fwd_enable <= 1'b1;
                            fwd_phys_rd <= load_store_queue[LSQ_found_index][75:70];
                            fwd_value <= { 24'b0, load_store_queue[LSQ_found_index][7:0]};
                        end
                        // load byte from memory
                        else if (!mem_op_in_progress) begin
                            mem_op_in_progress <= 1'b1;
                            
                            read_enable <= 1'b1;
                            read_address <= load_store_queue[head_entry][63:32];
                            load_byte <= 1'b1; // load byte
                        end        
                        else if (read_valid) begin
                            mem_op_in_progress <= 1'b0; // finish mem op
                            read_enable <= 1'b0;

                            // forward value
                            fwd_enable <= 1'b1;
                            fwd_phys_rd <= load_store_queue[head_entry][75:70];
                            fwd_value <= { 24'b0, read_value[7:0] };

                            head_entry <= (head_entry + 1) % NUM_INSTRUCTIONS;
                        end 
                    end
                    STORE_WORD :
                    begin
                        // writes always go to memory
                        if (!mem_op_in_progress) begin
                            mem_op_in_progress <= 1'b1;
                            write_enable <= 1'b1;
                            write_address <= load_store_queue[head_entry][63:32];
                            write_value <= load_store_queue[head_entry][31:0];
                            store_byte <= 1'b0; // Store word
                        end
                        else if (write_valid) begin    
                            mem_op_in_progress <= 1'b0;
                            head_entry <= (head_entry + 1) % NUM_INSTRUCTIONS;
                        end
                    end
                    STORE_BYTE :
                    begin
                        if (!mem_op_in_progress) begin
                            mem_op_in_progress <= 1'b1;
                            write_enable <= 1'b1;
                            write_address <= load_store_queue[head_entry][63:32];
                            write_value <= { 24'b0, load_store_queue[head_entry][7:0]};
                            store_byte <= 1'b1; // Store byte
                        end
                        else if (write_valid) begin
                            mem_op_in_progress <= 1'b0;
                            head_entry <= (head_entry + 1) % NUM_INSTRUCTIONS;
                        end
                    end
                endcase
            end
        end
    end

endmodule

/*
loads:
- look at stores in lsq first and then check from memory
- check if the address is the same to check if you can forward from

stores


load_store_queue:

    store / load bit (2 bit) | phys_rd (6 bits) | rob_entry (6 bits) | address (32 bits) | value (32 bits)
lsq:
    store / load : 77:76
    phys_rd : 75:70
    rob_entry : 69:64
    address : 63:32
    value : 31:0

*/