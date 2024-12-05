module load_store_unit (
    input clk,
    input reset,

    // Inputs from Decode and Check Mem Instr
    input [31:0] rs1_data,     // Source register 1 data from reg file
    input [31:0] rs2_data,     // Source register 2 data (store data) from reg file
    input [31:0] imm,          // Immediate value from Decode
    input is_load,             // Load flag from check_mem_instr
    input is_store,            // Store flag from check_mem_instr
    input is_byte,             // Byte-level operation flag from check_mem_instr
    input is_word,             // Word-level operation flag from check_mem_instr

    // Outputs to ROB and Complete Logic
    output reg [31:0] read_data,  // Data read from memory
    output reg mem_done,          // Memory operation completed
    output [31:0] mem_address     // Computed memory address
);

    // Simulated 32KB memory (8192 words, each 4 bytes)
    reg [31:0] memory [0:8191];  // 32KB memory as 8192 words of 4 bytes

    // Internal registers
    reg [31:0] effective_address; // Computed memory address
    reg [12:0] word_address;      // Word address (13 bits for 8192 words)
    reg [1:0] byte_offset;        // Byte offset within a word (2 bits for 4 selections)

    // Compute the memory address and offsets
    always @(*) begin
        effective_address = rs1_data + imm;    // Base address + offset
        word_address = effective_address[14:2]; // Extract word address (ignoring 2 LSBs for byte alignment)
        byte_offset = effective_address[1:0];  // Extract byte offset
    end

    // Perform memory operations
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            read_data <= 0;
            mem_done <= 0;
        end else if (is_load) begin
            if (is_byte) begin
                // Load a single byte and sign-extend to 32 bits
                case (byte_offset)
                    2'b00: read_data <= {{24{memory[word_address][7]}}, memory[word_address][7:0]};
                    2'b01: read_data <= {{24{memory[word_address][15]}}, memory[word_address][15:8]};
                    2'b10: read_data <= {{24{memory[word_address][23]}}, memory[word_address][23:16]};
                    2'b11: read_data <= {{24{memory[word_address][31]}}, memory[word_address][31:24]};
                endcase
            end else if (is_word) begin
                // Load a full word
                read_data <= memory[word_address];
            end
            mem_done <= 1; // Indicate load completion
        end else if (is_store) begin
            if (is_byte) begin
                // Store a single byte
                case (byte_offset)
                    2'b00: memory[word_address][7:0] <= rs2_data[7:0];
                    2'b01: memory[word_address][15:8] <= rs2_data[7:0];
                    2'b10: memory[word_address][23:16] <= rs2_data[7:0];
                    2'b11: memory[word_address][31:24] <= rs2_data[7:0];
                endcase
            end else if (is_word) begin
                // Store a full word
                memory[word_address] <= rs2_data;
            end
            mem_done <= 1; // Indicate store completion
        end else begin
            mem_done <= 0; // No operation
        end
    end

    // Output the computed address
    assign mem_address = effective_address;

endmodule