module reorder_buffer(
	input clk,
	input reset_n,
	
	input alloc_valid,
	input alloc_instr_addr,
	input [5:0] alloc_dest,
	input [5:0] alloc_oldDest, 
   output wire alloc_ready, //tells if possible to allocate
	
	input writeback_valid,
	input [5:0] writeback_idx, //writeback rob location
	input [31:0] writeback_value, //writeback rob destination reg value
	output reg [5:0] writeback_dest, //for forwarding without retiring??
	
	output reg commit_valid,
	output reg [5:0] commit_dest,
	output reg [5:0] free_oldDest, 
	output reg [31:0] commit_value, //output the ready value to the reg file
	input commit_ready
);
	 reg rob_valid[63:0];      // valid bit for each entry
    reg [5:0] rob_dest[63:0];        // destination register for each entry
    reg [5:0] rob_oldDest[63:0];     // previous destination register for each entry
    reg [32:0] rob_instr_addr[63:0];        // instruction address for each entry
    reg rob_result_ready[63:0];      // result ready bit for each entry
    reg [31:0] rob_value[63:0];      // value for each entry
	
	reg [5:0] head, tail;
	integer i;
	assign alloc_ready = !((tail + 1) % 64 == head);
	
	always @(*) begin
		if(commit_ready && rob_valid[head] && rob_result_ready[head]) begin
				commit_valid = 1;
				commit_dest = rob_dest[head];
				free_oldDest = rob_oldDest[head];
				commit_value = rob_value[head];
				i=0;
		end
		else begin
				commit_valid = 0;
				commit_dest = 6'b111111;
				free_oldDest = 6'b111111;
				commit_value = 0;
				i=0;
		end
	end
	
	always @(negedge clk or negedge reset_n) begin
		if (!reset_n) begin
			for(i = 0; i< 64; i=i+1) begin
				rob_valid[i] <= 0;
				rob_result_ready[i] <= 0;
				rob_dest[i] <=0;
				rob_oldDest[i] <= 0;
				rob_value[i] <=0;
				rob_instr_addr[i] <= 0;
			end
			head<= 0;
			tail <= 0;
			i=0;
		end
		else begin
			if (alloc_valid && alloc_ready) begin
				rob_valid[tail] <= 1;
				rob_instr_addr[tail] <= alloc_instr_addr;
				rob_dest[tail] <= alloc_dest;
				rob_oldDest[tail] <= alloc_oldDest;
				rob_result_ready[tail] <= 0;
				tail <= (tail +1) % 64;
			end
			if (writeback_valid) begin
				rob_result_ready[writeback_idx] <= 1;
				rob_value[writeback_idx] <= writeback_value;
				
			end
			
			if(commit_ready && rob_valid[head] && rob_result_ready[head]) begin
				rob_valid[head] <= 0;
				head <= (head+1) % 64;
			end
			i=0;
			
		end
	end
endmodule