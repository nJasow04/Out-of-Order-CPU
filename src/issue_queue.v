// TODO: read from reg file @ rising edge and set write enable high for that CC
module issue_queue (
    input clk,
    input reset_n,
    input write_enable, // reg read valid
    
    // source and destination regs
    input [5:0]  phys_dest,
    input [5:0]  phys_rs1,
    input [31:0] phys_rs1_val,
    input [5:0]  phys_rs2,
    input [31:0] phys_rs2_val,
    input [6:0]  opcode,
    input [31:0] immediate,
    input [5:0]  ROB_entry_index,

    // forwarded value
    input [31:0] fwd_rs1,
    input [31:0] fwd_rs2,

    output issue_queue_full
);
    // Issue Queue constants
    parameter NUM_FUNCTIONAL_UNITS = 3;
    parameter NUM_PHYSICAL_REGS = 64;
    parameter NUM_INSTRUCTIONS = 64;
    parameter IQ_INDEX_BITS = $clog2(NUM_INSTRUCTIONS);
    parameter ENTRY_SIZE = 131;
    parameter INVALID_ENTRY = 6'b111111;

    // Register and Functional Unit scoreboards - 1: available 0: unavailable
    reg [NUM_PHYSICAL_REGS-1:0] register_file_scoreboard; 
    reg [NUM_FUNCTIONAL_UNITS-1:0] functional_unit_scoreboard;

    // Issue queue: holds up to 64 instructions - see below more details
    reg [ENTRY_SIZE-1:0] issue_queue [NUM_INSTRUCTIONS-1:0];
    
    // Issue queue free list
    reg [NUM_INSTRUCTIONS-1:0] use_bits; 

    // Free Entry and round robin FU counter
    reg [IQ_INDEX_BITS-1:0] free_entry;
    reg [1:0] FU_count;

    integer i;

    // issue queue full logic
    assign issue_queue_full = (free_entry == INVALID_ENTRY) ? 1'b1 : 1'b0;

    // update combinationally 
    always @(*) begin

        free_entry = INVALID_ENTRY;

        for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
            if (use_bits[i] == 1'b0 && free_entry == INVALID_ENTRY) begin
                free_entry = i[5:0];
            end
        end

        // reg file read: sets write_enable for next clock cycle
        if (write_enable) begin

            // create entry
            issue_queue[free_entry] = { 
                opcode, 
                phys_dest,
                phys_rs1, 
                phys_rs1_val,
                register_file_scoreboard[phys_rs1],
                phys_rs2,
                phys_rs2_val,
                register_file_scoreboard[phys_rs2],
                immediate,
                FU_count,
                ROB_entry_index
            };
            
        end
    end

    // reset synchronously
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                issue_queue[i] <= {ENTRY_SIZE {1'b0}};
            end

            register_file_scoreboard <= {NUM_PHYSICAL_REGS {1'b1}};
            functional_unit_scoreboard <= {NUM_FUNCTIONAL_UNITS {1'b1}};  
            use_bits <= {NUM_INSTRUCTIONS {1'b0}};
            FU_count <= 2'b0;
        end 
        // round robin counter 
        else if (write_enable && !issue_queue_full) begin
            FU_count <= (FU_count + 1) % NUM_FUNCTIONAL_UNITS;
            use_bits[free_entry] <= 1; // set use bit
        end 
        // issue logic
        else begin
            /* TODO: I can create a seperate reg: like use_bits
                for each reg ready and search for first three instruction
                with both registers ready

                When issuing: mark regs are busy and functional unit as used
                    - issue at each clock cycle
                    - handle forwarding instructions (deal with this first before issue)
            */
        end
    end 


    // TODO: handle issue logic

endmodule

/*

Issue Queue Format: 64 instructions with 131 bits per entry

opcode (7-bits) | dest reg (6 bits) | src 1 reg (6 bits) | src 1 val (32 bits) | 
src 1 ready (1-bit) | src 2 reg (6 bits) | src 2 val (32 bits) | src 2 ready (1-bit) |
immediate (32-bits) | functional unit (2-bits) | ROB entry (6-bits)

Note: I opted to put use bit in a different container to simplify the logic and make lookups faster

$clog2: calculates ceiling log based 2 function 
*/