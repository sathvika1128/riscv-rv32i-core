//=============================================================================
// Module: program_counter
// Description: 32-bit Program Counter (PC) Register for RISC-V processor.
//              Synchronous update on positive clock edge, asynchronous active-low
//              reset to address 0x0000_0000.
//=============================================================================

`timescale 1ns / 1ps

module program_counter (
    input             clk,
    input             rst_n,
    input      [31:0] pc_next,
    output reg [31:0] pc
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h0000_0000;
        end else begin
            pc <= pc_next;
        end
    end

endmodule
