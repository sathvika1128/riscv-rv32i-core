//=============================================================================
// Module: control_unit
// Description: Main Combinational Control Unit for Single-Cycle RISC-V (RV32I).
//              Decodes the 7-bit opcode to generate all datapath control signals:
//              register write enables, memory enables, multiplexer selects,
//              ALU mode, and jump/branch directives.
//              NO state machines or delays — 100% pure combinational logic.
//=============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module control_unit (
    input      [6:0] opcode,        // 7-bit instruction opcode [6:0]
    output reg       branch_en,     // Asserted for conditional branches (B-type)
    output reg       mem_read,      // Asserted for load instructions (I-type load)
    output reg [1:0] mem_to_reg,    // Writeback mux select: 00=ALU, 01=Mem, 10=PC+4
    output reg [1:0] alu_op,        // ALU operation mode to ALU control decoder
    output reg       mem_write,     // Asserted for store instructions (S-type)
    output reg       alu_src_b,     // ALU operand B mux: 0=rs2, 1=Immediate
    output reg [1:0] alu_src_a,     // ALU operand A mux: 00=rs1, 01=PC (AUIPC)
    output reg       reg_write,     // Register file write enable
    output reg [1:0] jump           // Jump type: 00=None, 01=JAL, 10=JALR
);

    always @(*) begin
        // Default safe values (NOP state)
        branch_en  = 1'b0;
        mem_read   = 1'b0;
        mem_to_reg = 2'b00;
        alu_op     = 2'b00;
        mem_write  = 1'b0;
        alu_src_b  = 1'b0;
        alu_src_a  = 2'b00;
        reg_write  = 1'b0;
        jump       = 2'b00;

        case (opcode)
            // R-type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
            `OPCODE_R_TYPE: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b0;   // Operand B from rs2
                alu_src_a  = 2'b00;  // Operand A from rs1
                alu_op     = 2'b10;  // R-type ALU decode
                mem_to_reg = 2'b00;  // Writeback ALU result
            end

            // I-type Arithmetic: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            `OPCODE_I_ARITH: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;   // Operand B from Immediate
                alu_src_a  = 2'b00;  // Operand A from rs1
                alu_op     = 2'b10;  // I-type ALU decode
                mem_to_reg = 2'b00;  // Writeback ALU result
            end

            // I-type Load: LB, LH, LW, LBU, LHU
            `OPCODE_I_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src_b  = 1'b1;   // Address = rs1 + immediate
                alu_src_a  = 2'b00;  // Base address from rs1
                alu_op     = 2'b00;  // Addition for address calculation
                mem_to_reg = 2'b01;  // Writeback memory data to rd
            end

            // S-type Store: SB, SH, SW
            `OPCODE_S_TYPE: begin
                mem_write  = 1'b1;
                alu_src_b  = 1'b1;   // Address = rs1 + immediate
                alu_src_a  = 2'b00;  // Base address from rs1
                alu_op     = 2'b00;  // Addition for address calculation
            end

            // B-type Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU
            `OPCODE_B_TYPE: begin
                branch_en  = 1'b1;
                alu_src_b  = 1'b0;   // Compare rs1 and rs2
                alu_src_a  = 2'b00;
                alu_op     = 2'b01;  // Subtraction / comparison
            end

            // U-type LUI: Load Upper Immediate (rd = imm << 12)
            `OPCODE_LUI: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;   // Upper immediate
                alu_op     = 2'b11;  // Pass immediate B directly
                mem_to_reg = 2'b00;  // Writeback ALU result to rd
            end

            // U-type AUIPC: Add Upper Immediate to PC (rd = PC + (imm << 12))
            `OPCODE_AUIPC: begin
                reg_write  = 1'b1;
                alu_src_a  = 2'b01;  // Operand A is PC!
                alu_src_b  = 1'b1;   // Operand B is Upper Immediate
                alu_op     = 2'b00;  // Add PC + imm
                mem_to_reg = 2'b00;  // Writeback ALU result to rd
            end

            // J-type JAL: Jump and Link (rd = PC + 4; PC = PC + imm)
            `OPCODE_JAL: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b10;  // Writeback (PC + 4) to rd
                jump       = 2'b01;  // Direct jump (PC + imm)
            end

            // I-type JALR: Jump and Link Register (rd = PC + 4; PC = (rs1 + imm) & ~1)
            `OPCODE_JALR: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b10;  // Writeback (PC + 4) to rd
                alu_src_a  = 2'b00;  // Operand A is rs1
                alu_src_b  = 1'b1;   // Operand B is immediate
                alu_op     = 2'b00;  // ALU computes rs1 + imm
                jump       = 2'b10;  // Indirect jump (ALU result)
            end

            default: begin
                // Safe defaults (NOP)
            end
        endcase
    end

endmodule
