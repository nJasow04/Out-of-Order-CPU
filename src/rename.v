module rename(
	input [4:0] rd,
	input [4:0] rs1,
	input [4:0] rs2,
	input issue_valid,
	input reset_n,
	input clk,
	input retire_valid,
	input [5:0] retire_phys_reg,
	output reg [5:0] phys_rd,
	output reg [5:0] phys_rs1,
	output reg [5:0] phys_rs2,
	output reg free_list_empty
	
);
	parameter NUM_PHYS_REGS = 64;
	 reg [NUM_PHYS_REGS-1:0] free_list;
    reg [5:0] rename_alias_table [31:0];
	 //reg[5:0] next_phys_reg;
    integer i;

    // Combinational logic for renaming
    always @(*) begin
        
        if (issue_valid) begin
            // Find first free register combinationally
				phys_rd = 6'b111111;
				free_list_empty = 0;
				
            for(i = 0; i < NUM_PHYS_REGS; i = i + 1) begin
                if (free_list[i] && phys_rd == 6'b111111) begin
                    phys_rd = i[5:0];
              
                end
            end
				if(phys_rd == 6'b111111) begin
					free_list_empty = 1;
					//don't need to implement stalling
					//just print an error
					//don't need to account for flushing instructions, so don't need to store prev phys_reg in ROB, only the current, replace current tag with old tag
				end
				else begin
					phys_rs1 = rename_alias_table[rs1]; 
					phys_rs2 = rename_alias_table[rs2];
				end
        end
    end

    // Sequential logic for state updates only
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset free_list and alias table
            free_list <= {NUM_PHYS_REGS{1'b1}};
            for (i = 0; i < 32; i = i + 1) begin
                rename_alias_table[i] <= i;
                free_list[i] <= 1'b0;
            end
        end
        else begin
            if(issue_valid && !free_list_empty) begin
                // Update state based on the combinationally computed phys_rd
                free_list[phys_rd] <= 1'b0;
                rename_alias_table[rd] <= phys_rd;
            end
            
            if(retire_valid) begin
                free_list[retire_phys_reg] <= 1'b1;
            end
        end
    end

endmodule