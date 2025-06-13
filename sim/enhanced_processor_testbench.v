`timescale 1ns / 1ps

// Enhanced testbench for Vigna RISC-V processor
// Tests various instruction types and verifies correct execution with register monitoring

module enhanced_processor_testbench();

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
    reg [31:0] test_counter;
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
    
    // Task to wait for processor to be ready for next instruction
    task wait_for_instruction_complete;
        begin
            // Wait for instruction fetch to begin
            wait(i_valid == 1);
            wait(i_ready == 1);
            @(posedge clk);
            
            // Wait for instruction execution to complete (when PC changes or same instruction is fetched again)
            repeat(10) @(posedge clk); // Give enough time for instruction to execute
        end
    endtask
    
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
    
    // Test task with register checking
    task check_register_value;
        input [4:0] reg_num;
        input [31:0] expected_value;
        input [255:0] test_description;
        begin
            // Since we can't directly access registers, we'll use store instructions to check values
            // This is a limitation - in a real testbench, you'd use hierarchical references
            $display("  Check: %s (cannot directly verify register x%d)", test_description, reg_num);
        end
    endtask
    
    // Test arithmetic operations
    task test_arithmetic_operations;
        begin
            $display("Setting up arithmetic test...");
            
            // ADDI x1, x0, 10     // x1 = 10
            instruction_memory[0] = make_i_type(12'd10, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // ADDI x2, x0, 5      // x2 = 5  
            instruction_memory[1] = make_i_type(12'd5, 5'd0, 3'b000, 5'd2, 7'b0010011);
            
            // ADD x3, x1, x2      // x3 = x1 + x2 = 15
            instruction_memory[2] = make_r_type(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011);
            
            // SUB x4, x1, x2      // x4 = x1 - x2 = 5
            instruction_memory[3] = make_r_type(7'b0100000, 5'd2, 5'd1, 3'b000, 5'd4, 7'b0110011);
            
            // AND x5, x1, x2      // x5 = x1 & x2
            instruction_memory[4] = make_r_type(7'b0000000, 5'd2, 5'd1, 3'b111, 5'd5, 7'b0110011);
            
            // OR x6, x1, x2       // x6 = x1 | x2
            instruction_memory[5] = make_r_type(7'b0000000, 5'd2, 5'd1, 3'b110, 5'd6, 7'b0110011);
            
            // XOR x7, x1, x2      // x7 = x1 ^ x2
            instruction_memory[6] = make_r_type(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd7, 7'b0110011);
            
            // Store results to memory for verification
            // SW x3, 0(x0)       // Store x3 to address 0
            instruction_memory[7] = make_s_type(12'd0, 5'd3, 5'd0, 3'b010, 7'b0100011);
            
            // SW x4, 4(x0)       // Store x4 to address 4
            instruction_memory[8] = make_s_type(12'd4, 5'd4, 5'd0, 3'b010, 7'b0100011);
            
            // SW x5, 8(x0)       // Store x5 to address 8
            instruction_memory[9] = make_s_type(12'd8, 5'd5, 5'd0, 3'b010, 7'b0100011);
            
            // SW x6, 12(x0)      // Store x6 to address 12
            instruction_memory[10] = make_s_type(12'd12, 5'd6, 5'd0, 3'b010, 7'b0100011);
            
            // SW x7, 16(x0)      // Store x7 to address 16
            instruction_memory[11] = make_s_type(12'd16, 5'd7, 5'd0, 3'b010, 7'b0100011);
            
            // Infinite loop to halt
            instruction_memory[12] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111); // JALR x0, x0, -4
            
            run_test_sequence("Arithmetic Operations", 200);
            
            // Verify results
            if (data_memory[0] == 32'd15) begin
                $display("  PASS: ADD result = %d (expected 15)", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: ADD result = %d (expected 15)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[1] == 32'd5) begin
                $display("  PASS: SUB result = %d (expected 5)", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: SUB result = %d (expected 5)", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[2] == 32'd0) begin // 10 & 5 = 0
                $display("  PASS: AND result = %d (expected 0)", data_memory[2]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: AND result = %d (expected 0)", data_memory[2]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[3] == 32'd15) begin // 10 | 5 = 15
                $display("  PASS: OR result = %d (expected 15)", data_memory[3]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: OR result = %d (expected 15)", data_memory[3]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[4] == 32'd15) begin // 10 ^ 5 = 15
                $display("  PASS: XOR result = %d (expected 15)", data_memory[4]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: XOR result = %d (expected 15)", data_memory[4]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Test immediate operations
    task test_immediate_operations;
        begin
            $display("Setting up immediate operations test...");
            
            // ADDI x1, x0, 100   // x1 = 100
            instruction_memory[0] = make_i_type(12'd100, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // ANDI x2, x1, 15    // x2 = 100 & 15 = 4
            instruction_memory[1] = make_i_type(12'd15, 5'd1, 3'b111, 5'd2, 7'b0010011);
            
            // ORI x3, x1, 15     // x3 = 100 | 15 = 111
            instruction_memory[2] = make_i_type(12'd15, 5'd1, 3'b110, 5'd3, 7'b0010011);
            
            // XORI x4, x1, 15    // x4 = 100 ^ 15 = 107
            instruction_memory[3] = make_i_type(12'd15, 5'd1, 3'b100, 5'd4, 7'b0010011);
            
            // Store results
            instruction_memory[4] = make_s_type(12'd0, 5'd2, 5'd0, 3'b010, 7'b0100011);  // SW x2, 0(x0)
            instruction_memory[5] = make_s_type(12'd4, 5'd3, 5'd0, 3'b010, 7'b0100011);  // SW x3, 4(x0)
            instruction_memory[6] = make_s_type(12'd8, 5'd4, 5'd0, 3'b010, 7'b0100011);  // SW x4, 8(x0)
            
            // Halt
            instruction_memory[7] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            run_test_sequence("Immediate Operations", 150);
            
            // Verify results  
            if (data_memory[0] == 32'd4) begin // 100 & 15 = 4
                $display("  PASS: ANDI result = %d (expected 4)", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: ANDI result = %d (expected 4)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[1] == 32'd111) begin // 100 | 15 = 111
                $display("  PASS: ORI result = %d (expected 111)", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: ORI result = %d (expected 111)", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[2] == 32'd107) begin // 100 ^ 15 = 107
                $display("  PASS: XORI result = %d (expected 107)", data_memory[2]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: XORI result = %d (expected 107)", data_memory[2]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Test load/store operations
    task test_load_store_operations;
        begin
            $display("Setting up load/store test...");
            
            // Initialize data memory with test patterns
            data_memory[100] = 32'h12345678;
            
            // ADDI x1, x0, 400   // x1 = 400 (address 100 * 4)
            instruction_memory[0] = make_i_type(12'd400, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // LW x2, 0(x1)       // Load from memory[100]
            instruction_memory[1] = make_i_type(12'd0, 5'd1, 3'b010, 5'd2, 7'b0000011);
            
            // ADDI x3, x2, 1     // x3 = x2 + 1
            instruction_memory[2] = make_i_type(12'd1, 5'd2, 3'b000, 5'd3, 7'b0010011);
            
            // SW x3, 4(x1)       // Store to memory[101]
            instruction_memory[3] = make_s_type(12'd4, 5'd3, 5'd1, 3'b010, 7'b0100011);
            
            // Store original value to memory[0] for verification
            instruction_memory[4] = make_s_type(12'd0, 5'd2, 5'd0, 3'b010, 7'b0100011);
            
            // Halt
            instruction_memory[5] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            run_test_sequence("Load/Store Operations", 150);
            
            // Verify results
            if (data_memory[0] == 32'h12345678) begin
                $display("  PASS: Load operation retrieved correct value 0x%h", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: Load operation got 0x%h (expected 0x12345678)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[101] == 32'h12345679) begin
                $display("  PASS: Store operation saved correct value 0x%h", data_memory[101]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: Store operation saved 0x%h (expected 0x12345679)", data_memory[101]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Test comparison and set operations
    task test_comparison_operations;
        begin
            $display("Setting up comparison operations test...");
            
            // ADDI x1, x0, 10    // x1 = 10
            instruction_memory[0] = make_i_type(12'd10, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // ADDI x2, x0, 5     // x2 = 5
            instruction_memory[1] = make_i_type(12'd5, 5'd0, 3'b000, 5'd2, 7'b0010011);
            
            // SLT x3, x2, x1     // x3 = (5 < 10) = 1
            instruction_memory[2] = make_r_type(7'b0000000, 5'd1, 5'd2, 3'b010, 5'd3, 7'b0110011);
            
            // SLT x4, x1, x2     // x4 = (10 < 5) = 0
            instruction_memory[3] = make_r_type(7'b0000000, 5'd2, 5'd1, 3'b010, 5'd4, 7'b0110011);
            
            // SLTI x5, x1, 15    // x5 = (10 < 15) = 1
            instruction_memory[4] = make_i_type(12'd15, 5'd1, 3'b010, 5'd5, 7'b0010011);
            
            // Store results
            instruction_memory[5] = make_s_type(12'd0, 5'd3, 5'd0, 3'b010, 7'b0100011);   // SW x3, 0(x0)
            instruction_memory[6] = make_s_type(12'd4, 5'd4, 5'd0, 3'b010, 7'b0100011);   // SW x4, 4(x0)
            instruction_memory[7] = make_s_type(12'd8, 5'd5, 5'd0, 3'b010, 7'b0100011);   // SW x5, 8(x0)
            
            // Halt
            instruction_memory[8] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            run_test_sequence("Comparison Operations", 150);
            
            // Verify results
            if (data_memory[0] == 32'd1) begin
                $display("  PASS: SLT (5 < 10) = %d (expected 1)", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: SLT (5 < 10) = %d (expected 1)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[1] == 32'd0) begin
                $display("  PASS: SLT (10 < 5) = %d (expected 0)", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: SLT (10 < 5) = %d (expected 0)", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[2] == 32'd1) begin
                $display("  PASS: SLTI (10 < 15) = %d (expected 1)", data_memory[2]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: SLTI (10 < 15) = %d (expected 1)", data_memory[2]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $dumpfile("enhanced_processor_test.vcd");
        $dumpvars(0, enhanced_processor_testbench);
        
        // Initialize
        resetn = 0;
        test_pass_count = 0;
        test_fail_count = 0;
        
        // Clear memories
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
            data_memory[i] = 32'h00000000;
        end
        
        // Hold reset for a few cycles
        repeat(10) @(posedge clk);
        resetn = 1;
        
        $display("Starting Enhanced Vigna Processor Tests");
        $display("======================================");
        
        // Test 1: Arithmetic operations
        test_arithmetic_operations();
        
        // Reset and clear memory for next test
        resetn = 0;
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013;
            data_memory[i] = 32'h00000000;
        end
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 2: Immediate operations
        test_immediate_operations();
        
        // Reset and clear memory for next test
        resetn = 0;
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013;
            data_memory[i] = 32'h00000000;
        end
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 3: Load/Store operations
        test_load_store_operations();
        
        // Reset and clear memory for next test
        resetn = 0;
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013;
            data_memory[i] = 32'h00000000;
        end
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 4: Comparison operations
        test_comparison_operations();
        
        $display("\nTest Summary:");
        $display("=============");
        $display("Tests Passed: %d", test_pass_count);
        $display("Tests Failed: %d", test_fail_count);
        $display("Total Tests:  %d", test_pass_count + test_fail_count);
        
        if (test_fail_count == 0) begin
            $display("All tests PASSED!");
        end else begin
            $display("Some tests FAILED!");
        end
        
        $finish;
    end

endmodule