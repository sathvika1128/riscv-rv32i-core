//=============================================================================
// Module: riscv_core
// Description: Top-Level Single-Cycle 32-bit RISC-V (RV32I) Processor Core.
//              - Harvard architecture with separate instruction and data memories.
//              - Implements full base integer ISA: R, I, S, B, U, and J formats.
//              - 32x32-bit register file with hardwired x0.
//              - Immediate generator, 32-bit ALU, ALU control decoder,
//                branch decision comparator, and byte-addressable data memory.
//              - Executes one instruction per clock cycle with zero pipeline hazards.
//=============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module riscv_core (
    input         clk,
    input         rst_n,

    // Debug & Observability Outputs (for testbench & verification)
    output [31:0] pc_out,
    output [31:0] instruction_out,
    output [31:0] alu_result_out,
    output [31:0] writeback_data_out,
    output        reg_write_out,
    output        mem_write_out
);

    //-------------------------------------------------------------------------
    // Internal Datapath Wires
    //-------------------------------------------------------------------------
    wire [31:0] pc;
    reg  [31:0] pc_next;
    wire [31:0] pc_plus_4;
    wire [31:0] branch_target;
    wire [31:0] jal_target;
    wire [31:0] jalr_target;

    wire [31:0] instruction;
    wire [6:0]  opcode   = instruction[6:0];
    wire [4:0]  rd_addr  = instruction[11:7];
    wire [2:0]  funct3   = instruction[14:12];
    wire [4:0]  rs1_addr = instruction[19:15];
    wire [4:0]  rs2_addr = instruction[24:20];
    wire [6:0]  funct7   = instruction[31:25];

    // Control signals
    wire        branch_en;
    wire        mem_read;
    wire [1:0]  mem_to_reg;
    wire [1:0]  alu_op;
    wire        mem_write;
    wire        alu_src_b;
    wire [1:0]  alu_src_a;
    wire        reg_write;
    wire [1:0]  jump;
    wire [3:0]  alu_ctrl;
    wire        branch_decision;

    // Datapath data buses
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] imm_val;
    reg  [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [31:0] mem_read_data;
    reg  [31:0] writeback_data;

    //-------------------------------------------------------------------------
    // 1. Program Counter & PC Next Logic
    //-------------------------------------------------------------------------
    assign pc_plus_4     = pc + 32'd4;
    assign branch_target = pc + imm_val;
    assign jal_target    = pc + imm_val;
    assign jalr_target   = alu_result & ~32'd1; // Bit 0 forced to 0 per RISC-V spec

    always @(*) begin
        case (jump)
            2'b01:   pc_next = jal_target;       // JAL
            2'b10:   pc_next = jalr_target;      // JALR
            default: begin
                if (branch_decision)
                    pc_next = branch_target;    // Taken Branch
                else
                    pc_next = pc_plus_4;        // Normal sequential execution
            end
        endcase
    end

    program_counter u_pc (
        .clk     (clk),
        .rst_n   (rst_n),
        .pc_next (pc_next),
        .pc      (pc)
    );

    //-------------------------------------------------------------------------
    // 2. Instruction Memory (ROM)
    //-------------------------------------------------------------------------
    instruction_memory #(
        .MEM_DEPTH(256)
    ) u_imem (
        .addr        (pc),
        .instruction (instruction)
    );

    //-------------------------------------------------------------------------
    // 3. Main Control Unit
    //-------------------------------------------------------------------------
    control_unit u_control (
        .opcode     (opcode),
        .branch_en  (branch_en),
        .mem_read   (mem_read),
        .mem_to_reg (mem_to_reg),
        .alu_op     (alu_op),
        .mem_write  (mem_write),
        .alu_src_b  (alu_src_b),
        .alu_src_a  (alu_src_a),
        .reg_write  (reg_write),
        .jump       (jump)
    );

    //-------------------------------------------------------------------------
    // 4. Register File (32 x 32-bit, x0 hardwired to zero)
    //-------------------------------------------------------------------------
    register_file u_regfile (
        .clk       (clk),
        .rst_n     (rst_n),
        .reg_write (reg_write),
        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr),
        .rd_data   (writeback_data),
        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );

    //-------------------------------------------------------------------------
    // 5. Immediate Generator
    //-------------------------------------------------------------------------
    imm_generator u_imm_gen (
        .instruction (instruction),
        .imm_out     (imm_val)
    );

    //-------------------------------------------------------------------------
    // 6. ALU Control Decoder & 32-bit ALU
    //-------------------------------------------------------------------------
    alu_control u_alu_ctrl (
        .alu_op   (alu_op),
        .opcode   (opcode),
        .funct3   (funct3),
        .funct7   (funct7),
        .alu_ctrl (alu_ctrl)
    );

    // Operand A Multiplexer
    always @(*) begin
        case (alu_src_a)
            2'b01:   alu_operand_a = pc;        // AUIPC uses PC
            2'b10:   alu_operand_a = 32'd0;
            default: alu_operand_a = rs1_data;  // Standard rs1
        endcase
    end

    // Operand B Multiplexer (rs2 vs Immediate)
    assign alu_operand_b = (alu_src_b) ? imm_val : rs2_data;

    alu u_alu (
        .a          (alu_operand_a),
        .b          (alu_operand_b),
        .alu_ctrl   (alu_ctrl),
        .alu_result (alu_result),
        .zero       (alu_zero)
    );

    //-------------------------------------------------------------------------
    // 7. Branch Evaluation Unit
    //-------------------------------------------------------------------------
    branch_unit u_branch (
        .rs1_data        (rs1_data),
        .rs2_data        (rs2_data),
        .funct3          (funct3),
        .branch_en       (branch_en),
        .branch_decision (branch_decision)
    );

    //-------------------------------------------------------------------------
    // 8. Byte-Addressable Data Memory (RAM)
    //-------------------------------------------------------------------------
    data_memory #(
        .MEM_DEPTH(256)
    ) u_dmem (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .funct3     (funct3),
        .addr       (alu_result),
        .write_data (rs2_data),
        .read_data  (mem_read_data)
    );

    //-------------------------------------------------------------------------
    // 9. Writeback Multiplexer (to rd in Register File)
    //-------------------------------------------------------------------------
    always @(*) begin
        case (mem_to_reg)
            2'b01:   writeback_data = mem_read_data;  // Loads
            2'b10:   writeback_data = pc_plus_4;      // JAL, JALR return link address
            default: writeback_data = alu_result;     // ALU result, LUI, AUIPC
        endcase
    end

    //-------------------------------------------------------------------------
    // Assign Observability Outputs
    //-------------------------------------------------------------------------
    assign pc_out             = pc;
    assign instruction_out    = instruction;
    assign alu_result_out     = alu_result;
    assign writeback_data_out = writeback_data;
    assign reg_write_out      = reg_write;
    assign mem_write_out      = mem_write;

endmodule
