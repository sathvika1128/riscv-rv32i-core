//=============================================================================
// Module: instruction_memory
// Description: Harvard Architecture Instruction Memory (ROM) for RISC-V.
//              - Word-aligned 32-bit addressing (addr[ADDR_WIDTH+1:2]).
//              - Asynchronous/combinational read for single-cycle execution.
//              - Supports loading compiled programs via $readmemh.
//=============================================================================

`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_DEPTH  = 256,              // 256 words (1 KB)
    parameter ADDR_WIDTH = $clog2(MEM_DEPTH) // Address bits (8 bits for 256 words)
)(
    input  [31:0] addr,                      // Byte address from Program Counter
    output [31:0] instruction               // 32-bit fetched instruction
);

    // Memory array
    reg [31:0] mem [0:MEM_DEPTH-1];

    // Word-aligned index (ignore lower 2 byte-offset bits)
    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2];

    // Combinational read for single-cycle datapath
    assign instruction = mem[word_addr];

    // Default initialization: preloaded with verification test suite
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h0000_0013; // RISC-V standard NOP
        end

        // Program 1: Arithmetic & Logic Verification
        mem[0]  = 32'h00a00093; // 0x00: addi x1, x0, 10
        mem[1]  = 32'h01400113; // 0x04: addi x2, x0, 20
        mem[2]  = 32'h002081b3; // 0x08: add  x3, x1, x2
        mem[3]  = 32'h40110233; // 0x0C: sub  x4, x2, x1
        mem[4]  = 32'h0020f2b3; // 0x10: and  x5, x1, x2
        mem[5]  = 32'h0020e333; // 0x14: or   x6, x1, x2
        mem[6]  = 32'h0020c3b3; // 0x18: xor  x7, x1, x2
        mem[7]  = 32'h00209413; // 0x1C: slli x8, x1, 2
        mem[8]  = 32'h40145493; // 0x20: srai x9, x8, 1
        mem[9]  = 32'h0020a533; // 0x24: slt  x10, x1, x2

        // Program 2: U-Type Instructions
        mem[10] = 32'h123455b7; // 0x28: lui   x11, 0x12345
        mem[11] = 32'h00001617; // 0x2C: auipc x12, 0x00001

        // Program 3: Memory Operations (SW, LW, SB, LBU, SH, LH)
        mem[12] = 32'h00302023; // 0x30: sw   x3, 0(x0)
        mem[13] = 32'h00002683; // 0x34: lw   x13, 0(x0)
        mem[14] = 32'h00100223; // 0x38: sb   x1, 4(x0)
        mem[15] = 32'h00404703; // 0x3C: lbu  x14, 4(x0)
        mem[16] = 32'h00201323; // 0x40: sh   x2, 6(x0)
        mem[17] = 32'h00601783; // 0x44: lh   x15, 6(x0)

        // Program 4: Loop with Conditional Branches (Sum 1+2+3 = 6)
        mem[18] = 32'h00300813; // 0x48: addi x16, x0, 3
        mem[19] = 32'h00000893; // 0x4C: addi x17, x0, 0
        mem[20] = 32'h00100913; // 0x50: addi x18, x0, 1
        mem[21] = 32'h012888b3; // 0x54: add  x17, x17, x18
        mem[22] = 32'h00190913; // 0x58: addi x18, x18, 1
        mem[23] = 32'hff094ce3; // 0x5C: blt  x18, x16, -8
        mem[24] = 32'hff090ae3; // 0x60: beq  x18, x16, -12

        // Program 5: x0 Immutability
        mem[25] = 32'h3e700013; // 0x64: addi x0, x0, 999

        // Program 6: Jump and Link (JAL)
        mem[26] = 32'h008009ef; // 0x68: jal  x19, 8
        mem[27] = 32'h06f00a13; // 0x6C: addi x20, x0, 111 (skipped)
        mem[28] = 32'h0de00a13; // 0x70: addi x20, x0, 222 (target)
        mem[29] = 32'h0000006f; // 0x74: jal  x0, 0 (infinite self-loop)
    end

endmodule
