module cpu_top
(
    input clk,
    input [31:0] instruction_1,
    input [31:0] instruction_2,
    output [31:0] in1_out,
    output [31:0] in2_out,
);

    assign in1_out = instruction_1;
    assign in2_out = instruction_2;


endmodule