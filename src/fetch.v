module fetch (
    input clk,
    input reset_n,
	 input [8191:0] instruction_memory,
    output reg[31:0] instruction
);
    reg [7:0] pc = 0;  
	
    always @(*) begin
        // Calculate the start index for the instruction in the flattened array
        integer start_index;
        start_index = pc * 32;
        instruction = instruction_memory[start_index +: 32];  // Bit-slice to get 32-bit instruction
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            pc <= 0;
        else
            pc <= pc + 1;  
    end
	 
  
endmodule
