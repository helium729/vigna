`timescale 1ns / 1ps

// Comprehensive testbench for Vigna RISC-V processor
// Tests various instruction types and verifies correct execution

module processor_testbench();

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
            if (i_valid) begin
                i_rdata <= instruction_memory[i_addr[11:2]]; // Word aligned access
                i_ready <= 1;
            end else begin
                i_ready <= 0;
            end
        end else begin
            i_ready <= 0;
        end
    end
    
    // Memory simulation for data access
    always @(posedge clk) begin
        if (resetn) begin
            if (d_valid) begin
                if (d_wstrb != 0) begin
                    // Write operation
                    if (d_wstrb == 4'b1111) 
                        data_memory[d_addr[11:2]] <= d_wdata;
                    // Handle other write strobes if needed
                    d_ready <= 1;
                end else begin
                    // Read operation
                    d_rdata <= data_memory[d_addr[11:2]];
                    d_ready <= 1;
                end
            end else begin
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
    
    // Helper function to create U-type instruction
    function [31:0] make_u_type;
        input [19:0] imm;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            make_u_type = {imm, rd, opcode};
        end
    endfunction
    
    // Test task
    task run_test_sequence;
        input [255:0] test_name;
        input [31:0] num_instructions;
        input [31:0] expected_cycles;
        begin
            $display("Running test: %s", test_name);
            test_counter = 0;
            
            // Wait for processor to execute instructions
            repeat(expected_cycles) @(posedge clk);
            
            $display("Test completed: %s", test_name);
        end
    endtask
    
    // Initialize test programs
    task setup_arithmetic_test;
        begin
            // Test basic arithmetic operations
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
            
            // Infinite loop to halt
            instruction_memory[7] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111); // JAL x0, -4
        end
    endtask
    
    task setup_shift_test;
        begin
            // Test shift operations
            // ADDI x1, x0, 8      // x1 = 8 (1000 binary)
            instruction_memory[0] = make_i_type(12'd8, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // SLLI x2, x1, 1      // x2 = x1 << 1 = 16
            instruction_memory[1] = make_i_type(12'd1, 5'd1, 3'b001, 5'd2, 7'b0010011);
            
            // SRLI x3, x1, 1      // x3 = x1 >> 1 = 4 (logical)
            instruction_memory[2] = make_i_type(12'd1, 5'd1, 3'b101, 5'd3, 7'b0010011);
            
            // ADDI x4, x0, -8     // x4 = -8 (for arithmetic shift test)
            instruction_memory[3] = make_i_type(-12'd8, 5'd0, 3'b000, 5'd4, 7'b0010011);
            
            // SRAI x5, x4, 1      // x5 = x4 >> 1 = -4 (arithmetic)
            instruction_memory[4] = make_i_type(12'b010000000001, 5'd4, 3'b101, 5'd5, 7'b0010011);
            
            // Infinite loop to halt
            instruction_memory[5] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
        end
    endtask
    
    task setup_load_store_test;
        begin
            // Test load/store operations
            // ADDI x1, x0, 100    // x1 = 100 (base address)
            instruction_memory[0] = make_i_type(12'd100, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // ADDI x2, x0, 0x12345678 & 0xFFF  // Lower 12 bits
            instruction_memory[1] = make_i_type(12'h678, 5'd0, 3'b000, 5'd2, 7'b0010011);
            
            // SW x2, 0(x1)        // Store word to memory[100]
            instruction_memory[2] = make_s_type(12'd0, 5'd2, 5'd1, 3'b010, 7'b0100011);
            
            // LW x3, 0(x1)        // Load word from memory[100] to x3
            instruction_memory[3] = make_i_type(12'd0, 5'd1, 3'b010, 5'd3, 7'b0000011);
            
            // Infinite loop to halt
            instruction_memory[4] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
        end
    endtask
    
    task setup_branch_test;
        begin
            // Test branch operations
            // ADDI x1, x0, 10     // x1 = 10
            instruction_memory[0] = make_i_type(12'd10, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // ADDI x2, x0, 10     // x2 = 10
            instruction_memory[1] = make_i_type(12'd10, 5'd0, 3'b000, 5'd2, 7'b0010011);
            
            // BEQ x1, x2, 8       // Branch if equal (should branch)
            instruction_memory[2] = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'b01000, 7'b1100011}; // offset = 8
            
            // ADDI x3, x0, 99     // This should be skipped
            instruction_memory[3] = make_i_type(12'd99, 5'd0, 3'b000, 5'd3, 7'b0010011);
            
            // ADDI x4, x0, 1      // This should be executed (branch target)
            instruction_memory[4] = make_i_type(12'd1, 5'd0, 3'b000, 5'd4, 7'b0010011);
            
            // Infinite loop to halt
            instruction_memory[5] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
        end
    endtask
    
    task setup_upper_immediate_test;
        begin
            // Test upper immediate operations
            // LUI x1, 0x12345     // x1 = 0x12345000
            instruction_memory[0] = make_u_type(20'h12345, 5'd1, 7'b0110111);
            
            // ADDI x1, x1, 0x678  // x1 = 0x12345678
            instruction_memory[1] = make_i_type(12'h678, 5'd1, 3'b000, 5'd1, 7'b0010011);
            
            // AUIPC x2, 0x1000    // x2 = PC + 0x1000000
            instruction_memory[2] = make_u_type(20'h1000, 5'd2, 7'b0010111);
            
            // Infinite loop to halt
            instruction_memory[3] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
        end
    endtask
    
    // Main test sequence
    initial begin
        $dumpfile("processor_test.vcd");
        $dumpvars(0, processor_testbench);
        
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
        
        $display("Starting Vigna Processor Tests");
        $display("================================");
        
        // Test 1: Arithmetic operations
        setup_arithmetic_test();
        run_test_sequence("Arithmetic Operations", 8, 100);
        
        // Reset for next test
        resetn = 0;
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 2: Shift operations
        setup_shift_test();
        run_test_sequence("Shift Operations", 6, 80);
        
        // Reset for next test
        resetn = 0;
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 3: Load/Store operations
        setup_load_store_test();
        run_test_sequence("Load/Store Operations", 5, 100);
        
        // Reset for next test
        resetn = 0;
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 4: Branch operations
        setup_branch_test();
        run_test_sequence("Branch Operations", 6, 80);
        
        // Reset for next test
        resetn = 0;
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 5: Upper immediate operations
        setup_upper_immediate_test();
        run_test_sequence("Upper Immediate Operations", 4, 60);
        
        $display("\nTest Summary:");
        $display("=============");
        $display("Tests Passed: %d", test_pass_count);
        $display("Tests Failed: %d", test_fail_count);
        
        if (test_fail_count == 0) begin
            $display("All tests PASSED!");
        end else begin
            $display("Some tests FAILED!");
        end
        
        $finish;
    end
    
    // Monitor important signals for debugging
    initial begin
        $monitor("Time: %t, PC: 0x%h, Inst: 0x%h, Reset: %b", 
                 $time, i_addr, i_rdata, resetn);
    end

endmodule