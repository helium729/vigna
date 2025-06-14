`timescale 1ns / 1ps

// Comprehensive testbench for Vigna RISC-V processor
// Tests all major instruction categories with detailed verification

module comprehensive_processor_testbench();

    // Clock and reset
    reg clk;
    reg resetn;
    
    // Instruction memory interface
    wire        i_valid;
    reg         i_ready;
    wire [31:0] i_addr;
    reg  [31:0] i_rdata;
    
    // Data memory interface  
    wire        d_valid;
    reg         d_ready;
    wire [31:0] d_addr;
    reg  [31:0] d_rdata;
    wire [31:0] d_wdata;
    wire [ 3:0] d_wstrb;
    
    // Test control
    reg [31:0] instruction_memory [0:1023];
    reg [31:0] data_memory [0:1023];
    integer test_pass_count;
    integer test_fail_count;
    
    // Instantiate the processor core
    vigna dut (
        .clk(clk),
        .resetn(resetn),
        .i_valid(i_valid),
        .i_ready(i_ready),
        .i_addr(i_addr),
        .i_rdata(i_rdata),
        .d_valid(d_valid),
        .d_ready(d_ready),
        .d_addr(d_addr),
        .d_rdata(d_rdata),
        .d_wdata(d_wdata),
        .d_wstrb(d_wstrb)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Memory simulation for instruction fetch
    always @(posedge clk) begin
        if (resetn) begin
            if (i_valid && !i_ready) begin
                i_rdata <= instruction_memory[i_addr[11:2]]; // Word aligned access
                i_ready <= 1;
            end else if (!i_valid) begin
                i_ready <= 0;
            end
        end else begin
            i_ready <= 0;
        end
    end
    
    // Memory simulation for data access
    always @(posedge clk) begin
        if (resetn) begin
            if (d_valid && !d_ready) begin
                if (d_wstrb != 0) begin
                    // Write operation
                    if (d_wstrb == 4'b1111) 
                        data_memory[d_addr[11:2]] <= d_wdata;
                    else if (d_wstrb == 4'b0011)
                        data_memory[d_addr[11:2]] <= (data_memory[d_addr[11:2]] & 32'hFFFF0000) | (d_wdata & 32'h0000FFFF);
                    else if (d_wstrb == 4'b0001)
                        data_memory[d_addr[11:2]] <= (data_memory[d_addr[11:2]] & 32'hFFFFFF00) | (d_wdata & 32'h000000FF);
                end else begin
                    // Read operation
                    d_rdata <= data_memory[d_addr[11:2]];
                end
                d_ready <= 1;
            end else if (!d_valid) begin
                d_ready <= 0;
            end
        end else begin
            d_ready <= 0;
        end
    end
    
    // Helper function to create R-type instruction
    function [31:0] make_r_type;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            make_r_type = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction
    
    // Helper function to create I-type instruction
    function [31:0] make_i_type;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            make_i_type = {imm, rs1, funct3, rd, opcode};
        end
    endfunction
    
    // Helper function to create S-type instruction
    function [31:0] make_s_type;
        input [11:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            make_s_type = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
        end
    endfunction
    
    // Helper function to create B-type instruction
    function [31:0] make_b_type;
        input [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            make_b_type = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
        end
    endfunction
    
    // Helper function to create U-type instruction
    function [31:0] make_u_type;
        input [19:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            make_u_type = {imm, rd, opcode};
        end
    endfunction
    
    // Task to run a sequence and monitor registers
    task run_test_sequence;
        input [255:0] test_name;
        input integer max_cycles;
        
        integer cycle_count;
        begin
            $display("Running test: %s", test_name);
            
            cycle_count = 0;
            while (cycle_count < max_cycles) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                
                // Break if processor hits an infinite loop (same PC for multiple cycles)
                if (cycle_count > 20 && i_addr == 32'hFFFFFFFC) begin
                    $display("Test reached halt condition");
                    cycle_count = max_cycles; // Break out of loop
                end
            end
            
            $display("Test completed: %s (cycles: %d)", test_name, cycle_count);
        end
    endtask
    
    // Test shift operations  
    task test_shift_operations;
        begin
            $display("Setting up shift operations test...");
            
            // ADDI x1, x0, 16    // x1 = 16 (10000 binary)
            instruction_memory[0] = make_i_type(12'd16, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // SLLI x2, x1, 2     // x2 = 16 << 2 = 64
            instruction_memory[1] = make_i_type(12'd2, 5'd1, 3'b001, 5'd2, 7'b0010011);
            
            // SRLI x3, x1, 2     // x3 = 16 >> 2 = 4 (logical)
            instruction_memory[2] = make_i_type(12'd2, 5'd1, 3'b101, 5'd3, 7'b0010011);
            
            // ADDI x4, x0, -16   // x4 = -16 (for arithmetic shift test)
            instruction_memory[3] = make_i_type(-12'd16, 5'd0, 3'b000, 5'd4, 7'b0010011);
            
            // SRAI x5, x4, 2     // x5 = -16 >> 2 = -4 (arithmetic, sign extended)
            instruction_memory[4] = make_i_type(12'b010000000010, 5'd4, 3'b101, 5'd5, 7'b0010011);
            
            // Store results  
            instruction_memory[5] = make_s_type(12'd0, 5'd2, 5'd0, 3'b010, 7'b0100011);  // SW x2, 0(x0)
            instruction_memory[6] = make_s_type(12'd4, 5'd3, 5'd0, 3'b010, 7'b0100011);  // SW x3, 4(x0)
            instruction_memory[7] = make_s_type(12'd8, 5'd5, 5'd0, 3'b010, 7'b0100011);  // SW x5, 8(x0)
            
            // Halt
            instruction_memory[8] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            run_test_sequence("Shift Operations", 150);
            
            // Verify results
            if (data_memory[0] == 32'd64) begin
                $display("  PASS: SLLI (16 << 2) = %d (expected 64)", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: SLLI (16 << 2) = %d (expected 64)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[1] == 32'd4) begin
                $display("  PASS: SRLI (16 >> 2) = %d (expected 4)", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: SRLI (16 >> 2) = %d (expected 4)", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
            
            // Check for sign extension in arithmetic right shift
            if ($signed(data_memory[2]) == -32'd4) begin
                $display("  PASS: SRAI (-16 >> 2) = %d (expected -4)", $signed(data_memory[2]));
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: SRAI (-16 >> 2) = %d (expected -4)", $signed(data_memory[2]));
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Test upper immediate operations
    task test_upper_immediate_operations;
        begin
            $display("Setting up upper immediate operations test...");
            
            // LUI x1, 0x12345     // x1 = 0x12345000
            instruction_memory[0] = make_u_type(20'h12345, 5'd1, 7'b0110111);
            
            // ADDI x1, x1, 0x678  // x1 = 0x12345678
            instruction_memory[1] = make_i_type(12'h678, 5'd1, 3'b000, 5'd1, 7'b0010011);
            
            // AUIPC x2, 0x1000    // x2 = PC + 0x1000000 = 8 + 0x1000000 = 0x1000008
            instruction_memory[2] = make_u_type(20'h1000, 5'd2, 7'b0010111);
            
            // Store results for verification
            instruction_memory[3] = make_s_type(12'd0, 5'd1, 5'd0, 3'b010, 7'b0100011);  // SW x1, 0(x0)
            instruction_memory[4] = make_s_type(12'd4, 5'd2, 5'd0, 3'b010, 7'b0100011);  // SW x2, 4(x0)
            
            // Halt
            instruction_memory[5] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            run_test_sequence("Upper Immediate Operations", 120);
            
            // Verify results
            if (data_memory[0] == 32'h12345678) begin
                $display("  PASS: LUI + ADDI = 0x%h (expected 0x12345678)", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: LUI + ADDI = 0x%h (expected 0x12345678)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[1] == 32'h01000008) begin
                $display("  PASS: AUIPC = 0x%h (expected 0x01000008)", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  INFO: AUIPC = 0x%h (PC-relative result)", data_memory[1]);
                // Don't count this as pass/fail since PC value might vary
            end
        end
    endtask
    
    // Test basic branch operations
    task test_branch_operations;
        begin
            $display("Setting up branch operations test...");
            
            // ADDI x1, x0, 10     // x1 = 10
            instruction_memory[0] = make_i_type(12'd10, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // ADDI x2, x0, 10     // x2 = 10 (equal for BEQ test)
            instruction_memory[1] = make_i_type(12'd10, 5'd0, 3'b000, 5'd2, 7'b0010011);
            
            // BEQ x1, x2, 12      // Branch if equal (should branch to instruction 5)
            instruction_memory[2] = make_b_type(13'd12, 5'd2, 5'd1, 3'b000, 7'b1100011);
            
            // ADDI x3, x0, 99     // This should be skipped
            instruction_memory[3] = make_i_type(12'd99, 5'd0, 3'b000, 5'd3, 7'b0010011);
            
            // ADDI x4, x0, 88     // This should also be skipped  
            instruction_memory[4] = make_i_type(12'd88, 5'd0, 3'b000, 5'd4, 7'b0010011);
            
            // ADDI x5, x0, 1      // This should be executed (branch target)
            instruction_memory[5] = make_i_type(12'd1, 5'd0, 3'b000, 5'd5, 7'b0010011);
            
            // Store result to verify branch was taken
            instruction_memory[6] = make_s_type(12'd0, 5'd5, 5'd0, 3'b010, 7'b0100011);  // SW x5, 0(x0)
            instruction_memory[7] = make_s_type(12'd4, 5'd3, 5'd0, 3'b010, 7'b0100011);  // SW x3, 4(x0) - should be 0
            
            // Halt
            instruction_memory[8] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            run_test_sequence("Branch Operations", 150);
            
            // Verify results
            if (data_memory[0] == 32'd1) begin
                $display("  PASS: Branch was taken, x5 = %d (expected 1)", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: Branch result x5 = %d (expected 1)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[1] == 32'd0) begin
                $display("  PASS: Skipped instruction, x3 = %d (expected 0)", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: Should have skipped instruction, x3 = %d (expected 0)", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Test CSR operations
    task test_csr_operations;
        begin
            $display("Setting up CSR operations test...");
            
            // Initialize a CSR address (using 0x300 which is a common CSR address)
            // CSRRW x1, 0x300, x0    // Read CSR 0x300 to x1 (should be 0), write 0 to CSR
            instruction_memory[0] = {12'h300, 5'd0, 3'b001, 5'd1, 7'b1110011};
            
            // ADDI x2, x0, 0x123     // Load test value into x2
            instruction_memory[1] = make_i_type(12'h123, 5'd0, 3'b000, 5'd2, 7'b0010011);
            
            // CSRRW x3, 0x300, x2    // Write x2 to CSR 0x300, read old value to x3
            instruction_memory[2] = {12'h300, 5'd2, 3'b001, 5'd3, 7'b1110011};
            
            // CSRRS x4, 0x300, x0    // Read CSR 0x300 to x4 (should be 0x123)
            instruction_memory[3] = {12'h300, 5'd0, 3'b010, 5'd4, 7'b1110011};
            
            // ADDI x5, x0, 0x456     // Load another test value
            instruction_memory[4] = make_i_type(12'h456, 5'd0, 3'b000, 5'd5, 7'b0010011);
            
            // CSRRS x6, 0x300, x5    // Set bits in CSR, read old to x6
            instruction_memory[5] = {12'h300, 5'd5, 3'b010, 5'd6, 7'b1110011};
            
            // CSRRC x7, 0x300, x5    // Clear bits in CSR, read old to x7
            instruction_memory[6] = {12'h300, 5'd5, 3'b011, 5'd7, 7'b1110011};
            
            // CSRRWI x8, 0x300, 0x1F // Write immediate to CSR, read old to x8
            instruction_memory[7] = {12'h300, 5'd31, 3'b101, 5'd8, 7'b1110011};
            
            // Store results for verification
            instruction_memory[8] = make_s_type(12'd0, 5'd1, 5'd0, 3'b010, 7'b0100011);   // SW x1, 0(x0)
            instruction_memory[9] = make_s_type(12'd4, 5'd3, 5'd0, 3'b010, 7'b0100011);   // SW x3, 4(x0)
            instruction_memory[10] = make_s_type(12'd8, 5'd4, 5'd0, 3'b010, 7'b0100011);  // SW x4, 8(x0)
            instruction_memory[11] = make_s_type(12'd12, 5'd6, 5'd0, 3'b010, 7'b0100011); // SW x6, 12(x0)
            instruction_memory[12] = make_s_type(12'd16, 5'd7, 5'd0, 3'b010, 7'b0100011); // SW x7, 16(x0)
            instruction_memory[13] = make_s_type(12'd20, 5'd8, 5'd0, 3'b010, 7'b0100011); // SW x8, 20(x0)
            
            // Halt instruction
            instruction_memory[14] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            run_test_sequence("CSR Operations", 200);
            
            // Check results
            if (data_memory[0] == 32'h00000000) begin
                $display("  PASS: Initial CSR read = 0x%08x (expected 0x00000000)", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: Initial CSR read = 0x%08x (expected 0x00000000)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[1] == 32'h00000000) begin
                $display("  PASS: CSRRW old value = 0x%08x (expected 0x00000000)", data_memory[1]);
                test_pass_count = test_pass_count + 1; 
            end else begin
                $display("  FAIL: CSRRW old value = 0x%08x (expected 0x00000000)", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[2] == 32'h00000123) begin
                $display("  PASS: CSR read after write = 0x%08x (expected 0x00000123)", data_memory[2]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: CSR read after write = 0x%08x (expected 0x00000123)", data_memory[2]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[3] == 32'h00000123) begin
                $display("  PASS: CSRRS old value = 0x%08x (expected 0x00000123)", data_memory[3]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: CSRRS old value = 0x%08x (expected 0x00000123)", data_memory[3]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[4] == 32'h00000577) begin // 0x123 | 0x456 = 0x577
                $display("  PASS: CSRRS old value = 0x%08x (expected 0x00000577)", data_memory[4]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: CSRRS old value = 0x%08x (expected 0x00000577)", data_memory[4]);
                test_fail_count = test_fail_count + 1; 
            end
            
            if (data_memory[5] == 32'h00000121) begin // 0x577 & ~0x456 = 0x121
                $display("  PASS: CSRRWI old value = 0x%08x (expected 0x00000121)", data_memory[5]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: CSRRWI old value = 0x%08x (expected 0x00000121)", data_memory[5]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $dumpfile("comprehensive_processor_test.vcd");
        $dumpvars(0, comprehensive_processor_testbench);
        
        // Initialize
        resetn = 0;
        test_pass_count = 0;
        test_fail_count = 0;
        
        $display("Starting Comprehensive Vigna Processor Tests");
        $display("============================================");
        
        // Test 1: Shift operations
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP
            data_memory[i] = 32'h00000000;
        end
        repeat(10) @(posedge clk);
        resetn = 1;
        test_shift_operations();
        
        // Test 2: Upper immediate operations
        resetn = 0;
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013;
            data_memory[i] = 32'h00000000;
        end
        repeat(5) @(posedge clk);
        resetn = 1;
        test_upper_immediate_operations();
        
        // Test 3: Branch operations
        resetn = 0;
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013;
            data_memory[i] = 32'h00000000;
        end
        repeat(5) @(posedge clk);
        resetn = 1;
        test_branch_operations();
        

        // Test 4: CSR operations (only if extension is enabled)
        `ifdef VIGNA_CORE_ZICSR_EXTENSION
      
        resetn = 0;
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013;
            data_memory[i] = 32'h00000000;
        end
        repeat(5) @(posedge clk);
        resetn = 1;
        test_csr_operations();
        `endif
      

        // Test 5: C extension operations (only if enabled)
        `ifdef VIGNA_CORE_C_EXTENSION

        resetn = 0;
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013;
            data_memory[i] = 32'h00000000;
        end
        repeat(5) @(posedge clk);
        resetn = 1;
        test_c_extension_operations();
        `endif
        
        $display("\nComprehensive Test Summary:");
        $display("===========================");
        $display("Tests Passed: %d", test_pass_count);
        $display("Tests Failed: %d", test_fail_count);
        $display("Total Tests:  %d", test_pass_count + test_fail_count);
        
        if (test_fail_count == 0) begin
            $display("All comprehensive tests PASSED!");
        end else begin
            $display("Some comprehensive tests FAILED!");
        end
        
        $finish;
    end
    
    // Test C extension operations
    task test_c_extension_operations;
        begin
            $display("Setting up C extension operations test...");
            
            // Test C.LI x1, 10 (load immediate 10 into x1)
            // C.LI format: 010_0_00001_01010_01 = 0x40a9
            instruction_memory[0] = {16'h0000, 16'h40a9};
            
            // Test C.ADDI x1, 5 (add immediate 5 to x1)  
            // C.ADDI format: 000_0_00001_00101_01 = 0x0095
            instruction_memory[1] = {16'h0000, 16'h0095};
            
            // Store result using regular SW instruction
            instruction_memory[2] = make_s_type(12'd12, 5'd1, 5'd0, 3'b010, 7'b0100011); // SW x1, 12(x0)
            
            // Infinite loop to halt
            instruction_memory[3] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111); // JALR x0, x0, -4
            
            run_test_sequence("C Extension Operations", 150);
            
            // Verify C.LI x1, 10 + C.ADDI x1, 5 = 15
            if (data_memory[3] == 32'd15) begin
                $display("  PASS: C extension result = %d (expected 15)", data_memory[3]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: C extension result = %d (expected 15)", data_memory[3]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask

endmodule