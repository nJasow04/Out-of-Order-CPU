module pipeline_buffer_execute (
    input clk,
    input reset_n,
	 input stall,
    input [146:0] data_in,
    output reg [146:0] data_out
);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            data_out <= 146'd0;
		  else if(stall) begin
				data_out <= data_out;
		  end
        else begin
            data_out <= data_in;
        end
    end
endmodule