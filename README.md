# RISC-V Processor Implementation and Verification

This project is trying to do a functional verification for RISC-V 5-staged pipelined processor. The goal of this project is to cover the usage of UVM, including driver, monitor, scoreboard, etc. 

In the following I documented most of the issues and questions I had when doing this project. Hope this helps for someone who is also trying to learn verification basics. If you feel this project is helpful, please click the star botton. That will be much apprectiated!


## Progress
### Completed
1. Completed `rtl_sim/unitTest`. Under `testbench/rtl_sim/unitTest`, please run: 
    
    ```bash=
    bash run_unitTest.tcsh -c
    ``` 

### Todos
1. `rtl_sim/bubbleSortTest` needs debugging

## References
- [chipverify.com](https://www.chipverify.com/)
- [SystemVerilog - Event Scheduling Algorithm](https://verificationguide.com/systemverilog/systemverilog-scheduling-semantics/)

## Processor Implementation
> TBD

## Processor Verification (UVM)

### Overall UVM Structure

<img src="fig/uvm.png" alt="Alt text" width="500"/>

### File Structure
```
rtl_verification/
    |
    |--- env/
    |     |
    |     |--- agent/
    |     |     |
    |     |     |--- agent.sv
    |     |     |--- driver.sv
    |     |     |--- monitor.sv
    |     |     |--- sequence.sv
    |     |     |--- sequencer.sv
    |     |     |--- transaction.sv
    |     |
    |     |--- env.sv
    |     |--- scoreboard.sv
    |
    |--- tb/
    |     |--- interface.sv
    |
    |--- test/
    |     |--- test.sv
    |
    |--- tb_top.sv
```

### UVM Verification
- **Components:**
  - [Environment](docs/verification/components/environment.md)
  - [Testbench_top](docs/verification/components/testbench_top.md)
  - [Driver](docs/verification/components/driver.md)
  - [Monitor](docs/verification/components/monitor.md)
  - [Scoreboard](docs/verification/components/scoreboard.md)
  - [Sequences](docs/verification/components/sequences.md)
  - [Transaction](docs/verification/components/transaction.md)
  - [Interface](docs/verification/components/interface.md)

#### Testbench Top
> file: `tb_top.sv`

`tb_top.sv` works as top level module to call both DUT (Design Under Testing) and our UVM test. ASssuming we are doing the RTL simluation, we need `top.sv`, which is our design, and the `testbench.sv`, which provides the testing signal. Same idea here but we use UVM test to replace the `testbench.sv` in RTL simulation.

`tb_top.sv` plays as the top module for our simulation, every module will be included in this root module, DUT and the interface for UVM testing will be connected, and the input siganl will be setup here (not necessary but for simplicity I am doing this in this project). For instance, we need to setup the `clk` and `rst` signal here since these are the input for our processor.  

In gerneral, most of the setups in `tb_top.sv` are very much alike with setup in RTL simulation testbench. Setting up the clk and rst signals, sending them into DUT and UVM environment, and dumping the waveform file. One thing noticeable is this section: 
```Verilog=
initial begin
    uvm_config_db#(virtual if)::set(null, "*", "vif", intf);
    run_test();
end
```
`uvm_config_db` is a built-in function for UVM which provides a global configurable database across all the verifcation components. The detailed explanation is as below: 
- `#(virtual if)` - storing a virtual interface into this global database
- `set(null, "*", "vif", intf);` - set the config for this component
    - `null` - means this component can be accessed by any component
    - `"*"` - means this config can be applied to all components in the hierachy
    - `"vif"` - represents the name (key) for this component
    - `intf` - represents the interface will be retrieved and used by other components

`run_test()` calls our the base_test for testing. To specify which test are we running, we can use `run_test(base_test)` to run the `base_test` class in `test.sv` file. The other option is to add `+UVM_TESTNAME=base_test` when running the simulation in command line.

#### Test
> path: `test/test.sv`

We are allowed to run different test cases. `test.sv` starts from `riscv_base_test`, which only provides basic `build_phase` and `run_phase`. We then inherited the `riscv_base_test` and created `riscv_{RISC-V Inst Type}_type_test`, including 'r' for R-type, 'i' for I-type, and 'load_store' for LOAD and STORE instruction. 

`riscv_{RISC-V Inst Type}_type_test` will create each type of the following sequence in `sequence.sv`, where we actually create the transaction for sending to DUT. 

In the `riscv_base_test` class, we are reusing the virtual interface that we created in `tb_top.sv`. After getting and checking it, we then pass it down to the env where our monitor and driver use it to connect with DUT. 

> **Why and where we need virtual interface?**
> For the components that are directly interacting with DUT, we need virtual interface. The reason is because in SystemVerilog, there are two separate worlds: static module world and dynamic class world. Static module world includes DUT, interfaces, and all the other physical connections. On the other hand, dynamic class world includes all UVM objects. The keyword "virtual" provides the class objects the ability to access the static module items. So for virtual interface, we are basically providing our env, monitor, and driver the ability to communicate with DUT.

> **Why we need `phase_raise_object(this)` and `phase_drop_object(this)`?**
> The raise and drop is generally a flag that tells UVM if we are still doing something in this phase. UVM process will not enter the next phase unless all the components in the current phase have called `phase_drop_object(this)`. Addtionally, these statements can be added to all the phases, but it's often not necessary to do so beside run_phase, since run_phase is the phase that actually executes the stimulus, and the duration of this phase is often not predetermined.

#### Environment
> path: `env/env.sv`
UVM environment is the place that you put all of your reusable UVM components and define their default configuration by different applications. Inside the environment, you can have different numbers of interfaces, scoreboards, functional coverage collectors, etc, depending on the test cases you need. You can also have another environment inside it to provide a finer granularity testing. For instance, from sub-system level to block level.

From the code, you can see we have one driver, monitor, sequencer, and scoreboard in our environment. In `build_phase`, we create all the components and make sure the virtual interface is set to both driver and monitor correctly. In `connect_phase`, we connect the driver to sequencer and monitor to scoreboard. In `reset_phase`, we initialize the reg_file and memory to the default value.

> **Why `reset_phase` is using task and all the other phases are using function?**
> In UVM, we can choose our phases either using task or function based on the specific usage of component. As our understanding in SystemVerilog, function happens immediately and we have no timing control in it. For task, it consumes simulation time and that's why we need to add the raise/drop objects to make sure the UVM won't enter the next phase til this `reset_phase` finishes.

> **What's the `UVM_LOW` at the end of `uvm_info`?**
> Represent the verbosity level of this print message is LOW. The console will print the verbosity level which is less than the system configuration. Default verbosity is MEDIUM, so the message will be printed. For more information, you can check [Report Functions](https://www.chipverify.com/uvm/report-functions)

#### Driver
> file: `env/agent/driver.sv`

Driver will 'drive' the the transaction to the design through virtual interface, and the transaction level object will be obtained from the `sequencer`, which we will talk about next.

The main focus for the driver will be in the `run_phase`. In the `run_phase`, the complete process to pass the transaction will be: get the next transaction from sequencer, send the transaction to DUT, and end the current transaction. There are 3 methods for a driver to interact with a sequencer:
1. `get_next_item()` - block until the next item is available from sequencer, should follow by `item_done()`
2. `try_next_item()` - non-blocking method, which will return null if the request transaction object if not available from sequencer. Else will return a pointer to the object
3. `item_done()` - be called after `get_next_item` or the successful `try_next_item`

There are two ways to complete the handshake between `dirver` and `sequencer`:
1. `get_next_item` followed by `item_done` - `finish_item` call in sequence finishes after `item_done` call (`finish_item` will be mentioned in the following chapter)
2. `get` followed by `put` - `finish_item` call in sequence finishes right after `put` call

> **Is it necessary to use non-blocking assignment with `get_next_item`/`item_done` handshake?**
> No, it is not necessary, the usage of the handshake protocol is not related to the blocking/non-blocking assignment. So does the blocking/non-blocking usage in `get`/`put` protocol.

> **Why don't we need to declare `seq_item_port` in driver?**
> The `seq_item_port` is already declared in the uvm_driver base class so we don't have to declare it again.

#### Transaction
> file: `env/agent/transaction.sv`

- **Purpose**: 
    
    The transaction class creates some standardized data structure that flows between verification components.

    In verification of our processor, our transaction represents a RISC-V instruction (RV32I ISA) along with its expected behavior (including memory addr/data, output reg/data).

- **Key Components**:
  
  - instruction
  - PC
  - expected results (both reg and data)
  - flags inside the processor (reg_write, mem_write, etc)
  - helper function

- **Implementation Details**:

    - `decode_instruction()` - breaks down 32-bit instruction
    - `convert2string()` - provides transaction information for debugging

#### Interface
> file: `tb/interface.sv`

- **Purpose**: 

    The interface acts as the bridge between the DUT and our verification env, allowing the testbench to reuse the interface for multiple testcases. The interface defines the contract between the hardware design and the software verification components. Thus, all signals used for our verification stages or passed into the DUT should be declared in this file. 
    
    The interface ensures proper synchronization through clocking blocks and provides separate access points for drivers and monitors. This maintains a clean verification environment.

- **Key Components**:
- **Implementation Details**:







