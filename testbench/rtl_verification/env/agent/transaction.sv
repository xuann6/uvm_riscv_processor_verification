`ifndef RISCV_TRANSACTION_SV
`define RISCV_TRANSACTION_SV


class transaction extends uvm_sequence_item;
    `uvm_object_utils(transaction)

    rand bit [31:0] instruction; // for sending stimulus to driver. 

    bit [31:0] pc; // for monitor observation

    // decode
    bit [6:0]  opcode;
    bit [4:0]  rd, rs1, rs2;
    bit [2:0]  funct3;
    bit [6:0]  funct7;
    bit [31:0] imm;

    // expected result for scoreboard
    bit [31:0] result;
    bit [4:0]  result_reg;
    bit        reg_write;
    bit        mem_write;
    bit [31:0] mem_addr;
    bit [31:0] mem_data;

    typedef enum {R_TYPE,
                  I_TYPE,
                  S_TYPE,
                  B_TYPE,
                  U_TYPE,
                  J_TYPE,
                  UNKNOWN} instr_type_t;

    instr_type_t instr_type;
    string instr_name;

    function new(string name = "transaction");
        super.new(name);
    endfunction

    function void decode_instruction();
    
        opcode = instruction[6:0];
        rd     = instruction[11:7];
        funct3 = instruction[14:12];
        rs1    = instruction[19:15];
        rs2    = instruction[24:20];
        funct7 = instruction[31:25];
    
        case(opcode)
            7'b0110011: begin // R-type
                
                instr_type = R_TYPE;
                
                case(funct3)
                    3'b000: instr_name = (funct7[5]) ? "SUB" : "ADD";
                    3'b001: instr_name = "SLL";
                    3'b010: instr_name = "SLT";
                    3'b011: instr_name = "SLTU";
                    3'b100: instr_name = "XOR";
                    3'b101: instr_name = (funct7[5]) ? "SRA" : "SRL";
                    3'b110: instr_name = "OR";
                    3'b111: instr_name = "AND";
                endcase
                reg_write = 1;
                mem_write = 0;
            end
            
            7'b0010011: begin // I-type
                
                instr_type = I_TYPE;
                imm = {{20{instruction[31]}}, instruction[31:20]};
                
                case(funct3)
                    3'b000: instr_name = "ADDI";
                    3'b001: instr_name = "SLLI";
                    3'b010: instr_name = "SLTI";
                    3'b011: instr_name = "SLTIU";
                    3'b100: instr_name = "XORI";
                    3'b101: instr_name = (instruction[30]) ? "SRAI" : "SRLI";
                    3'b110: instr_name = "ORI";
                    3'b111: instr_name = "ANDI";
                endcase
                reg_write = 1;
                mem_write = 0;
            end
            
            7'b0000011: begin // LOAD
                
                instr_type = I_TYPE;
                imm = {{20{instruction[31]}}, instruction[31:20]};
                
                case(funct3)
                    3'b000 : instr_name = "LB";
                    3'b001 : instr_name = "LH";
                    3'b010 : instr_name = "LW";
                    3'b100 : instr_name = "LBU";
                    3'b101 : instr_name = "LHU";
                    default: instr_name = "UNKNOWN_LOAD";
                endcase
                reg_write = 1;
                mem_write = 0;
            end
            
            7'b0100011: begin // STORE
                
                instr_type = S_TYPE;
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
                
                case(funct3)
                    3'b000 : instr_name = "SB";
                    3'b001 : instr_name = "SH";
                    3'b010 : instr_name = "SW";
                    default: instr_name = "UNKNOWN_STORE";
                endcase
                reg_write = 0;
                mem_write = 1;
            end
            
            7'b1100011: begin // B-type
                
                instr_type = B_TYPE;
                imm = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                
                case(funct3)
                    3'b000 : instr_name = "BEQ";
                    3'b001 : instr_name = "BNE";
                    3'b100 : instr_name = "BLT";
                    3'b101 : instr_name = "BGE";
                    3'b110 : instr_name = "BLTU";
                    3'b111 : instr_name = "BGEU";
                    default: instr_name = "UNKNOWN_BRANCH";
                endcase
                reg_write = 0;
                mem_write = 0;
            end
            
            7'b0110111: begin // U-type (LUI)
                
                instr_type = U_TYPE;
                imm = {instruction[31:12], 12'b0};
                
                instr_name = "LUI";
                reg_write = 1;
                mem_write = 0;
            end
            
            7'b0010111: begin // U-type (AUIPC)
                
                instr_type = U_TYPE;
                imm = {instruction[31:12], 12'b0};
                
                instr_name = "AUIPC";
                reg_write = 1;
                mem_write = 0;
            end
            
            7'b1101111: begin // JAL
                
                instr_type = J_TYPE;
                imm = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                
                instr_name = "JAL";
                reg_write = 1;
                mem_write = 0;
            end
            
            7'b1100111: begin // JALR
                
                instr_type = I_TYPE;
                imm = {{20{instruction[31]}}, instruction[31:20]};
                
                instr_name = "JALR";
                reg_write = 1;
                mem_write = 0;
            end
            
            default: begin
                instr_type = UNKNOWN;
                instr_name = "UNKNOWN";
                reg_write = 0;
                mem_write = 0;
            end
        endcase
        
        result_reg = rd;
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("PC: 0x%08h\n", pc);
    
        case(instr_type)
            R_TYPE: s = {s, $sformatf("x%0d %s x%0d -> x%0d", rs1, instr_name, rs2, rd)};
            I_TYPE: begin
                if (instr_name inside {"LW", "LH", "LB", "LBU", "LHU", "JALR"}) begin
                    s = {s, $sformatf("%s x%0d, %0d(x%0d)", instr_name, rd, imm, rs1)};
                end else begin
                    s = {s, $sformatf("x%0d %s %0d -> x%0d", rs1, instr_name, imm, rd)};
                end
            end
            S_TYPE: s = {s, $sformatf("%s x%0d, %0d(x%0d)", instr_name, rs2, imm, rs1)};
            B_TYPE: s = {s, $sformatf("%s x%0d, x%0d, %0d", instr_name, rs1, rs2, imm)};
            U_TYPE: s = {s, $sformatf("%s x%0d, 0x%05h", instr_name, rd, imm[31:12])};
            J_TYPE: s = {s, $sformatf("%s x%0d, %0d", instr_name, rd, imm)};
            
            default: s = {s, $sformatf("%s (UNKNOWN)", instr_name)};
        endcase
    
        return s;
    endfunction

    function string result_string(bit [31:0] actual_result);
        string s;

        if (reg_write && rd != 0) begin
            s = $sformatf("Expected: 0x%08h | Actual: 0x%08h | %s", 
                            result, actual_result, 
                            (result == actual_result) ? "PASS" : "FAIL");
        end else if (mem_write) begin
            s = $sformatf("Memory Write: addr=0x%08h, data=0x%08h", 
                            mem_addr, mem_data);
        end else begin
            s = "No result check needed";
        end

        return s;
    endfunction

endclass
`endif