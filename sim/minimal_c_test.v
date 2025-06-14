`timescale 1ns / 1ps

`define VIGNA_CORE_C_EXTENSION
`include "vigna_conf.vh"

module minimal_c_test;

    reg clk, resetn;
    
    // Processor interface
    wire i_valid;
    reg i_ready;
    wire [31:0] i_addr;
    reg [31:0] i_rdata;
    
    wire d_valid;
    reg d_ready;
    wire [31:0] d_addr;
    reg [31:0] d_rdata;
    wire [31:0] d_wdata;
    wire [3:0] d_wstrb;
    
    // Memory
    reg [31:0] memory [0:255];
    
    // Processor instance
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
    
    // Simple memory interface
    always @(posedge clk) begin
        if (resetn) begin
            if (i_valid && !i_ready) begin
                i_rdata <= memory[i_addr[9:2]];
                i_ready <= 1;
            end else if (!i_valid) begin
                i_ready <= 0;
            end
            
            if (d_valid && !d_ready) begin
                if (d_wstrb != 0) begin
                    memory[d_addr[9:2]] <= d_wdata;
                    $display("Write: addr=0x%08x, data=0x%08x", d_addr, d_wdata);
                end else begin
                    d_rdata <= memory[d_addr[9:2]];
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
    
    initial begin
        $display("Minimal C Extension Test");
        $display("=======================");
        
        // Initialize
        clk = 0;
        resetn = 0;
        
        // Clear memory
        for (integer i = 0; i < 256; i = i + 1) begin
            memory[i] = 32'h00000013; // NOP
        end
        
        // Test program: regular ADDI x1, x0, 10
        memory[0] = {12'd10, 5'd0, 3'b000, 5'd1, 7'b0010011}; // ADDI x1, x0, 10
        
        // SW x1, 0(x0) 
        memory[1] = {12'd0, 5'd1, 3'b010, 5'd0, 7'b0100011};
        
        // Halt
        memory[2] = {-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111};
        
        $display("Program:");
        $display("  memory[0] = 0x%08x (ADDI x1, x0, 10)", memory[0]);
        $display("  memory[1] = 0x%08x (SW x1, 0(x0))", memory[1]);
        
        // Start processor
        repeat(10) @(posedge clk);
        resetn = 1;
        
        // Let it run
        repeat(100) @(posedge clk);
        
        // Check result
        $display("Result: memory[0] = 0x%08x (expected 10)", memory[0]);
        if (memory[0] == 10) begin
            $display("PASS: ADDI instruction worked!");
        end else begin
            $display("FAIL: ADDI instruction failed");
        end
        
        $finish;
    end

endmodule