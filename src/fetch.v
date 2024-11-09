module fetch (
    input clk,
    input reset_n,
    output [31:0] instruction
);
    reg [7:0] pc = 0;  
    reg [31:0] instruction_memory [0:255];  

    assign instruction = instruction_memory[pc];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            pc <= 0;
        else
            pc <= pc + 1;  
    end
  
endmodule
