module cpu_tb ();
	
    // parameters:
    integer PC_MAX = 20;

    // holds each byte
    reg [7:0] instruction_bytes [0:1023]; 

    // holds each instruction
    reg [31:0] instruction_mem [0:255];   

    // clock and instructions
    reg clk = 0;
    reg [31:0] instruction = 0;

    integer pc = 0;

    // instantiate CPU
    cpu_top cpu_uut (
        .clk(clk),
        .instruction(instruction),
    );

    always #100 clk = ~clk;

    initial begin

        // create wave forms
		$dumpfile("test.vcd");
      	$dumpvars(1, cpu_tb);

        // Load the bytes from the file
        $readmemh("my_file.txt", instruction_bytes);
        
        for (int i = 0; i < 256; i = i + 1) begin
            instruction_mem[i] = {instruction_bytes[4*i+3], instruction_bytes[4*i+2], instruction_bytes[4*i+1], instruction_bytes[4*i]};
        end

        $display("Contents of instruction memory:");
      	for (int i = 0; i < PC_MAX; i = i + 1) begin
            $display("instruction_mem[%0d] = %h", i, instruction_mem[i]);
        end

    end

    always @(posedge clk) begin
      	if (pc < PC_MAX) begin

            // Read two consecutive instructions
            instruction = instruction_mem[pc];

            pc = pc + 1;
        end
        else begin
            $stop;
        end
    end

endmodule
