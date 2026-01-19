`timescale 1ns/1ps

module tb;

    // Clock and reset
    logic clk;
    logic reset;
    
    // DUT instantiation
    RISCVPipelined dut(
        .clk(clk),
        .reset(reset)
    );
    
    // For test configuration
    int array_size = 10;
    int base_addr_word = 64;   // Word address 64 (0x40)
    int done_flag_addr = 128;  // Word address 128 (0x80)
    int max_cycles = 500;      // Increased for full sort completion
    
    // Arrays for verification
    int unsorted_array[10] = '{10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
    int expected_sorted_array[10] = '{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    
    // Clock generation - 100MHz (10ns period)
    always begin
        #5 clk = ~clk;  
    end
    
    // Test execution
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        
        // Display test information
        $display("Starting bubble sort test");
        $display("Array size: %0d", array_size);
        $display("Unsorted array: [%p]", unsorted_array);
        
        // Initialize memories
        initialize_bubble_sort_program();
        initialize_data();
        
        // Release reset after 2 clock cycles
        #20;
        reset = 0;
        
        // Wait for completion or timeout
        wait_for_completion();
        
        // Verify results
        verify_results();
        
        // End simulation
        #100;
        $finish;
    end
    
    task initialize_bubble_sort_program();
        dut.imem.inst_mem[0]  = 32'h04000093;  // li x1, 64 (base word address)
        dut.imem.inst_mem[1]  = 32'h00209093;  // slli x1, x1, 2 (convert to byte address)
        
        // Load first two elements
        dut.imem.inst_mem[2]  = 32'h0000a303;  // lw x6, 0(x1) (load arr[0])
        dut.imem.inst_mem[3]  = 32'h0040a383;  // lw x7, 4(x1) (load arr[1])
        
        // Forced unconditional swap (no branch to check)
        dut.imem.inst_mem[4]  = 32'h0060a223;  // sw x6, 4(x1) (store x6 to arr[1])
        dut.imem.inst_mem[5]  = 32'h0070a023;  // sw x7, 0(x1) (store x7 to arr[0])
        
        // Infinite loop to stop
        dut.imem.inst_mem[6]  = 32'h0000006f;  // j self
    endtask

    // Initialize data memory with the unsorted array
    task initialize_data();
        automatic int byte_addr;
        automatic int word_addr;
        automatic int done_byte_addr;
        automatic int done_word_addr;
        
        // Fill data memory with unsorted array at base_addr (in byte addresses)
        for (int i = 0; i < array_size; i++) begin
            // Convert byte address to word address for initialization
            byte_addr = base_addr_word * 4 + i * 4;
            word_addr = byte_addr >> 2;
            dut.dmem.mem[word_addr] = unsorted_array[i];
            $display("Initialized mem[%0d] = %0d (byte addr 0x%h, word addr 0x%h)", 
                    word_addr, unsorted_array[i], byte_addr, word_addr);
        end
        
        // Clear done flag
        done_byte_addr = done_flag_addr * 4;
        done_word_addr = done_byte_addr >> 2;
        dut.dmem.mem[done_word_addr] = 0;
        $display("Initialized done flag at byte addr 0x%h (word addr 0x%h) = %0d", 
                done_byte_addr, done_word_addr, 0);
    endtask
    
    // Wait for the program to complete sorting or timeout
    task wait_for_completion();
        automatic int cycle_count = 0;
        
        // Run until done flag is set or timeout
        while (dut.dmem.mem[done_flag_addr] != 1 && cycle_count < max_cycles) begin
            @(posedge clk);
            cycle_count++;
            
            // Print debug information
            if (cycle_count % 10 == 0) begin
                $display("Cycle %0d: PC = 0x%h, Instruction = 0x%h", 
                         cycle_count, dut.PC_F, dut.instruction_F);
                
                // Show key register values
                $display("  x1 (base) = 0x%h, x3 (i) = %0d, x5 (j) = %0d", 
                         dut.rf.r_file[1], dut.rf.r_file[3], dut.rf.r_file[5]);
                
                // Show comparison registers
                $display("  x6 (curr) = %0d, x7 (next) = %0d",
                         dut.rf.r_file[6], dut.rf.r_file[7]);
                
                // Check first few array elements
                $display("  Array: [%0d, %0d, %0d, %0d, %0d]", 
                         dut.dmem.mem[base_addr_word], 
                         dut.dmem.mem[base_addr_word+1],
                         dut.dmem.mem[base_addr_word+2],
                         dut.dmem.mem[base_addr_word+3],
                         dut.dmem.mem[base_addr_word+4]);
                
                $display("  ALUResult_E = 0x%h, ALUResult_M = 0x%h, memWrite_M = %b", 
                        dut.ALUResult_E, dut.ALUResult_M, dut.memWrite_M);
                $display("  writeData_M = 0x%h, addr = 0x%h", 
                        dut.writeData_M, dut.ALUResult_M[13:0]);
            end
        end
        
        if (cycle_count >= max_cycles) begin
            $display("TEST FAILED: Timeout after %0d cycles", cycle_count);
        end
        else begin
            $display("Sorting completed in %0d cycles", cycle_count);
        end
    endtask
    
    // Verify the sorted array is correct
    task verify_results();
        automatic int errors = 0;
        
        $display("Verifying sorted array:");
        for (int i = 0; i < array_size; i++) begin
            // Just use the same addressing as initialization
            automatic int word_addr = base_addr_word + i;
            automatic int data = dut.dmem.mem[word_addr];
            
            $display("mem[0x%h] = %0d (Word addr: 0x%h) (Expected: %0d)", 
                    word_addr*4, data, word_addr, expected_sorted_array[i]);
            
            if (data != expected_sorted_array[i]) begin
                errors++;
                $display("ERROR: Mismatch at index %0d", i);
            end
        end
        
        if (errors == 0) begin
            $display("TEST PASSED: Array sorted correctly!");
        end
        else begin
            $display("TEST FAILED: %0d errors found in sorted array", errors);
        end
    endtask

endmodule