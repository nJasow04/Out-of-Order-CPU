module cpu_top
(
    input clk,
    input [31:0] instruction,
    output [31:0] in_out
);

    assign in_out = instruction;


endmodule