`timescale 1ns / 1ps
`include "vigna_conf.vh"

module trace_debug;

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
                $display("Fetch: PC=0x%08x, Inst=0x%08x", i_addr, instruction_memory[i_addr[7:2]]);
            end else if (!i_valid) begin
                i_ready <= 0;
            end
            
            if (d_valid && !d_ready) begin
                if (d_wstrb != 0) begin
                    data_memory[d_addr[7:2]] <= d_wdata;
                    $display("Write: addr=0x%08x, data=0x%08x", d_addr, d_wdata);
                end else begin
                    d_rdata <= data_memory[d_addr[7:2]];
                    $display("Read: addr=0x%08x, data=0x%08x", d_addr, data_memory[d_addr[7:2]]);
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
    
    // Monitor register values
    always @(posedge clk) begin
        if (resetn && vigna_core_inst.exec_state == 0 && vigna_core_inst.fetched) begin
            $display("PC=0x%08x, x1=0x%08x, x2=0x%08x, exec_state=%d", 
                     vigna_core_inst.pc, 
                     vigna_core_inst.cpu_regs[1], 
                     vigna_core_inst.cpu_regs[2],
                     vigna_core_inst.exec_state);
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
        $dumpfile("trace_debug.vcd");
        $dumpvars(0, trace_debug);
        
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
        
        $display("Trace Debug Test");
        $display("================");
        
        // Test simple ADDI and register read
        instruction_memory[0] = make_i_type(12'h800, 5'd0, 3'b000, 5'd1, 7'b0010011); // ADDI x1, x0, 0x800
        instruction_memory[1] = make_s_type(12'd0, 5'd1, 5'd0, 3'b010, 7'b0100011); // SW x1, 0(x0)
        instruction_memory[2] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111); // Infinite loop (halt)
        
        $display("Instruction 0: ADDI x1, x0, 0x800 = 0x%08x", instruction_memory[0]);
        $display("Instruction 1: SW x1, 0(x0) = 0x%08x", instruction_memory[1]);
        
        repeat(10) @(posedge clk);
        resetn = 1;
        
        repeat(50) @(posedge clk);
        
        $display("Final result: x1 stored = 0x%08x (expected 0x00000800)", data_memory[0]);
        
        $finish;
    end

endmodule