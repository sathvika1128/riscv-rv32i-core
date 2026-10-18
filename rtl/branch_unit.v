//=============================================================================
// Module: branch_unit
// Description: Branch Comparator Unit for RISC-V (RV32I).
//              Evaluates conditional branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)
//              by comparing rs1 and rs2 based on funct3.
//=============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module branch_unit (
    input      [31:0] rs1_data,        // Data from rs1
    input      [31:0] rs2_data,        // Data from rs2
    input      [2:0]  funct3,          // Branch condition code
    input             branch_en,       // Asserted for B-type instructions
    output reg        branch_decision  // 1 if branch condition is satisfied, else 0
);

    reg condition_met;

    always @(*) begin
        case (funct3)
            `FUNCT3_BEQ:  condition_met = (rs1_data == rs2_data);
            `FUNCT3_BNE:  condition_met = (rs1_data != rs2_data);
            `FUNCT3_BLT:  condition_met = ($signed(rs1_data) < $signed(rs2_data));
            `FUNCT3_BGE:  condition_met = ($signed(rs1_data) >= $signed(rs2_data));
            `FUNCT3_BLTU: condition_met = (rs1_data < rs2_data);
            `FUNCT3_BGEU: condition_met = (rs1_data >= rs2_data);
            default:      condition_met = 1'b0;
        endcase

        branch_decision = branch_en & condition_met;
    end

endmodule
