# Driver Component

## What is the Driver Class?
The driver receives transactions from the sequencer and converts them into signals passed to the DUT through the interface (interface details in `interface.md`). The driver acts as a pump, continuously sending transactions to the DUT.

## Driver Flow
```
SEQUENCER              DRIVER                    DUT
|                       |                       |
|-- tx available        |                       |
|                       |                       |
|<-- get_next_item() ---|                       |
|-- send tx ----------->|                       |
|                       |                       |
|-- test_mode = 1       |                       |
|-- test_instr = inst ->| (Execute instruction) |  
|                       |                       |
|-- @(driver_cb)        |                       |
|   (wait clock edge)   |                       |
|                       |                       |
|-- item_done() ------->|                       |
|<-- handshake done ----|                       |
```

The descriptions for `get_next_item()` and `item_done()` are in the following sections.

## Key Responsibilities

**Transaction Handling:**
> Detailed interaction between sequence, sequencer, and driver can be found in `sequences.md`
- `get_next_item()` - Retrieves transactions from sequencer. Sequences are placed in the sequencer queue in order; this function retrieves one transaction from the queue
- `item_done()` - Signals completion to sequencer. Tells the sequencer this transaction is complete, allowing the next sequence to proceed

**Signal Generation:**
- Drives instructions directly to processor in test mode
- Synchronizes with DUT clock using clocking blocks

## Key Methods

### run_phase()
Main execution loop that continuously processes transactions.

### drive_instruction()
Drives a single instruction to the processor and waits for one clock cycle.

### reset_phase()
Initializes driver state when DUT resets. The correlation between `reset_phase()` and `run_phase()` can be found at https://www.chipverify.com/uvm/uvm-phases

## Some More Details

### Why Don't We Need `raise_objection()` and `drop_objection()` in `run_phase()`?

A UVM phase ends when all objections are dropped **OR** when all tasks in the phase reach their end.

In `run_phase()`, we use a `forever` loop to keep the driver sending transactions. When there are no transactions, this loop blocks at `get_next_item()` and `run_phase()` never exits naturally. Instead, we exit this forever loop by using `drop_objection()` in `test.sv`.

This approach provides centralized control—we only manage phase termination in the test without worrying about it in the driver. It also avoids issues like premature exit if the sequencer is temporarily empty while more sequences are pending.

In contrast, `reset_phase()` must end when the reset negedge occurs. The raise-drop mechanism ensures we properly wait for and exit the reset phase at the correct time.