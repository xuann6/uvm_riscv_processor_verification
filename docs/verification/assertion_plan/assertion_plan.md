# Assertion Verification Plan

## Overview
This document describes the SystemVerilog Assertions (SVA) used to verify the RISC-V pipelined processor implementation in this project.

## Assertion Categories

### A1: Control Flow Assertions (1 assertion)
**Purpose:** Verify program counter behavior and control flow integrity
1. PC should increment by 4 each cycle if no stall/flush

---

### A2: Data Integrity Assertions (2 assertions)
**Purpose:** Ensure no X/Z (unknown) value propagation in critical data paths
1. Instruction should not include X/Z
2. Write back values should not include X/Z

---

### A3: RISC-V ISA Compliance Assertions (2 assertions)
**Purpose:** Verify adherence to RISC-V architectural specification
1. Register X0 should always be 0
2. Make sure we are writing to the valid register destination

---

### A4: Testbench Protocol Assertions (1 assertion)
**Purpose:** Verify testbench and DUT interface behavior
1. Make sure instruction mode signal (instr_mode) should remain stable during execution