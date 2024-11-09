`include "fetch.v"

module cpu_top
(
    input clk,
    input reset_n
);
  	wire [31:0] instruction_fetch;

    // Instantiate Fetch Unit
    fetch fetch_unit (
        .clk(clk),
        .reset_n(reset),
      	.instruction(instruction_fetch)
    );
    wire [31:0] instruction_fetch_pipelined;

    pipeline_buffer IF_ID_buffer (
        .clk(clk),
        .reset_n(reset_n),
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

    pipeline_buffer ID_EX_buffer (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(),
        .data_out()
    );
endmodule