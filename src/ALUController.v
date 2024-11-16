module ALUController(
    input [1:0] ALUOp,       
    input [2:0] funct3,      
    input [6:0] funct7,     
    output reg [3:0] ALUControl,
	output reg MemSize
);

    always @(*) begin
			ALUControl = 4'b1111;
			MemSize = 0; // 0 is word, 1 is byte
        case (ALUOp)
            2'b00: begin // For load and store instructions (LB, LW, SB, SW)
                ALUControl = 4'b0010; // ADD 
					 case (funct3)
                    3'b000: MemSize = 1'b0; // Byte (LB, SB)
                    3'b010: MemSize = 1'b1; // Word (LW, SW)
                    default: MemSize = 1'b0; // Default to Byte for invalid codes
                endcase
            end
            2'b11: begin // I-type instructions (ADDI, ORI, SRAI)
                case (funct3)
                    3'b000: ALUControl = 4'b0010; // ADD
                    3'b110: ALUControl = 4'b0001; // OR
                    3'b100: ALUControl = 4'b0011; // XOR
                    3'b101: ALUControl = 4'b0111; // Shift Right Arithmetic
                    default: ALUControl = 4'b1111;
                endcase
            end
            2'b10: begin // R-type instructions (ADD, XOR)
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000)
                            ALUControl = 4'b0010; // ADD
                        else if (funct7 == 7'b0100000)
                            ALUControl = 4'b0110; // SUB
                        else
                            ALUControl = 4'b1111;
                    end
                    3'b100: ALUControl = 4'b0011; // XOR
                    default: ALUControl = 4'b1111;
                endcase
            end
            2'b01: begin // U-type instruction (LUI)
                ALUControl = 4'b1111; // Load Upper Immediate, don't need ALU
            end
            default: ALUControl = 4'b1111; // Default, invalid operation
        endcase
    end
endmodule
