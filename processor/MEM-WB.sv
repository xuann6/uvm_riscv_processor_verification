`timescale 1ns/1ps

module MEMWB(
    input clk, reset,
    
    // Data path inputs
    input [31:0] instruction_M,
    input [31:0] ALUResult_M,
    input [31:0] r_Data_M,
    input [31:0] PC_plus4_M,
    input [4:0] rd_M,
    
    // Control signals
    input regWrite_M,
    input [1:0] resultSrc_M,
    
    // Data path outputs
    output reg [31:0] instruction_W,
    output reg [31:0] ALUResult_W,
    output reg [31:0] r_Data_W,
    output reg [31:0] PC_plus4_W,
    output reg [4:0] rd_W,
    
    // Control signal outputs
    output reg regWrite_W,
    output reg [1:0] resultSrc_W
);
    
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            instruction_W <= 32'b0;
            ALUResult_W <= 32'b0;
            r_Data_W <= 32'b0;
            PC_plus4_W <= 32'b0;
            rd_W <= 5'b0;
            
            regWrite_W <= 1'b0;
            resultSrc_W <= 2'b0;
        end
        else begin
            instruction_W <= instruction_M;
            ALUResult_W <= ALUResult_M;
            r_Data_W <= r_Data_M;
            PC_plus4_W <= PC_plus4_M;
            rd_W <= rd_M;
            
            regWrite_W <= regWrite_M;
            resultSrc_W <= resultSrc_M;
        end
    end
endmodule