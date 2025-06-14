`timescale 1ns / 1ps

// Enable C extension for this test
`define VIGNA_CORE_C_EXTENSION
`include "vigna_conf.vh"

module simple_c_test;

    // Test a simple C.LI instruction expansion
    reg [15:0] c_inst;
    wire [31:0] expanded;
    
    // Extract fields manually
    wire [1:0] c_op = c_inst[1:0];
    wire [2:0] c_funct3 = c_inst[15:13]; 
    wire [4:0] c_rd = c_inst[11:7];
    wire [5:0] c_imm = {c_inst[12], c_inst[6:2]};
    wire [31:0] c_imm_extended = {{26{c_inst[12]}}, c_inst[12], c_inst[6:2]};
    
    // Check if it's C.LI
    wire is_c_li = (c_op == 2'b01) && (c_funct3 == 3'b010);
    
    // Expand to ADDI rd, x0, imm
    assign expanded = is_c_li ? {c_imm_extended[11:0], 5'd0, 3'b000, c_rd, 7'b0010011} : 32'h00000013;
    
    initial begin
        $display("Testing C.LI instruction expansion:");
        
        // Test C.LI x1, 10
        // Format: funct3=010, imm[5], rd=00001, imm[4:0]=01010, op=01
        c_inst = {3'b010, 1'b0, 5'b00001, 5'b01010, 2'b01};
        
        #1;
        $display("C.LI x1, 10:");
        $display("  Input C instruction: 0x%04x", c_inst);
        $display("  Detected as C.LI: %b", is_c_li);
        $display("  Immediate value: %d (raw: 0x%02x, extended: 0x%08x)", $signed(c_imm_extended), c_imm, c_imm_extended);
        $display("  Expanded instruction: 0x%08x", expanded);
        
        // Expected: ADDI x1, x0, 10 = 0x00a00093
        if (expanded == 32'h00a00093) begin
            $display("  PASS: Expansion correct");
        end else begin
            $display("  FAIL: Expected 0x00a00093, got 0x%08x", expanded);
        end
        
        // Test C.ADDI x1, 5  
        c_inst = {3'b000, 1'b0, 5'b00001, 5'b00101, 2'b01};
        
        #1;
        $display("C.ADDI x1, 5:");
        $display("  Input C instruction: 0x%04x", c_inst);
        $display("  Detected as C.LI: %b (should be false)", is_c_li);
        
        $finish;
    end

endmodule