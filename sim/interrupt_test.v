//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: AI Assistant
// 
// Create Date: 2024/12/20
// Design Name: interrupt_test
// Module Name: interrupt_test
// Project Name: vigna
// Description: Test interrupt functionality for Vigna CPU core
// 
// Dependencies: vigna_core.v
// 
// Revision: 
// Revision 1.0 - Basic interrupt testing
// Additional Comments:
// Tests basic interrupt handling, CSR management, and MRET functionality
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`include "vigna_conf.vh"

module interrupt_test;

    // Clock and reset
    reg clk;
    reg resetn;
    
    // Interrupt signals
    reg ext_irq;
    reg timer_irq;
    reg soft_irq;
    
    // Simple memory interface
    wire        i_valid;
    reg         i_ready;
    wire [31:0] i_addr;
    reg  [31:0] i_rdata;
    
    wire        d_valid;
    reg         d_ready;
    wire [31:0] d_addr;
    reg  [31:0] d_rdata;
    wire [31:0] d_wdata;
    wire [3:0]  d_wstrb;
    
    // Memory arrays
    reg [31:0] instruction_memory [1023:0];
    reg [31:0] data_memory [1023:0];
    
    // Test status
    integer test_pass_count;
    integer test_fail_count;
    integer cycle_count;
    
    // Instantiate Vigna core
    vigna vigna_core_inst(
        .clk(clk),
        .resetn(resetn),
        
        .ext_irq(ext_irq),
        .timer_irq(timer_irq),
        .soft_irq(soft_irq),
        
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
    
    // Simple memory interface implementation
    always @(posedge clk) begin
        if (resetn) begin
            if (i_valid && !i_ready) begin
                i_rdata <= instruction_memory[i_addr[11:2]];
                i_ready <= 1;
            end else if (!i_valid) begin
                i_ready <= 0;
            end
            
            if (d_valid && !d_ready) begin
                if (d_wstrb != 0) begin
                    // Write operation
                    data_memory[d_addr[11:2]] <= d_wdata;
                    $display("Write: addr=0x%08x, data=0x%08x", d_addr, d_wdata);
                end else begin
                    // Read operation  
                    d_rdata <= data_memory[d_addr[11:2]];
                end
                d_ready <= 1;
            end else if (!d_valid) begin
                d_ready <= 0;
            end
        end else begin
            i_ready <= 0;
            d_ready <= 0;
        end
    end
    
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
    
    // Task to wait for test completion
    task wait_for_test_complete;
        input integer max_cycles;
        begin
            cycle_count = 0;
            while (cycle_count < max_cycles) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                // Check for halt condition (infinite loop at same address)
                if (cycle_count > 10 && i_addr == instruction_memory[i_addr[11:2]]) begin
                    $display("Test reached halt condition");
                    cycle_count = max_cycles; // Exit loop
                end
            end
            $display("Test completed: (cycles: %10d)", cycle_count);
        end
    endtask
    
    // Test basic interrupt setup and CSR access
    task test_interrupt_csr_setup;
        begin
            $display("Testing interrupt CSR setup...");
            
            // Set up interrupt vector base address (mtvec = 0x100)
            // CSRRW x0, 0x305, x1  where x1 contains 0x100
            instruction_memory[0] = make_i_type(12'd256, 5'd0, 3'b000, 5'd1, 7'b0010011); // ADDI x1, x0, 256
            instruction_memory[1] = {12'h305, 5'd1, 3'b001, 5'd0, 7'b1110011}; // CSRRW x0, mtvec, x1
            
            // Enable global interrupts (set mstatus.MIE = 1)
            instruction_memory[2] = make_i_type(12'd8, 5'd0, 3'b000, 5'd2, 7'b0010011); // ADDI x2, x0, 8 (bit 3)
            instruction_memory[3] = {12'h300, 5'd2, 3'b001, 5'd0, 7'b1110011}; // CSRRW x0, mstatus, x2
            
            // Enable external interrupt (set mie.MEI = 1, bit 11)
            // Use ORI to set bit 11 without sign extension issues
            instruction_memory[4] = {20'h00000, 5'd3, 7'b0110111}; // LUI x3, 0 (clear x3)
            instruction_memory[5] = make_i_type(12'h800, 5'd3, 3'b110, 5'd3, 7'b0010011); // ORI x3, x3, 0x800
            instruction_memory[6] = {12'h304, 5'd3, 3'b001, 5'd0, 7'b1110011}; // CSRRW x0, mie, x3
            
            // Store results for verification
            instruction_memory[7] = {12'h305, 5'd0, 3'b010, 5'd4, 7'b1110011}; // CSRRS x4, mtvec, x0 (read mtvec)
            instruction_memory[8] = make_s_type(12'd0, 5'd4, 5'd0, 3'b010, 7'b0100011); // SW x4, 0(x0)
            
            instruction_memory[9] = {12'h300, 5'd0, 3'b010, 5'd5, 7'b1110011}; // CSRRS x5, mstatus, x0 (read mstatus)
            instruction_memory[10] = make_s_type(12'd4, 5'd5, 5'd0, 3'b010, 7'b0100011); // SW x5, 4(x0)
            
            instruction_memory[11] = {12'h304, 5'd0, 3'b010, 5'd6, 7'b1110011}; // CSRRS x6, mie, x0 (read mie)
            instruction_memory[12] = make_s_type(12'd8, 5'd6, 5'd0, 3'b010, 7'b0100011); // SW x6, 8(x0)
            
            // Halt
            instruction_memory[13] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            wait_for_test_complete(200);
            
            // Verify results
            if (data_memory[0] == 32'd256) begin
                $display("  PASS: mtvec = 0x%08x (expected 0x00000100)", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: mtvec = 0x%08x (expected 0x00000100)", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[1] == 32'd8) begin
                $display("  PASS: mstatus = 0x%08x (expected 0x00000008)", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: mstatus = 0x%08x (expected 0x00000008)", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
            
            if (data_memory[2] == 32'h00000800) begin
                $display("  PASS: mie = 0x%08x (expected 0x00000800)", data_memory[2]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: mie = 0x%08x (expected 0x00000800)", data_memory[2]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Test basic interrupt response
    task test_basic_interrupt_response;
        begin
            $display("Testing basic interrupt response...");
            
            // Clear memory
            for (integer i = 0; i < 1024; i = i + 1) begin
                instruction_memory[i] = 32'h00000013; // NOP
                data_memory[i] = 32'h00000000;
            end
            
            // Setup: Enable interrupts and set trap vector
            instruction_memory[0] = make_i_type(12'd256, 5'd0, 3'b000, 5'd1, 7'b0010011); // ADDI x1, x0, 256 (trap vector)
            instruction_memory[1] = {12'h305, 5'd1, 3'b001, 5'd0, 7'b1110011}; // CSRRW x0, mtvec, x1
            instruction_memory[2] = make_i_type(12'd8, 5'd0, 3'b000, 5'd2, 7'b0010011); // ADDI x2, x0, 8 (MIE bit)
            instruction_memory[3] = {12'h300, 5'd2, 3'b001, 5'd0, 7'b1110011}; // CSRRW x0, mstatus, x2
            instruction_memory[4] = {20'h00000, 5'd3, 7'b0110111}; // LUI x3, 0 (clear x3)
            instruction_memory[5] = make_i_type(12'h800, 5'd3, 3'b110, 5'd3, 7'b0010011); // ORI x3, x3, 0x800
            instruction_memory[6] = {12'h304, 5'd3, 3'b001, 5'd0, 7'b1110011}; // CSRRW x0, mie, x3
            
            // Main loop: wait for interrupt
            instruction_memory[7] = make_i_type(12'd1, 5'd4, 3'b000, 5'd4, 7'b0010011); // ADDI x4, x4, 1 (counter)
            instruction_memory[8] = make_s_type(12'd0, 5'd4, 5'd0, 3'b010, 7'b0100011); // SW x4, 0(x0) (store counter)
            instruction_memory[9] = make_i_type(-12'd8, 5'd0, 3'b000, 5'd0, 7'b1100111); // JAL x0, -8 (loop)
            
            // Interrupt handler at address 256 (0x100)
            instruction_memory[64] = make_i_type(12'd255, 5'd0, 3'b000, 5'd10, 7'b0010011); // ADDI x10, x0, 255 (interrupt marker)
            instruction_memory[65] = make_s_type(12'd4, 5'd10, 5'd0, 3'b010, 7'b0100011); // SW x10, 4(x0) (store marker)
            instruction_memory[66] = {12'h0, 5'b00010, 3'b000, 5'd0, 7'b1110011}; // MRET
            
            wait_for_test_complete(100);
            
            // Trigger external interrupt
            ext_irq = 1;
            
            wait_for_test_complete(200);
            
            // Check if interrupt was handled
            if (data_memory[1] == 32'd255) begin
                $display("  PASS: Interrupt handler executed, marker = 0x%08x", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: Interrupt handler not executed, marker = 0x%08x", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
            
            // Clear interrupt
            ext_irq = 0;
        end
    endtask
    
    // Main test sequence
    initial begin
        $dumpfile("interrupt_test.vcd");
        $dumpvars(0, interrupt_test);
        
        // Initialize
        clk = 0;
        resetn = 0;
        ext_irq = 0;
        timer_irq = 0;
        soft_irq = 0;
        test_pass_count = 0;
        test_fail_count = 0;
        
        // Clear memory
        for (integer i = 0; i < 1024; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP
            data_memory[i] = 32'h00000000;
        end
        
        $display("Starting Vigna Interrupt Tests");
        $display("===============================");
        
        // Start processor
        repeat(10) @(posedge clk);
        resetn = 1;
        
        // Test 1: CSR setup
        test_interrupt_csr_setup();
        
        // Reset for next test
        resetn = 0;
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 2: Basic interrupt response
        test_basic_interrupt_response();
        
        $display("\nInterrupt Test Summary:");
        $display("======================");
        $display("Tests Passed: %d", test_pass_count);
        $display("Tests Failed: %d", test_fail_count);
        
        if (test_fail_count == 0) begin
            $display("All interrupt tests PASSED!");
        end else begin
            $display("Some interrupt tests FAILED!");
        end
        
        $finish;
    end

endmodule