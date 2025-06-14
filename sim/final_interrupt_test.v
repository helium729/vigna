`timescale 1ns / 1ps
`include "vigna_conf.vh"

module final_interrupt_test;

    reg clk;
    reg resetn;
    
    reg ext_irq;
    reg timer_irq;
    reg soft_irq;
    
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
    
    reg [31:0] instruction_memory [63:0];
    reg [31:0] data_memory [63:0];
    
    integer test_pass_count;
    integer test_fail_count;
    
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
    
    always #5 clk = ~clk;
    
    always @(posedge clk) begin
        if (resetn) begin
            if (i_valid && !i_ready) begin
                i_rdata <= instruction_memory[i_addr[7:2]];
                i_ready <= 1;
            end else if (!i_valid) begin
                i_ready <= 0;
            end
            
            if (d_valid && !d_ready) begin
                if (d_wstrb != 0) begin
                    data_memory[d_addr[7:2]] <= d_wdata;
                    $display("Write: addr=0x%08x, data=0x%08x", d_addr, d_wdata);
                end else begin
                    d_rdata <= data_memory[d_addr[7:2]];
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
    
    // Test interrupt functionality
    task test_software_interrupt;
        begin
            $display("Testing software interrupt...");
            
            // Set up interrupt enable (MSI = bit 3)
            instruction_memory[0] = {12'h304, 5'd8, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mie, 8 (enable software interrupt)
            
            // Enable global interrupts (MIE = bit 3 in mstatus)
            instruction_memory[1] = {12'h300, 5'd8, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mstatus, 8 (enable global interrupts)
            
            // Set trap vector to address 20 
            instruction_memory[2] = {12'h305, 5'd20, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mtvec, 20
            
            // Main loop
            instruction_memory[3] = 32'h00000013; // NOP (PC=12)
            instruction_memory[4] = 32'hffdff06f; // JAL x0, -4 (infinite loop - jump back to PC=12)
            
            // Interrupt handler at PC=20 (instruction_memory[5])
            instruction_memory[5] = {12'd99, 5'd0, 3'b000, 5'd10, 7'b0010011}; // ADDI x10, x0, 99 (interrupt marker)
            instruction_memory[6] = make_s_type(12'd0, 5'd10, 5'd0, 3'b010, 7'b0100011); // SW x10, 0(x0)
            instruction_memory[7] = {12'h0, 5'b00010, 3'b000, 5'd0, 7'b1110011}; // MRET
            
            // Wait for initialization
            repeat(50) @(posedge clk);
            
            // Trigger software interrupt
            soft_irq = 1;
            $display("Software interrupt triggered");
            
            // Wait for interrupt handling
            repeat(50) @(posedge clk);
            
            // Check if interrupt was handled
            if (data_memory[0] == 32'd99) begin
                $display("  PASS: Software interrupt handled, marker = %d", data_memory[0]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: Software interrupt not handled, marker = %d", data_memory[0]);
                test_fail_count = test_fail_count + 1;
            end
            
            soft_irq = 0;
        end
    endtask
    
    // Test external interrupt
    task test_external_interrupt;
        begin
            $display("Testing external interrupt...");
            
            // Clear memory
            for (integer i = 0; i < 64; i = i + 1) begin
                instruction_memory[i] = 32'h00000013; // NOP
                data_memory[i] = 32'h00000000;
            end
            
            // Set up interrupt enable (MEI = bit 11 = 2048, use CSRRS to set bit 11)
            instruction_memory[0] = {12'h304, 5'd0, 3'b001, 5'd0, 7'b1110011}; // CSRRW x0, mie, x0 (clear mie)
            instruction_memory[1] = {12'h304, 5'd11, 3'b110, 5'd0, 7'b1110011}; // CSRRSI x0, mie, 11 (set bit 11 for external interrupt)
            
            // Enable global interrupts
            instruction_memory[2] = {12'h300, 5'd8, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mstatus, 8
            
            // Set trap vector to address 24
            instruction_memory[3] = {12'h305, 5'd24, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mtvec, 24
            
            // Main loop
            instruction_memory[4] = 32'h00000013; // NOP (PC=16)
            instruction_memory[5] = 32'hffdff06f; // JAL x0, -4 (infinite loop)
            
            // Interrupt handler at PC=24 (instruction_memory[6])
            instruction_memory[6] = {12'd123, 5'd0, 3'b000, 5'd11, 7'b0010011}; // ADDI x11, x0, 123 (interrupt marker)
            instruction_memory[7] = make_s_type(12'd4, 5'd11, 5'd0, 3'b010, 7'b0100011); // SW x11, 4(x0)
            instruction_memory[8] = {12'h0, 5'b00010, 3'b000, 5'd0, 7'b1110011}; // MRET
            
            // Wait for initialization
            repeat(50) @(posedge clk);
            
            // Trigger external interrupt
            ext_irq = 1;
            $display("External interrupt triggered");
            
            // Wait for interrupt handling
            repeat(50) @(posedge clk);
            
            // Check if interrupt was handled
            if (data_memory[1] == 32'd123) begin
                $display("  PASS: External interrupt handled, marker = %d", data_memory[1]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: External interrupt not handled, marker = %d", data_memory[1]);
                test_fail_count = test_fail_count + 1;
            end
            
            ext_irq = 0;
        end
    endtask
    
    initial begin
        $dumpfile("final_interrupt_test.vcd");
        $dumpvars(0, final_interrupt_test);
        
        clk = 0;
        resetn = 0;
        ext_irq = 0;
        timer_irq = 0;
        soft_irq = 0;
        test_pass_count = 0;
        test_fail_count = 0;
        
        // Clear memory
        for (integer i = 0; i < 64; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP
            data_memory[i] = 32'h00000000;
        end
        
        $display("Vigna Interrupt Functionality Test");
        $display("===================================");
        
        // Start processor
        repeat(10) @(posedge clk);
        resetn = 1;
        
        // Test 1: Software interrupt
        test_software_interrupt();
        
        // Reset for next test
        resetn = 0;
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Test 2: External interrupt
        test_external_interrupt();
        
        $display("\nFinal Interrupt Test Summary:");
        $display("=============================");
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