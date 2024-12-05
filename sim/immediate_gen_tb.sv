module immediate_gen_tb;

	reg [31:0] instruction = 0;
	reg [31:0] immediate;

	immediate_generate immediate_gen(
		.instruction(instruction),
		.immediate(immediate)
		);
		
	initial begin
		#10 instruction = 32'h00600113;
		#10 $display("%d",immediate);
		#10 instruction = 32'h00400113;
		#10 $display("%d",immediate);
		#10 instruction = 32'h12345037;
		#10 $display("%d",immediate);
		
	end
endmodule	
