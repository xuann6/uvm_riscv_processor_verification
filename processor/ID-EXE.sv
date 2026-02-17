`timescale 1ns/1ps

module IDEX(
    input clk, reset,
  
    // Data path inputs
    input [31:0] PC_D,
    input [31:0] PC_plus4_D,
    input [31:0] r_data1,
    input [31:0] r_data2,
    input [31:0] immExt_D,
    input [2:0] funct3_D,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
  
    // Control signals from Control Unit
    input regWrite_D,                
    input [1:0] resultSrc_D,         
    input memWrite_D,                
    input branch_D,                  
    input jump_D,                    
    input [4:0] ALUControl_D, // support 5 bits for extending differnet ALU operation
    input ALUSrc_D,                   
  
    input [31:0] instruction_D,

  input flush,

    // Data path outputs
    output reg [31:0] instruction_E,
    output reg [31:0] PC_E,
    output reg [31:0] PC_plus4_E,
    output reg [31:0] rd1_E,
    output reg [31:0] rd2_E,
    output reg [31:0] immExt_E,
    output reg [2:0] funct3_E,
    output reg [4:0] rs1_E,
    output reg [4:0] rs2_E,
    output reg [4:0] rd_E,
  
    // Control signal outputs
    output reg regWrite_E,
    output reg [1:0] resultSrc_E,
    output reg memWrite_E,
    output reg branch_E,
    output reg jump_E,
    output reg [4:0] ALUControl_E,
    output reg ALUSrc_E
);
  
    always @(posedge clk) begin
        if (reset == 1'b1 || flush == 1'b1) begin
            instruction_E <= 32'b0;
            PC_E <= 32'b0;
            PC_plus4_E <= 32'b0;
            rd1_E <= 32'b0;
            rd2_E <= 32'b0;
            immExt_E <= 32'b0;
            funct3_E <= 3'b0;
            rs1_E <= 5'b0;
            rs2_E <= 5'b0;
            rd_E <= 5'b0;
            
            regWrite_E <= 1'b0;
            resultSrc_E <= 2'b0;
            memWrite_E <= 1'b0;
            branch_E <= 1'b0;
            jump_E <= 1'b0;
            ALUControl_E <= 5'b0;
            ALUSrc_E <= 1'b0;
        end
        else begin
            instruction_E <= instruction_D;
            PC_E <= PC_D;
            PC_plus4_E <= PC_plus4_D;
            rd1_E <= r_data1;
            rd2_E <= r_data2;
            immExt_E <= immExt_D;
            funct3_E <= funct3_D;
            rs1_E <= rs1;
            rs2_E <= rs2;
            rd_E <= rd;
            
            regWrite_E <= regWrite_D;
            resultSrc_E <= resultSrc_D;
            memWrite_E <= memWrite_D;
            branch_E <= branch_D;
            jump_E <= jump_D;
            ALUControl_E <= ALUControl_D;
            ALUSrc_E <= ALUSrc_D;
        end
    end
endmodule