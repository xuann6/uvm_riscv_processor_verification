`timescale 1ns/1ps

`include "32-bits_alu.sv"
`include "control_unit.sv"
`include "hazard_unit.sv"
`include "data_mem.sv"
`include "inst_mem.sv"
`include "program_counter.sv"
`include "reg_file.sv"
`include "IF-ID.sv"
`include "ID-EXE.sv"
`include "EXE-MEM.sv"
`include "MEM-WB.sv"

module RISCVPipelined(
    input logic clk,
    input logic reset, 

    input logic instr_mode, // 0: from inst memory, 1: from external input
                            // this gives the flexibility to test from either instuction memory or external stimulus from UVM environment
    input logic [31:0] instr_ext
);
    // Fetch
    logic [31:0] PC_F;
    logic [31:0] PC_next;
    logic [31:0] PC_plus4_F;
    logic [31:0] instruction_F;
    logic [31:0] instruction_from_mem;  // instruction from internal memory
    logic stall_F;
    logic flush_F;
    
    // Decode
    logic [31:0] instruction_D;
    logic [31:0] PC_D;
    logic [31:0] PC_plus4_D;
    logic [31:0] r_data1_D, r_data2_D;
    logic [31:0] immExt_D;
    logic [2:0] funct3_D;
    logic [4:0] rs1_D, rs2_D, rd_D;
    
    logic regWrite_D;
    logic [1:0] resultSrc_D;
    logic memWrite_D;
    logic branch_D;
    logic jump_D;
    logic [4:0] ALUControl_D;
    logic ALUSrc_D;
    logic [1:0] immSrc_D;
    logic stall_D;
    logic flush_D;
    
    // Execute
    logic [31:0] PC_E;
    logic [31:0] PC_plus4_E;
    logic [31:0] rd1_E, rd2_E;
    logic [31:0] immExt_E;
    logic [2:0] funct3_E;
    logic [4:0] rs1_E, rs2_E, rd_E;
    logic [31:0] ALUResult_E;
    logic [31:0] writeData_E;
    logic zero_E;
    logic PCSrc_E;
    logic [31:0] PC_target_E;
    
    logic regWrite_E;
    logic [1:0] resultSrc_E;
    logic memWrite_E;
    logic branch_E;
    logic jump_E;
    logic [4:0] ALUControl_E;
    logic ALUSrc_E;
    logic flush_E;
    
    // Memory
    logic [31:0] ALUResult_M;
    logic [31:0] writeData_M;
    logic [31:0] PC_plus4_M;
    logic [4:0] rd_M;
    logic [31:0] readData_M;
    
    logic regWrite_M;
    logic [1:0] resultSrc_M;
    logic memWrite_M;
    
    // Writeback
    logic [31:0] ALUResult_W;
    logic [31:0] readData_W;
    logic [31:0] PC_plus4_W;
    logic [4:0] rd_W;
    logic [31:0] result_W;
    
    logic regWrite_W;
    logic [1:0] resultSrc_W;
    
    // Hazard unit
    logic [1:0] forwardA_E, forwardB_E;
    logic stall_F_hazard, stall_D_hazard, flush_E_hazard, flush_D_hazard;
    
    logic [31:0] srcA_E, srcB_E;
    
    // ===== Fetch Stage =====
    
    // Program Counter
    PC pc_module(
        .clk(clk), 
        .reset(reset),
        .stall(stall_F),
        .PC_next(PC_next),
        .PC(PC_F)
    );
    
    // Instruction Memory
    inst_memory imem(
        .addr(PC_F[11:0]),
        .inst(instruction_from_mem)
    );
    
    assign PC_plus4_F = PC_F + 32'd4;
    assign PC_next = PCSrc_E ? PC_target_E : PC_plus4_F;
    assign instruction_F = instr_mode ? instr_ext : instruction_from_mem;
    
    // ===== IF/ID Pipeline Register =====
    IFID if_id(
        .clk(clk),
        .reset(reset),
        .instruction(instruction_F),
        .PC(PC_F),
        .PC_plus4(PC_plus4_F),
        .stall(stall_D),
        .flush(flush_D),
        .inst(instruction_D),
        .PC_out(PC_D),
        .PC_plus4_out(PC_plus4_D)
    );
    
    // ===== Decode Stage =====
    
    // Register File
    registerFile rf(
        .clk(clk),
        .reset(reset),
        .rs1(instruction_D[19:15]),
        .rs2(instruction_D[24:20]),
        .rd(rd_W),
        .w_enable(regWrite_W),
        .w_data(result_W),
        .r_data1(r_data1_D),
        .r_data2(r_data2_D)
    );
    
    // Control Unit
    ControlUnit control_unit(
        .opcode(instruction_D[6:0]),
        .funct3(instruction_D[14:12]),
        .funct7_bit5(instruction_D[30]),
        .regWrite_D(regWrite_D),
        .resultSrc_D(resultSrc_D),
        .memWrite_D(memWrite_D),
        .jump_D(jump_D),
        .branch_D(branch_D),
        .ALUControl_D(ALUControl_D),
        .ALUSrc_D(ALUSrc_D),
        .immSrc_D(immSrc_D)
    );
    
    // Immediate Extend
    always_comb begin
        case(immSrc_D)
            2'b00: immExt_D = {{20{instruction_D[31]}}, instruction_D[31:20]}; // I-type
            2'b01: immExt_D = {{20{instruction_D[31]}}, instruction_D[31:25], instruction_D[11:7]}; // S-type
            2'b10: immExt_D = {{20{instruction_D[31]}}, instruction_D[7], instruction_D[30:25], instruction_D[11:8], 1'b0}; // B-type
            2'b11: begin
                if (instruction_D[6:0] == 7'b1101111) // JAL
                    immExt_D = {{12{instruction_D[31]}}, instruction_D[19:12], instruction_D[20], instruction_D[30:21], 1'b0}; // J-type
                else // LUI/AUIPC
                    immExt_D = {instruction_D[31:12], 12'b0}; // U-type
            end
            default: immExt_D = 32'b0;
        endcase
    end
    
    // register addresses for Hazard Unit
    assign rs1_D = instruction_D[19:15];
    assign rs2_D = instruction_D[24:20];
    assign rd_D = instruction_D[11:7];
    assign funct3_D = instruction_D[14:12];
    
    // ===== ID/EX Pipeline Register =====
    IDEX id_ex(
        .clk(clk), 
        .reset(reset),
        .PC_D(PC_D),
        .PC_plus4_D(PC_plus4_D),
        .r_data1(r_data1_D),
        .r_data2(r_data2_D),
        .immExt_D(immExt_D),
        .funct3_D(funct3_D),
        .funct3_E(funct3_E),
        .rs1(rs1_D),
        .rs2(rs2_D),
        .rd(rd_D),
        .regWrite_D(regWrite_D),
        .resultSrc_D(resultSrc_D),
        .memWrite_D(memWrite_D),
        .branch_D(branch_D),
        .jump_D(jump_D),
        .ALUControl_D(ALUControl_D),
        .ALUSrc_D(ALUSrc_D),
        .flush(flush_E),
        .PC_E(PC_E),
        .PC_plus4_E(PC_plus4_E),
        .rd1_E(rd1_E),
        .rd2_E(rd2_E),
        .immExt_E(immExt_E),
        .rs1_E(rs1_E),
        .rs2_E(rs2_E),
        .rd_E(rd_E),
        .regWrite_E(regWrite_E),
        .resultSrc_E(resultSrc_E),
        .memWrite_E(memWrite_E),
        .branch_E(branch_E),
        .jump_E(jump_E),
        .ALUControl_E(ALUControl_E),
        .ALUSrc_E(ALUSrc_E)
    );
    
    // ===== Execute Stage =====
    
    // Forwarding muxes
    always_comb begin
        case(forwardA_E)
            2'b00: srcA_E = rd1_E;
            2'b01: srcA_E = result_W;
            2'b10: srcA_E = ALUResult_M;
            default: srcA_E = rd1_E;
        endcase
        
        case(forwardB_E)
            2'b00: writeData_E = rd2_E;
            2'b01: writeData_E = result_W;
            2'b10: writeData_E = ALUResult_M;
            default: writeData_E = rd2_E;
        endcase
    end
    
    assign srcB_E = ALUSrc_E ? immExt_E : writeData_E;
    
    // ALU
    ALU alu(
        .a(srcA_E),
        .b(srcB_E),
        .alu_op(ALUControl_E),
        .result(ALUResult_E),
        .zero(zero_E)
    );
    assign PC_target_E = PC_E + immExt_E;
    
    always_comb begin
        if (jump_E)
            PCSrc_E = 1'b1;
        else if (branch_E) begin
            case(funct3_E)
                3'b000: PCSrc_E = zero_E;                    // BEQ
                3'b001: PCSrc_E = ~zero_E;                   // BNE
                3'b100: PCSrc_E = ALUResult_E[31];           // BLT - check sign bit
                3'b101: PCSrc_E = ~ALUResult_E[31] || zero_E; // BGE
                3'b110: PCSrc_E = ALUResult_E[0];            // BLTU (if using SLT)
                3'b111: PCSrc_E = ~ALUResult_E[0] || zero_E; // BGEU (if using SLT)
                default: PCSrc_E = zero_E;
            endcase
        end
        else if (branch_E && zero_E)
            PCSrc_E = 1'b1;

        else
            PCSrc_E = 1'b0;
    end
    
    // ===== EX/MEM Pipeline Register =====
    EXMEM ex_mem(
        .clk(clk), 
        .reset(reset),
        .ALUResult_E(ALUResult_E),
        .writeData_E(writeData_E),
        .PC_plus4_E(PC_plus4_E),
        .rd_E(rd_E),
        .regWrite_E(regWrite_E),
        .resultSrc_E(resultSrc_E),
        .memWrite_E(memWrite_E),
        .ALUResult_M(ALUResult_M),
        .writeData_M(writeData_M),
        .PC_plus4_M(PC_plus4_M),
        .rd_M(rd_M),
        .regWrite_M(regWrite_M),
        .resultSrc_M(resultSrc_M),
        .memWrite_M(memWrite_M)
    );
    
    // ===== Memory Stage =====
    
    // Data Memory
    data_memory dmem(
        .clk(clk),
        .w_enable(memWrite_M),
        .addr(ALUResult_M[13:0]),
        .w_data(writeData_M),
        .r_data(readData_M)
    );
    
    // ===== MEM/WB Pipeline Register =====
    MEMWB mem_wb(
        .clk(clk), 
        .reset(reset),
        .ALUResult_M(ALUResult_M),
        .r_Data_M(readData_M),
        .PC_plus4_M(PC_plus4_M),
        .rd_M(rd_M),
        .regWrite_M(regWrite_M),
        .resultSrc_M(resultSrc_M),
        .ALUResult_W(ALUResult_W),
        .r_Data_W(readData_W),
        .PC_plus4_W(PC_plus4_W),
        .rd_W(rd_W),
        .regWrite_W(regWrite_W),
        .resultSrc_W(resultSrc_W)
    );
    
    // ===== Writeback Stage =====
    
    // Result selection mux
    always_comb begin
        case(resultSrc_W)
            2'b00: result_W = ALUResult_W;
            2'b01: result_W = readData_W;
            2'b10: result_W = PC_plus4_W;
            2'b11: result_W = ALUResult_W; // PC + Imm (for AUIPC)
            default: result_W = ALUResult_W;
        endcase
    end
    
    // ===== Hazard Unit =====
    // This is inferred from the diagram, you may need to update it
    HazardUnit hazard_unit(
        .rs1_D(rs1_D),
        .rs2_D(rs2_D),
        .rs1_E(rs1_E),
        .rs2_E(rs2_E),
        .rd_E(rd_E),
        .rd_M(rd_M),
        .rd_W(rd_W),
        .resultSrc_E(resultSrc_E[0]),
        .regWrite_M(regWrite_M),
        .regWrite_W(regWrite_W),
        .PCSrc_E(PCSrc_E),
        .forwardA_E(forwardA_E),
        .forwardB_E(forwardB_E),
        .stall_F(stall_F),
        .stall_D(stall_D),
        .flush_D(flush_D),
        .flush_E(flush_E)
    );

endmodule