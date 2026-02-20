`ifndef RISCV_TEST_SV
`define RISCV_TEST_SV

class riscv_base_test extends uvm_test;
    `uvm_component_utils(riscv_base_test)
    
    riscv_env env;
    virtual riscv_if vif;
    
    function new(string name = "riscv_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get interface from config DB (reusing it)
        if (!uvm_config_db#(virtual riscv_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("TEST", "Could not get vif from config DB")
        end
        
        // Create environment
        env = riscv_env::type_id::create("env", this);
        
        // Pass interface to environment for monitor and driver to use it
        uvm_config_db#(virtual riscv_if)::set(this, "env", "vif", vif);
    endfunction
    
    task run_phase(uvm_phase phase);  
        
        nop_seq seq;

        phase.raise_objection(this);
        
        `uvm_info("TEST", $sformatf("\033[1;34m RUNNING TEST: %s \033[0m\n", get_type_name()), UVM_LOW)
        
        #100;

        seq = nop_seq::type_id::create("seq");
        seq.start(env.sqr);

        #100;

        phase.drop_objection(this);
    endtask
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("TEST", $sformatf("\n\n********************************************"), UVM_LOW)
        `uvm_info("TEST", $sformatf("TEST COMPLETE: %s", get_type_name()), UVM_LOW)
        `uvm_info("TEST", $sformatf("********************************************\n"), UVM_LOW)
    endfunction
endclass

