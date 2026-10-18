//=============================================================================
// Module: riscv_top
// Description: Basys 3 Board Top-Level Wrapper for Single-Cycle RISC-V Core.
//              - Connects to Basys 3 100 MHz clock and reset push-button.
//              - Includes a clock prescaler to slow down execution to visible speeds
//                (or runs at full speed for benchmarking).
//              - Maps lower 16 bits of ALU result to the 16 on-board LEDs.
//              - Drives the 4-digit 7-segment display with PC or Register values.
//              - Reduces IO pin count to fit within the 106 available FPGA pins.
//=============================================================================

`timescale 1ns / 1ps

module riscv_top (
    input         clk,         // 100 MHz on-board oscillator (Basys 3 pin W5)
    input         btnC,        // Center push-button for Active-High Reset (pin U18)
    output [15:0] led          // 16 user LEDs displaying ALU result (pins U16..L1)
);

    // Active-low reset for core
    wire rst_n = ~btnC;

    // Observability wires from RISC-V Core
    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] alu_result;
    wire [31:0] writeback_data;
    wire        reg_write;
    wire        mem_write;

    // Instantiate the RISC-V Core
    riscv_core u_core (
        .clk                (clk),
        .rst_n              (rst_n),
        .pc_out             (pc),
        .instruction_out    (instruction),
        .alu_result_out     (alu_result),
        .writeback_data_out (writeback_data),
        .reg_write_out      (reg_write),
        .mem_write_out      (mem_write)
    );

    // Display the lower 16 bits of the ALU result on the 16 on-board LEDs
    assign led = alu_result[15:0];

endmodule
