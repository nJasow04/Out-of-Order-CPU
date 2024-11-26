// This module is a priority encoder used to find the first two entries in a table
module priority_encoder #(
    parameter ENTRY_COUNT = 64
)(
    input [ENTRY_COUNT-1:0] free_table,
    output reg [$clog2(ENTRY_COUNT)-1:0] free_index,
    output reg valid
);
    integer i;

    always @(*) begin
        free_index = 0;
        valid = 0;

        for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
            if (!valid && free_table[i] == 1'b0) begin // Check only if no valid entry is found
                free_index = i[$clog2(ENTRY_COUNT)-1:0];
                valid = 1'b1;
            end
        end
    end
endmodule
