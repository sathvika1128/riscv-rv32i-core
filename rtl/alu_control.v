//=============================================================================
// Module: alu_control
// Description: ALU Decoder for RISC-V (RV32I).
//              Translates 2-bit alu_op from main control unit along with
//              instruction funct3, funct7, and opcode fields into the exact
//              4-bit alu_ctrl code for the ALU.
//=============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module alu_control (
    input      [1:0] alu_op,     // 2-bit operation mode from main control
    input      [6:0] opcode,     // Opcode (distinguishes R-type vs I-type)
    input      [2:0] funct3,     // funct3 field (bits [14:12])
    input      [6:0] funct7,     // funct7 field (bits [31:25])
    output reg [3:0] alu_ctrl    // 4-bit ALU operation command
);

    always @(*) begin
        case (alu_op)
            // Mode 00: Force Addition (Load, Store, AUIPC, JALR)
            2'b00: alu_ctrl = `ALU_ADD;

            // Mode 01: Force Subtraction (Branch comparison helper)
            2'b01: alu_ctrl = `ALU_SUB;

            // Mode 11: Pass Immediate B directly (LUI)
            2'b11: alu_ctrl = `ALU_PASS_B;

            // Mode 10: Decode based on funct3 and funct7 (R-type and I-type Arithmetic)
            2'b10: begin
                case (funct3)
                    `FUNCT3_ADD_SUB: begin
                        // In R-type, funct7[5] distinguishes ADD (0) from SUB (1).
                        // In I-type (ADDI), operation is always ADD.
                        if (opcode == `OPCODE_R_TYPE && funct7[5])
                            alu_ctrl = `ALU_SUB;
                        else
                            alu_ctrl = `ALU_ADD;
                    end
                    `FUNCT3_SLL:     alu_ctrl = `ALU_SLL;
                    `FUNCT3_SLT:     alu_ctrl = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_ctrl = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_ctrl = `ALU_XOR;
                    `FUNCT3_SRL_SRA: begin
                        // funct7[5] distinguishes SRL (0) from SRA (1) for both R and I types
                        if (funct7[5])
                            alu_ctrl = `ALU_SRA;
                        else
                            alu_ctrl = `ALU_SRL;
                    end
                    `FUNCT3_OR:      alu_ctrl = `ALU_OR;
                    `FUNCT3_AND:     alu_ctrl = `ALU_AND;
                    default:         alu_ctrl = `ALU_ADD;
                endcase
            end

            default: alu_ctrl = `ALU_ADD;
        endcase
    end

endmodule
