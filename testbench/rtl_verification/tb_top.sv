`timescale 1ns/1ps

import uvm_pkg::*;

`include "uvm_macros.svh"

`include "tb/interface.sv"
`include "env/agent/transaction.sv"
`include "env/agent/sequencer.sv"
`include "env/agent/sequence.sv"
`include "env/agent/driver.sv"
`include "env/agent/monitor.sv"
`include "env/scoreboard.sv"
`include "env/env.sv"
`include "test/test.sv"

module tb;
    bit clk;
    bit reset;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // clock period 10ns
    end
    
    // Reset signal
    initial begin
        reset = 1;
        repeat(5) @(posedge clk);
        reset = 0;
    end
    
    // Interface instantiation
    riscv_if intf(.clk(clk), .reset(reset));
    
    // DUT instantiation
    RISCVPipelined dut(
        .clk(clk),
        .reset(reset)
        .instr_mode(intf.instr_mode),
        .instr_ext(intf.instr_ext)
    );
    
    // Todo: 
    //  1. What exactly signal are we trying to get from the DUT for monitor
    //  2. What exactly signal are we passing into the DUT (basically just clk and rst)
    assign intf.monitor_pc = dut.PC_F;
    assign intf.monitor_instr = dut.instruction_F;
    assign intf.monitor_result = dut.result_W;
    assign intf.monitor_regwrite = dut.regWrite_W;
    assign intf.monitor_rd = dut.rd_W;
    
    initial begin
        // Register interface with UVM config database
        uvm_config_db#(virtual riscv_if)::set(null, "*", "vif", intf);

        // Need to specify the running test name here 
        // or in the command line when simulation
        run_test();
    end
    
    // Dumping waveform (optional)
    // initial begin
    //     $dumpfile("dump.vcd");
    //     $dumpvars(0, top);
    // end
endmodule