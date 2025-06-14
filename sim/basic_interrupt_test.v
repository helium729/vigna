`timescale 1ns / 1ps
`include "vigna_conf.vh"

module basic_interrupt_test;

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
    
    initial begin
        $dumpfile("basic_interrupt_test.vcd");
        $dumpvars(0, basic_interrupt_test);
        
        clk = 0;
        resetn = 0;
        ext_irq = 0;
        timer_irq = 0;
        soft_irq = 0;
        
        // Clear memory
        for (integer i = 0; i < 64; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP
            data_memory[i] = 32'h00000000;
        end
        
        $display("Basic Interrupt Test");
        $display("====================");
        
        // Test: Enable timer interrupt (bit 7) using CSRRWI
        // First clear, then set bit 7 using CSRRS
        instruction_memory[0] = {12'h304, 5'd0, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mie, 0 (clear mie)
        instruction_memory[1] = {12'h304, 5'd8, 3'b110, 5'd0, 7'b1110011}; // CSRRSI x0, mie, 8 (set bit 3 for software interrupt test)
        instruction_memory[2] = {12'h304, 5'd0, 3'b010, 5'd1, 7'b1110011}; // CSRRS x1, mie, x0 (read mie)
        instruction_memory[3] = make_s_type(12'd0, 5'd1, 5'd0, 3'b010, 7'b0100011); // SW x1, 0(x0)
        
        // Set global interrupt enable
        instruction_memory[4] = {12'h300, 5'd8, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mstatus, 8 (set MIE bit)
        instruction_memory[5] = {12'h300, 5'd0, 3'b010, 5'd2, 7'b1110011}; // CSRRS x2, mstatus, x0 (read mstatus)
        instruction_memory[6] = make_s_type(12'd4, 5'd2, 5'd0, 3'b010, 7'b0100011); // SW x2, 4(x0)
        
        // Set trap vector
        instruction_memory[7] = {12'h305, 5'd16, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mtvec, 16 (trap vector = 64)
        instruction_memory[8] = {12'h305, 5'd0, 3'b010, 5'd3, 7'b1110011}; // CSRRS x3, mtvec, x0 (read mtvec)
        instruction_memory[9] = make_s_type(12'd8, 5'd3, 5'd0, 3'b010, 7'b0100011); // SW x3, 8(x0)
        
        // Main loop - wait for interrupt
        instruction_memory[10] = 32'h00000013; // NOP
        instruction_memory[11] = 32'hfe5ff06f; // JAL x0, -28 (jump to instruction 10, infinite loop)
        
        // Interrupt handler at instruction 16 (PC=64)
        instruction_memory[16] = make_s_type(12'd12, 5'd31, 5'd0, 3'b010, 7'b0100011); // SW x31, 12(x0) (interrupt marker)
        instruction_memory[17] = {12'h0, 5'b00010, 3'b000, 5'd0, 7'b1110011}; // MRET
        
        repeat(10) @(posedge clk);
        resetn = 1;
        
        // Let it run for a bit
        repeat(50) @(posedge clk);
        
        $display("MIE register: 0x%08x (expected 0x00000008)", data_memory[0]);
        $display("MSTATUS register: 0x%08x (expected 0x00000008)", data_memory[1]);
        $display("MTVEC register: 0x%08x (expected 0x00000010)", data_memory[2]);
        
        // Trigger software interrupt instead of timer
        soft_irq = 1;
        $display("Triggering software interrupt...");
        
        repeat(50) @(posedge clk);
        
        $display("Interrupt marker: 0x%08x (expected != 0)", data_memory[3]);
        if (data_memory[3] != 0) begin
            $display("PASS: Interrupt was handled!");
        end else begin
            $display("FAIL: Interrupt was not handled");
        end
        
        $finish;
    end

endmodule