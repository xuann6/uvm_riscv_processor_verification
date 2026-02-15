interface riscv_if(input logic clk, input logic reset);
  
  // input for DUT for instruction source selection
  logic        instr_mode; // 0=memory, 1=external
  logic [31:0] instr_ext;

  // monitor/checking
  logic [31:0] monitor_pc;
  logic [31:0] monitor_instr;
  logic [31:0] monitor_result;
  logic [4:0]  monitor_rd;
  logic        monitor_regwrite;
  logic        dmem_write;
  
  // Clocking blocks for driver and monitor
  
  // driver clocking block (for initialization and stimulus)
  clocking driver_cb @(posedge clk);
    output instr_mode, instr_ext;
  endclocking
  
  // monitor clocking block (for checking results)
  clocking monitor_cb @(posedge clk);
    input monitor_pc, monitor_instr, monitor_result, monitor_rd, monitor_regwrite, dmem_write;
  endclocking
  
  // modport for driver
  modport driver(
    clocking driver_cb,
    input clk, reset
  );
  
  // Modport for monitor
  modport monitor(
    clocking monitor_cb,
    input clk, reset
  );
  
endinterface