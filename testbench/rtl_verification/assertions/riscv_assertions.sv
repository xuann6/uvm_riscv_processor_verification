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

// Assertion counters for reporting
int unsigned a1_pass_count = 0;
int unsigned a1_fail_count = 0;
int unsigned a2_instr_pass = 0;
int unsigned a2_result_pass = 0;
int unsigned a3_x0_pass = 0;
int unsigned a3_rd_pass = 0;
int unsigned a4_pass_count = 0;
int unsigned a4_fail_count = 0;

// ============================================
// (A1) Control Flow Assertions
//   - verify program counter behavior
// ============================================

// PC increments by 4 when no stall/flush.
// Also disabled on the cycle immediately after a flush clears, because that
// is when the branch/jump target PC first appears in the fetch stage — it
// will be a non-+4 value relative to the flushed PC and is architecturally
// correct behavior.
property pc_increment;
    @(posedge clk) disable iff (reset || $past(flush))
    (!stall && !flush) |-> (PC_F == $past(PC_F) + 4);
endproperty
assert property (pc_increment) begin
    a1_pass_count++;
end else begin
    a1_fail_count++;
    $error("[SVA-A1] PC did not increment by 4! PC=0x%h, prev=0x%h", PC_F, $past(PC_F));
end

// ============================================
// (A2) Data Integrity Assertions
//   - ensure no X/Z in critical paths
//   NOTE: Verilator is 2-state (no X/Z), so these assertions
//   always pass in Verilator but are kept for portability to
//   4-state simulators.
// ============================================

// Instruction no X/Z
property valid_instruction;
    @(posedge clk) disable iff (reset)
    !$isunknown(instruction_F);
endproperty
assert property (valid_instruction) begin
    a2_instr_pass++;
end else $error("[SVA-A2] Instruction contains X/Z values!");

// Writeback result no X/Z
property no_x_in_result;
    @(posedge clk) disable iff (reset)
    regWrite_W |-> !$isunknown(result_W);
endproperty
assert property (no_x_in_result) begin
    a2_result_pass++;
end else $error("[SVA-A2] Write back result contains X/Z!");

// ============================================
// (A3) RISC-V ISA Compliance Assertions
//   - verify rules in RISC-V specification
// ============================================

// Register x0 must always read as 0 (writes to x0 are discarded)
property x0_hardwired_zero;
    @(posedge clk) disable iff (reset)
    (regWrite_W && rd_W == 0) |-> (result_W == 0);
endproperty
assert property (x0_hardwired_zero) begin
    a3_x0_pass++;
end else $error("[SVA-A3] Write to x0 with non-zero value! result=0x%h", result_W);

// Destination register must be in valid range [0:31]
property valid_rd_on_regwrite;
    @(posedge clk) disable iff (reset)
    regWrite_W |-> (rd_W inside {[0:31]});
endproperty
assert property (valid_rd_on_regwrite) begin
    a3_rd_pass++;
end else $error("[SVA-A3] Invalid destination register! rd=%0d", rd_W);

// ============================================
// (A4) Testbench Protocol Assertions
//   - verify testbench and DUT interface behavior
// ============================================

// Instruction mode should remain stable during execution
property instr_mode_stable;
    @(posedge clk) disable iff (reset || $past(reset))
    $stable(instr_mode);
endproperty
assert property (instr_mode_stable) begin
    a4_pass_count++;
end else begin
    a4_fail_count++;
    $warning("[SVA-A4] Instruction mode changed during execution!");
end

// ============================================
// SVA Summary Report (printed at end of simulation)
// ============================================
final begin
    $display("\n============================================");
    $display("          SVA ASSERTION SUMMARY");
    $display("============================================");
    $display("  A1 - PC Increment:        %0d PASS, %0d FAIL", a1_pass_count, a1_fail_count);
    $display("  A2 - Valid Instruction:   %0d PASS", a2_instr_pass);
    $display("  A2 - Valid WB Result:     %0d PASS", a2_result_pass);
    $display("  A3 - x0 Hardwired Zero:   %0d PASS", a3_x0_pass);
    $display("  A3 - Valid Rd Range:      %0d PASS", a3_rd_pass);
    $display("  A4 - Instr Mode Stable:   %0d PASS, %0d FAIL", a4_pass_count, a4_fail_count);
    $display("============================================\n");
end

endmodule
