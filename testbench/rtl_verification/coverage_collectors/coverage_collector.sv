`ifndef RISCV_COVERAGE_COLLECTOR_SV
`define RISCV_COVERAGE_COLLECTOR_SV

class coverage_collector extends uvm_subscriber #(transaction);
    `uvm_component_utils(coverage_collector)

    typedef enum int {
        // R-type (10)
        OP_ADD=0, OP_SUB,  OP_AND,  OP_OR,   OP_XOR,
        OP_SLL,   OP_SRL,  OP_SRA,  OP_SLT,  OP_SLTU,
        // I-type ALU immediate (9)
        OP_ADDI,  OP_ANDI, OP_ORI,  OP_XORI,
        OP_SLTI,  OP_SLTIU,
        OP_SLLI,  OP_SRLI, OP_SRAI,
        // Load — I-type encoding (5)
        OP_LW,    OP_LB,   OP_LH,   OP_LBU,  OP_LHU,
        // Store — S-type (3)
        OP_SW,    OP_SH,   OP_SB,
        // Branch — B-type (6)
        OP_BEQ,   OP_BNE,  OP_BLT,  OP_BGE,  OP_BLTU, OP_BGEU,
        // Upper immediate — U-type (2)
        OP_LUI,   OP_AUIPC,
        // Jump — J-type (2)
        OP_JAL,   OP_JALR,
        // Sentinel: catch-all, never counted
        OP_UNKNOWN
    } opcode_e;

    localparam int NUM_OPCODES     = 37;
    localparam int NUM_INSTR_TYPES = 6;

    int opcode_hit [NUM_OPCODES];
    int type_hit   [NUM_INSTR_TYPES];

    // Human-readable names, parallel to the enum ordering above
    string opcode_names [NUM_OPCODES] = '{
        // R-type
        "ADD",   "SUB",   "AND",   "OR",    "XOR",
        "SLL",   "SRL",   "SRA",   "SLT",   "SLTU",
        // I-type ALU immediate
        "ADDI",  "ANDI",  "ORI",   "XORI",
        "SLTI",  "SLTIU",
        "SLLI",  "SRLI",  "SRAI",
        // Load
        "LW",    "LB",    "LH",    "LBU",   "LHU",
        // Store
        "SW",    "SH",    "SB",
        // Branch
        "BEQ",   "BNE",   "BLT",   "BGE",   "BLTU",  "BGEU",
        // U-type
        "LUI",   "AUIPC",
        // J-type
        "JAL",   "JALR"
    };

    string type_names [NUM_INSTR_TYPES] = '{
        "R_TYPE", "I_TYPE", "S_TYPE", "B_TYPE", "U_TYPE", "J_TYPE"
    };

    function new(string name, uvm_component parent);
        super.new(name, parent);
        foreach (opcode_hit[i]) opcode_hit[i] = 0;
        foreach (type_hit[i])   type_hit[i]   = 0;
    endfunction

    function void write(transaction t);
        opcode_e op;
        int      type_idx;

        case (t.instr_type)
            transaction::R_TYPE : type_idx = 0;
            transaction::I_TYPE : type_idx = 1;
            transaction::S_TYPE : type_idx = 2;
            transaction::B_TYPE : type_idx = 3;
            transaction::U_TYPE : type_idx = 4;
            transaction::J_TYPE : type_idx = 5;
            default             : type_idx = -1;
        endcase

        if (type_idx >= 0)
            type_hit[type_idx] = 1;

        op = string_to_opcode(t.instr_name);
        if (op != OP_UNKNOWN)
            opcode_hit[int'(op)] = 1;
    endfunction

    function void report_phase(uvm_phase phase);
        int  type_covered   = 0;
        int  opcode_covered = 0;
        real type_pct, opcode_pct;

        foreach (type_hit[i])   if (type_hit[i])   type_covered++;
        foreach (opcode_hit[i]) if (opcode_hit[i]) opcode_covered++;

        type_pct   = (type_covered   * 100.0) / NUM_INSTR_TYPES;
        opcode_pct = (opcode_covered * 100.0) / NUM_OPCODES;

        $display("\n============================================");
        $display("      FUNCTIONAL COVERAGE REPORT");
        $display("============================================");

        $display("  Instr Type Coverage: %0d / %0d  (%0.1f%%)",
                  type_covered, NUM_INSTR_TYPES, type_pct);
        foreach (type_hit[i])
            $display("    [%s] %s",
                      type_hit[i] ? "HIT " : "    ",
                      type_names[i]);

        $display("  ------------------------------------------");
        $display("  Opcode Coverage:     %0d / %0d  (%0.1f%%)",
                  opcode_covered, NUM_OPCODES, opcode_pct);
        foreach (opcode_hit[i])
            $display("    [%s] %s",
                      opcode_hit[i] ? "HIT " : "    ",
                      opcode_names[i]);

        $display("============================================\n");
    endfunction

    function opcode_e string_to_opcode(string name);
        case (name)
            "ADD"   : return OP_ADD;    "SUB"   : return OP_SUB;
            "AND"   : return OP_AND;    "OR"    : return OP_OR;
            "XOR"   : return OP_XOR;    "SLL"   : return OP_SLL;
            "SRL"   : return OP_SRL;    "SRA"   : return OP_SRA;
            "SLT"   : return OP_SLT;    "SLTU"  : return OP_SLTU;
            "ADDI"  : return OP_ADDI;   "ANDI"  : return OP_ANDI;
            "ORI"   : return OP_ORI;    "XORI"  : return OP_XORI;
            "SLTI"  : return OP_SLTI;   "SLTIU" : return OP_SLTIU;
            "SLLI"  : return OP_SLLI;   "SRLI"  : return OP_SRLI;
            "SRAI"  : return OP_SRAI;
            "LW"    : return OP_LW;     "LB"    : return OP_LB;
            "LH"    : return OP_LH;     "LBU"   : return OP_LBU;
            "LHU"   : return OP_LHU;
            "SW"    : return OP_SW;     "SH"    : return OP_SH;
            "SB"    : return OP_SB;
            "BEQ"   : return OP_BEQ;    "BNE"   : return OP_BNE;
            "BLT"   : return OP_BLT;    "BGE"   : return OP_BGE;
            "BLTU"  : return OP_BLTU;   "BGEU"  : return OP_BGEU;
            "LUI"   : return OP_LUI;    "AUIPC" : return OP_AUIPC;
            "JAL"   : return OP_JAL;    "JALR"  : return OP_JALR;
            default : return OP_UNKNOWN;
        endcase
    endfunction

endclass

`endif
