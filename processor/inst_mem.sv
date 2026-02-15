`timescale 1ns/1ps

module inst_memory(
    input [11:0] addr,
    output reg [31:0] inst
);
  
    reg [31:0] inst_mem [0:(1<<10)-1]; // inst memory size 4KB
    wire [9:0] word_addr = addr[11:2];

    // for testing if the instruction memory can be read correctly
    initial begin
        for (int i = 0; i < (1<<10); i++) begin
            inst_mem[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        end
        
        // R-type test instructions (matching your sequence)
        // These should write to registers x5, x6, x7, x8, x9, x10, x11, x12, x13
        
        // inst_mem[0] = 32'b00000000001000001000001010110011; // ADD x5, x1, x2 (x5 = 5 + 10 = 15)
        // inst_mem[1] = 32'b01000000000100010000001100110011; // SUB x6, x2, x1 (x6 = 10 - 5 = 5)  
        // inst_mem[2] = 32'b00000000001100010111001110110011; // AND x7, x2, x3 (x7 = 0xA & 0xFFFFFFFF = 0xA)
        // inst_mem[3] = 32'b00000000001000001110010000110011; // OR x8, x1, x2 (x8 = 5 | 10 = 15)
        // inst_mem[4] = 32'b00000000001000001100010010110011; // XOR x9, x1, x2 (x9 = 5 ^ 10 = 15)
        // inst_mem[5] = 32'b00000000001000001010010100110011; // SLT x10, x1, x2 (x10 = (5 < 10) ? 1 : 0 = 1)
        // inst_mem[6] = 32'b00000000010000001001010110110011; // SLL x11, x1, x4 (x11 = 5 << 3 = 40)
        // inst_mem[7] = 32'b00000000010000010101011000110011; // SRL x12, x2, x4 (x12 = 10 >> 3 = 1)
        // inst_mem[8] = 32'b01000000010000011101011010110011; // SRA x13, x3, x4 (x13 = -1 >> 3 = -1)
        
        // // Add some NOPs at the end to help with pipeline flushing
        // inst_mem[9] = 32'h00000013;  // NOP
        // inst_mem[10] = 32'h00000013; // NOP
        // inst_mem[11] = 32'h00000013; // NOP
        // inst_mem[12] = 32'h00000013; // NOP
    end

    always @(*) begin
        inst = inst_mem[word_addr];
    end

endmodule