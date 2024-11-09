module cpu_tb;
  
    reg clk = 0;
    reg reset = 1;
  
    reg [7:0] instruction_bytes [0:1023];  // 4 bytes per instruction * 256 instructions = 1024 bytes
    
    // Declare the instruction memory in the fetch unit
    reg [31:0] instruction_memory [0:255];   

    // Instantiate the CPU top module
    cpu_top cpu_uut (
        .clk(clk),
        .reset_n(reset)
    );

    // Clock generation
    always #100 clk = ~clk;

    // Integer for looping
    integer i;

    initial begin
        // Set up waveform dumping
        $dumpfile("dump.vcd"); 
        $dumpvars(0, cpu_uut);  

        // Read in the instruction bytes from the file (my_file.txt)
        $readmemh("my_file.txt", instruction_bytes);
        
        for (int i = 0; i < 256; i = i + 1) begin
            instruction_mem[i] = {instruction_bytes[4*i+3], instruction_bytes[4*i+2], instruction_bytes[4*i+1], instruction_bytes[4*i]};
        end

        $display("Contents of instruction memory:");
		  for (int i = 0; i < PC_MAX; i = i + 1) begin
            $display("instruction_mem[%0d] = %h", i, instruction_mem[i]);
        end
      	
        // Apply reset and then simulate
        #50 reset = 0; 

        #50 reset = 1;
        #500;
        $finish();
    end
endmodule
