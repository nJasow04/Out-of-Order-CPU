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
    input fwd_enable, // all four forward enable signals or'd together

    input [5:0]  fwd_rd_funct_unit0,
    input [31:0] fwd_rd_val_funct_unit0,

    input [5:0]  fwd_rd_funct_unit1,
    input [31:0] fwd_rd_val_funct_unit1,
    
    input [5:0]  fwd_rd_funct_unit2,
    input [31:0] fwd_rd_val_funct_unit2,

    output reg [128:0] issued_funct_unit0,
    output reg [128:0] issued_funct_unit1,
    output reg [128:0] issued_funct_unit2,

    output reg funct0_enable,
    output reg funct1_enable,
    output reg funct2_enable,

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

    // issue queue full logic
    assign issue_queue_full = (free_entry == INVALID_ENTRY);

    // forward / wake-up logic

    // holds which functional unit to forward from: 00 - unit0, 01 - unit1, 10 - unit 2, 11 - no forwarding
    reg [1:0] rs1_fwd; 
    reg [1:0] rs2_fwd;

    reg [5:0] fwd_entry;

    // combinational used to update ready list on forwards
    reg [NUM_INSTRUCTIONS-1:0] src1_ready_fwd; 
    reg [NUM_INSTRUCTIONS-1:0] src2_ready_fwd; 

    // holds issued instruction
    reg [ENTRY_SIZE-1:0] issued_instruction;

    integer i;

    // free entry logic
    always @(*) begin

        free_entry = INVALID_ENTRY;

        // Priority encoder to find first entry
        for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
            if (use_bits[i] == 1'b0 && free_entry == INVALID_ENTRY) begin
                free_entry = i;
            end
        end
    end

    // forward logic
    always @(*) begin

        // default values to avoid latches: if rs1_fwd or rs2_fwd are low values don't matter
        src1_ready_fwd = src1_ready;
        src2_ready_fwd = src2_ready;  
        rs1_fwd = 2'b11;
        rs2_fwd = 2'b11;
        fwd_entry = INVALID_ENTRY;

        for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
            
            if (fwd_enable) begin
                
                // FORWARD FUNCTIONAL UNIT 0

                // both forward
                if (issue_queue[i][115:110] == fwd_rd_funct_unit0 && issue_queue[i][77:72] == fwd_rd_funct_unit0) begin
                    src1_ready_fwd[i] = 1'b1;
                    rs1_fwd = 2'b00; 
                    src2_ready_fwd[i] = 1'b1;
                    rs2_fwd = 2'b00;    
                    fwd_entry = i;
                end
                // rs1 forward
                else if (issue_queue[i][115:110] == fwd_rd_funct_unit0) begin
                    src1_ready_fwd[i] = 1'b1;
                    rs1_fwd = 2'b00; 
                    fwd_entry = i;
                end
                // rs2 forward
                else if (issue_queue[i][77:72] == fwd_rd_funct_unit0) begin
                    src2_ready_fwd[i] = 1'b1;
                    rs2_fwd = 2'b00;    
                    fwd_entry = i;
                end

                // FORWARD FUNCTIONAL UNIT 1

                // both forward
                if (issue_queue[i][115:110] == fwd_rd_funct_unit1 && issue_queue[i][77:72] == fwd_rd_funct_unit1) begin
                    src1_ready_fwd[i] = 1'b1;
                    rs1_fwd = 2'b01; 
                    src2_ready_fwd[i] = 1'b1;
                    rs2_fwd = 2'b01;    
                    fwd_entry = i;
                end
                // rs1 forward
                else if (issue_queue[i][115:110] == fwd_rd_funct_unit1) begin
                    src1_ready_fwd[i] = 1'b1;
                    rs1_fwd = 2'b01; 
                    fwd_entry = i;
                end
                // rs2 forward
                else if (issue_queue[i][77:72] == fwd_rd_funct_unit1) begin
                    src2_ready_fwd[i] = 1'b1;
                    rs2_fwd = 2'b01;    
                    fwd_entry = i;
                end

                // FORWARD FUNCTIONAL UNIT 2

                // both forward
                if (issue_queue[i][115:110] == fwd_rd_funct_unit2 && issue_queue[i][77:72] == fwd_rd_funct_unit2) begin
                    src1_ready_fwd[i] = 1'b1;
                    rs1_fwd = 2'b10; 
                    src2_ready_fwd[i] = 1'b1;
                    rs2_fwd = 2'b10; 
                    fwd_entry = i;
                end
                // rs1 forward
                else if (issue_queue[i][115:110] == fwd_rd_funct_unit2) begin
                    src1_ready_fwd[i] = 1'b1;
                    rs1_fwd = 2'b10; 
                    fwd_entry = i;
                end
                // rs2 forward
                else if (issue_queue[i][77:72] == fwd_rd_funct_unit2) begin
                    src2_ready_fwd[i] = 1'b1;
                    rs2_fwd = 2'b10; 
                    fwd_entry = i;
                end
            end
        end
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

            issued_funct_unit0 <= {ENTRY_SIZE{1'b0}};
            issued_funct_unit1 <= {ENTRY_SIZE{1'b0}};
            issued_funct_unit2 <= {ENTRY_SIZE{1'b0}};

            funct0_enable <=  1'b0;
            funct1_enable <=  1'b0;
            funct2_enable <=  1'b0;

        end 
        else begin
            
            if (write_enable && !issue_queue_full) begin
                
                issue_queue[free_entry] <= {
                    opcode, phys_rd, phys_rs1, phys_rs1_val,
                    phys_rs2, phys_rs2_val, immediate,
                    ROB_entry_index, FU_count
                };
                $display("Free entry: %d", free_entry);
                // mark entry as used
                use_bits[free_entry] <= 1'b1;

                // assign ready regs
                src1_ready[free_entry] <= register_file_scoreboard[phys_rs1];
                src2_ready[free_entry] <= register_file_scoreboard[phys_rs2];
                
                // Round robin logic: increment FU count
                FU_count <= (FU_count + 1) % NUM_FUNCTIONAL_UNITS;
            end

            // wake up logic: ready by next clock cycle
            case (rs1_fwd)
                2'b00: 
                begin
                    issue_queue[fwd_entry][109:78] <= fwd_rd_val_funct_unit0;
                    src1_ready[fwd_entry] <= 1'b1;
                    $display("Forward reg 1: %d", fwd_entry);
                end
                2'b01:
                begin
                    issue_queue[fwd_entry][109:78] <= fwd_rd_val_funct_unit1;
                    src1_ready[fwd_entry] <= 1'b1;
                    $display("Forward reg 1: %d", fwd_entry);
                end
                2'b10:
                begin
                    issue_queue[fwd_entry][109:78] <= fwd_rd_val_funct_unit2;
                    src1_ready[fwd_entry] <= 1'b1;
                    $display("Forward reg 1: %d", fwd_entry);
                end
                default: 
                    $display("No forward");
            endcase

            case (rs2_fwd)
                2'b00: 
                begin
                    issue_queue[fwd_entry][71:40] <= fwd_rd_val_funct_unit0;
                    src2_ready[fwd_entry] <= 1'b1;
                    $display("Forward reg 2: %d", fwd_entry);
                end
                2'b01:
                begin
                    issue_queue[fwd_entry][71:40] <= fwd_rd_val_funct_unit1;
                    src2_ready[fwd_entry] <= 1'b1;
                    $display("Forward reg 2: %d", fwd_entry);
                end
                2'b10:
                begin
                    issue_queue[fwd_entry][71:40] <= fwd_rd_val_funct_unit2;
                    src2_ready[fwd_entry] <= 1'b1;
                    $display("Forward reg 2: %d", fwd_entry);
                end
                default: 
                    $display("No forward");            
            endcase

            // flags to enable functional units
            funct0_enable <= 1'b0;
            funct1_enable <= 1'b0;
            funct2_enable <= 1'b0;

            // Issue logic
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                // both sources ready and functional unit ready (bits 1:0 of issue queue entry are the functional unit it corresponds to)
                if (src1_ready_fwd[i] && src2_ready_fwd[i] && funct_unit_scoreboard[issue_queue[i][1:0]]) begin
                    
                    use_bits[i] <= 1'b0; 
                    register_file_scoreboard[phys_rd] <= 1'b0; // set dest reg as in use
                    
                    // default not forwarding
                    issued_instruction = issue_queue[i];    

                    // send to correct functional unit
                    case (issued_instruction[1:0])
                        2'b00: 
                        begin

                            // both source registers forward
                            if (rs1_fwd && rs2_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit0, 
                                issue_queue[i][77:72], fwd_rd_val_funct_unit0, issue_queue[i][39:0] };
                            end
                            // forward rs1
                            else if (rs1_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit0, issue_queue[i][77:0] };                  
                            end
                            // forward rs2
                            else if (rs2_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:72], fwd_rd_val_funct_unit0, issue_queue[i][39:0] };              
                            end

                            funct0_enable <= 1'b1;
                            issued_funct_unit0 <= issued_instruction;
                            funct_unit_scoreboard[0] <= 1'b0;
                            $display("Issued to FU 0!");
                        end
                        2'b01:
                        begin

                            // both source registers forward
                            if (rs1_fwd && rs2_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit1, 
                                issue_queue[i][77:72], fwd_rd_val_funct_unit1, issue_queue[i][39:0] };
                            end
                            // forward rs1
                            else if (rs1_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit1, issue_queue[i][77:0] };                  
                            end
                            // forward rs2
                            else if (rs2_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:72], fwd_rd_val_funct_unit1, issue_queue[i][39:0] };              
                            end

                            funct1_enable <= 1'b1;
                            issued_funct_unit1 <= issued_instruction;
                            funct_unit_scoreboard[1] <= 1'b0;
                            $display("Issued to FU 1!");
                        end
                        2'b10:
                        begin
                            
                            // both source registers forward
                            if (rs1_fwd && rs2_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit2, 
                                issue_queue[i][77:72], fwd_rd_val_funct_unit2, issue_queue[i][39:0] };
                            end
                            // forward rs1
                            else if (rs1_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit2, issue_queue[i][77:0] };                  
                            end
                            // forward rs2
                            else if (rs2_fwd && i == fwd_entry) begin
                                issued_instruction = { issue_queue[i][ENTRY_SIZE-1:72], fwd_rd_val_funct_unit2, issue_queue[i][39:0] };              
                            end
                            
                            funct2_enable <= 1'b1;
                            issued_funct_unit2 <= issued_instruction;
                            funct_unit_scoreboard[2] <= 1'b0;
                            $display("Issued to FU 2!");
                        end
                        default: 
                        begin
                            $display("Warning: Invalid functional unit code %b", issued_instruction[1:0]);
                        end
                    endcase
            end
        end

    // reset functional units since all instructions take one clock cycle: can be changed in future
    funct_unit_scoreboard <= {NUM_FUNCTIONAL_UNITS{1'b1}};
    end 

    end
    
                        



endmodule

/*

Issue Queue Format: 64 instructions with 129 bits per entry

opcode (7-bits) | dest reg (6 bits) | src 1 reg (6 bits) | src 1 val (32 bits) | 
src 2 reg (6 bits) | src 2 val (32 bits) | immediate (32-bits) | 
ROB entry (6-bits) | functional unit (2-bits)

    opcode,          // 128:122
    phys_rd,         // 121:116
    phys_rs1,        // 115:110
    phys_rs1_val,    // 109:78
    phys_rs2,        // 77:72
    phys_rs2_val,    // 71:40
    immediate,       // 39:8
    ROB_entry_index, // 7:2
    FU_count         // 1:0

Note: I opted to put use bit in a different container to simplify the logic and make lookups faster

$clog2: calculates ceiling log based 2 function 

*/