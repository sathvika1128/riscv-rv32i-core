//=============================================================================
// Module: register_file
// Description: 32 x 32-bit General Purpose Register File for RISC-V (RV32I).
//              - 2 asynchronous read ports (rs1, rs2) for single-cycle access.
//              - 1 synchronous write port (rd) enabled by reg_write on posedge clk.
//              - Register x0 is HARDWIRED TO ZERO (reads always 0, writes ignored).
//=============================================================================

`timescale 1ns / 1ps

module register_file (
    input             clk,
    input             rst_n,
    input             reg_write, // Write enable
    input      [4:0]  rs1_addr,  // Source register 1 address (0-31)
    input      [4:0]  rs2_addr,  // Source register 2 address (0-31)
    input      [4:0]  rd_addr,   // Destination register address (0-31)
    input      [31:0] rd_data,   // Write data input
    output     [31:0] rs1_data,  // Read data port 1
    output     [31:0] rs2_data   // Read data port 2
);

    // 32 registers of 32-bit width (registers x1 to x31 stored in memory)
    (* KEEP = "TRUE" *) reg [31:0] registers [0:31];

    // Asynchronous Read Ports (x0 is always 0)
    assign rs1_data = (rs1_addr == 5'd0) ? 32'h0000_0000 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'h0000_0000 : registers[rs2_addr];

    // Synchronous Write Port (Writes to x0 are discarded)
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h0000_0000;
            end
        end else if (reg_write && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= rd_data;
        end
    end

endmodule
