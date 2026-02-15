`timescale 1ns/1ps

module data_memory(
    input clk,
    input w_enable, // w_enable==1 write, otherwise read
    input [13:0] addr,
    input [31:0] w_data,
    output reg [31:0] r_data
);
  
    reg [31:0] mem [0:(1<<12)-1]; // memory size 16KB
    wire [11:0] word_addr = addr[13:2];

    initial begin
        integer i;
        for (i = 0; i < (1<<12); i = i + 1) begin
            mem[i] = 32'h00000000;
        end
        
        mem[5] = 32'hABCDEF01;
    end

    always @(*) begin
        r_data = mem[word_addr];
    end

    always @(posedge clk) begin
        if (w_enable) begin
            mem[word_addr] <= w_data;
        end
    end
endmodule
