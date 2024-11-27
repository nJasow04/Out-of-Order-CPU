module rename (
    input clk,
    input reset_n,
    input issue_valid,
    input retire_valid,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [5:0] retire_phys_reg,
    output reg [5:0] phys_rd,
    output reg [5:0] phys_rs1,
    output reg [5:0] phys_rs2,
    output reg free_list_empty 
);
	// Constants
	parameter NUM_PHYS_REGS = 64; // Physical Registers
	parameter NUM_ARCH_REGS = 32; // Architectural Registers 
	parameter [5:0] INVALID_REG = 6'b111111;

 
	// RAT and Free List
	reg [5:0] rename_alias_table [NUM_ARCH_REGS-1:0];
	reg [NUM_PHYS_REGS-1:0] free_list;

	integer i;

	// Combinational logic for renaming
	always @(*) begin

		if (issue_valid) begin

			phys_rd = INVALID_REG;
			phys_rs1 = rename_alias_table[rs1]; 
			phys_rs2 = rename_alias_table[rs2];
			free_list_empty = 0; // 1: free list empty
		
			// Find first free register combinationally
			for (i = 0; i < NUM_PHYS_REGS; i = i + 1) begin
				if (free_list[i] && phys_rd == INVALID_REG) begin
					phys_rd = i[5:0];
				end
			end
			//don't need to implement stall, just print an error
			//don't need to account for flushing instructions, so don't need to store prev phys_reg in ROB, only the current, replace current tag with old tag
			if (phys_rd == INVALID_REG) 
				free_list_empty = 1;
			else
				free_list_empty = 0;
			
	    end
	end

	// Sequential logic for state updates only
	always @(posedge clk or negedge reset_n) begin
	  // Reset free_list and alias table
        if (!reset_n) begin
        	free_list <= {{NUM_PHYS_REGS-NUM_ARCH_REGS{1'b1}}, {NUM_ARCH_REGS{1'b0}}};
            for (i = 0; i < NUM_ARCH_REGS; i = i + 1) begin
                rename_alias_table[i] <= i;
            end
        end
        else begin
            // Update state based on the combinationally computed phys_rd
            if(issue_valid && !free_list_empty) begin
                free_list[phys_rd] <= 1'b0;
                rename_alias_table[rd] <= phys_rd;
            end
            // update free list on retire
            if(retire_valid) begin
                free_list[retire_phys_reg] <= 1'b1;
            end
        end
	end

endmodule