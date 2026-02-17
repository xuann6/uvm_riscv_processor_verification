`ifndef RISCV_MONITOR_SV
`define RISCV_MONITOR_SV

class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)

    virtual riscv_if vif;

    uvm_analysis_port #(transaction) analysis_port;

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

    task run_phase(uvm_phase phase);
        transaction tx;

        @(negedge vif.reset);

        forever begin
            // Check WB stage for register writes
            if (vif.monitor_cb.monitor_regwrite && vif.monitor_cb.monitor_rd != 0) begin
                tx = create_result_transaction();

                `uvm_info("MONITOR", $sformatf("\033[1;34m Starting a new transaction...\033[0m"), UVM_LOW)
                analysis_port.write(tx);
            end

            // Monitor memory operations
            if (vif.monitor_cb.dmem_write) begin
                monitor_memory_operations();
            end

            // Wait for next clock edge
            @(vif.monitor_cb);
        end

    endtask

    // Create a transaction from WB-stage signals
    // instruction and result are from the same pipeline stage
    function transaction create_result_transaction();
        transaction tx = transaction::type_id::create("tx");

        tx.pc          = vif.monitor_cb.monitor_pc;
        tx.instruction = vif.monitor_cb.monitor_instr;
        tx.result_reg  = vif.monitor_cb.monitor_rd;
        tx.result      = vif.monitor_cb.monitor_result;

        tx.decode_instruction();

        return tx;
    endfunction

    // Monitor memory operations
    task monitor_memory_operations();
        // TBD
    endtask

endclass
`endif
