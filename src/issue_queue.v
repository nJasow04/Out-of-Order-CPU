// TODO: read from reg file @ rising edge and set write enable high for that CC
module issue_queue (
    input clk,
    input reset_n,
    input write_enable, // reg read valid
    
    // rename stage: source and destination regs
    input [5:0]  phys_rd,
    input [5:0]  phys_rs1,
    input [31:0] phys_rs1_val,
    input [5:0]  phys_rs2,
    input [31:0] phys_rs2_val,
    input [6:0]  opcode,
    input [31:0] immediate,
    input [5:0]  ROB_entry_index,

    // execute stage: forward and funct unit available
    input [5:0]  fwd_rd,
    input [31:0] fwd_rd_val,

    output reg [129-1:0] issued_instruction,
    output reg issue_valid,
    output issue_queue_full
);
    // Issue Queue constants
    parameter NUM_FUNCTIONAL_UNITS = 3;
    parameter NUM_PHYSICAL_REGS = 64;
    parameter NUM_INSTRUCTIONS = 64;
    parameter IQ_INDEX_BITS = $clog2(NUM_INSTRUCTIONS);
    
    parameter ENTRY_SIZE = 129;
    parameter INVALID_ENTRY = 6'b111111;
    parameter INVALID_ISSUE_QUEUE_ENTRY = 6'd0;

    // Register and Functional Unit scoreboards - 1: available 0: unavailable
    reg [NUM_PHYSICAL_REGS-1:0] register_file_scoreboard; 
    reg [NUM_FUNCTIONAL_UNITS-1:0] funct_unit_scoreboard;

    // Issue queue: holds up to 64 instructions - see below more details
    reg [ENTRY_SIZE-1:0] issue_queue [NUM_INSTRUCTIONS-1:0];
    
    // Issue queue free list and ready lists
    reg [NUM_INSTRUCTIONS-1:0] use_bits; 
    reg [NUM_INSTRUCTIONS-1:0] src1_ready; 
    reg [NUM_INSTRUCTIONS-1:0] src2_ready; 

    // Free Entry and round robin FU counter
    reg [IQ_INDEX_BITS-1:0] free_entry;
    reg [1:0] FU_count;

    integer i;

    // issue queue full logic
    assign issue_queue_full = (free_entry == INVALID_ENTRY);

    // update combinationally 
    always @(*) begin

        // Defaults to prevent inferred latches
        free_entry = INVALID_ENTRY;
        // issue_valid = 1'b0;
        // issued_instruction = {ENTRY_SIZE{1'b0}};

        // Find the first free entry
        for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
            if (use_bits[i] == 1'b0 && free_entry == INVALID_ENTRY) begin
                free_entry = i[5:0];
            end
        end

        if (write_enable && free_entry != INVALID_ENTRY) begin
            // Ready bits update (only update separate ready table)
            //src1_ready[free_entry] = register_file_scoreboard[phys_rs1];
            //src2_ready[free_entry] = register_file_scoreboard[phys_rs2];
            // use_bits[free_entry] = 1'b1;
            // issue_valid = 1'b1; 
        end

        // FORWARD LOGIC 
        // for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
        //     // rs1 forward
        //     if (issue_queue[i][115:110] == fwd_rd) begin
        //         issue_queue[i][109:78] = fwd_rd_val;
        //         src1_ready[i] = 1'b1;
        //     end
        //     // rs2 forward
        //     if (issue_queue[i][77:72] == fwd_rd) begin
        //         issue_queue[i][71:40] = fwd_rd_val;
        //         src2_ready[i] = 1'b1;
        //     end
        // end
    end

    // reset and update
    always @(posedge clk or negedge reset_n) begin
        
        if (!reset_n) begin
            // Reset all logic
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                issue_queue[i] <= {ENTRY_SIZE{1'b0}};
            end
            register_file_scoreboard <= {NUM_PHYSICAL_REGS{1'b1}};
            funct_unit_scoreboard <= {NUM_FUNCTIONAL_UNITS{1'b1}};
            use_bits <= {NUM_INSTRUCTIONS{1'b0}};
            src1_ready <= {NUM_INSTRUCTIONS{1'b0}};
            src2_ready <= {NUM_INSTRUCTIONS{1'b0}};
            FU_count <= 2'b0;
            issue_valid <= 1'b0;

        end else begin
            // Round-robin logic
            if (write_enable && free_entry != INVALID_ENTRY) begin
                FU_count <= (FU_count + 1) % NUM_FUNCTIONAL_UNITS;

                // Write to issue queue
                issue_queue[free_entry] <= {
                    opcode, phys_rd, phys_rs1, phys_rs1_val,
                    phys_rs2, phys_rs2_val, immediate,
                    ROB_entry_index, FU_count
                };
                use_bits[free_entry] <= 1'b1;
            end

            // // Issue logic
            // for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
            //     if (src1_ready[i] && src2_ready[i] && funct_unit_scoreboard[issue_queue[i][1:0]]) begin
            //         use_bits[i] <= 1'b0;
            //         issue_valid <= 1'b1;
            //         funct_unit_scoreboard[issue_queue[i][1:0]] <= 1'b0;
            //         issued_instruction <= issue_queue[i];
            //     end
            // end
        end 

    end 


endmodule

/*

Issue Queue Format: 64 instructions with 129 bits per entry

opcode (7-bits) | dest reg (6 bits) | src 1 reg (6 bits) | src 1 val (32 bits) | 
src 2 reg (6 bits) | src 2 val (32 bits) | immediate (32-bits) | 
ROB entry (6-bits) | functional unit (2-bits)

Note: I opted to put use bit in a different container to simplify the logic and make lookups faster

$clog2: calculates ceiling log based 2 function 
*/