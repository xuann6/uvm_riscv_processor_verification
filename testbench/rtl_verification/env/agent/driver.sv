`ifndef RISCV_DRIVER_SV
`define RISCV_DRIVER_SV

class driver extends uvm_driver #(transaction);
    `uvm_component_utils(driver)
    
    virtual riscv_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRIVER", "Could not get virtual interface")
    endfunction
    
    task run_phase(uvm_phase phase);        
        
        @(negedge vif.reset);
        vif.driver_cb.instr_mode <= 1; // for UVM testing,
                                       // DUT will read instructions from UVM interface directly

        forever begin
            seq_item_port.get_next_item(tx);
            drive_instruction(tx);
            seq_item_port.item_done();
        end
    endtask
    
    task drive_instruction(transaction tx);

        vif.driver_cb.instr_ext <= tx.instruction;
        `uvm_info("DRIVER", $sformatf("Drove instruction: %s", tx.convert2string()), UVM_HIGH)

        @(vif.driver_cb); // wait for one cycle
    endtask
    
    task reset_phase(uvm_phase phase);
        phase.raise_objection(this);
        @(negedge vif.reset);
        phase.drop_objection(this);
    endtask
    
endclass
`endif