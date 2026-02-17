`timescale 1ns/1ps

module EXMEM(
    input clk, reset,
    
    // Data path inputs
    input [31:0] ALUResult_E,
    input [31:0] writeData_E,    // RD2E forwarded to MEM stage
    input [31:0] PC_plus4_E,
    input [31:0] instruction_E,
    input [4:0] rd_E,
    
    // Control signals
    input regWrite_E,
    input [1:0] resultSrc_E,
    input memWrite_E,
    
    // Data path outputs
    output reg [31:0] ALUResult_M,
    output reg [31:0] writeData_M,
    output reg [31:0] PC_plus4_M,
    output reg [31:0] instruction_M,
    output reg [4:0] rd_M,
    
    // Control signal outputs
    output reg regWrite_M,
    output reg [1:0] resultSrc_M,
    output reg memWrite_M
);
    
    always @(posedge clk) begin
        if (reset == 1'b1) begin // no flush here
            ALUResult_M <= 32'b0;
            writeData_M <= 32'b0;
            PC_plus4_M <= 32'b0;
            instruction_M <= 32'b0;
            rd_M <= 5'b0;
            
            regWrite_M <= 1'b0;
            resultSrc_M <= 2'b0;
            memWrite_M <= 1'b0;
        end
        else begin
            ALUResult_M <= ALUResult_E;
            writeData_M <= writeData_E;
            PC_plus4_M <= PC_plus4_E;
            instruction_M <= instruction_E;
            rd_M <= rd_E;
            
            regWrite_M <= regWrite_E;
            resultSrc_M <= resultSrc_E;
            memWrite_M <= memWrite_E;
        end
    end
endmodule