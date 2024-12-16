module functional_unit(
    input [138:0] issue_queue_entry,  // 139-bit instruction
	 input enable,
    output reg [31:0] result,         // ALU result
    output reg zero_flag,             // Zero flag from ALU
    output reg [5:0] dest_reg,        // Destination register
    output reg [5:0] rob_index,        // ROB entry index
	 output reg [31:0] store_data,
	 output reg memWrite,
	 output reg memRead,
	 output reg memSize,
	 output reg regWrite
);

    // Extract fields from issue queue entry
	 wire [2:0] funct3       = issue_queue_entry[138:136];
	 wire [6:0] funct7       = issue_queue_entry[135:129];
    wire [6:0] opcode       = issue_queue_entry[128:122];
    wire [5:0] phys_rd      = issue_queue_entry[121:116];
    wire [5:0] phys_rs1     = issue_queue_entry[115:110];
    wire [31:0] phys_rs1_val = issue_queue_entry[109:78];
    wire [5:0] phys_rs2     = issue_queue_entry[77:72];
    wire [31:0] phys_rs2_val = issue_queue_entry[71:40];
    wire [31:0] immediate   = issue_queue_entry[39:8];
    wire [5:0] ROB_entry_index = issue_queue_entry[7:2];
    wire [1:0] FU_count     = issue_queue_entry[1:0];

    // Control signals
    wire MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite, LoadUpper;
    wire [1:0] ALUOp;
    wire [3:0] ALUControl;
    wire MemSize;

    // Intermediate operand
    wire [31:0] operand_b;

    // ALU Outputs
    wire [31:0] alu_result;
    wire zero;

    // Instantiate Controller
    controller u_controller (
        .opcode(opcode),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .LoadUpper(LoadUpper)
    );

    // Instantiate ALU Controller
    ALU_controller u_alu_controller (
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .ALUControl(ALUControl),
        .MemSize(MemSize)
    );

    // Select operand B (immediate or rs2_val) based on ALUSrc
    assign operand_b = ALUSrc ? immediate : phys_rs2_val;

    // Instantiate ALU
    ALU u_alu (
        .A(phys_rs1_val),
        .B(operand_b),
        .ALUControl(ALUControl),
        .Result(alu_result),
        .Zero(zero)
    );

    // Process Results and Outputs
    always @(*) begin
		 if (enable) begin
			  result = alu_result;
			  zero_flag = zero;
			  dest_reg = phys_rd;
			  rob_index = ROB_entry_index;
			  if (MemWrite)begin
					store_data = phys_rs2_val;
			  end else begin
					store_data = 'd0;
			  end
			  
			  
			  memWrite = MemWrite;
			  memRead = MemRead;
			  memSize= MemSize;
			  regWrite = RegWrite;
		  end else begin
				result = 'd0;
			  zero_flag = 'd0;
			  dest_reg = 'd0;
			  rob_index = 'd0;
			  store_data = 'd0;
			  memWrite = 'd0;
			  memRead = 'd0;
			  memSize= 'd0;
			  regWrite = 'd0;
		  end
    end

endmodule
