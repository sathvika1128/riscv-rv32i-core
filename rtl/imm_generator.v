//=============================================================================
// Module: imm_generator
// Description: Immediate Sign-Extension Generator for RISC-V (RV32I).
//              Decodes and sign-extends immediate fields for all standard
//              instruction formats: I-type, S-type, B-type, U-type, and J-type.
//=============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module imm_generator (
    input      [31:0] instruction, // 32-bit instruction word
    output reg [31:0] imm_out      // 32-bit sign-extended immediate
);

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-type: Arithmetic Immediates, Loads, JALR
            `OPCODE_I_ARITH,
            `OPCODE_I_LOAD,
            `OPCODE_JALR: begin
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
            end

            // S-type: Store Immediates (SW, SH, SB)
            `OPCODE_S_TYPE: begin
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            // B-type: Conditional Branch Immediates (BEQ, BNE, BLT, etc.)
            // Note: Bit 0 is always 0 for half-word aligned branch offsets
            `OPCODE_B_TYPE: begin
                imm_out = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end

            // U-type: Upper Immediates (LUI, AUIPC) - 20 bits placed in [31:12]
            `OPCODE_LUI,
            `OPCODE_AUIPC: begin
                imm_out = {instruction[31:12], 12'h000};
            end

            // J-type: Jump and Link (JAL)
            // Note: Bit 0 is always 0 for half-word aligned jump offsets
            `OPCODE_JAL: begin
                imm_out = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end

            // Default (R-type or unsupported)
            default: begin
                imm_out = 32'h0000_0000;
            end
        endcase
    end

endmodule
