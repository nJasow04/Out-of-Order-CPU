//`include "fetch.v"

module cpu_top
(
    input clk,
    input reset_n
);
  	wire [31:0] instruction_fetch;
	wire stall;

    // Instantiate Fetch Unit
    fetch fetch_unit (
        .clk(clk),
        .reset_n(reset_n),
      	.instruction(instruction_fetch)
    );
    wire [31:0] instruction_fetch_pipelined;

    pipeline_buffer IF_ID_buffer (
        .clk(clk),
        .reset_n(reset_n),
		  .stall(stall),
        .data_in(instruction_fetch),
        .data_out(instruction_fetch_pipelined)
    );

    wire [31:0] instruction;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [6:0] funct7;
    wire [2:0] funct3;
    wire [6:0] opcode;

    decode decode_unit (
        .instruction(instruction_fetch_pipelined),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct7(funct7),
        .funct3(funct3),
        .opcode(opcode)
    );

    wire [31:0] immediate;

    immediate_generate imm_gen (
        .instruction(instruction_fetch_pipelined),
        .immediate(immediate)
    );
	 
	 wire MemRead;
	 wire MemWrite;
	 wire MemtoReg;
	 wire [1:0] ALUOp;
	 wire ALuSrc;
	 wire RegWrite;
	 wire LoadUpper;
	 
	 controller controller_unit(
		.opcode(opcode),
		.MemRead(MemRead),
		.MemWrite(MemWrite),
		.MemtoReg(MemtoReg),
		.ALUOp(ALUOp),
		.ALUSrc(ALUSrc),
		.RegWrite(RegWrite),
		.LoadUpper(LoadUpper)
	 );
	 
	 wire [3:0] ALUControl;
	 wire MemSize;
	 
	 ALUController ALUControl_unit(
		.ALUOp(ALUOp),
		.funct3(funct3),
		.funct7(funct7),
		.ALUControl(ALUControl),
		.MemSize(MemSize)
	 );
	 
	 wire [31:0] instruction_decode = {rd, rs1, rs2, ALUControl, ALUSrc, MemRead, MemWrite, MemtoReg, RegWrite, MemSize, LoadUpper};
	 wire [31:0] instruction_decode_pipelined;
	 
	 
    pipeline_buffer ID_RN_buffer (
        .clk(clk),
        .reset_n(reset_n),
		  .stall(stall),
        .data_in(instruction_decode), //rd rs1 rs2, control sigs
        .data_out(instruction_decode_pipelined)
    );
	 
	 
	 
	 wire [5:0] phys_rd, phys_rs1, phys_rs2;
	 wire free_list_empty;
	 
	 rename rename_module(
	 .rd(instruction_decode_pipelined[25:21]),
	 .rs1(instruction_decode_pipelined[20:16]),
	 .rs2(instruction_decode_pipelined[15:11]),
	 .issue_valid(instruction_decode_pipelined[2]),
	 .reset_n(reset_n),
	 .clk(clk),
	 .retire_valid(1'b0), //fill in signal when retire added
	 .retire_phys_reg(6'b0), //fill in signal when retire added
	 .phys_rd(phys_rd),
	 .phys_rs1(phys_rs1),
	 .phys_rs2(phys_rs2),
	 .free_list_empty(free_list_empty)
	 );
	 
	 assign stall = stall | free_list_empty;
	 
	 
	 
	 
	 
endmodule