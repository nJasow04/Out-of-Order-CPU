module reg_file(
    input clk,
    input [4:0] rs1,         // Read register 1
    input [4:0] rs2,         // Read register 2
    input [4:0] rd,          // Write register
    input [31:0] rd_data,    // Data to write
    input RegWrite,          // Write enable signal
    output reg [31:0] rs1_data, // Data output for rs1
    output reg [31:0] rs2_data  // Data output for rs2
);

    // Define the register file (32 registers, 32-bit wide)
    reg [31:0] registers [0:31];

    // Read register data (asynchronous read)
    always @(*) begin
        rs1_data = (rs1 == 5'b00000) ? 32'b0 : registers[rs1]; // x0 is always 0
        rs2_data = (rs2 == 5'b00000) ? 32'b0 : registers[rs2]; // x0 is always 0
    end

    // Write register data (synchronous write)
    always @(posedge clk) begin
        if (RegWrite && (rd != 5'b00000)) begin
            registers[rd] <= rd_data; // Write data to rd if RegWrite is enabled
        end
    end

endmodule