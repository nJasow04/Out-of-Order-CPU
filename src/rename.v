module rename (
    input clk,
    input reset_n,
    input issue_valid,
    
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
	 input retire_valid1,
	 input isStore,
	input [5:0] retire_phys_reg1,
	//input [5:0] retire_cur_phys_reg1,
	input retire_valid2,
	//input [5:0] retire_cur_phys_reg2,
	input [5:0] retire_phys_reg2,
	//input complete_valid,
	//input [5:0] complete_phys_reg,
	output reg [5:0] phys_rd,
	output reg [5:0] phys_rs1,
	output reg [5:0] phys_rs2,
	output reg [5:0] old_phys_rd,
	output reg [4:0] arch_reg,
	output reg free_list_empty,
	output reg rename_valid
	
);
	parameter NUM_PHYS_REGS = 64;
	 reg [NUM_PHYS_REGS-1:0] free_list;
    reg [5:0] rename_alias_table [31:0];
	 reg [5:0] prev_rd;
	 reg prev_issue_valid;
	 reg prev_retire_valid1;
	 reg prev_retire_valid2;
	 reg [5:0] prev_retire_phys_reg1;
	 reg [5:0] prev_retire_phys_reg2;
    integer i;

	 
    // Combinational logic for renaming
    always @(*) begin
	 
			phys_rd = 6'b111111;
			free_list_empty = 0;
			i=0;
			rename_valid = 0;
			phys_rs1=6'b111111;
			phys_rs2=6'b111111;
			old_phys_rd=6'b111111;
			arch_reg = 5'b11111;
			//arch_reg2 = 5'b11111;
			
		  if (issue_valid)begin
				phys_rd = 6'b111111;
				free_list_empty = 0;
            // Find first free register combinationally
				if(isStore) begin
					phys_rd = 6'b111111;
					arch_reg = 5'b11111;
				end else begin
					for(i = 0; i < NUM_PHYS_REGS; i = i + 1) begin
						 if (free_list[i] && phys_rd == 6'b111111) begin
							  phys_rd = i[5:0];
						 end
					end
				end
                //don't need to implement stall, just print an error
                //don't need to account for flushing instructions, so don't need to store prev phys_reg in ROB, only the current, replace current tag with old tag
				if(phys_rd != 6'b111111 || isStore) begin
                rename_valid = 1'b1;
					 
                phys_rs1 = rename_alias_table[rs1]; 
                phys_rs2 = rename_alias_table[rs2];
					 if(!isStore)begin
						old_phys_rd = rename_alias_table[rd];
						arch_reg = rd;
					 end
            end else begin
                free_list_empty = 1'b1;
            end
				
			end
			
		  if (retire_valid1) begin
            /*arch_reg1 = 5'b11111; // Default invalid value
            for (i = 0; i < 32; i = i + 1) begin
                if (arch_reg1 == 5'b11111 && rename_alias_table[i] == retire_cur_phys_reg1) begin
                    arch_reg1 = i[4:0]; // Found the architectural register
                end
            end*/
				prev_retire_phys_reg1 = retire_phys_reg1;
				prev_retire_valid1=retire_valid1;
        end else begin
				prev_retire_valid1=0;
		  end
		  if (retire_valid2) begin
            /*arch_reg2 = 5'b11111; // Default invalid value
            for (i = 0; i < 32; i = i + 1) begin
                if (arch_reg2 == 5'b11111 && rename_alias_table[i] == retire_cur_phys_reg2) begin
                    arch_reg2 = i[4:0]; // Found the architectural register
                end
            end
				*/
				prev_retire_phys_reg2 = retire_phys_reg2;
				prev_retire_valid2=retire_valid2;
		  end else begin
				prev_retire_valid2=0;
		  end
    end

    // Sequential logic for state updates only
    always @(posedge clk or negedge reset_n) begin
			//rename_done <= 0;
        if (!reset_n) begin
            //free_list <= {NUM_PHYS_REGS{1'b1}};
				free_list <= {{NUM_PHYS_REGS-32{1'b1}}, {32{1'b0}}};
            for (i = 0; i < 32; i = i + 1) begin
					rename_alias_table[i] <= i;
            end
				prev_rd <= 6'b000000;
        end
        else begin
				prev_rd <= rd;
				prev_issue_valid<=issue_valid;
				//prev_retire_valid1 <= retire_valid1;  // Capture retire_valid1
				//prev_retire_valid2 <= retire_valid2;  // Capture retire_valid2
				
				
            // Update state based on the combinationally computed phys_rd
				
            if(prev_issue_valid && !free_list_empty&&!isStore) begin
                free_list[phys_rd] <= 1'b0;
               rename_alias_table[rd] <= phys_rd;
            end
            // update free list on retire
            if(prev_retire_valid1) begin
                free_list[prev_retire_phys_reg1] <= 1'b1;
            end
				if(prev_retire_valid2) begin
                free_list[prev_retire_phys_reg2] <= 1'b1;				 
            end
				
        end
	end

endmodule