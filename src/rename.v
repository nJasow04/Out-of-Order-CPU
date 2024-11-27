module rename (
    input clk,
	input reset_n,
    input issue_valid,
	input retire_valid,
	input [4:0] rs1,
	input [4:0] rs2,
    input [4:0] rd,
	input [5:0] retire_phys_reg,
	input complete_valid,
	input [5:0] complete_phys_reg,
	output reg [5:0] phys_rd,
	output reg [5:0] phys_rs1,
	output reg [5:0] phys_rs2,
	output reg [5:0] old_phys_rd,
	output reg [4:0] arch_reg,
	output reg free_list_empty
	
);
	parameter NUM_PHYS_REGS = 64;
	 reg [NUM_PHYS_REGS-1:0] free_list;
    reg [5:0] rename_alias_table [31:0];
    integer i;
	 
	 

    // Combinational logic for renaming
    always @(*) begin
        if (issue_valid) begin
		  
				
            // Find first free register combinationally
            for(i = 0; i < NUM_PHYS_REGS; i = i + 1) begin
                if (free_list[i] && phys_rd == 6'b111111) begin
                    phys_rd = i[5:0];
                end
            end
                //don't need to implement stall, just print an error
                //don't need to account for flushing instructions, so don't need to store prev phys_reg in ROB, only the current, replace current tag with old tag
				if(phys_rd == 6'b111111) begin
					free_list_empty = 1;
				end
				else begin
					phys_rs1 = rename_alias_table[rs1]; 
					phys_rs2 = rename_alias_table[rs2];
					old_phys_rd = rename_alias_table[rd];
				end
				
        end
		  else if (retire_valid) begin
            arch_reg = 5'b11111; // Default invalid value
            for (i = 0; i < 32; i = i + 1) begin
                if (arch_reg == 5'b11111 && rename_alias_table[i] == retire_phys_reg) begin
                    arch_reg = i[4:0]; // Found the architectural register
                end
            end
        end
		  else begin
			i=0;
			phys_rd = 6'b111111;
			free_list_empty = 0;
			phys_rs1=6'b111111;
			phys_rs2=6'b111111;
			old_phys_rd=6'b111111;
			arch_reg=5'b11111;
		  end
    end

    // Sequential logic for state updates only
    always @(negedge clk or negedge reset_n) begin
			//rename_done <= 0;
        if (!reset_n) begin
            free_list <= {NUM_PHYS_REGS{1'b1}};
            for (i = 0; i < 32; i = i + 1) begin
					
                rename_alias_table[i] <= i;
                free_list[i] <= 1'b0;
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