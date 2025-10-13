`ifndef RISCV_MONITOR_SV
`define RISCV_MONITOR_SV

class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)
    
    virtual riscv_if vif;
    
    uvm_analysis_port #(transaction) analysis_port;
    
    bit [31:0] current_instr;
    bit [31:0] current_pc;
    
    // Instruction to transaction mapping (for tracking instruction execution)
    // Address (PC) → Transaction
    transaction instr_map[bit[31:0]];
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction
    
    // Build phase - get interface from config db
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
        `uvm_fatal("MONITOR", "Could not get vif")
    endfunction
    
    // Run phase - monitor DUT activity
    task run_phase(uvm_phase phase);
        transaction tx;
        
        @(negedge vif.reset);
        
        forever begin
            begin
                
                //`uvm_info("DEBUG", $sformatf("monitor_regwrite=%b, monitor_rd=%d, monitor_result=0x%h", 
                //    vif.monitor_cb.monitor_regwrite, vif.monitor_cb.monitor_rd, vif.monitor_cb.monitor_result), UVM_MEDIUM)

                // Monitor register file writes
                if (vif.monitor_cb.monitor_regwrite && vif.monitor_cb.monitor_rd != 0) begin
                    // transaction for the result
                    tx = create_result_transaction();
                    
                    `uvm_info("MONITOR", $sformatf("\033[1;34m Starting a new transaction...\033[0m"), UVM_LOW)

                    // send to the scoreboard
                    analysis_port.write(tx);
                end
            
                // Monitor for new instructions
                // if (vif.monitor_cb.monitor_instr != 32'h0) begin        
                //     // Track new instruction
                //     track_new_instruction();
                // end
                
                // Monitor memory operations
                monitor_memory_operations();
                
                // Wait for next clock edge
                @(vif.monitor_cb);
            end
        end
    
    endtask
    
    // Create a transaction representing an execution result
    function transaction create_result_transaction();
        transaction tx = transaction::type_id::create("tx");
    
        tx.pc = vif.monitor_cb.monitor_pc;
        tx.instruction = vif.monitor_cb.monitor_instr;
        tx.result_reg = vif.monitor_cb.monitor_rd;
        tx.result = vif.monitor_cb.monitor_result;
        
        tx.decode_instruction();
        
        //`uvm_info("MONITOR", $sformatf("Observed result: x%0d = 0x%8h for instruction %s at PC=0x%8h", 
        //            tx.result_reg, tx.result, tx.instr_name, tx.pc), UVM_MEDIUM)
        
        return tx;
        
    endfunction
    
    // Track a new instruction entering the pipeline
    task track_new_instruction();
        transaction tx = transaction::type_id::create("tx");
        
        // Capture instruction and PC
        tx.instruction = vif.monitor_cb.monitor_instr;
        tx.pc = vif.monitor_cb.monitor_pc;
        
        // Decode instruction fields
        tx.decode_instruction();
        
        // Store in tracking map
        instr_map[tx.pc] = tx;
        
        `uvm_info("MONITOR", $sformatf("Tracking new instruction: %s at PC=0x%8h", tx.instr_name, tx.pc), UVM_MEDIUM)
    endtask
    
    // Monitor memory operations
    task monitor_memory_operations();
        // Monitor memory writes
        if (vif.monitor_cb.dmem_write) begin
        bit [31:0] addr = {18'b0, vif.monitor_cb.dmem_addr};
        
        `uvm_info("MONITOR", $sformatf("Observed memory write: Addr=0x%8h, Data=0x%8h",
                    addr, vif.monitor_cb.dmem_wdata), UVM_MEDIUM)
                    
        // Here you would tie this memory write to a specific instruction
        // if you can correlate it to a PC value
        end
    endtask

endclass

`endif