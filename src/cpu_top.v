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
	 
    wire is_load;
    wire is_store;
    wire is_byte;
    wire is_word;
	 wire is_instr;

    // Instance of check_mem_instr
    check_mem_instr check_mem_unit_inst (
        .opcode(opcode),
        .funct3(funct3),
        .is_load(is_load),
        .is_store(is_store),
        .is_byte(is_byte),
        .is_word(is_word),
		  .is_instr(is_instr)
    );
	 
	 wire is_mem = is_load | is_store;
	 
	 //immeditae gen and control signals to be done after the issue queue
	/*
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
	 
	 ALU_controller ALUControl_unit(
		.ALUOp(ALUOp),
		.funct3(funct3),
		.funct7(funct7),
		.ALUControl(ALUControl),
		.MemSize(MemSize)
	 );
	 */
	 
	 wire [31:0] instruction_decode = {rd, rs1, rs2, is_instr}; //if not mem then uses reg
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
	 wire retire = 1'b0;
	 wire [5:0] free_reg;
	 wire [5:0] old_phys_rd;
	 wire [4:0] arch_reg;
	 
	 rename rename_module(
	 .rd(instruction_decode_pipelined[15:11]),
	 .rs1(instruction_decode_pipelined[10:6]),
	 .rs2(instruction_decode_pipelined[5:1]),
	 .issue_valid(instruction_decode_pipelined[0]),
	 .reset_n(reset_n),
	 .clk(clk),
	 .retire_valid(retire), //fill in signal when retire added
	 .retire_phys_reg(free_reg), //fill in signal when retire added
	 .phys_rd(phys_rd),
	 .phys_rs1(phys_rs1),
	 .phys_rs2(phys_rs2),
	 .old_phys_rd(old_phys_rd),
	 .arch_reg(arch_reg),
	 .free_list_empty(free_list_empty)
	 );
	 
	 
	 
	 wire rob_open = 1'b1;
	 wire [5:0] writeback_reg; //for forwarding that dest reg is ready?
	 wire [31:0] retire_value; //for updating reg file
	 wire [5:0] retire_reg = 6'b0;
	 
	 reorder_buffer rob(
		.clk(clk),
		.reset_n(reset_n),
		.alloc_valid(instruction_decode_pipelined[2]), //regwrite signal used
		.alloc_dest(phys_rd),
		.alloc_oldDest(old_phys_rd), //rd
		.alloc_instr_addr(31'b0), //need to get pc? not sure if this is needed for now
		.writeback_valid(1'b0), //need signal from alu or rs station
		.writeback_idx(6'b0), 
		.writeback_value(32'b0),
		.commit_ready(1'b0), //need signal from alu or rs station
		
		.alloc_ready(rob_open),
		.writeback_dest(writeback_reg),
		.commit_valid(retire),
		.commit_dest(retire_reg),
		.free_oldDest(free_reg),
		.commit_value(retire_value)
		
	 );
	 
	 reg_file architectural_register_file (
    .clk(clk),
    .rs1(instruction_decode_pipelined[20:16]),
    .rs2(instruction_decode_pipelined[15:11]),
    .rd(arch_reg),    // Use architectural register from RAT
    .rd_data(retire_value),  // Value to write
    .RegWrite(retire),       // Writeback enable from ROB
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);
	 
	 assign stall = stall | free_list_empty | (!rob_open);
	 
	 
	 
	 
endmodule