// R-Type Instructions Test, 
// all the tests (R, I, LOAD/STORE types) derive from riscv_base_test class
class riscv_r_type_test extends riscv_base_test;
    `uvm_component_utils(riscv_r_type_test)
    
    function new(string name = "riscv_r_type_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        r_type_seq seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", $sformatf("\n\n********************************************"), UVM_LOW)
        `uvm_info("TEST", $sformatf("RUNNING TEST: %s", get_type_name()), UVM_LOW)
        `uvm_info("TEST", $sformatf("********************************************\n"), UVM_LOW)
        
        #100;
        
        seq = r_type_seq::type_id::create("seq");
        seq.start(env.sqr);
        
        #200;
        
        phase.drop_objection(this);
    endtask
endclass

// I-Type Instructions Test
class riscv_i_type_test extends riscv_base_test;
    `uvm_component_utils(riscv_i_type_test)
    
    function new(string name = "riscv_i_type_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        i_type_seq seq;
        
        phase.raise_objection(this);
        
        `uvm_info("TEST", $sformatf("\n\n********************************************"), UVM_LOW)
        `uvm_info("TEST", $sformatf("RUNNING TEST: %s", get_type_name()), UVM_LOW)
        `uvm_info("TEST", $sformatf("********************************************\n"), UVM_LOW)
        
        #100;
        
        seq = i_type_seq::type_id::create("seq");
        seq.start(env.sqr);
        
        #200;
        
        phase.drop_objection(this);
    endtask
endclass

// Load/Store Instructions Test
class riscv_load_store_test extends riscv_base_test;
    `uvm_component_utils(riscv_load_store_test)

    function new(string name = "riscv_load_store_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        load_store_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", $sformatf("\n\n********************************************"), UVM_LOW)
        `uvm_info("TEST", $sformatf("RUNNING TEST: %s", get_type_name()), UVM_LOW)
        `uvm_info("TEST", $sformatf("********************************************\n"), UVM_LOW)

        #100;

        seq = load_store_seq::type_id::create("seq");
        seq.start(env.sqr);

        #200;

        phase.drop_objection(this);
    endtask
endclass

// B-Type (Branch) Instructions Test
class riscv_b_type_test extends riscv_base_test;
    `uvm_component_utils(riscv_b_type_test)

    function new(string name = "riscv_b_type_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        b_type_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", $sformatf("\n\n********************************************"), UVM_LOW)
        `uvm_info("TEST", $sformatf("RUNNING TEST: %s", get_type_name()), UVM_LOW)
        `uvm_info("TEST", $sformatf("********************************************\n"), UVM_LOW)

        #100;

        seq = b_type_seq::type_id::create("seq");
        seq.start(env.sqr);

        #200;

        phase.drop_objection(this);
    endtask
endclass

// J-Type (Jump) Instructions Test
class riscv_j_type_test extends riscv_base_test;
    `uvm_component_utils(riscv_j_type_test)

    function new(string name = "riscv_j_type_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        j_type_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", $sformatf("\n\n********************************************"), UVM_LOW)
        `uvm_info("TEST", $sformatf("RUNNING TEST: %s", get_type_name()), UVM_LOW)
        `uvm_info("TEST", $sformatf("********************************************\n"), UVM_LOW)

        #100;

        seq = j_type_seq::type_id::create("seq");
        seq.start(env.sqr);

        #200;

        phase.drop_objection(this);
    endtask
endclass

// U-Type (Upper Immediate) Instructions Test
class riscv_u_type_test extends riscv_base_test;
    `uvm_component_utils(riscv_u_type_test)

    function new(string name = "riscv_u_type_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        u_type_seq seq;

        phase.raise_objection(this);

        `uvm_info("TEST", $sformatf("\n\n********************************************"), UVM_LOW)
        `uvm_info("TEST", $sformatf("RUNNING TEST: %s", get_type_name()), UVM_LOW)
        `uvm_info("TEST", $sformatf("********************************************\n"), UVM_LOW)

        #100;

        seq = u_type_seq::type_id::create("seq");
        seq.start(env.sqr);

        #200;

        phase.drop_objection(this);
    endtask
endclass

// Full-Coverage Test: runs all instruction-type stimulus files back-to-back
// in a single simulation so the coverage collector accumulates hits across
// R, I, Load/Store, B, J, and U types.
class riscv_full_test extends riscv_base_test;
    `uvm_component_utils(riscv_full_test)

    function new(string name = "riscv_full_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        r_type_seq     r_seq;
        i_type_seq     i_seq;
        load_store_seq ls_seq;
        b_type_seq     b_seq;
        j_type_seq     j_seq;
        u_type_seq     u_seq;

        phase.raise_objection(this);

        `uvm_info("TEST", $sformatf("\n\n********************************************"), UVM_LOW)
        `uvm_info("TEST", $sformatf("RUNNING TEST: %s", get_type_name()), UVM_LOW)
        `uvm_info("TEST", $sformatf("********************************************\n"), UVM_LOW)

        #100;

        // R-type: ADD SUB AND OR XOR SLT SLL SRL SRA
        `uvm_info("TEST", "--- Phase: R-Type Instructions ---", UVM_LOW)
        r_seq = r_type_seq::type_id::create("r_seq");
        r_seq.start(env.sqr);

        // I-type ALU: ADDI ANDI ORI XORI SLTI SLLI SRLI SRAI
        `uvm_info("TEST", "--- Phase: I-Type Instructions ---", UVM_LOW)
        i_seq = i_type_seq::type_id::create("i_seq");
        i_seq.start(env.sqr);

        // Load/Store: SW LW (and NOPs)
        `uvm_info("TEST", "--- Phase: Load/Store Instructions ---", UVM_LOW)
        ls_seq = load_store_seq::type_id::create("ls_seq");
        ls_seq.start(env.sqr);

        // B-type: BEQ BNE (with ADDI setup)
        `uvm_info("TEST", "--- Phase: B-Type Instructions ---", UVM_LOW)
        b_seq = b_type_seq::type_id::create("b_seq");
        b_seq.start(env.sqr);

        // J-type: JAL JALR
        `uvm_info("TEST", "--- Phase: J-Type Instructions ---", UVM_LOW)
        j_seq = j_type_seq::type_id::create("j_seq");
        j_seq.start(env.sqr);

        // U-type: LUI
        `uvm_info("TEST", "--- Phase: U-Type Instructions ---", UVM_LOW)
        u_seq = u_type_seq::type_id::create("u_seq");
        u_seq.start(env.sqr);

        #200;

        phase.drop_objection(this);
    endtask
endclass

`endif