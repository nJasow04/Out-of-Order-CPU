module cpu_tb ();
  
    reg clk, reset_n;
    
    // Top level
    cpu_top cpu_uut (
        .clk(clk),
        .reset_n(reset_n)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        reset_n = 1'b0;
    end
    
    always #100 clk = ~clk;

    initial begin
        #50 reset_n = 1; 
        	
        repeat (30) @(posedge clk);

        $stop();
    end
endmodule