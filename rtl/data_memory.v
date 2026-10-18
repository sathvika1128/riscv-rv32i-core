//=============================================================================
// Module: data_memory
// Description: Byte-Addressable Data Memory (RAM) for RISC-V (RV32I).
//              - Supports all RV32I load types: LB, LBU, LH, LHU, LW.
//              - Supports all RV32I store types: SB, SH, SW.
//              - 4-bank byte-lane architecture for clean FPGA/ASIC synthesis.
//              - Combinational read for single-cycle datapath, synchronous write.
//=============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module data_memory #(
    parameter MEM_DEPTH  = 256,              // 256 words (1024 bytes)
    parameter ADDR_WIDTH = $clog2(MEM_DEPTH) // 8 bits for 256 words
)(
    input             clk,
    input             mem_read,     // Read enable
    input             mem_write,    // Write enable
    input      [2:0]  funct3,       // Width and sign mode (LB, LH, LW, LBU, LHU, SB, SH, SW)
    input      [31:0] addr,         // 32-bit byte address from ALU
    input      [31:0] write_data,   // 32-bit data to store (from rs2)
    output reg [31:0] read_data     // 32-bit formatted data to writeback
);

    // 4 byte-wide memory banks to handle byte, halfword, and word accesses
    reg [7:0] mem0 [0:MEM_DEPTH-1]; // Byte offset 00
    reg [7:0] mem1 [0:MEM_DEPTH-1]; // Byte offset 01
    reg [7:0] mem2 [0:MEM_DEPTH-1]; // Byte offset 10
    reg [7:0] mem3 [0:MEM_DEPTH-1]; // Byte offset 11

    // Address decoding
    wire [ADDR_WIDTH-1:0] word_addr   = addr[ADDR_WIDTH+1:2];
    wire [1:0]            byte_offset = addr[1:0];

    // Raw 32-bit word assembled from the 4 byte banks
    wire [31:0] raw_word = {mem3[word_addr], mem2[word_addr], mem1[word_addr], mem0[word_addr]};

    // Extract targeted byte and halfword based on address offset
    reg [7:0]  selected_byte;
    reg [15:0] selected_half;

    always @(*) begin
        case (byte_offset)
            2'b00: selected_byte = raw_word[7:0];
            2'b01: selected_byte = raw_word[15:8];
            2'b10: selected_byte = raw_word[23:16];
            2'b11: selected_byte = raw_word[31:24];
        endcase

        case (byte_offset[1])
            1'b0:  selected_half = raw_word[15:0];  // Lower halfword
            1'b1:  selected_half = raw_word[31:16]; // Upper halfword
        endcase
    end

    // Combinational Read Logic (with sign/zero extension)
    always @(*) begin
        if (mem_read) begin
            case (funct3)
                `FUNCT3_LB:  read_data = {{24{selected_byte[7]}}, selected_byte}; // Sign-extended byte
                `FUNCT3_LBU: read_data = {24'h000000, selected_byte};             // Zero-extended byte
                `FUNCT3_LH:  read_data = {{16{selected_half[15]}}, selected_half}; // Sign-extended halfword
                `FUNCT3_LHU: read_data = {16'h0000, selected_half};               // Zero-extended halfword
                `FUNCT3_LW:  read_data = raw_word;                                // 32-bit word
                default:     read_data = 32'h0000_0000;
            endcase
        end else begin
            read_data = 32'h0000_0000;
        end
    end

    // Synchronous Write Logic (Byte, Halfword, Word stores)
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                // SB: Store Byte
                `FUNCT3_SB: begin
                    case (byte_offset)
                        2'b00: mem0[word_addr] <= write_data[7:0];
                        2'b01: mem1[word_addr] <= write_data[7:0];
                        2'b10: mem2[word_addr] <= write_data[7:0];
                        2'b11: mem3[word_addr] <= write_data[7:0];
                    endcase
                end

                // SH: Store Halfword
                `FUNCT3_SH: begin
                    if (!byte_offset[1]) begin
                        mem0[word_addr] <= write_data[7:0];
                        mem1[word_addr] <= write_data[15:8];
                    end else begin
                        mem2[word_addr] <= write_data[7:0];
                        mem3[word_addr] <= write_data[15:8];
                    end
                end

                // SW: Store Word (all 4 bytes)
                `FUNCT3_SW: begin
                    mem0[word_addr] <= write_data[7:0];
                    mem1[word_addr] <= write_data[15:8];
                    mem2[word_addr] <= write_data[23:16];
                    mem3[word_addr] <= write_data[31:24];
                end

                default: begin
                    // Do nothing
                end
            endcase
        end
    end

    // Initial memory clear
    integer k;
    initial begin
        for (k = 0; k < MEM_DEPTH; k = k + 1) begin
            mem0[k] = 8'h00;
            mem1[k] = 8'h00;
            mem2[k] = 8'h00;
            mem3[k] = 8'h00;
        end
    end

endmodule
