
# Scoreboard Component

## What is the Scoreboard Class?
The scoreboard verifies DUT correctness by comparing actual execution results (from monitor) against expected results calculated by a reference model. It maintains a software model of the processor's register file and memory to predict expected behavior.

## Scoreboard Flow

```
MONITOR                SCOREBOARD
|                       |                                           |
|-- analysis_port ----->|                                           | 
|   .write(tx)          |                                           |
|                       |                                           |
|                       |-- write(tx)                               |
|                       | (analysis_imp)                            |
|                       |                                           |
|                       |-- check_transaction()                     |
|                       |     1. calculate_expected()               |
|                       |     2. return expected_value              |
|                       |     3. compare actual vs expected         |
|                       |     4. update ref models (reg_file/memory)|
```

The scoreboard receives transactions from the monitor, predicts expected results using internal models, compares against actual results, and tracks pass/fail statistics.

## Key Responsibilities

**Transaction Verification:**
> The scoreboard acts as the **checker** - it receives DUT behavior, verifies correctness, and records the stats.
- `write()` - Entry point called by monitor's analysis_port
- `check_transaction()` - Main verification logic that compares actual vs expected
- `calculate_expected_result()` - Reference model calculation for predicting correct behavior

**Reference Modeling:**
- `reg_file_model[32]` - Software model of 32 RISC-V registers
- `mem_model[addr]` - Associative array modeling memory (good for efficient memory usage)
- Models are updated with actual values after each check

**Statistics Tracking:**
- `passed_checks` - Count of successful verifications
- `failed_checks` - Count of mismatches
- `total_checks` - Total verifications performed
- `report_phase()` - Final summary of test results

## Key Methods

### write(transaction tx)
Entry point called automatically when monitor broadcasts a transaction via `analysis_port`. This is the implementation of `uvm_analysis_imp`, simply calls `check_transaction(tx)` to perform verification.

### check_transaction(transaction tx)
> **Current scope**: Only verifies register writes (`tx.reg_write && tx.result_reg != 0`). Memory writes are tracked but not verified yet.
1. **Calculate expected** - Calls `calculate_expected_result()` using reference model
2. **Compare** - Checks if `tx.result === expected_value`
3. **Report** - Logs PASS (green) or FAIL (red) with details
4. **Update model** - Stores actual result in `reg_file_model` 
5. **Track stats** - Increments `passed_checks` or `failed_checks`

### calculate_expected_result(transaction tx, output expected_value)
**The reference model** - implements RISC-V instruction semantics to predict correct results.
1. Fetch operand values from `reg_file_model`
2. Execute instruction based on type:
   - **R-Type**: ALU operations (ADD, SUB, AND, OR, XOR, shifts, comparisons)
   - **I-Type**: Immediate ALU, loads, JALR
   - **U-Type**: LUI, AUIPC
   - **J-Type**: JAL
3. Return `expected_value`

### reset_models()
Initializes the reference models
- reg_file_model[32] - All registers set to 0 (hardwired x0 to 0)
- mem_model.delete() - Clears associative memory array

### set_initial_reg_value(int reg_num, bit [31:0] value)

Helper function to pre-load register values in the reference model (I do this in environment). Useful for debugging and testing. After the test cases are completed, this function should be commented.

### set_initial_mem_value(bit [31:0] addr, bit [31:0] value)
Helper function to pre-load memory values in the reference model, same usage with `set_initial_reg_value()`

### report_phase()
UVM phase that runs at the end of simulation to print final statistics.

## Some More Details
### Current Verification Scope
> **Currently only register write operations are verified. Memory writes are tracked in mem_model but not checked against expected values yet.**

> **Currently using direct instruction stimulus to simplify the verification process. For better functional coverage, stimulus should be generated using SystemVerilog randomization.** 

> **In current implementation, the ref model is placed inside scoreboard component. However, for more flexiblility, scalability, and maintainability, it's better to separate the scoreboard and ref model.**

What is verified:

- All R-Type ALU instructions (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
- All I-Type ALU instructions (ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI)
- U-Type instructions (LUI, AUIPC)
- J-Type instructions (JAL - return address)
- JALR (return address)

### Why Use analysis_imp Instead of a Regular Function?
The scoreboard uses uvm_analysis_imp to receive transactions from the monitor. This is the receiver side of the TLM connection:
- In scoreboard 
    ```
    uvm_analysis_imp#(transaction, scoreboard) analysis_imp;
    ```
- In environment - connects monitor to scoreboard 
    ```
    monitor.analysis_port.connect(scoreboard.analysis_imp);
    ```
How it works:
1. Monitor calls analysis_port.write(tx)
2. UVM routes this to scoreboard's analysis_imp
3. Scoreboard's write() function is automatically invoked
4. write() calls check_transaction() to verify

The benefits of using standard UVM TLM communication is that it supports multiple connections and decouple monitor from scoreboard implementation (seen monitor.md)

### Why Update Models with Actual Values?
```
if (tx.result_reg != 0) begin
    reg_file_model[tx.result_reg] = tx.result;
end
```

This prevents error propagation and makes debugging easier - you see the exact failing instruction.
```
ADD x1, x2, x3   <- BUG: Returns 15 instead of 10
ADD x4, x1, x5   <- Uses actual value (15) from x1, not expected (10)
                    If x1=15 and x5=20, we expect x4=35 (not 30)
```

### Why Use Associative Array for Memory Model?
```
bit [31:0] mem_model[bit[31:0]];  // Associative array
```
Instead of a fixed-size array, the memory model uses an associative array (like a hash map). This is efficient for memory usage (sparse memory access).