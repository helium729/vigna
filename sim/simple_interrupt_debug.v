`timescale 1ns / 1ps
`include "vigna_conf.vh"

module simple_interrupt_debug;

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
        $dumpfile("simple_interrupt_debug.vcd");
        $dumpvars(0, simple_interrupt_debug);
        
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
        
        $display("Simple Interrupt Debug Test");
        $display("===========================");
        
        // Test 1: Load value 0x800 and write to mie
        instruction_memory[0] = make_i_type(12'h800, 5'd0, 3'b000, 5'd1, 7'b0010011); // ADDI x1, x0, 0x800
        instruction_memory[1] = {12'h304, 5'd1, 3'b001, 5'd0, 7'b1110011}; // CSRRW x0, mie, x1
        instruction_memory[2] = {12'h304, 5'd0, 3'b010, 5'd2, 7'b1110011}; // CSRRS x2, mie, x0 (read mie)
        instruction_memory[3] = make_s_type(12'd0, 5'd2, 5'd0, 3'b010, 7'b0100011); // SW x2, 0(x0)
        instruction_memory[4] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111); // Infinite loop (halt)
        
        repeat(10) @(posedge clk);
        resetn = 1;
        
        repeat(100) @(posedge clk);
        
        $display("Result: mie read = 0x%08x (expected 0x00000800)", data_memory[0]);
        
        // Test 2: Try direct CSR address
        resetn = 0;
        for (integer i = 0; i < 64; i = i + 1) begin
            data_memory[i] = 32'h00000000;
        end
        repeat(5) @(posedge clk);
        resetn = 1;
        
        // Direct write to mie with immediate
        instruction_memory[0] = {12'h304, 5'd11, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mie, 11 (0x0B)
        instruction_memory[1] = {12'h304, 5'd0, 3'b010, 5'd3, 7'b1110011}; // CSRRS x3, mie, x0 (read mie)
        instruction_memory[2] = make_s_type(12'd4, 5'd3, 5'd0, 3'b010, 7'b0100011); // SW x3, 4(x0)
        instruction_memory[3] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111); // Infinite loop (halt)
        
        repeat(100) @(posedge clk);
        
        $display("Result: mie read = 0x%08x (expected 0x0000000B)", data_memory[1]);
        
        $finish;
    end

endmodule