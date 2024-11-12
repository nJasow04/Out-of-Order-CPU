
module controller(
	input [6:0] opcode,
	output reg MemRead,
	output reg MemtoReg,
	output reg [1:0] ALUOp,
	output reg MemWrite,
	output reg ALUSrc,
	output reg RegWrite,
	output reg LoadUpper
	);
	
	parameter R_TYPE = 7'b0110011;
   parameter I_TYPE = 7'b0010011;
   parameter S_TYPE = 7'b0100011;
   parameter U_TYPE = 7'b0110111;
	parameter LOAD = 7'b0000011;
	
	always @(*) begin
		MemRead =0;
		MemtoReg = 0;
		ALUOp = 2'b00;
		MemWrite = 0;
		ALUSrc = 0;
		RegWrite = 0;
		case (opcode)
			R_TYPE: begin
				 // ADD, XOR
				 ALUOp = 2'b10; // ALUOp for R-type (ADD, XOR)
				 RegWrite = 1;  // Register write enabled for R-type
			end
			I_TYPE: begin
				 // ADDI, ORI, SRAI
				 ALUOp = 2'b11; // ALUOp for I-type (ADDI, ORI, SRAI)
				 ALUSrc = 1;    // ALU source is immediate
				 RegWrite = 1;  // Register write enabled for I-type
			end
			S_TYPE: begin
				 // SB, SW
				 MemWrite = 1;  // Enable memory write for store instructions
				 ALUSrc = 1;    // ALU source is immediate for store instructions
			end
			LOAD: begin
				 // LB, LW
				 MemRead = 1;   // Enable memory read for load instructions
				 MemtoReg = 1;  // Memory to register enabled for load instructions
				 ALUSrc = 1;    // ALU source is immediate
				 RegWrite = 1;  // Register write enabled for load instructions
			end
			U_TYPE: begin
				 // LUI
				 ALUOp = 2'b01; //don't need alu
				 LoadUpper = 1; // Enable loading upper immediate
				 RegWrite = 1;  // Register write enabled for LUI
			end
			default: begin
				 // Default case for unknown opcodes, do nothing
			end
			
		endcase
		
	end
	endmodule