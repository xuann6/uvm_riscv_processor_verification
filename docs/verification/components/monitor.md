# Monitor Component

## What is the Monitor Class?
The monitor observes DUT outputs and converts them into transactions that are sent to the scoreboard via an analysis port. The monitor acts as a passive observer, only capturing execution results.

## Monitor Flow
```
DUT                    MONITOR              SCOREBOARD
|                       |                       |
|-- execute instr       |                       |
|-- write register ---->|                       |
|                       |                       |
|                       |-- create_result_tx()  |
|                       |                       |
|                       |-- analysis_port ----->|
|                       |   .write(tx)          |
|                       |                       |
|                       |-- @(monitor_cb)       |
|                       |   (wait clock edge)   |
|                       |                       |
|-- next instruction -->|                       |
```

The monitor continuously observes DUT signals through the interface and creates transactions representing observed behavior.

## Key Responsibilities

**Transaction Creation:**
> The monitor creates transactions based on *observed* DUT behavior, unlike the driver which creates stimulus transactions
- `create_result_transaction()` - Creates a transaction capturing register write results
- Populates transaction fields from interface signals (PC, instruction, result register, result value) to scoreboard for the comparison with reference model

**Communication:**
- `analysis_port` - TLM port that broadcasts transactions to connected components (scoreboard), where scoreboard receives through `analysis_imp`, having the actual implementation of the write function to compare the result
- Uses `write()` method to send transactions through the analysis port

## Key Methods

### run_phase()
Main execution loop that continuously observes DUT activity and creates transactions. These transactions are sent to scoreboard for comparison.


### create_result_transaction()
Creates a transaction representing an observed reg file execution result.
- `tx.pc` ← `monitor_pc`
- `tx.instruction` ← `monitor_instr` 
- `tx.result_reg` ← `monitor_rd`
- `tx.result` ← `monitor_result`

The function also calls `tx.decode_instruction()` to fill all the necessary info in our instruction.

### monitor_memory_operations()
**(Currently commented out)** Observes memory write operations.

## Some More Details

> **In current stage we only monitor reg file write, and compare the result of reg write in scoreboard.**

### Why Don't We Need `raise_objection()` and `drop_objection()` in `run_phase()`?

The same reasoning from `driver.md` applies here. The monitor's `run_phase()` uses a `forever` loop that never exits naturally. Phase termination is controlled centrally in the test using `drop_objection()`, which causes all component tasks (including monitor and driver) to terminate.

### Why Don't We Use Direct Function Call But Use `Analysis Port`?

We use a TLM `analysis_port` instead of directly calling scoreboard methods. This provides:
- **Decoupling** - Monitor doesn't need to know about scoreboard implementation
- **Broadcast capability** - Multiple components can connect to the same analysis port (e.g., scoreboard + coverage collector)
- **Flexibility** - Easy to add/remove subscribers without modifying monitor code

The connection is made in the environment: `monitor.analysis_port.connect(scoreboard.analysis_export)`

### Monitor vs. Driver: Key Differences

| Aspect | Driver | Monitor |
|--------|--------|---------|
| **Direction** | Drives stimulus *into* DUT | Observes outputs *from* DUT |
| **Active/Passive** | Active (drives signals) | Passive (only observes) |
| **Clocking Block** | `driver_cb` (outputs signals) | `monitor_cb` (inputs signals) |
| **Communication** | Gets transactions from sequencer | Broadcasts transactions via analysis port |
