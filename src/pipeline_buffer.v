module pipeline_buffer (
    input clk,
    input reset_n,
    input [31:0] data_in,
    output reg [31:0] data_out
);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            data_out <= 32'd0;
        else begin
            data_out <= data_in;
        end
    end
endmodule