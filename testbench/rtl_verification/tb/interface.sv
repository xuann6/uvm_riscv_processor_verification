interface riscv_if(input logic clk, input logic reset);
  
  // monitor/checking
  logic [31:0] monitor_pc;
  logic [31:0] monitor_instr;
  logic [31:0] monitor_result;
  logic [4:0]  monitor_rd;
  logic        monitor_regwrite;
  
  // Clocking blocks for driver and monitor
  
  // driver clocking block (for initialization and stimulus)
  clocking driver_cb @(posedge clk);
    output init_mem, init_data, init_addr;
    output imem_write, imem_addr, imem_wdata;
    output rf_raddr1, rf_raddr2;
    input rf_rdata1, rf_rdata2;
  endclocking
  
  // monitor clocking block (for checking results)
  clocking monitor_cb @(posedge clk);
    input monitor_pc, monitor_instr, monitor_result, monitor_rd, monitor_regwrite;
    input dmem_addr, dmem_wdata, dmem_rdata, dmem_write;
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