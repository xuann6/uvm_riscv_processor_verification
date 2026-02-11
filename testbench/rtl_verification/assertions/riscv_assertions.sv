module riscv_assertions(
    input logic clk,
    input logic reset,

    input logic [31:0] PC_F,
    input logic [31:0] instruction_F,
    input logic [31:0] result_W,
    input logic [4:0]  rd_W,
    input logic        regWrite_W,
    input logic        stall,
    input logic        flush,
    input logic        instr_mode
);

// ============================================
// (A1) Control Flow Assertions
//   - verify program counter behavior
// ============================================

// PC increments by 4 when activating pipeline
property pc_increment;
    @(posedge clk) disable iff (reset)
    (!stall && !flush) |-> (PC_F == $past(PC_F) + 4);
endproperty
assert property (pc_increment) else $error("[SVA-A1] PC did not increment by 4!");

// ============================================
// (A2) Data Integrity Assertions
//   - ensure no X/Z in critical paths
// ============================================

// Instruction no X/Z
property valid_instruction;
    @(posedge clk) disable iff (reset)
    !$isunknown(instruction_F);
endproperty
assert property (valid_instruction) else $error("[SVA-A2] Instruction contains X/Z values!");

// Writeback result no X/Z
property no_x_in_result;
    @(posedge clk) disable iff (reset)
    regWrite_W |-> !$isunknown(result_W);
endproperty
assert property (no_x_in_result) else $error("[SVA-A2] Write back result contains X/Z!");

// ============================================
// (A3) RISC-V ISA Compliance Assertions
//   - verify rules in RISC-V specification
// ============================================

// Register x0 must be 0
property x0_hardwired_zero;
    @(posedge clk) disable iff (reset)
    (regWrite_W && rd_W == 0) |-> (result_W == 0);
endproperty
assert property (x0_hardwired_zero) else $error("[SVA-A3] Write to x0 violated!");

// Destination register must be in valid range
property valid_rd_on_regwrite;
    @(posedge clk) disable iff (reset)
    regWrite_W |-> (rd_W inside {[0:31]});
endproperty
assert property (valid_rd_on_regwrite) else $error("[SVA-A3] Invalid destination register! rd=%0d", rd_W);

// ============================================
// (A4) Testbench Protocol Assertions
//   - verify testbench and DUT interface behavior
// ============================================

// Instruction mode should remain stable during execution
property instr_mode_stable;
    @(posedge clk) disable iff (reset)
    $stable(instr_mode);
endproperty
assert property (instr_mode_stable) else $warning("[SVA-A4] Instruction mode changed during execution!");

endmodule
