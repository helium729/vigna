`timescale 1ns / 1ps

module simple_f_debug;
    reg clk;
    reg resetn;
    
    // Test the processor with a simple integer instruction first
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
                if (d_wstrb == 0) begin
                    // Read operation - return test data
                    d_rdata <= 32'h3F800000; // Always return 1.0f
                end
            end
        end
    end
    
    integer cycle_count = 0;
    
    initial begin
        // Initialize
        clk = 0;
        resetn = 0;
        i_ready = 0;
        d_ready = 0;
        
        // Initialize instruction memory with NOPs
        for (integer i = 0; i < 256; i = i + 1) begin
            instruction_memory[i] = 32'h00000013; // NOP
        end
        
        $dumpfile("simple_f_debug.vcd");
        $dumpvars(0, simple_f_debug);
        
        $display("Starting Simple F Debug Test");
        $display("============================");
        
        // Reset
        #10 resetn = 1;
        i_ready = 1;
        d_ready = 1;
        
        // Test basic instruction first
        instruction_memory[0] = 32'h00100093; // ADDI x1, x0, 1
        instruction_memory[1] = 32'hFF800067; // JALR x0, -8(x0) - halt
        
        // Run for a few cycles to see if basic execution works
        for (integer i = 0; i < 20; i = i + 1) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            $display("Cycle %0d: PC=0x%08x, i_valid=%b, i_rdata=0x%08x, d_valid=%b", 
                     cycle_count, i_addr, i_valid, i_rdata, d_valid);
                     
            if (i_valid && i_rdata == 32'hFF800067) begin
                $display("Reached halt - basic execution works!");
                i = 20; // Exit loop
            end
        end
        
        // Now test a simple FLW instruction
        $display("Testing FLW instruction...");
        cycle_count = 0;
        
        // Reset again
        resetn = 0;
        #10 resetn = 1;
        
        // Load simple FLW test
        instruction_memory[0] = 32'h00002087; // FLW f1, 0(x0)
        instruction_memory[1] = 32'hFF800067; // JALR x0, -8(x0) - halt
        
        // Run and see what happens
        for (integer i = 0; i < 50; i = i + 1) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            $display("Cycle %0d: PC=0x%08x, i_valid=%b, i_rdata=0x%08x, d_valid=%b, d_addr=0x%08x", 
                     cycle_count, i_addr, i_valid, i_rdata, d_valid, d_addr);
                     
            if (i_valid && i_rdata == 32'hFF800067) begin
                $display("FLW test completed successfully!");
                i = 50; // Exit loop
            end
            
            if (cycle_count >= 49) begin
                $display("FLW test timed out - likely stuck in execution");
            end
        end
        
        $finish;
    end
    
endmodule