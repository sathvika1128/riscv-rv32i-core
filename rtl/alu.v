//=============================================================================
// Module: alu
// Description: 32-bit Arithmetic Logic Unit (ALU) for RISC-V (RV32I).
//              Performs arithmetic (ADD, SUB), logical (AND, OR, XOR),
//              comparison (SLT, SLTU), shifts (SLL, SRL, SRA), and pass-through.
//=============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module alu (
    input      [31:0] a,          // Operand A (from rs1 or PC)
    input      [31:0] b,          // Operand B (from rs2 or immediate)
    input      [3:0]  alu_ctrl,   // 4-bit ALU control operation code
    output reg [31:0] alu_result, // 32-bit computed result
    output            zero        // Zero flag (asserted if result == 0)
);

    // Shift amount is always lower 5 bits of operand B (0 to 31 shifts)
    wire [4:0] shamt = b[4:0];

    always @(*) begin
        case (alu_ctrl)
            `ALU_ADD:    alu_result = a + b;
            `ALU_SUB:    alu_result = a - b;
            `ALU_AND:    alu_result = a & b;
            `ALU_OR:     alu_result = a | b;
            `ALU_XOR:    alu_result = a ^ b;
            `ALU_SLT:    alu_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLTU:   alu_result = (a < b) ? 32'd1 : 32'd0;
            `ALU_SLL:    alu_result = a << shamt;
            `ALU_SRL:    alu_result = a >> shamt;
            `ALU_SRA:    alu_result = $signed(a) >>> shamt;
            `ALU_PASS_B: alu_result = b; // Pass immediate directly (used for LUI)
            default:     alu_result = 32'h0000_0000;
        endcase
    end

    // Zero flag generation (useful for comparisons)
    assign zero = (alu_result == 32'h0000_0000);

endmodule
