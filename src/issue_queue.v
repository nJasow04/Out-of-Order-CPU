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
    input [2:0]  funct3,
    input [6:0]  funct7,
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

    input [5:0]  fwd_rd_mem,
    input [31:0] fwd_rd_val_mem,

    // functional unit issues
    output reg [138:0] issued_funct_unit0,
    output reg [138:0] issued_funct_unit1,
    output reg [138:0] issued_funct_unit2,

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
    
    parameter ENTRY_SIZE = 139;
    parameter INVALID_ENTRY = 6'b111111;
    parameter EMPTY_ISSUE_QUEUE_ENTRY = {ENTRY_SIZE{1'b0}};

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

    reg [5:0] rs1_fwd_entry_0, rs1_fwd_entry_1, rs1_fwd_entry_2, rs1_fwd_entry_mem;
    reg [5:0] rs2_fwd_entry_0, rs2_fwd_entry_1, rs2_fwd_entry_2, rs2_fwd_entry_mem;


    reg [5:0] instruction_index_0, instruction_index_1, instruction_index_2;

    // combinational used to update ready list on forwards
    reg [NUM_INSTRUCTIONS-1:0] src1_ready_fwd; 
    reg [NUM_INSTRUCTIONS-1:0] src2_ready_fwd; 

    // holds issued instruction
    reg [ENTRY_SIZE-1:0] issued_instruction [2:0];

    // array of regs holding ready instructions
    reg [3:0] instruction_ready;

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

    // forward logic and select ready instructions logic
    always @(*) begin

        // default values to avoid latches: if rs1_fwd or rs2_fwd are low values don't matter
        src1_ready_fwd = src1_ready;
        src2_ready_fwd = src2_ready;

        rs1_fwd_entry_0 = INVALID_ENTRY;
        rs1_fwd_entry_1 = INVALID_ENTRY;
        rs1_fwd_entry_2 = INVALID_ENTRY;
        rs1_fwd_entry_mem = INVALID_ENTRY;

        rs2_fwd_entry_0 = INVALID_ENTRY;
        rs2_fwd_entry_1 = INVALID_ENTRY;
        rs2_fwd_entry_2 = INVALID_ENTRY;
        rs2_fwd_entry_mem = INVALID_ENTRY;

        // set high if instruction ready
        instruction_ready = 3'b0;

        // index of ready instruction
        instruction_index_0 = INVALID_ENTRY;
        instruction_index_1 = INVALID_ENTRY;
        instruction_index_2 = INVALID_ENTRY;

        for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
            
            // check forward is a helper task that updates src_1/2 ready, rs1/2_fwd, fwd_entry
            if (fwd_enable) begin
                
                // FORWARD FUNCTIONAL UNIT 0
                check_forward(fwd_rd_funct_unit0, 2'b00, i);

                // FORWARD FUNCTIONAL UNIT 1
                check_forward(fwd_rd_funct_unit1, 2'b01, i);

                // FORWARD FUNCTIONAL UNIT 2
                check_forward(fwd_rd_funct_unit2, 2'b10, i);

                // MEMORY UNIT
                check_forward(fwd_rd_funct_unit2, 2'b11, i);

            end

            // First instruction ready
            if (src1_ready_fwd[i] && src2_ready_fwd[i] && funct_unit_scoreboard[issue_queue[i][1:0]] && instruction_ready[0] == 1'b0 && use_bits[i]) begin
                instruction_ready[0] = 1'b1;
                instruction_index_0 = i;
            end
            // Second instruction ready
            else if (src1_ready_fwd[i] && src2_ready_fwd[i] && funct_unit_scoreboard[issue_queue[i][1:0]] && instruction_ready[1] == 1'b0 && use_bits[i]) begin
                instruction_ready[1] = 1'b1;
                instruction_index_1 = i;
            end
            // Third instruction ready
            else if (src1_ready_fwd[i] && src2_ready_fwd[i] && funct_unit_scoreboard[issue_queue[i][1:0]] && instruction_ready[2] == 1'b0 && use_bits[i]) begin
                instruction_ready[2] = 1'b1;
                instruction_index_2 = i;
            end

        end
    end

    // reset and update
    always @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin
            
            // Reset all logic
            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                issue_queue[i] <= {ENTRY_SIZE{1'b0}}; // TODO: to test: fill with $random
            end

            register_file_scoreboard <= {NUM_PHYSICAL_REGS{1'b1}};
            funct_unit_scoreboard <= {NUM_FUNCTIONAL_UNITS{1'b1}};

            use_bits <= {NUM_INSTRUCTIONS{1'b0}}; 
            src1_ready <= {NUM_INSTRUCTIONS{1'b0}}; 
            src2_ready <= {NUM_INSTRUCTIONS{1'b0}}; 
            FU_count <= 2'b0;

            issued_funct_unit0 <= EMPTY_ISSUE_QUEUE_ENTRY;
            issued_funct_unit1 <= EMPTY_ISSUE_QUEUE_ENTRY;
            issued_funct_unit2 <= EMPTY_ISSUE_QUEUE_ENTRY;

            funct0_enable <=  1'b0;
            funct1_enable <=  1'b0;
            funct2_enable <=  1'b0;

        end 
        else begin
            
            // instructions only take one clock cycle
            funct_unit_scoreboard <= {NUM_FUNCTIONAL_UNITS{1'b1}};

            // CREATE ENTRY
            if (write_enable && !issue_queue_full) begin
                
                register_file_scoreboard[phys_rd] <= 1'b0; // set dest reg as in use on dispatch

                issue_queue[free_entry] <= {
                    funct3, funct7, opcode, 
                    phys_rd, phys_rs1, phys_rs1_val,
                    phys_rs2, phys_rs2_val, immediate,
                    ROB_entry_index, FU_count
                };
                // mark entry as used
                use_bits[free_entry] <= 1'b1;

                // assign ready regs
                src1_ready[free_entry] <= register_file_scoreboard[phys_rs1];
                src2_ready[free_entry] <= register_file_scoreboard[phys_rs2];
                
                // Round robin logic: increment FU count
                FU_count <= (FU_count + 1) % NUM_FUNCTIONAL_UNITS;
            end

            // WAKE UP (ready by next clock cycle) and forward logic 

            for (i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                
                if (fwd_enable) begin

                    // rs1
                    if (rs1_fwd_entry_0 == issue_queue[i][109:78]) begin
                        issue_queue[rs1_fwd_entry_0][109:78] <= fwd_rd_val_funct_unit0;
                        src1_ready[rs1_fwd_entry_0] <= 1'b1;
                        $display("Forward reg 1: %d", rs1_fwd_entry_0);
                    end
                    else if (rs1_fwd_entry_1 == issue_queue[i][109:78]) begin
                        issue_queue[rs1_fwd_entry_1][109:78] <= fwd_rd_val_funct_unit1;
                        src1_ready[rs1_fwd_entry_1] <= 1'b1;
                        $display("Forward reg 1: %d", rs1_fwd_entry_1);
                    end
                    else if (rs1_fwd_entry_2 == issue_queue[i][109:78]) begin
                        issue_queue[rs1_fwd_entry_2][109:78] <= fwd_rd_val_funct_unit2;
                        src1_ready[rs1_fwd_entry_2] <= 1'b1;
                        $display("Forward reg 1: %d", rs1_fwd_entry_2);
                    end
                    else if (rs1_fwd_entry_mem == issue_queue[i][109:78]) begin
                        issue_queue[rs1_fwd_entry_mem][109:78] <= fwd_rd_val_mem;
                        src1_ready[rs1_fwd_entry_mem] <= 1'b1;
                        $display("Forward reg 1: %d", rs1_fwd_entry_mem);
                    end

                    // rs2
                    if (rs2_fwd_entry_0 == issue_queue[i][71:40]) begin
                        issue_queue[rs2_fwd_entry_0][71:40] <= fwd_rd_val_funct_unit0;
                        src2_ready[rs2_fwd_entry_0] <= 1'b1;

                        $display("Forward reg 2: %d", rs2_fwd_entry_0);
                    end
                    else if (rs2_fwd_entry_1 == issue_queue[i][71:40]) begin
                        issue_queue[rs2_fwd_entry_1][71:40] <= fwd_rd_val_funct_unit1;
                        src2_ready[rs2_fwd_entry_1] <= 1'b1;

                        $display("Forward reg 2: %d", rs2_fwd_entry_1);
                    end
                    else if (rs2_fwd_entry_2 == issue_queue[i][71:40]) begin
                        issue_queue[rs2_fwd_entry_2][71:40] <= fwd_rd_val_funct_unit2;
                        src2_ready[rs2_fwd_entry_2] <= 1'b1;

                        $display("Forward reg 2: %d", rs2_fwd_entry_2);
                    end
                    else if (rs2_fwd_entry_mem == issue_queue[i][71:40]) begin
                        issue_queue[rs2_fwd_entry_mem][71:40] <= fwd_rd_mem;
                        src2_ready[rs2_fwd_entry_mem] <= 1'b1;
                        $display("Forward reg 1: %d", rs2_fwd_entry_mem);
                    end
                end
            end

            // ISSUE LOGIC

            // flags to enable functional units
            funct0_enable <= 1'b0;
            funct1_enable <= 1'b0;
            funct2_enable <= 1'b0;

            issued_funct_unit0 <= EMPTY_ISSUE_QUEUE_ENTRY;
            issued_funct_unit1 <= EMPTY_ISSUE_QUEUE_ENTRY;
            issued_funct_unit2 <= EMPTY_ISSUE_QUEUE_ENTRY;
                 

            issued_instruction[0] = issue_queue[instruction_index_0];  
            issued_instruction[1] = issue_queue[instruction_index_1];    
            issued_instruction[2] = issue_queue[instruction_index_2]; 

            // FUNCTIONAL UNIT 0

            // Instruction 0 ready
            if (instruction_ready[0]) begin
                forward_value(0, instruction_index_0);

                use_bits[instruction_index_0] <= 1'b0;
                funct0_enable <= 1'b1;
                issued_funct_unit0 <= issued_instruction[0];
                funct_unit_scoreboard[0] <= 1'b0;
                $display("Issued to FU 0!");
            end

            // FUNCTIONAL UNIT 1

            // Instruction 1 ready
            if (instruction_ready[1]) begin
                forward_value(1, instruction_index_1);

                use_bits[instruction_index_1] <= 1'b0;
                funct1_enable <= 1'b1;
                issued_funct_unit1 <= issued_instruction[1];
                funct_unit_scoreboard[1] <= 1'b0;
                $display("Issued to FU 1!");                
            end
            

            // FUNCTIONAL UNIT 2

            // Instruction 2 ready
            if (instruction_ready[2]) begin
                forward_value(2, instruction_index_2);

                use_bits[instruction_index_2] <= 1'b0;
                funct2_enable <= 1'b1;
                issued_funct_unit2 <= issued_instruction[2];
                funct_unit_scoreboard[2] <= 1'b0;
                $display("Issued to FU 2!");       
            end

        end 
    end
    

    // HELPER TASKS

    // Task to check forwarding for a specific functional unit
    task check_forward(
        input [5:0] fwd_rd_funct_unit,  // Functional unit to forward from
        input [1:0] fwd_unit_id,        // Identifier for the functional unit
        input integer i             // Issue queue index
    );
    begin
        // Both forward
        if (issue_queue[i][115:110] == fwd_rd_funct_unit &&
            issue_queue[i][77:72] == fwd_rd_funct_unit) begin
            src1_ready_fwd[i] = 1'b1;
            src2_ready_fwd[i] = 1'b1;
            
            case (fwd_unit_id)
                2'b00: begin rs1_fwd_entry_0 = i; rs2_fwd_entry_0 = i; end
                2'b01: begin rs1_fwd_entry_1 = i; rs2_fwd_entry_1 = i; end
                2'b10: begin rs1_fwd_entry_2 = i; rs2_fwd_entry_2 = i; end  
                2'b11: begin rs1_fwd_entry_mem = i; rs2_fwd_entry_mem = i; end         
            endcase

        end
        // rs1 forward
        else if (issue_queue[i][115:110] == fwd_rd_funct_unit) begin
            src1_ready_fwd[i] = 1'b1;

            case (fwd_unit_id)
                2'b00: rs1_fwd_entry_0 = i;
                2'b01: rs1_fwd_entry_1 = i;
                2'b10: rs1_fwd_entry_2 = i;
                2'b11: rs1_fwd_entry_mem = i;    
            endcase
        end
        // rs2 forward
        else if (issue_queue[i][77:72] == fwd_rd_funct_unit) begin
            src2_ready_fwd[i] = 1'b1;

            case (fwd_unit_id)
                2'b00: rs2_fwd_entry_0 = i;
                2'b01: rs2_fwd_entry_1 = i;
                2'b10: rs2_fwd_entry_2 = i;    
                2'b11: rs2_fwd_entry_mem = i;        
            endcase    
        end
    end
    endtask

    task forward_value(
        input integer i,
        input [5:0] instruction_index 
    );
    begin
    
        // FUNCT UNIT 0 FORWARD

        // both source registers forward
        if (instruction_index == rs1_fwd_entry_0 && instruction_index == rs2_fwd_entry_0) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit0, 
            issue_queue[instruction_index][77:72], fwd_rd_val_funct_unit0, issue_queue[instruction_index][39:0] };
            $display("Forwarded here!");
        end
        // forward rs1
        else if (instruction_index == rs1_fwd_entry_0) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit0, issue_queue[instruction_index][77:0] };                  
        end
        // forward rs2
        else if (instruction_index == rs2_fwd_entry_0) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:72], fwd_rd_val_funct_unit0, issue_queue[instruction_index][39:0] };              
        end

        // FUNCT UNIT 1 FORWARD

        // both source registers forward
        if (instruction_index == rs1_fwd_entry_1 && instruction_index == rs2_fwd_entry_1) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit1, 
            issue_queue[instruction_index][77:72], fwd_rd_val_funct_unit1, issue_queue[instruction_index][39:0] };
        end
        // forward rs1
        else if (instruction_index == rs1_fwd_entry_1) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit1, issue_queue[instruction_index][77:0] };                  
        end
        // forward rs2
        else if (instruction_index == rs2_fwd_entry_1) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:72], fwd_rd_val_funct_unit1, issue_queue[instruction_index][39:0] };              
        end

        // FUNCT UNIT 2 FORWARD

        // both source registers forward
        if (instruction_index == rs1_fwd_entry_2 && instruction_index == rs2_fwd_entry_2) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit2, 
            issue_queue[instruction_index][77:72], fwd_rd_val_funct_unit2, issue_queue[instruction_index][39:0] };
        end
        // forward rs1
        else if (instruction_index == rs1_fwd_entry_2) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:110], fwd_rd_val_funct_unit2, issue_queue[instruction_index][77:0] };                  
        end
        // forward rs2
        else if (instruction_index == rs2_fwd_entry_2) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:72], fwd_rd_val_funct_unit2, issue_queue[instruction_index][39:0] };              
        end

        // MEM UNIT FORWARD

        // both source registers forward
        if (instruction_index == rs1_fwd_entry_mem && instruction_index == rs2_fwd_entry_mem) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:110], fwd_rd_val_mem, 
            issue_queue[instruction_index][77:72], fwd_rd_val_mem, issue_queue[instruction_index][39:0] };
        end
        // forward rs1
        else if (instruction_index == rs1_fwd_entry_mem) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:110], fwd_rd_val_mem, issue_queue[instruction_index][77:0] };                  
        end
        // forward rs2
        else if (instruction_index == rs2_fwd_entry_mem) begin
            issued_instruction[i] = { issue_queue[instruction_index][ENTRY_SIZE-1:72], fwd_rd_val_mem, issue_queue[instruction_index][39:0] };              
        end

    
    end
    endtask
                        
endmodule

/*

Issue Queue Format: 64 instructions with 139 bits per entry

funct3 (3-bits) | funct7 (7-bits) | opcode (7-bits) | 
dest reg (6 bits) | src 1 reg (6 bits) | src 1 val (32 bits) | 
src 2 reg (6 bits) | src 2 val (32 bits) | immediate (32-bits) | 
ROB entry (6-bits) | functional unit (2-bits)

    funct3,          // 138:136
    funct7,          // 135:129        
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