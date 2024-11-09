module cpu_tb;
  
    reg clk = 0;
    reg reset = 0;
  
    reg [7:0] instruction_bytes [0:1023];  
    
    // Top level
    cpu_top cpu_uut (
        .clk(clk),
        .reset_n(reset),
		  .instruction_memory(flat_instruction_memory)
    );
	 
	 // 
	 reg [31:0] instruction_memory [0:255];
	 reg [8191:0] flat_instruction_memory;

    // Clock generation
    always #100 clk = ~clk;

    // Integer for looping
    integer i;

    initial begin
        // Set up waveform dumping
        // $dumpfile("dump.vcd"); 
        // $dumpvars(0, cpu_uut);  

        // Read in the instruction bytes from the file (my_file.txt)
        $readmemh("my_file.txt", instruction_bytes);
      
        // Loop through the instruction bytes and assemble them into 32-bit instructions
        for (i = 0; i < 255; i = i + 1) begin
					instruction_memory[i] = {
                instruction_bytes[4*i+3],  // Least significant byte (LSB)
                instruction_bytes[4*i+2],  // Second byte
                instruction_bytes[4*i+1],  // Third byte
                instruction_bytes[4*i]     // Most significant byte (MSB)
            };
        end
		  for (i = 0; i < 256; i = i + 1) begin
            flat_instruction_memory[i*32 +: 32] = instruction_memory[i];
        end
      	
        // Apply reset and then simulate
        #50 reset = 1; 

        #500;
        $finish();
    end
endmodule