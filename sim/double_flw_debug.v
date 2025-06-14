`timescale 1ns / 1ps

module double_flw_debug;
    reg clk;
    reg resetn;
    
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
            if (i_valid && !i_ready) begin
                i_rdata <= instruction_memory[i_addr[11:2]];
                i_ready <= 1;
            end else if (!i_valid) begin
                i_ready <= 0;
            end
            
            // Data memory interface
            if (d_valid && !d_ready) begin
                if (d_wstrb == 0) begin
                    // Read operation
                    d_rdata <= data_memory[d_addr[11:2]];
                    $display("  -> MEMORY READ: addr=0x%08x, data=0x%08x", d_addr, data_memory[d_addr[11:2]]);
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
    
    integer cycle_count = 0;
    
    initial begin
        // Initialize
        clk = 0;
        resetn = 0;
        
        // Initialize memories
        for (integer i = 0; i < 256; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP
            data_memory[i] = 32'h0;
        end
        
        // Set up test data
        data_memory[0] = 32'h3F800000; // 1.0f
        data_memory[1] = 32'h40000000; // 2.0f
        
        // Two FLW instructions followed by halt
        instruction_memory[0] = 32'h00002087; // FLW f1, 0(x0)
        instruction_memory[1] = 32'h00402107; // FLW f2, 4(x0)
        instruction_memory[2] = 32'hFF800067; // JALR x0, -8(x0) - halt
        
        $dumpfile("double_flw_debug.vcd");
        $dumpvars(0, double_flw_debug);
        
        $display("Starting Double FLW Debug Test");
        $display("==============================");
        
        // Reset
        #20 resetn = 1;
        #10;
        
        // Run and monitor
        for (integer i = 0; i < 50; i = i + 1) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            $display("Cycle %0d: PC=0x%08x, i_valid=%b, i_rdata=0x%08x, d_valid=%b, d_addr=0x%08x", 
                     cycle_count, i_addr, i_valid, i_rdata, d_valid, d_addr);
            
            // Monitor FP register state
            if (cycle_count > 10) begin
                $display("  -> FP registers: f1=0x%08x, f2=0x%08x", 
                         cpu.fp_regs[1], cpu.fp_regs[2]);
            end
                     
            if (i_valid && i_rdata == 32'hFF800067 && cycle_count > 10) begin
                $display("Test completed!");
                // Wait a few more cycles to see register updates
                for (integer j = 0; j < 5; j = j + 1) begin
                    @(posedge clk);
                    cycle_count = cycle_count + 1;
                    $display("Extra cycle %0d: f1=0x%08x, f2=0x%08x", 
                             cycle_count, cpu.fp_regs[1], cpu.fp_regs[2]);
                end
                i = 50; // Exit loop
            end
        end
        
        // Final check
        $display("");
        $display("Final FP register values:");
        $display("f1 = 0x%08x (expected 0x3F800000)", cpu.fp_regs[1]);
        $display("f2 = 0x%08x (expected 0x40000000)", cpu.fp_regs[2]);
        
        if (cpu.fp_regs[1] == 32'h3F800000 && cpu.fp_regs[2] == 32'h40000000) begin
            $display("SUCCESS: Both FLW instructions worked correctly!");
        end else begin
            $display("FAIL: FLW instructions did not work correctly");
        end
        
        $finish;
    end
    
endmodule