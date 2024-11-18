module immediate_generate (
    input [31:0] instruction,
    output reg [31:0] immediate
);
    // opcodes
    parameter R_TYPE = 7'b0110011;
    parameter I_TYPE = 7'b0010011;
    parameter S_TYPE = 7'b0100011;
    parameter U_TYPE = 7'b0110111;
	parameter LW_TYPE = 7'b0000011;
    
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            R_TYPE: 
                begin
                    immediate[31:0] = 32'd0;
                end
            I_TYPE: 
                begin
                    immediate = { { 20{instruction[31]} }, instruction[31:20]}; // sign-extend MSB
                end
			LW_TYPE:
                begin
                    immediate = { { 20{instruction[31]} }, instruction[31:20]}; // sign-extend
                end
            S_TYPE: 
                begin
                    immediate = { {20{ instruction[31]} } , instruction[31:25], instruction[11:7]}; // sign-extend MSB
                end
            U_TYPE: 
                begin
                    immediate = { instruction[31:12], 12'd0}; // zero-extend the remaining bits
                end
            default:
                begin
                    immediate[31:0] = 32'd0;
                end
        endcase

    end

endmodule