//////////////////////////////////////////////////////////////////////////////////
// Testbench for Vigna AXI4-Lite Interface
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module vigna_axi_testbench;

    // Clock and reset
    reg clk;
    reg resetn;
    
    // AXI4-Lite Instruction Read Interface
    wire        i_arvalid;
    reg         i_arready;
    wire [31:0] i_araddr;
    wire [2:0]  i_arprot;
    
    reg         i_rvalid;
    wire        i_rready;
    reg  [31:0] i_rdata;
    reg  [1:0]  i_rresp;

    // AXI4-Lite Data Read Interface
    wire        d_arvalid;
    reg         d_arready;
    wire [31:0] d_araddr;
    wire [2:0]  d_arprot;
    
    reg         d_rvalid;
    wire        d_rready;
    reg  [31:0] d_rdata;
    reg  [1:0]  d_rresp;

    // AXI4-Lite Data Write Interface
    wire        d_awvalid;
    reg         d_awready;
    wire [31:0] d_awaddr;
    wire [2:0]  d_awprot;
    
    wire        d_wvalid;
    reg         d_wready;
    wire [31:0] d_wdata;
    wire [3:0]  d_wstrb;
    
    reg         d_bvalid;
    wire        d_bready;
    reg  [1:0]  d_bresp;

    // Test data
    reg [31:0] instruction_memory [0:1023];
    reg [31:0] data_memory [0:1023];
    
    // Test counters
    integer test_pass_count = 0;
    integer test_fail_count = 0;

    // Instantiate the Vigna AXI processor
    vigna_axi uut (
        .clk(clk),
        .resetn(resetn),
        
        .i_arvalid(i_arvalid),
        .i_arready(i_arready),
        .i_araddr(i_araddr),
        .i_arprot(i_arprot),
        .i_rvalid(i_rvalid),
        .i_rready(i_rready),
        .i_rdata(i_rdata),
        .i_rresp(i_rresp),
        
        .d_arvalid(d_arvalid),
        .d_arready(d_arready),
        .d_araddr(d_araddr),
        .d_arprot(d_arprot),
        .d_rvalid(d_rvalid),
        .d_rready(d_rready),
        .d_rdata(d_rdata),
        .d_rresp(d_rresp),
        
        .d_awvalid(d_awvalid),
        .d_awready(d_awready),
        .d_awaddr(d_awaddr),
        .d_awprot(d_awprot),
        .d_wvalid(d_wvalid),
        .d_wready(d_wready),
        .d_wdata(d_wdata),
        .d_wstrb(d_wstrb),
        .d_bvalid(d_bvalid),
        .d_bready(d_bready),
        .d_bresp(d_bresp)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // AXI4-Lite Memory simulation for instruction fetch
    always @(posedge clk) begin
        if (resetn) begin
            // Handle instruction read address
            if (i_arvalid && i_arready) begin
                // Address phase complete, prepare data
                i_rdata <= instruction_memory[i_araddr[11:2]]; // Word aligned access
                i_rvalid <= 1;
                i_rresp <= 2'b00; // OKAY response
            end else if (i_rvalid && i_rready) begin
                i_rvalid <= 0;
            end
        end else begin
            i_rvalid <= 0;
        end
    end
    
    // AXI4-Lite Memory simulation for data access
    always @(posedge clk) begin
        if (resetn) begin
            // Handle data read address
            if (d_arvalid && d_arready) begin
                // Address phase complete, prepare data
                d_rdata <= data_memory[d_araddr[11:2]];
                d_rvalid <= 1;
                d_rresp <= 2'b00; // OKAY response
            end else if (d_rvalid && d_rready) begin
                d_rvalid <= 0;
            end
            
            // Handle data write
            if (d_awvalid && d_awready && d_wvalid && d_wready) begin
                // Both address and data received, perform write
                if (d_wstrb == 4'b1111) 
                    data_memory[d_awaddr[11:2]] <= d_wdata;
                // Handle other write strobes if needed
                d_bvalid <= 1;
                d_bresp <= 2'b00; // OKAY response
            end else if (d_bvalid && d_bready) begin
                d_bvalid <= 0;
            end
        end else begin
            d_rvalid <= 0;
            d_bvalid <= 0;
        end
    end
    
    // AXI4-Lite ready signal generation (simple immediate ready)
    always @(posedge clk) begin
        if (!resetn) begin
            i_arready <= 0;
            d_arready <= 0;
            d_awready <= 0;
            d_wready <= 0;
        end else begin
            i_arready <= i_arvalid;
            d_arready <= d_arvalid;
            d_awready <= d_awvalid;
            d_wready <= d_wvalid;
        end
    end
    
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
    
    // Test sequence
    task run_test_sequence;
        input [255:0] test_name;
        input integer max_cycles;
        integer cycle_count;
        reg test_finished;
        reg [31:0] last_pc;
        integer pc_stuck_count;
        begin
            $display("Running test: %s", test_name);
            cycle_count = 0;
            test_finished = 0;
            last_pc = 32'hffffffff;
            pc_stuck_count = 0;
            
            while (cycle_count < max_cycles && !test_finished) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                
                // Check for halt condition - PC stuck in same location for multiple cycles
                if (i_arvalid && i_araddr == last_pc) begin
                    pc_stuck_count = pc_stuck_count + 1;
                    if (pc_stuck_count > 10) begin
                        $display("Test reached halt condition - PC stuck at 0x%h", i_araddr);
                        test_finished = 1;
                    end
                end else if (i_arvalid) begin
                    last_pc = i_araddr;
                    pc_stuck_count = 0;
                end
            end
            
            $display("Test completed: %s (cycles: %d)", test_name, cycle_count);
        end
    endtask
    
    // Test basic operations
    task test_basic_operations;
        begin
            $display("Setting up basic operations test...");
            
            // ADDI x1, x0, 42     // x1 = 42
            instruction_memory[0] = make_i_type(12'd42, 5'd0, 3'b000, 5'd1, 7'b0010011);
            
            // SW x1, 16(x0)       // Store x1 to address 16
            instruction_memory[1] = make_s_type(12'd16, 5'd1, 5'd0, 3'b010, 7'b0100011);
            
            // LW x2, 16(x0)       // Load from address 16 to x2
            instruction_memory[2] = make_i_type(12'd16, 5'd0, 3'b010, 5'd2, 7'b0000011);
            
            // SW x2, 20(x0)       // Store x2 to address 20 for verification
            instruction_memory[3] = make_s_type(12'd20, 5'd2, 5'd0, 3'b010, 7'b0100011);
            
            // Halt: JALR x0, x0, -4
            instruction_memory[4] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111);
            
            // Reset after setting up instructions
            resetn = 0;
            repeat(5) @(posedge clk);
            resetn = 1;
            repeat(5) @(posedge clk);
            
            run_test_sequence("Basic AXI Operations", 200);
            
            // Verify results
            if (data_memory[4] == 32'd42 && data_memory[5] == 32'd42) begin
                $display("  PASS: Load/Store via AXI - stored %d, loaded %d", data_memory[4], data_memory[5]);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("  FAIL: Load/Store via AXI - stored %d at addr 4, loaded %d at addr 5", data_memory[4], data_memory[5]);
                $display("    Debug: memory[0]=%d, memory[1]=%d, memory[2]=%d, memory[3]=%d, memory[4]=%d, memory[5]=%d", 
                         data_memory[0], data_memory[1], data_memory[2], data_memory[3], data_memory[4], data_memory[5]);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("Starting Vigna AXI4-Lite Interface Tests");
        $display("========================================");
        
        // Initialize
        resetn = 0;
        
        // Initialize AXI signals
        i_arready = 0;
        i_rvalid = 0;
        i_rdata = 0;
        i_rresp = 0;
        
        d_arready = 0;
        d_rvalid = 0;
        d_rdata = 0;
        d_rresp = 0;
        
        d_awready = 0;
        d_wready = 0;
        d_bvalid = 0;
        d_bresp = 0;
        
        // Reset sequence
        repeat(10) @(posedge clk);
        resetn = 1;
        repeat(5) @(posedge clk);
        
        // Run tests
        test_basic_operations();
        
        // Display results
        $display("\nAXI Test Summary:");
        $display("=================");
        $display("Tests Passed: %d", test_pass_count);
        $display("Tests Failed: %d", test_fail_count);
        $display("Total Tests:  %d", test_pass_count + test_fail_count);
        
        if (test_fail_count == 0) begin
            $display("All AXI tests PASSED!");
        end else begin
            $display("Some AXI tests FAILED!");
        end
        
        $finish;
    end

endmodule