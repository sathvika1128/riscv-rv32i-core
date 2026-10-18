//=============================================================================
// File: riscv_defines.vh
// Description: Standard RISC-V (RV32I) Base Integer Instruction Set Definitions.
//              Contains opcodes, funct3/funct7 codes, and internal ALU control flags.
//=============================================================================

`ifndef RISCV_DEFINES_VH
`define RISCV_DEFINES_VH

//-----------------------------------------------------------------------------
// Base RV32I 7-bit Opcodes (instruction[6:0])
//-----------------------------------------------------------------------------
`define OPCODE_R_TYPE      7'b0110011  // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
`define OPCODE_I_ARITH     7'b0010011  // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
`define OPCODE_I_LOAD      7'b0000011  // LB, LH, LW, LBU, LHU
`define OPCODE_S_TYPE      7'b0100011  // SB, SH, SW
`define OPCODE_B_TYPE      7'b1100011  // BEQ, BNE, BLT, BGE, BLTU, BGEU
`define OPCODE_JAL         7'b1101111  // JAL (Jump and Link)
`define OPCODE_JALR        7'b1100111  // JALR (Jump and Link Register)
`define OPCODE_LUI         7'b0110111  // LUI (Load Upper Immediate)
`define OPCODE_AUIPC       7'b0010111  // AUIPC (Add Upper Immediate to PC)
`define OPCODE_SYSTEM      7'b1110011  // ECALL, EBREAK, CSR (Environment Calls)
`define OPCODE_FENCE       7'b0001111  // FENCE

//-----------------------------------------------------------------------------
// funct3 Constants
//-----------------------------------------------------------------------------
// Arithmetic & Logic (R-type and I-type)
`define FUNCT3_ADD_SUB     3'b000
`define FUNCT3_SLL         3'b001
`define FUNCT3_SLT         3'b010
`define FUNCT3_SLTU        3'b011
`define FUNCT3_XOR         3'b100
`define FUNCT3_SRL_SRA     3'b101
`define FUNCT3_OR          3'b110
`define FUNCT3_AND         3'b111

// Branch Conditions (B-type)
`define FUNCT3_BEQ         3'b000
`define FUNCT3_BNE         3'b001
`define FUNCT3_BLT         3'b100
`define FUNCT3_BGE         3'b101
`define FUNCT3_BLTU        3'b110
`define FUNCT3_BGEU        3'b111

// Load Operations (I-type Load)
`define FUNCT3_LB          3'b000
`define FUNCT3_LH          3'b001
`define FUNCT3_LW          3'b010
`define FUNCT3_LBU         3'b100
`define FUNCT3_LHU         3'b101

// Store Operations (S-type Store)
`define FUNCT3_SB          3'b000
`define FUNCT3_SH          3'b001
`define FUNCT3_SW          3'b010

//-----------------------------------------------------------------------------
// funct7 Constants (instruction[31:25])
//-----------------------------------------------------------------------------
`define FUNCT7_BASE        7'b0000000
`define FUNCT7_SUB_SRA     7'b0100000

//-----------------------------------------------------------------------------
// Internal ALU Control Codes (4-bit encoded)
//-----------------------------------------------------------------------------
`define ALU_ADD            4'b0000
`define ALU_SUB            4'b0001
`define ALU_AND            4'b0010
`define ALU_OR             4'b0011
`define ALU_XOR            4'b0100
`define ALU_SLT            4'b0101  // Signed Less-Than
`define ALU_SLTU           4'b0110  // Unsigned Less-Than
`define ALU_SLL            4'b0111  // Shift Left Logical
`define ALU_SRL            4'b1000  // Shift Right Logical
`define ALU_SRA            4'b1001  // Shift Right Arithmetic
`define ALU_PASS_B         4'b1010  // Pass Operand B directly (for LUI)

`endif // RISCV_DEFINES_VH
