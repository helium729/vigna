`timescale 1ns / 1ps

// Enable C extension for this test
//`define VIGNA_CORE_C_EXTENSION
`include "vigna_conf.vh"

module c_extension_testbench;

    // Clock and reset
    reg clk;
    reg resetn;

    // Instruction memory interface
    wire i_valid;
    reg i_ready;
    wire [31:0] i_addr;
    reg [31:0] i_rdata;

    // Data memory interface  
    wire d_valid;
    reg d_ready;
    wire [31:0] d_addr;
    reg [31:0] d_rdata;
    wire [31:0] d_wdata;
    wire [3:0] d_wstrb;

    // Instruction and data memory
    reg [31:0] instruction_memory [0:1023];
    reg [31:0] data_memory [0:1023];

    // Test counters
    integer test_pass_count = 0;
    integer test_fail_count = 0;

    // Instantiate the processor
    vigna uut (
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
    always #5 clk = ~clk;

    // Memory read logic - instruction fetch
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
                    data_memory[d_addr[11:2]] <= d_wdata;
                    $display("Memory Write: addr=0x%08x, data=0x%08x, strb=0x%x", d_addr, d_wdata, d_wstrb);
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

    // Helper function to create C.ADDI instruction (16-bit)
    function [15:0] make_c_addi;
        input [4:0] rd;
        input [5:0] imm;
        begin
            make_c_addi = {3'b000, imm[5], rd, imm[4:0], 2'b01};
        end
    endfunction

    // Helper function to create C.LI instruction (16-bit)
    function [15:0] make_c_li;
        input [4:0] rd;
        input [5:0] imm;
        begin
            make_c_li = {3'b010, imm[5], rd, imm[4:0], 2'b01};
        end
    endfunction

    // Helper function to create C.ADD instruction (16-bit)
    function [15:0] make_c_add;
        input [4:0] rd;
        input [4:0] rs2;
        begin
            make_c_add = {3'b100, 1'b1, rd, rs2, 2'b10};
        end
    endfunction

    // Helper function to create 32-bit word from two 16-bit C instructions
    function [31:0] make_c_word;
        input [15:0] c_inst1;
        input [15:0] c_inst2;
        begin
            make_c_word = {c_inst2, c_inst1};
        end
    endfunction

    // Task to run a test sequence
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

    // Test basic C extension instructions
    task test_c_basic;
        begin
            $display("Setting up C extension test...");
            
            // Pack two C instructions: C.LI x1, 42 (lower) + C.ADDI x1, 0 (upper, NOP)
            // Pack two C instructions: C.LI x1, 42 (lower) + C.ADDI x1, 0 (upper, NOP)
            instruction_memory[0] = {C_ADDI_X1_NOP, C_LI_X1_42};
            
            // Store result - SW x1, 0(x0) (regular 32-bit instruction at next word)
            instruction_memory[1] = {12'd0, 5'd1, 3'b010, 5'd0, 7'b0100011};
            
            // Infinite loop to halt
            instruction_memory[2] = {-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111};
        end
    endtask

    // Main test sequence
    initial begin
        $dumpfile("c_extension_test.vcd");
        $dumpvars(0, c_extension_testbench);
        
        $display("Starting C Extension Test");
        $display("=======================");
        
        // Initialize
        clk = 0;
        resetn = 0;
        i_ready = 0;
        d_ready = 0;
        
        // Clear memories
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP
            data_memory[i] = 32'h00000000;
        end
        
        // Start test
        repeat(10) @(posedge clk);
        resetn = 1;
        test_c_basic();
        run_test_sequence("C Extension Basic Test", 200);
        
        // Verify results
        if (data_memory[0] == 32'd42) begin
            $display("  PASS: Simple test result = %d (expected 42)", data_memory[0]);
            test_pass_count = test_pass_count + 1;
        end else begin
            $display("  FAIL: Simple test result = %d (expected 42)", data_memory[0]);
            test_fail_count = test_fail_count + 1;
        end
        
        // Test summary
        $display("C Extension Test Summary:");
        $display("========================");
        $display("Tests Passed: %d", test_pass_count);
        $display("Tests Failed: %d", test_fail_count);
        
        if (test_fail_count == 0) begin
            $display("All C extension tests PASSED!");
        end else begin
            $display("Some tests FAILED!");
        end
        
        $finish;
    end

endmodule