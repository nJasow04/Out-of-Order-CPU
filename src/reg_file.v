module reg_file(
    input clk,
    input reset_n,
    input [4:0] rs1,         // Read register 1
    input [4:0] rs2,         // Read register 2
    input [4:0] rd1,         // Write register 1
    input [31:0] rd1_data,   // Data to write for retire 1
    input RegWrite1,         // Write enable signal for retire 1
    input [4:0] rd2,         // Write register 2
    input [31:0] rd2_data,   // Data to write for retire 2
    input RegWrite2,         // Write enable signal for retire 2
    output reg [31:0] rs1_data, // Data output for rs1
    output reg [31:0] rs2_data  // Data output for rs2
);

    // Define the register file (32 registers, 32-bit wide)
    reg [31:0] registers [0:31];
    reg prev_RegWrite1;
    reg prev_RegWrite2;

    // Read register data (asynchronous read)
    always @(*) begin
        rs1_data = (rs1 == 5'b00000) ? 32'b0 : registers[rs1]; // x0 is always 0
        rs2_data = (rs2 == 5'b00000) ? 32'b0 : registers[rs2]; // x0 is always 0
		if(RegWrite1)begin
			prev_RegWrite1 = RegWrite1;
		end else 
        begin
			prev_RegWrite1 = 0;
		end
		if(RegWrite2)begin
				prev_RegWrite2 = RegWrite2;
		end 
        else begin
			prev_RegWrite2 = 0;
		end
    end

    integer i;
    // Write register data (synchronous write)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] = 32'd0;
            end
        end
        else begin
            // Handle write for retire 1
            if (prev_RegWrite1 && (rd1 != 5'b00000)) begin
                registers[rd1] <= rd1_data; // Write data to rd1 if RegWrite1 is enabled
            end
            // Handle write for retire 2
            if (prev_RegWrite2 && (rd2 != 5'b00000)) begin
                registers[rd2] <= rd2_data; // Write data to rd2 if RegWrite2 is enabled
            end
        end
    end

endmodule
