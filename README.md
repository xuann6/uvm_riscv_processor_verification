# RISC-V Processor Implementation and Verification

This project is about the verification for RISC-V 5-staged pipelined processor. I built-up a complete UVM testbench with SystemVerilog assertion & functional coverage for verification.

In the following I documented most of the issues and questions I had when doing this project. Hope this helps for someone who is also trying to learn verification basics. If you feel this project is helpful, please click the star botton. That means a lot to me:)

## File Structure

```
rtl_sim/
    |--- unitTest/
    |--- bubbleSortTest/
    |
rtl_verification/
    |--- Makefile
    |--- env/
    |     |--- agent/
    |     |     |--- agent.sv
    |     |     |--- driver.sv
    |     |     |--- monitor.sv
    |     |     |--- sequence.sv
    |     |     |--- sequencer.sv
    |     |     |--- transaction.sv
    |     |--- env.sv
    |     |--- scoreboard.sv
    |
    |--- assertions/
    |     |--- riscv_assertions.sv
    |
    |--- coverage_collectors/
    |     |--- coverage_collector.sv
    |
    |--- tb/
    |     |--- interface.sv
    |
    |--- test/
    |     |--- test.sv
    |
    |--- tb_top.sv
```

## Getting Started

### Prerequisites
- [Verilator](https://verilator.org/guide/latest/install.html) 5.x with `--timing` support
- `make`, `curl`, `tar`

### 1. Download UVM sources (run once)
```bash
cd testbench/rtl_verification
make setup
```

This downloads the Accellera UVM 1800.2-2017-1.0 library into `1800.2-2017-1.0/`.

### 2. Build and run
```bash
# Full rebuild + run all instruction types
make rebuild TEST=riscv_full_test

# Run single instruction type 
# (riscv_i_type_test, 
#  riscv_load_store_test, 
#  riscv_b_type_test, 
#  riscv_j_type_test, 
#  riscv_u_type_test, 
#  riscv_full_test)
make run TEST=riscv_r_type_test
```

### Available tests
| Test name | Instructions exercised |
|-----------|------------------------|
| `riscv_base_test` | NOP only (sanity check) |
| `riscv_r_type_test` | ADD SUB AND OR XOR SLT SLTU SLL SRL SRA |
| `riscv_i_type_test` | ADDI ANDI ORI XORI SLTI SLTIU SLLI SRLI SRAI |
| `riscv_load_store_test` | SW SH SB LW LB LH LBU LHU |
| `riscv_b_type_test` | BEQ BNE BLT BGE BLTU BGEU |
| `riscv_j_type_test` | JAL JALR |
| `riscv_u_type_test` | LUI AUIPC |
| `riscv_full_test` | All of the above — achieves 100% coverage |

### Makefile targets
| Target | Description |
|--------|-------------|
| `make setup` | Download UVM 2017-1.0 sources (run once) |
| `make build` | Compile with Verilator (incremental) |
| `make run TEST=<name>` | Build if needed and run a named test |
| `make rebuild TEST=<name>` | Clean, recompile, then run |
| `make clean` | Remove `obj_dir/` build artifacts |
| `make help` | Print usage summary |

## Test Plan
### RTL Simulation

Before the UVM environment was built, unit-level RTL simulation was used to verify individual instructions and their functional correctness. Under `testbench/rtl_sim/unitTest/tb_unittest.sv`, a set of directed test cases validates different instuctions. The bubble sort test under `rtl_sim/bubbleSortTest` exercises the full processor end-to-end with real sorting algorithm.

### UVM Simulation

The UVM environment targets the full 5-stage pipelined processor as the DUT. Stimulus is organized into **file-based sequences**: each test reads 32-bit binary instruction encodings from a `.txt` file under `testbench/stimulus/`, wraps them into `transaction` objects, and sends them through the sequencer → driver → DUT path.

The monitor observes DUT outputs from Fetch and WB stages:
- **WB stage** — captures register write results and check it in scoreboard
- **Fetch stage** — captures every instructions enter and feed to coverage collector for functional coverage

I inject 5 NOPs instructions before and after each test sequence. This ensures the monitor sees all writeback results.

#### SystemVerilog Assertion

Currently four assertion groups are implemented (in `assertions/riscv_assertions.sv`), more details can be found in [assertion_plan.md](docs/verification/assertion_plan/assertion_plan.md).

| ID | Assertion | What it checks |
|----|-----------|----------------|
| A1 | `pc_increment` | PC turns into PC+4 every cycle besides `stall` and `flush`. |
| A2 | `valid_instruction` | Instruction sent to DUT never contains X/Z values (Verilator is 2-state simulator so this always pass). |
| A2 | `no_x_in_result` | Writeback result never contains X/Z when `regWrite_W` is asserted. |
| A3 | `x0_hardwired_zero` | Register x0 is always 0. |
| A3 | `valid_rd_on_regwrite` | Destination register is always in range [0:31]. |
| A4 | `instr_mode_stable` | `instr_mode` stays constant during execution (`instr_mode`==1 for UVM to drive stimulus). |

**Result from `riscv_full_test`:**

```
============================================
          SVA ASSERTION SUMMARY
============================================
  A1 - PC Increment:        155 PASS, 0 FAIL
  A2 - Valid Instruction:   155 PASS
  A2 - Valid WB Result:     155 PASS
  A3 - x0 Hardwired Zero:   155 PASS
  A3 - Valid Rd Range:      155 PASS
  A4 - Instr Mode Stable:   155 PASS, 0 FAIL
============================================
```

SVA assertions are evaluated every clock cycle during the simulation. The pass count shows the number of cycles checked and is not meaningful on its own. Instead, what matters is **zero failures across all assertions**.

#### Functional Coverage

Functional coverage tracks which instructions and instruction types were actually exercised during simulation. In a commercial simulator (Questa, VCS, Xcelium), this is done with `covergroup` / `coverpoint` / `bins` syntax. However, in this project I use **Verilator**, which does not support covergroups ([GitHub issue #784](https://github.com/verilator/verilator/issues/784)). The reason is Verilator is an open-source project which I think is more accessible for peopole without commercial simulator access.

Instead of covergroups, each tracked item (opcode, instruction type) gets one entry in an integer array. An entry is set to 1 the first time that item is hit, and stays 0 if never seen. This works in the same way as `covergroup` & `coverpoint`, and the only drawback is lacks of support of plotting and tabling the statics, which I think is not that important in this project.

```systemverilog
// Standard SV covergroup (NOT supported in Verilator):
covergroup instr_cg;
    cp_type:   coverpoint tx.instr_type;
    cp_opcode: coverpoint tx.instr_name { bins all_ops[] = {...}; }
endgroup

// What this project uses instead:
int type_hit   [NUM_INSTR_TYPES];  // one entry per type
int opcode_hit [NUM_OPCODES];      // one entry per opcode (37 in total for now)
```

**Result from `riscv_full_test`:**

```
============================================
      FUNCTIONAL COVERAGE REPORT
============================================
  Instr Type Coverage: 6 / 6  (100.0%)
    [HIT ] R_TYPE
    [HIT ] I_TYPE
    [HIT ] S_TYPE
    [HIT ] B_TYPE
    [HIT ] U_TYPE
    [HIT ] J_TYPE
  ------------------------------------------
  Opcode Coverage:     37 / 37  (100.0%)
    R_TYPE: [HIT ] ADD    [HIT ] SUB    [HIT ] AND    [HIT ] OR     [HIT ] XOR
            [HIT ] SLL    [HIT ] SRL    [HIT ] SRA    [HIT ] SLT    [HIT ] SLTU
    I_TYPE: [HIT ] ADDI   [HIT ] ANDI   [HIT ] ORI    [HIT ] XORI   [HIT ] SLTI
            [HIT ] SLTIU  [HIT ] SLLI   [HIT ] SRLI   [HIT ] SRAI
            [HIT ] LW     [HIT ] LB     [HIT ] LH     [HIT ] LBU    [HIT ] LHU
    S_TYPE: [HIT ] SW     [HIT ] SH     [HIT ] SB
    B_TYPE: [HIT ] BEQ    [HIT ] BNE    [HIT ] BLT    [HIT ] BGE    [HIT ] BLTU   [HIT ] BGEU
    U_TYPE: [HIT ] LUI    [HIT ] AUIPC
    J_TYPE: [HIT ] JAL    [HIT ] JALR
============================================
```

## UVM Design Detail

- **Components:**
  - [Driver](docs/verification/components/driver.md)
  - [Monitor](docs/verification/components/monitor.md)
  - [Scoreboard](docs/verification/components/scoreboard.md)
  - [Sequences](docs/verification/components/sequences.md)
  - [Transaction](docs/verification/components/transaction.md)
  - [Interface](docs/verification/components/interface.md)

#### Testbench Top
> file: `tb_top.sv`

`tb_top.sv` is the top module, every module is included and I connect the DUT, interface, and UVM testbench here. The connection bewteen DUT and UVM testbench:

```systemverilog
// WB-stage signals (for scoreboard)
assign intf.monitor_pc       = dut.PC_plus4_W - 32'd4;
assign intf.monitor_instr    = dut.instruction_W;
assign intf.monitor_result   = dut.result_W;
assign intf.monitor_regwrite = dut.regWrite_W;
assign intf.monitor_rd       = dut.rd_W;

// Fetch-stage signals (for coverage collector)
assign intf.fetch_pc    = dut.PC_F;
assign intf.fetch_instr = dut.instruction_F;
assign intf.fetch_stall = dut.stall_F;
assign intf.fetch_flush = dut.flush_D;
```

#### Test
> file: `test/test.sv`

Including different test cases. `test.sv` starts from `riscv_base_test`, which only provides basic `build_phase` and `run_phase`. We then inherited the `riscv_base_test` and created `riscv_{RISC-V Inst Type}_type_test` for different instruction type test, and `riscv_full_test` runs all types sequentially.

`riscv_{RISC-V Inst Type}_type_test` will create each type of the following sequence in `sequence.sv`, where we actually create the transaction for sending to DUT.

In the base class, I reuse the virtual interface that is created in `tb_top.sv`. After getting and checking it, I pass it down to the env where our monitor and driver use it to connect with DUT.

#### Environment
> path: `env/env.sv`

UVM environment is the place that you put all of your reusable UVM components and define their default configuration by different applications. Inside the environment, you can have different numbers of interfaces, scoreboards, functional coverage collectors, etc, depending on the test cases you need. You can also have another environment inside it to provide a finer granularity testing. For instance, from sub-system level to block level.

From the code, you can see we have one driver, monitor, sequencer, scoreboard, and coverage collector in our environment. In `build_phase`, we create all the components and make sure the virtual interface is set to both driver and monitor correctly. In `connect_phase`, we connect the driver to sequencer, the monitor WB-port to scoreboard, and the monitor fetch-port to coverage collector.

## References

- [chipverify.com](https://www.chipverify.com/)
- [SystemVerilog - Event Scheduling Algorithm](https://verificationguide.com/systemverilog/systemverilog-scheduling-semantics/)
- [Accellera UVM 1800.2-2017-1.0](https://www.accellera.org/downloads/standards/uvm)
- [Verilator Documentation](https://verilator.org/guide/latest/)
- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
