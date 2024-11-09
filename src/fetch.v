`include "instruction_rom.v"  

module fetch (
    input clk,
    input reset_n,
    output [31:0] instruction  
);
    reg [7:0] pc = 0;  

    wire [31:0] instruction_rom;  
    
    instruction_rom rom (
        .address(pc),
        .data(instruction_rom)  
    );

    assign instruction = instruction_rom;

    // Program counter logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            pc <= 0;  
        else
            pc <= pc + 1; 
    end
endmodule
