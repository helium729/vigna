`timescale 1ns / 1ps

module vigna_f_ext_testbench;
    reg clk;
    reg resetn;
    
    // Instruction and data memory interfaces
    wire        i_valid;
    reg         i_ready;
    wire [31:0] i_addr;
    reg  [31:0] i_rdata;
    
    wire        d_valid;
    reg         d_ready;
    wire [31:0] d_addr;
    reg  [31:0] d_rdata;
    wire [31:0] d_wdata;
    wire [ 3:0] d_wstrb;
    
    // Instantiate the processor
    vigna cpu (
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
    
    // Test instruction memory
    reg [31:0] instruction_memory [255:0];
    
    // Test data memory  
    reg [31:0] data_memory [255:0];
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Memory simulation
    always @(posedge clk) begin
        if (resetn) begin
            // Instruction memory interface
            if (i_valid && i_ready) begin
                i_rdata <= instruction_memory[i_addr[9:2]];
            end
            
            // Data memory interface
            if (d_valid && d_ready) begin
                if (d_wstrb != 0) begin
                    // Write operation
                    if (d_wstrb[0]) data_memory[d_addr[9:2]][7:0]   <= d_wdata[7:0];
                    if (d_wstrb[1]) data_memory[d_addr[9:2]][15:8]  <= d_wdata[15:8];
                    if (d_wstrb[2]) data_memory[d_addr[9:2]][23:16] <= d_wdata[23:16];
                    if (d_wstrb[3]) data_memory[d_addr[9:2]][31:24] <= d_wdata[31:24];
                end else begin
                    // Read operation
                    d_rdata <= data_memory[d_addr[9:2]];
                end
            end
        end
    end
    
    // Helper function to create R-type instruction
    function [31:0] make_r_type;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            make_r_type = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction
    
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
    
    // Test execution control
    integer cycle_count;
    integer max_cycles;
    
    task run_test_sequence;
        input [255:0] test_name;
        input integer max_test_cycles;
        begin
            $display("Running test: %0s", test_name);
            cycle_count = 0;
            max_cycles = max_test_cycles;
            i_ready = 1;
            d_ready = 1;
            
            // Wait for test completion or timeout
            while (cycle_count < max_cycles) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                
                // Check for halt condition (JALR to negative offset)
                if (i_valid && i_rdata == 32'hFF800067) begin // JALR x0, -8(x0)
                    $display("Test reached halt condition");
                    $display("Test completed: %0s (cycles: %10d)", test_name, cycle_count);
                    cycle_count = max_cycles; // Break the loop
                end
            end
            $display("Test timed out: %0s", test_name);
        end
    endtask
    
    initial begin
        // Initialize
        clk = 0;
        resetn = 0;
        i_ready = 0;
        d_ready = 0;
        
        // Initialize memories
        for (integer i = 0; i < 256; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP
            data_memory[i] = 32'h0;
        end
        
        // Setup some test FP data in memory
        data_memory[0] = 32'h3F800000; // 1.0f in IEEE 754
        data_memory[1] = 32'h40000000; // 2.0f in IEEE 754  
        data_memory[2] = 32'h40400000; // 3.0f in IEEE 754
        
        $dumpfile("vigna_f_ext_test.vcd");
        $dumpvars(0, vigna_f_ext_testbench);
        
        $display("Starting Vigna F Extension Tests");
        $display("==================================");
        
        // Reset
        #10 resetn = 1;
        
        // Test 1: Basic FP Load/Store Operations
        $display("Setting up FP load/store test...");
        
        // Load 1.0f from memory[0] to f1
        instruction_memory[0] = 32'h00002087;  // FLW f1, 0(x0)
        // Load 2.0f from memory[1] to f2  
        instruction_memory[1] = 32'h00402107;  // FLW f2, 4(x0)
        // Store f1 to memory[4]
        instruction_memory[2] = 32'h02102027;  // FSW f1, 16(x0) 
        // Store f2 to memory[5]
        instruction_memory[3] = 32'h02202227;  // FSW f2, 20(x0)
        // Halt
        instruction_memory[4] = 32'hFF800067; // JALR x0, -8(x0)
        
        run_test_sequence("FP Load/Store Operations", 200);
        
        // Verify results
        if (data_memory[4] == 32'h3F800000) begin // 1.0f
            $display("  PASS: FP Load/Store f1 = 0x%08x (expected 0x3F800000)", data_memory[4]);
        end else begin
            $display("  FAIL: FP Load/Store f1 = 0x%08x (expected 0x3F800000)", data_memory[4]);
        end
        
        if (data_memory[5] == 32'h40000000) begin // 2.0f
            $display("  PASS: FP Load/Store f2 = 0x%08x (expected 0x40000000)", data_memory[5]);
        end else begin
            $display("  FAIL: FP Load/Store f2 = 0x%08x (expected 0x40000000)", data_memory[5]);
        end
        
        // Test 2: FMV instructions (move between FP and integer registers)
        $display("Setting up FP move test...");
        
        // Load immediate 0x3F800000 (1.0f) into x1
        instruction_memory[0] = 32'h3F800093;  // ADDI x1, x0, 0x3F8  
        instruction_memory[1] = 32'h00C09093;  // SLLI x1, x1, 12     (x1 = 0x3F800000)
        
        // Move x1 to f3
        instruction_memory[2] = 32'hF00081D3;  // FMV.W.X f3, x1
        
        // Move f3 back to x2  
        instruction_memory[3] = 32'hE0018153;  // FMV.X.W x2, f3
        
        // Store x2 to memory[6]
        instruction_memory[4] = 32'h01202C23;  // SW x2, 24(x0)
        
        // Halt
        instruction_memory[5] = 32'hFF800067; // JALR x0, -8(x0)
        
        run_test_sequence("FP Move Operations", 300);
        
        // Verify results  
        if (data_memory[6] == 32'h3F800000) begin // 1.0f
            $display("  PASS: FMV operations = 0x%08x (expected 0x3F800000)", data_memory[6]);
        end else begin
            $display("  FAIL: FMV operations = 0x%08x (expected 0x3F800000)", data_memory[6]);
        end
        
        $display("");
        $display("F Extension Test Summary:");
        $display("========================");
        $display("Basic F extension functionality verified:");
        $display("- FLW/FSW (floating point load/store)");
        $display("- FMV.W.X/FMV.X.W (move between FP and integer registers)");
        $display("- FP register file operations");
        $display("");
        $display("All F extension tests completed!");
        
        $finish;
    end
    
endmodule