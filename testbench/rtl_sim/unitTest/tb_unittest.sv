`timescale 1ns/1ps

module tb;
    logic clk;
    logic reset;
    
    int total_tests;
    int passed_tests;
    int failed_tests;
    
    RISCVPipelined dut (
        .clk(clk),
        .reset(reset)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period (100MHz)
    end
    
    int cycle_count;
    logic [31:0] test_instruction;
    logic [31:0] expected_result;
    logic [31:0] actual_result;
    string test_name;
    
    task init_instruction_memory(input logic [31:0] instructions[], input int size);
        for (int i = 0; i < size; i++) begin
            dut.imem.inst_mem[i] = instructions[i];
        end
    endtask
    
    task init_data_memory(input logic [31:0] data[], input int size, input int start_addr = 0);
        for (int i = 0; i < size; i++) begin
            dut.dmem.mem[start_addr + i] = data[i];
        end
    endtask
    
    task init_register_file(input logic [31:0] reg_values[]);
        for (int i = 1; i < 32; i++) begin
            dut.rf.r_file[i] = reg_values[i];
        end
    endtask
    
    task check_register_result(input int reg_num, input logic [31:0] expected_value, input string instr_name);
        repeat(5) @(posedge clk);
        
        actual_result = dut.rf.r_file[reg_num];
        total_tests++;
        
        if (actual_result !== expected_value) begin
            $display("TEST FAILED: %s", instr_name);
            $display("  Expected x%0d = 0x%8h, Got 0x%8h", reg_num, expected_value, actual_result);
            failed_tests++;
        end else begin
            $display("TEST PASSED: %s", instr_name);
            $display("  x%0d = 0x%8h", reg_num, actual_result);
            passed_tests++;
        end
    endtask
    
    task check_memory_result(input int addr, input logic [31:0] expected_value, input string instr_name);
        actual_result = dut.dmem.mem[addr];
        total_tests++;
        
        if (actual_result !== expected_value) begin
            $display("TEST FAILED: %s", instr_name);
            $display("  Expected mem[%0d] = 0x%8h, Got 0x%8h", addr, expected_value, actual_result);
            failed_tests++;
        end else begin
            $display("TEST PASSED: %s", instr_name);
            $display("  mem[%0d] = 0x%8h", addr, actual_result);
            passed_tests++;
        end
    endtask
    
    task print_test_summary();
        $display("\n===========================================================");
        $display("                    TEST SUMMARY                           ");
        $display("===========================================================");
        $display("Total Tests:    %0d", total_tests);
        $display("Passed Tests:   %0d", passed_tests);
        $display("Failed Tests:   %0d", failed_tests);
        $display("Pass Rate:      %.1f%%", (passed_tests * 100.0) / total_tests);
        $display("===========================================================");
        
        if (failed_tests == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
            
        $display("===========================================================");
    endtask
    
    task reset_processor();
        reset = 1;
        repeat(3) @(posedge clk);
        reset = 0;
    endtask
    
    initial begin
        int i; 
        logic [31:0] initial_regs[32];
        logic [31:0] test_program[128];
        logic [31:0] data_mem[32];
        
        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;
        
        cycle_count = 0;
        reset = 1;
        
        for (i = 0; i < 32; i++) begin 
            initial_regs[i] = 0; 
            data_mem[i] = 0;
        end
        
        initial_regs[1] = 32'h00000005;  // x1 = 5
        initial_regs[2] = 32'h0000000A;  // x2 = 10
        initial_regs[3] = 32'hFFFFFFFF;  // x3 = -1 (for testing logical operations)
        initial_regs[4] = 32'h00000003;  // x4 = 3 (for testing shift operations)
        
        data_mem[5] = 32'hABCDEF01;     // For load tests
        
        reset_processor();
        init_register_file(initial_regs);
        init_data_memory(data_mem, 32);
        
        $display("\n===========================================================");
        $display("      STARTING RISC-V PIPELINED PROCESSOR TESTS             ");
        $display("===========================================================");
        
        //===================================================================
        // 1. Test R-Type Instructions (ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA)
        //===================================================================
        
        $display("\n----- Testing R-Type Instructions -----");
        
        // 1.1 ADD - rd = rs1 + rs2
        test_name = "ADD (x5 = x1 + x2 = 5 + 10 = 15)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000001000001000001010110011; // ADD x5, x1, x2
        test_program[0] = test_instruction;
        // Fill rest with NOPs
        for (i = 1; i < 128; i++) begin
            test_program[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        end
        init_instruction_memory(test_program, 128);
        expected_result = 32'h0000000F; // 15
        check_register_result(5, expected_result, test_name);
        
        // 1.2 SUB - rd = rs1 - rs2
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SUB (x6 = x2 - x1 = 10 - 5 = 5)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b01000000000100010000001100110011; // SUB x6, x2, x1
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000005; // 5
        check_register_result(6, expected_result, test_name);
        
        // 1.3 AND - rd = rs1 & rs2
        reset_processor();
        init_register_file(initial_regs);
        test_name = "AND (x7 = x2 & x3 = 0xA & 0xFFFFFFFF = 0xA)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000001100010111001110110011; // AND x7, x2, x3
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h0000000A; // 10 (0xA)
        check_register_result(7, expected_result, test_name);
        
        // 1.4 OR - rd = rs1 | rs2
        reset_processor();
        init_register_file(initial_regs);
        test_name = "OR (x8 = x1 | x2 = 5 | 10 = 15)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000001000001110010000110011; // OR x8, x1, x2
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h0000000F; // 15 (0xF)
        check_register_result(8, expected_result, test_name);
        
        // 1.5 XOR - rd = rs1 ^ rs2
        reset_processor();
        init_register_file(initial_regs);
        test_name = "XOR (x9 = x1 ^ x2 = 5 ^ 10 = 15)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000001000001100010010110011; // XOR x9, x1, x2
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h0000000F; // 15 (0xF)
        check_register_result(9, expected_result, test_name);
        
        // 1.6 SLT - rd = (rs1 < rs2) ? 1 : 0 (signed)
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SLT (x10 = (x1 < x2) ? 1 : 0 = 1)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000001000001010010100110011; // SLT x10, x1, x2
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000001; // 1 (true, x1 < x2)
        check_register_result(10, expected_result, test_name);
        
        // 1.7 SLL - rd = rs1 << rs2
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SLL (x11 = x1 << x4 = 5 << 3 = 40)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000010000001001010110110011; // SLL x11, x1, x4
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000028; // 40 (0x28)
        check_register_result(11, expected_result, test_name);
        
        // 1.8 SRL - rd = rs1 >> rs2 (logical)
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SRL (x12 = x2 >> x4 = 10 >> 3 = 1)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000010000010101011000110011; // SRL x12, x2, x4
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000001; // 1
        check_register_result(12, expected_result, test_name);
        
        // 1.9 SRA - rd = rs1 >> rs2 (arithmetic)
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SRA (x13 = x3 >> x4 = -1 >> 3 = -1)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b01000000010000011101011010110011; // SRA x13, x3, x4
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'hFFFFFFFF; // -1 (sign extended)
        check_register_result(13, expected_result, test_name);
        
        //===================================================================
        // 2. Test I-Type Instructions (ADDI, ANDI, ORI, XORI, SLTI, SLLI, SRLI, SRAI)
        //===================================================================
        
        $display("\n----- Testing I-Type Instructions -----");
        
        // 2.1 ADDI - rd = rs1 + imm
        reset_processor();
        init_register_file(initial_regs);
        test_name = "ADDI (x14 = x1 + 20 = 5 + 20 = 25)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000001010000001000011100010011; // ADDI x14, x1, 20
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000019; // 25 (0x19)
        check_register_result(14, expected_result, test_name);
        
        // 2.2 ANDI - rd = rs1 & imm
        reset_processor();
        init_register_file(initial_regs);
        test_name = "ANDI (x15 = x2 & 7 = 10 & 7 = 2)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000011100010111011110010011; // ANDI x15, x2, 7
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000002; // 2
        check_register_result(15, expected_result, test_name);
        
        // 2.3 ORI - rd = rs1 | imm
        reset_processor();
        init_register_file(initial_regs);
        test_name = "ORI (x16 = x1 | 10 = 5 | 10 = 15)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000101000001110100000010011; // ORI x16, x1, 10
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h0000000F; // 15 (0xF)
        check_register_result(16, expected_result, test_name);
        
        // 2.4 XORI - rd = rs1 ^ imm
        reset_processor();
        init_register_file(initial_regs);
        test_name = "XORI (x17 = x1 ^ 10 = 5 ^ 10 = 15)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000101000001100100010010011; // XORI x17, x1, 10
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h0000000F; // 15 (0xF)
        check_register_result(17, expected_result, test_name);
        
        // 2.5 SLTI - rd = (rs1 < imm) ? 1 : 0
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SLTI (x18 = (x1 < 10) ? 1 : 0 = 1)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000101000001010100100010011; // SLTI x18, x1, 10
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000001; // 1 (true)
        check_register_result(18, expected_result, test_name);
        
        // 2.6 SLLI - rd = rs1 << imm
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SLLI (x19 = x1 << 4 = 5 << 4 = 80)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000010000001001100110010011; // SLLI x19, x1, 4
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000050; // 80 (0x50)
        check_register_result(19, expected_result, test_name);
        
        // 2.7 SRLI - rd = rs1 >> imm (logical)
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SRLI (x20 = x2 >> 2 = 10 >> 2 = 2)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000001000010101101000010011; // SRLI x20, x2, 2
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'h00000002; // 2
        check_register_result(20, expected_result, test_name);
        
        // 2.8 SRAI - rd = rs1 >> imm (arithmetic)
        reset_processor();
        init_register_file(initial_regs);
        test_name = "SRAI (x21 = x3 >> 4 = -1 >> 4 = -1)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b01000000010000011101101010010011; // SRAI x21, x3, 4
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'hFFFFFFFF; // -1 (sign extended)
        check_register_result(21, expected_result, test_name);
        
        //===================================================================
        // 3. Test Load/Store Instructions (LW, SW)
        //===================================================================
        
        $display("\n----- Testing Load/Store Instructions -----");
        
        // 3.1 SW - Store Word: mem[rs1+imm] = rs2
        reset_processor();
        init_register_file(initial_regs);
        init_data_memory(data_mem, 32);
        test_name = "SW (Store x2 to mem[0])";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000000001000000010000000100011; // SW x2, 0(x0)
        test_program[0] = test_instruction;
        // Add NOPs to avoid hazards
        for (i = 1; i < 4; i++) begin
            test_program[i] = 32'h00000013; // NOP
        end
        init_instruction_memory(test_program, 128);
        // Wait for the store to complete
        repeat(5) @(posedge clk);
        expected_result = 32'h0000000A; // 10 (value in x2)
        check_memory_result(0, expected_result, test_name);
        
        // 3.2 LW - Load Word: rd = mem[rs1+imm]
        reset_processor();
        init_register_file(initial_regs);
        init_data_memory(data_mem, 32);
        
        $display("Before test - Value at mem[5]: 0x%8h", dut.dmem.mem[5]);

        test_name = "LW (Load from mem[5] to x22)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b00000001010000000010101100000011; // LW x22, 5*4(x0)
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'hABCDEF01; // Value at data_mem[5]
        check_register_result(22, expected_result, test_name);
        
        //===================================================================
        // 4. Test Branch Instructions (BEQ, BNE, BLT, BGE)
        //===================================================================
        
        $display("\n----- Testing Branch Instructions -----");
        
        // 4.1 BEQ - Branch if equal
        reset_processor();
        init_register_file(initial_regs);
        test_name = "BEQ (Branch Taken)";
        $display("\n=== Testing %s ===", test_name);
        
        // Program to test BEQ:
        // 0: ADDI x23, x0, 5    # x23 = 5
        // 4: ADDI x24, x0, 5    # x24 = 5 (same as x23)
        // 8: BEQ x23, x24, 12   # Branch to PC+12 (offset=3 instructions) if x23 == x24
        // 12: ADDI x25, x0, 10  # x25 = 10 (should not execute)
        // 16: ADDI x25, x0, 20  # x25 = 20 (should not execute) 
        // 20: ADDI x25, x0, 30  # x25 = 30 (should execute after branch)
        
        test_program[0] = 32'b00000000010100000000101110010011; // ADDI x23, x0, 5
        test_program[1] = 32'b00000000010100000000110000010011; // ADDI x24, x0, 5
        test_program[2] = 32'b00000001100010111000001100100011; // BEQ x23, x24, 12
        test_program[3] = 32'b00000000101000000000110010010011; // ADDI x25, x0, 10
        test_program[4] = 32'b00000001010000000000110010010011; // ADDI x25, x0, 20
        test_program[5] = 32'b00000001111000000000110010010011; // ADDI x25, x0, 30
        
        init_instruction_memory(test_program, 128);
        
        repeat(12) @(posedge clk);
        
        expected_result = 32'h0000001E; // 30 (0x1E)
        check_register_result(25, expected_result, test_name);
        
        // 4.2 BNE - Branch if not equal
        reset_processor();
        init_register_file(initial_regs);
        test_name = "BNE (Branch Taken)";
        $display("\n=== Testing %s ===", test_name);
        
        // Program to test BNE:
        // 0: ADDI x23, x0, 5    # x23 = 5
        // 4: ADDI x24, x0, 10   # x24 = 10 (different from x23)
        // 8: BNE x23, x24, 12   # Branch to PC+12 (offset=3 instructions) if x23 != x24
        // 12: ADDI x26, x0, 10  # x26 = 10 (should not execute)
        // 16: ADDI x26, x0, 20  # x26 = 20 (should not execute) 
        // 20: ADDI x26, x0, 40  # x26 = 40 (should execute after branch)
        
        test_program[0] = 32'b00000000010100000000101110010011; // ADDI x23, x0, 5
        test_program[1] = 32'b00000000101000000000110000010011; // ADDI x24, x0, 10
        test_program[2] = 32'b00000001100010111001001100100011; // BNE x23, x24, 12
        test_program[3] = 32'b00000000101000000000110100010011; // ADDI x26, x0, 10
        test_program[4] = 32'b00000001010000000000110100010011; // ADDI x26, x0, 20
        test_program[5] = 32'b00000010100000000000110100010011; // ADDI x26, x0, 40
        
        init_instruction_memory(test_program, 128);
        
        repeat(12) @(posedge clk);
        
        expected_result = 32'h00000028; // 40 (0x28)
        check_register_result(26, expected_result, test_name);

        // 4.3 BLT - Branch if Less Than
        reset_processor();
        init_register_file(initial_regs);
        test_name = "BLT (Branch Taken when rs1 < rs2)";
        $display("\n=== Testing %s ===", test_name);

        // Program to test BLT:
        // 0: ADDI x20, x0, 5     # x20 = 5
        // 4: ADDI x21, x0, 10    # x21 = 10 (greater than x20)
        // 8: BLT x20, x21, 8     # Branch to PC+8 (offset=2 instructions) if x20 < x21
        // 12: ADDI x22, x0, 0    # x22 = 0 (should not execute)
        // 16: ADDI x22, x0, 50   # x22 = 50 (should execute after branch)

        test_program[0] = 32'b00000000010100000000101000010011; // ADDI x20, x0, 5
        test_program[1] = 32'b00000000101000000000101010010011; // ADDI x21, x0, 10
        test_program[2] = 32'b00000001000010100010000001100011; // BLT x20, x21, 8 (offset = 2 instructions)
        test_program[3] = 32'b00000000000000000000101100010011; // ADDI x22, x0, 0
        test_program[4] = 32'b00000011001000000000101100010011; // ADDI x22, x0, 50

        init_instruction_memory(test_program, 128);

        repeat(10) @(posedge clk);

        expected_result = 32'h00000032; // 50 (0x32)
        check_register_result(22, expected_result, test_name);

        // test when branch should NOT be taken
        reset_processor();
        init_register_file(initial_regs);

        for (i = 0; i < 32; i++) begin
            $display("x%0d = 0x%8h", i, dut.rf.r_file[i]);
        end
        $display("========================================\n");

        test_name = "BLT (Branch Not Taken when rs1 >= rs2)";
        $display("\n=== Testing %s ===", test_name);

        // Program to test BLT (not taken):
        // 0: ADDI x20, x0, 15    # x20 = 15
        // 4: ADDI x21, x0, 10    # x21 = 10 (less than x20)
        // 8: BLT x20, x21, 8     # Branch to PC+8 if x20 < x21 (should NOT branch)
        // 12: ADDI x22, x0, 25   # x22 = 25 (should execute)

        test_program[0] = 32'b00000000111100000000101000010011; // ADDI x20, x0, 15
        test_program[1] = 32'b00000000101000000000101010010011; // ADDI x21, x0, 10
        test_program[2] = 32'b00000001000010100010000001100011; // BLT x20, x21, 8 (should NOT branch)
        test_program[3] = 32'b00000001100100000000101100010011; // ADDI x22, x0, 25
        
        // Todo
        //   Need to add this since the init_instruction_memory function did not clean up 
        //   all the inst_mem space, which some instructions from the previous test might 
        //   still be inside the inst_mem. 
        test_program[4] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        test_program[5] = 32'h00000013; // NOP (ADDI x0, x0, 0) 
        

        init_instruction_memory(test_program, 128);

        repeat(8) @(posedge clk);

        expected_result = 32'h00000019; // 25 (0x19)
        check_register_result(22, expected_result, test_name);

        //===================================================================
        // 5. Test U-Type Instructions (LUI)
        //===================================================================

        $display("\n----- Testing U-Type Instructions -----");

        // 5.1 LUI - Load Upper Immediate
        reset_processor();
        init_register_file(initial_regs);
        test_name = "LUI (x27 = 0xABCDE000)";
        $display("\n=== Testing %s ===", test_name);
        test_instruction = 32'b10101011110011011110110110110111; // LUI x27, 0xABCDE
        test_program[0] = test_instruction;
        init_instruction_memory(test_program, 128);
        expected_result = 32'hABCDE000; // Upper 20 bits set, lower 12 bits zero
        check_register_result(27, expected_result, test_name);
                
        //===================================================================
        // Print Test Summary
        //===================================================================
        
        // End simulation
        #100;
        print_test_summary();
        $finish;
    end
    
    // Monitor pipeline stages
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count++;
            $display("\nCycle: %0d", cycle_count);
            $display("Fetch:      PC = 0x%8h, Instr = 0x%8h", dut.PC_F, dut.instruction_F);
            $display("Decode:     PC = 0x%8h, Instr = 0x%8h", dut.PC_D, dut.instruction_D);
            $display("Execute:    PC = 0x%8h, ALUResult = 0x%8h", dut.PC_E, dut.ALUResult_E);
            $display("Memory:     ALUResult = 0x%8h, WriteData = 0x%8h", dut.ALUResult_M, dut.writeData_M);
            $display("Writeback:  Result = 0x%8h, RegWrite = %0d, Rd = %0d", 
                    dut.result_W, dut.regWrite_W, dut.rd_W);
            $display("Immediate Extension: 0x%8h", dut.immExt_D);
            $display("ALUControl: 0x%8h", dut.ALUControl_D);
            $display("ALUSrc: %b", dut.ALUSrc_D);
            $display("Execute Stage - srcA: 0x%8h, srcB: 0x%8h", dut.srcA_E, dut.srcB_E);
            $display("LW Decode Stage - ALUControl: 0x%0h, ALUSrc: %0b", dut.ALUControl_D, dut.ALUSrc_D);
            $display("LW Execute Stage - srcA: 0x%0h, srcB: 0x%0h, ALUControl: 0x%0h", dut.srcA_E, dut.srcB_E, dut.ALUControl_E);

            $display("BLT Debug - x20 value: 0x%8h, x21 value: 0x%8h", dut.rf.r_file[20], dut.rf.r_file[21]);
            $display("BLT Debug - ALUResult: 0x%8h, ALUControl: 0x%8h", dut.ALUResult_E, dut.ALUControl_E);
            $display("BLT Debug - PCSrc_E: %b, branch_E: %b, funct3_E: %b", dut.PCSrc_E, dut.branch_E, dut.funct3_E);
        end
    end
endmodule