# Interface Component

## What is the Interface?
The interface defines the communication boundary between the testbench and the DUT (Design Under Test). It encapsulates signal connections and provides synchronized access through clocking blocks. The interface separates driver and monitor access using modports, ensuring isolation between stimulus generation (driver) and result checking (monitor).

## Interface Architecture

```
TESTBENCH                    INTERFACE                  DUT

Driver -----> driver_cb ---> (currently no signals) --> Processor

Monitor <---- monitor_cb <--- monitor_* signals    <--- Processor
```

The interface serves as the **signal bridge** between the verification environment and the processor, ensuring:
- Proper clock synchronization via clocking blocks
- Separated access for driver (stimulus) and monitor (checking)
- Providing abstraction layer between testbench and hardware

## Key Responsibilities

**Signal Definition:**
> The interface declares all signals that cross the testbench-DUT boundary. We only support signals for observing from monitor for now. 
- `monitor_pc` - program counter
- `monitor_instr` - instruction being executed
- `monitor_result` - result from ALU output
- `monitor_rd` - destination register
- `monitor_regwrite` - register write signal

**Clock Synchronization:**
- `driver_cb` - Clocking block for synchronized stimulus (currently unused)
- `monitor_cb` - Clocking block for synchronized observation
- Both clocking blocks trigger on `posedge clk`

**Access Control:**
- `driver` modport - Restricts driver to appropriate signals and timing
- `monitor` modport - Restricts monitor to read-only observation.

## Clocking Blocks

### What Are Clocking Blocks?
Clocking blocks define **when** and **how** the testbench interacts with interface signals. By using clocking block, we are able to eliminate the race condition between DUT and testbench.

**Without clocking blocks (RACE CONDITION):**
```systemverilog
// In Monitor
forever begin
  @(posedge clk);

  if (vif.monitor_regwrite) begin
    tx.result = vif.monitor_result;
  end
end
```

From the above example, we tried to sample at the posedge of the clock. However, the DUT will update the flip-flop while the monitor is sampling (race condition). To avoid race condition, we can use clocking blocks to separate the timing for updating the flip-flop and observing the value.

To understand how clocking blocks work, we have to understand different regions of SystemVerilog. SystemVerilog supports [events scheduling algorithm](https://verificationguide.com/systemverilog/systemverilog-scheduling-semantics/), which divides each simulation time slot into regions for different events. The following shows different regions in SV; however, for understanding the mechanism of clocking blocks, we only need to focus on the active, the NBA (non-blocking assignment), and the observed region.

```
1) preponed 
2) active - DUT execution
3) inactive
4) pre-NBA
5) NBA - update left-hand side of non-blocking assignments (<=)
6) post-NBA
7) observed - clocking block input sample here
8) reactive
9) postponed 
```

As you can see, using clocking blocks naturally allows us to get the value after the DUT execution. We can simply modify the previous example to avoid the race condition between the monitor and the DUT:

**With clocking blocks (WORK SUCCESSFULLY):**
```systemverilog
// In Monitor
forever begin
  @(vif.monitor_cb); // wait for clocking block event

  if (vif.monitor_cb.monitor_regwrite) begin // sample in observed region to avoid race condition
    tx.result = vif.monitor_cb.monitor_result;
  end
end
```

## Modports

### What Are Modports?
Modports (module ports) define **restricted views** of the interface for different components. They enforce access control by limiting which signals and clocking blocks each component can see.

This is good for compile-time safety since by doing so, the monitor cannot drive the DUT. Also, the driver cannot access the signals for the monitor. Using modports gives us clarity on the responsibility of each component.

### Driver Modport
```systemverilog
modport driver(
  clocking driver_cb,
  input clk, reset
);
```

### Monitor Modport
```systemverilog
modport monitor(
  clocking monitor_cb,
  input clk, reset
);
```


## Some More Details

### Current Implementation Status
> **Currently the interface only supports monitor observation. Driver signals are not connected to the DUT.**

### Why Modports Matter

Modports isolate the inputs/outputs between driver and monitor. The driver can only send signals to the DUT via the interface, and the monitor can only receive signals from the DUT via the interface.

```systemverilog
// Compile-time protection example
virtual riscv_if.monitor vif;  // Uses monitor modport

// This will cause COMPILATION ERROR:
vif.monitor_cb.monitor_result = 32'hDEAD;  // ERROR: monitor_result is input-only!

// This is correct:
data = vif.monitor_cb.monitor_result;  // OK: reading input
```

### Monitor/driver Clocking Block Example
Again, clocking blocks automatically schedule operations in the correct region, preventing races between RTL and testbench.

**Monitor Example:**
```systemverilog
// DUT updates in Active/NBA
always_ff @(posedge clk)
  result <= alu_out;

// Monitor samples in Observed
@(vif.monitor_cb);
tx.result = vif.monitor_cb.monitor_result;  // Safe - DUT already finished!
```

**Driver Example (Future):**
```systemverilog
// Driver drives in Preponed (before Active)
vif.driver_cb.data <= value;

@(vif.driver_cb);  // DUT will sample this value in Active region
```