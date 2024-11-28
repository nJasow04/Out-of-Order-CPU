module check_mem_instr (
    input [6:0] opcode,
    input [2:0] funct3,
    output reg is_load,       // High if it's a load instruction
    output reg is_store,      // High if it's a store instruction
    output reg is_byte,       // High if it's byte-level
    output reg is_word,       // High if it's word-level
	 output reg is_instr
);

    always @(*) begin
        // Initialize outputs
        is_load = 0;
        is_store = 0;
        is_byte = 0;
        is_word = 0;
		  is_instr = 1;

        case (opcode)
            7'b0000011: begin
                is_load = 1;
                case (funct3)
                    3'b000: is_byte = 1;  // LB (Load Byte)
                    3'b010: is_word = 1;  // LW (Load Word)
                    default: begin end
                endcase
            end

            7'b0100011: begin
                is_store = 1;
                case (funct3)
                    3'b000: is_byte = 1;  // SB (Store Byte)
                    3'b010: is_word = 1;  // SW (Store Word)
                    default: begin end  
                endcase
            end

            default: begin
                // Not a memory instruction
                is_load = 0;
                is_store = 0;
                is_byte = 0;
                is_word = 0;
            end
        endcase
    end

endmodule
