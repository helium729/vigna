`timescale 1ns / 1ps
`include "vigna_conf.vh"

module debug_interrupt_signals;

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
    
    // Monitor interrupt signals
    always @(posedge clk) begin
        if (resetn) begin
            $display("t=%0t: PC=0x%02x, exec_state=%d, fetched=%b, soft_irq=%b, mie[3]=%b, mstatus[3]=%b, irq_req=%b, irq_taken=%b", 
                     $time, vigna_core_inst.pc[7:0], vigna_core_inst.exec_state, vigna_core_inst.fetched, 
                     soft_irq, vigna_core_inst.mie[3], vigna_core_inst.mstatus[3], 
                     vigna_core_inst.interrupt_request, vigna_core_inst.interrupt_taken);
        end
    end
    
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
        $dumpfile("debug_interrupt_signals.vcd");
        $dumpvars(0, debug_interrupt_signals);
        
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
        
        $display("Debug Interrupt Signals Test");
        $display("============================");
        
        // Set up basic program
        instruction_memory[0] = {12'h304, 5'd8, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mie, 8 (enable software interrupt)
        instruction_memory[1] = {12'h300, 5'd8, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mstatus, 8 (enable global interrupts)
        instruction_memory[2] = {12'h305, 5'd20, 3'b101, 5'd0, 7'b1110011}; // CSRRWI x0, mtvec, 20 (set trap vector to address 20)
        instruction_memory[3] = 32'h00000013; // NOP (PC=12 - loop start)
        instruction_memory[4] = 32'hffdff06f; // JAL x0, -4 (infinite loop - jump back to PC=12)
        
        // Interrupt handler at PC=20 (instruction_memory[5])
        instruction_memory[5] = make_s_type(12'd0, 5'd31, 5'd0, 3'b010, 7'b0100011); // SW x31, 0(x0) (interrupt marker)
        instruction_memory[6] = {12'h0, 5'b00010, 3'b000, 5'd0, 7'b1110011}; // MRET
        
        repeat(10) @(posedge clk);
        resetn = 1;
        
        // Let it run for a bit
        repeat(20) @(posedge clk);
        
        // Trigger software interrupt
        soft_irq = 1;
        $display("=== SOFTWARE INTERRUPT TRIGGERED ===");
        
        repeat(20) @(posedge clk);
        
        $finish;
    end

endmodule