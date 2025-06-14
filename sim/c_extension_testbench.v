`timescale 1ns / 1ps

// Enable C extension for this test
`define VIGNA_CORE_C_EXTENSION
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

    // Memory read logic
    always @(*) begin
        if (i_valid) begin
            i_rdata = instruction_memory[i_addr[31:2]];
        end else begin
            i_rdata = 32'h00000000;
        end
    end

    always @(*) begin
        if (d_valid && !d_wstrb) begin
            d_rdata = data_memory[d_addr[31:2]];
        end else begin
            d_rdata = 32'h00000000;
        end
    end

    // Memory write logic
    always @(posedge clk) begin
        if (d_valid && d_wstrb && d_ready) begin
            data_memory[d_addr[31:2]] <= d_wdata;
        end
    end

    // Control ready signals
    always @(posedge clk) begin
        if (!resetn) begin
            i_ready <= 0;
            d_ready <= 0;
        end else begin
            if (i_valid && !i_ready) begin
                i_ready <= 1;
            end else if (!i_valid) begin
                i_ready <= 0;
            end
            
            if (d_valid && !d_ready) begin
                d_ready <= 1;
            end else if (!d_valid) begin
                d_ready <= 0;
            end
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

    // Test basic C instructions
    task test_c_basic;
        begin
            $display("Setting up basic C extension test...");
            
            // Put each 16-bit C instruction in lower half of 32-bit word
            // Test C.LI x1, 10 (load immediate 10 into x1)
            instruction_memory[0] = {16'h0000, make_c_li(5'd1, 6'd10)};
            
            // Test C.ADDI x1, 5 (add immediate 5 to x1) 
            instruction_memory[1] = {16'h0000, make_c_addi(5'd1, 6'd5)};
            
            // Test C.LI x2, 3 (load immediate 3 into x2)
            instruction_memory[2] = {16'h0000, make_c_li(5'd2, 6'd3)};
            
            // Test C.ADD x1, x2 (add x2 to x1)
            instruction_memory[3] = {16'h0000, make_c_add(5'd1, 5'd2)};
            
            // Store result - regular 32-bit SW instruction
            instruction_memory[4] = {12'd0, 5'd1, 3'b010, 5'd0, 7'b0100011}; // SW x1, 0(x0)
            
            // Infinite loop to halt - regular 32-bit JALR
            instruction_memory[5] = {-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111}; // JALR x0, x0, -4

            $display("Debug: C.LI x1, 10 = 0x%04x", make_c_li(5'd1, 6'd10));
            $display("Debug: C.ADDI x1, 5 = 0x%04x", make_c_addi(5'd1, 6'd5));
            $display("Debug: C.LI x2, 3 = 0x%04x", make_c_li(5'd2, 6'd3));
            $display("Debug: C.ADD x1, x2 = 0x%04x", make_c_add(5'd1, 5'd2));
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
        if (data_memory[0] == 32'd18) begin
            $display("  PASS: C instruction sequence result = %d (expected 18)", data_memory[0]);
            test_pass_count = test_pass_count + 1;
        end else begin
            $display("  FAIL: C instruction sequence result = %d (expected 18)", data_memory[0]);
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