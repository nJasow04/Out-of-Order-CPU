module cpu_tb;
  
    reg clk = 0;
    reg reset = 0;
  
    reg [7:0] instruction_bytes [0:1023];  
    
    // Top level
    cpu_top cpu_uut (
        .clk(clk),
        .reset_n(reset)
    );

    // instruction memory
    reg [31:0] instruction_memory [0:255];

    // Clock generation
    always #100 clk = ~clk;

    // Integer for looping
    integer i;

    initial begin
        // Set up waveform dumping
        $dumpfile("dump.vcd"); 
        $dumpvars(0, cpu_uut);  
      	
        // Apply reset and then simulate
        #50 reset = 1; 

        #1000;
        $finish();
    end
endmodule