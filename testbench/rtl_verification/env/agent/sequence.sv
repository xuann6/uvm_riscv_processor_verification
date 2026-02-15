`ifndef RISCV_SEQUENCES_SV
`define RISCV_SEQUENCES_SV

class base_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(base_seq)
    
    function new(string name = "base_seq");
        super.new(name);
    endfunction
    
    virtual function transaction create_instr(bit [31:0] instr_code);
        transaction tx;
        tx = transaction::type_id::create("tx");
        tx.instruction = instr_code;
        tx.decode_instruction();
        return tx;
    endfunction
    
    virtual task send_tx(transaction tx);
        start_item(tx);
        finish_item(tx);
    endtask
endclass

class file_based_seq extends base_seq;
    `uvm_object_utils(file_based_seq)

    string filename;
    
    function new(string name = "file_based_seq");
        super.new(name);
    endfunction

    virtual task body();
        int file;
        string line;
        bit [31:0] instr;
        transaction tx;

        file = $fopen(filename, "r");
        if (file == 0) begin
            `uvm_fatal("SEQ", $sformatf("Failed to open file: %s", filename))
        end

        `uvm_info("SEQ", $sformatf("Reading from: %s", filename), UVM_LOW)

        while(!$feof(file)) begin
            void'($fgets(line, file));
            
            if (line.len() == 0 || line[0] == "#" || line[0] == "\n") 
                continue;
            
            if ($sscanf(line, "%b", instr) == 1) begin
                tx = transaction::type_id::create("tx");
                tx.instruction = instr;
                tx.decode_instruction();
                
                `uvm_info("SEQ", $sformatf("Sending: %s", tx.convert2string()), UVM_MEDIUM)
                send_tx(tx);
            end
        end

        $fclose(file);
        `uvm_info("SEQ", "Completed file reading", UVM_LOW)
    endtask
endclass

class nop_file_seq extends file_based_seq;
    `uvm_object_utils(nop_file_seq)

    function new(string name = "nop_file_seq");
        super.new(name);
        filename = "../stimulus/nop-test.txt";
    endfunction
endclass

class r_type_file_seq extends file_based_seq;
    `uvm_object_utils(r_type_file_seq)

    function new(string name = "r_type_file_seq");
        super.new(name);
        filename = "../stimulus/r-type-test.txt";
    endfunction
endclass

class i_type_file_seq extends file_based_seq;
    `uvm_object_utils(i_type_file_seq)

    function new(string name = "i_type_file_seq");
        super.new(name);
        filename = "../stimulus/i-type-test.txt";
    endfunction
endclass

class b_type_file_seq extends file_based_seq;
    `uvm_object_utils(b_type_file_seq)

    function new(string name = "b_type_file_seq");
        super.new(name);
        filename = "../stimulus/b-type-test.txt";
    endfunction
endclass

class j_type_file_seq extends file_based_seq;
    `uvm_object_utils(j_type_file_seq)

    function new(string name = "j_type_file_seq");
        super.new(name);
        filename = "../stimulus/j-type-test.txt";
    endfunction
endclass

class u_type_file_seq extends file_based_seq;
    `uvm_object_utils(u_type_file_seq)

    function new(string name = "u_type_file_seq");
        super.new(name);
        filename = "../stimulus/u-type-test.txt";
    endfunction
endclass

class load_store_file_seq extends file_based_seq;
    `uvm_object_utils(load_store_file_seq)

    function new(string name = "load_store_file_seq");
        super.new(name);
        filename = "../stimulus/load-store-test.txt";
    endfunction
endclass

// Short-name aliases used by test classes
typedef nop_file_seq        nop_seq;
typedef r_type_file_seq     r_type_seq;
typedef i_type_file_seq     i_type_seq;
typedef load_store_file_seq load_store_seq;

`endif