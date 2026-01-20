`ifndef RISCV_SCOREBOARD_SV
`define RISCV_SCOREBOARD_SV

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)
    
    uvm_analysis_imp#(transaction, scoreboard) analysis_imp;
    
    int passed_checks;
    int failed_checks;
    int total_checks;
    
    bit [31:0] reg_file_model[32];
    bit [31:0] mem_model[bit[31:0]];
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_imp = new("analysis_imp", this);
        reset_stats();
        reset_models();
    endfunction
    
    function void reset_stats();
        passed_checks = 0;
        failed_checks = 0;
        total_checks = 0;
    endfunction
    
    function void reset_models();
        // initialize register file model (register 0 is hardwired to 0)
        for (int i = 0; i < 32; i++) begin
            reg_file_model[i] = 32'h0;
        end
        
        mem_model.delete();
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    
    // called when monitor write to analysis_port
    virtual function void write(transaction tx);
        check_transaction(tx);
    endfunction
    
    function void check_transaction(transaction tx);
        bit [31:0] expected_value;
        
        `uvm_info("SCOREBOARD", $sformatf("Checking transaction: %s", tx.convert2string()), UVM_LOW)
        
        // only focus on reg/mem write function for now, 
        // other instructions (read, jump, branch) will be verified indirectly.
        // Those are left to the future todo.
        if (tx.reg_write && tx.result_reg != 0) begin
            calculate_expected_result(tx, expected_value);
            
            if (expected_value === tx.result) begin
                `uvm_info("SCOREBOARD", $sformatf("\033[1;32m PASS: %s\033[0m ", tx.instr_name), UVM_MEDIUM)

                `uvm_info("SCOREBOARD", $sformatf("%8h %s %8h = %8h and expected %8h", reg_file_model[tx.rs1], tx.instr_name, reg_file_model[tx.rs2], tx.result, expected_value), UVM_MEDIUM)
                passed_checks++;
            end
            else begin
                `uvm_error("SCOREBOARD", $sformatf("\033[1;31m FAIL: %s\033[0m - x%0d expected: 0x%8h, actual: 0x%8h", 
                           tx.instr_name, tx.result_reg, expected_value, tx.result))
                
                `uvm_info("SCOREBOARD", $sformatf("%8h %s %8h = %8h but expected %8h", reg_file_model[tx.rs1], tx.instr_name, reg_file_model[tx.rs2], tx.result, expected_value), UVM_MEDIUM)
                
                failed_checks++;
            end
            
            total_checks++;
            
            // update register file model with actual value
            if (tx.result_reg != 0) begin
                reg_file_model[tx.result_reg] = tx.result;
            end
        end
        else if (tx.mem_write) begin
            mem_model[tx.mem_addr] = tx.mem_data;
            `uvm_info("SCOREBOARD", $sformatf("Memory write: addr=0x%8h, data=0x%8h", 
                      tx.mem_addr, tx.mem_data), UVM_MEDIUM)
        end
    endfunction
    
    function void calculate_expected_result(input transaction tx, output bit [31:0] expected_value);
        bit [31:0] rs1_val, rs2_val;
        
        rs1_val = (tx.rs1 == 0) ? 32'h0 : reg_file_model[tx.rs1];
        rs2_val = (tx.rs2 == 0) ? 32'h0 : reg_file_model[tx.rs2];
        
        case (tx.instr_type)
            transaction::R_TYPE: begin
                case (tx.instr_name)
                    "ADD":  expected_value = rs1_val + rs2_val;
                    "SUB":  expected_value = rs1_val - rs2_val;
                    "AND":  expected_value = rs1_val & rs2_val;
                    "OR":   expected_value = rs1_val | rs2_val;
                    "XOR":  expected_value = rs1_val ^ rs2_val;
                    "SLL":  expected_value = rs1_val << rs2_val[4:0];
                    "SRL":  expected_value = rs1_val >> rs2_val[4:0];
                    "SRA":  expected_value = $signed(rs1_val) >>> rs2_val[4:0];
                    "SLT":  expected_value = ($signed(rs1_val) < $signed(rs2_val)) ? 32'h1 : 32'h0;
                    "SLTU": expected_value = (rs1_val < rs2_val) ? 32'h1 : 32'h0;
                    default: `uvm_error("SCOREBOARD", $sformatf("Unsupported R-type instruction: %s", tx.instr_name))
                endcase
            end
            
            transaction::I_TYPE: begin
                case (tx.instr_name)
                    "ADDI":  expected_value = rs1_val + tx.imm;
                    "ANDI":  expected_value = rs1_val & tx.imm;
                    "ORI":   expected_value = rs1_val | tx.imm;
                    "XORI":  expected_value = rs1_val ^ tx.imm;
                    "SLTI":  expected_value = ($signed(rs1_val) < $signed(tx.imm)) ? 32'h1 : 32'h0;
                    "SLTIU": expected_value = (rs1_val < tx.imm) ? 32'h1 : 32'h0;
                    "SLLI":  expected_value = rs1_val << tx.imm[4:0];
                    "SRLI":  expected_value = rs1_val >> tx.imm[4:0];
                    "SRAI":  expected_value = $signed(rs1_val) >>> tx.imm[4:0];
                    "LW":    expected_value = mem_model[rs1_val + tx.imm];
                    "JALR":  expected_value = tx.pc + 4;
                    default: `uvm_error("SCOREBOARD", $sformatf("Unsupported I-type instruction: %s", tx.instr_name))
                endcase
            end
            
            transaction::U_TYPE: begin
                case (tx.instr_name)
                    "LUI":   expected_value = tx.imm;
                    "AUIPC": expected_value = tx.pc + tx.imm;
                    default: `uvm_error("SCOREBOARD", $sformatf("Unsupported U-type instruction: %s", tx.instr_name))
                endcase
            end
            
            transaction::J_TYPE: begin
                if (tx.instr_name == "JAL") begin
                    expected_value = tx.pc + 4;
                end
                else begin
                    `uvm_error("SCOREBOARD", $sformatf("Unsupported J-type instruction: %s", tx.instr_name))
                end
            end
            
            default: begin
                `uvm_error("SCOREBOARD", $sformatf("Unsupported instruction type for %s", tx.instr_name))
            end
        endcase
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf("\n--- SCOREBOARD REPORT ---\n"), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Total Checks:      %0d", total_checks), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Passed Checks:     %0d", passed_checks), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Failed Checks:     %0d", failed_checks), UVM_LOW)
        
        if (failed_checks == 0 && total_checks > 0) begin
            `uvm_info("SCOREBOARD", $sformatf("\033[1;34m\n*** TEST PASSED: All %0d checks passed! ***\033[0m\n", total_checks), UVM_LOW)
        end
        else if (failed_checks > 0) begin
            `uvm_error("SCOREBOARD", $sformatf("\033[1;31m\n*** TEST FAILED: %0d of %0d checks failed! ***\033[0m\n", 
                    failed_checks, total_checks))
        end
        else begin
            `uvm_warning("SCOREBOARD", $sformatf("\033[1;33m\n*** No checks were performed! ***\033[0m\n"))
        end
    endfunction
    
    // Helper method to set initial register values (useful in env file)
    function void set_initial_reg_value(int reg_num, bit [31:0] value);

        if (reg_num >= 0 && reg_num < 32) begin
            if (reg_num != 0) begin  // Reg 0 is hardwired to 0
                reg_file_model[reg_num] = value;
                `uvm_info("SCOREBOARD", $sformatf("Set initial value for x%0d = 0x%8h", reg_num, value), UVM_MEDIUM)
            end
        end
        else begin
            `uvm_error("SCOREBOARD", $sformatf("Invalid register number: %0d", reg_num))
        end
    endfunction
    
    // Helper method to set initial memory values (useful in env file)
    function void set_initial_mem_value(bit [31:0] addr, bit [31:0] value);
        mem_model[addr] = value;
        `uvm_info("SCOREBOARD", $sformatf("Set initial value for mem[0x%8h] = 0x%8h", addr, value), UVM_MEDIUM)
    endfunction
    
endclass

`endif