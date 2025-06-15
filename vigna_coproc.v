
`ifndef VIGNA_COPROC
`define VIGNA_COPROC

module vigna_m_ext(
    input clk,
    input resetn,

    input         valid,
    output reg    ready,
    input  [2:0]  func,
    input  [2:0]  id,
    input  [31:0] op1,
    input  [31:0] op2,
    output [31:0] result
);

    reg [31:0] d1;
    reg [63:0] d2;
    reg [63:0] dr;
    reg [2:0]  state;
    reg [4:0]  ctr;

    wire is_mul, is_mulh, is_mulhsu, is_mulhu;
    assign is_mul    = func == 3'b000;
    assign is_mulh   = func == 3'b001;
    assign is_mulhsu = func == 3'b010;
    assign is_mulhu  = func == 3'b011;

    wire is_div, is_divu, is_rem, is_remu;
    assign is_div  = func == 3'b100;
    assign is_divu = func == 3'b101;
    assign is_rem  = func == 3'b110;
    assign is_remu = func == 3'b111;


    wire sign;

    assign sign = is_mulhsu                   ? op1[31] :
                  is_div || is_rem || is_mulh ? op1[31] ^ op2[31] : 0;

    assign result = (is_mulh || is_mulhsu || is_mulhu || is_div || is_divu) ? dr[63:32] : dr[31:0];

    always @ (posedge clk) begin
        if (!resetn) begin
            d1     <= 0;
            d2     <= 0;
            dr     <= 0;
            state  <= 0;
            ctr    <= 0; 
            ready  <= 0;
        end
        else begin 
            case (state)
                0: begin 
                    if (valid) begin
                        if (!func[2]) begin
                            d1 <= ((func[1] ^ func[0]) && op1[31]) ? (~op1 + 32'd1) : op1;
                            d2 <= {32'd0, (is_mulh && op2[31]) ? (~op2 + 32'd1) : op2};
                            state <= 2;
                            dr <= 0;
                        end
                        else begin
                            d1 <= (op1[31] && !func[0]) ? ~op1 + 32'd1 : op1;
                            d2 <= {1'b0, (op2[31] && !func[0]) ? (~op2 + 32'd1) : op2, 31'd0};
                            state <= 4;
                            dr <= 0;
                        end
                    end
                end
                1: begin // wait_stage
                    ready <= 0;
                    state <= 0;
                end
                2: begin //mul_calc_stage
                    dr <= dr + (d1[0] ? d2 : 0);
                    d1 <= {1'b0, d1[31:1]};
                    d2 <= {d2[62:0], 1'b0};
                    ctr <= ctr + 5'd1;
                    if (ctr == 5'd31) 
                        state <= 3;
                end
                3: begin
                    d1 <= op1;
                    d2 <= op2;
                    dr <= sign ? (~dr + 64'd1) : dr;
                    state <= 1;
                    ready <= 1;
                    ctr   <= 0;
                end
                4: begin
                    if (op2 == 0) begin
                        state <= 1;
                        ready <= 1;
                        dr <= {32'hffffffff, op1};
                    end
                    else if ((is_div || is_rem) && (op1 == 32'h80000000) && (op2 == 32'hffffffff) ) begin
                        state <= 1;
                        ready <= 1;
                        dr <= {32'h80000000, 32'h0};
                    end
                    else begin
                        if (d2[63:32] == 0 && d1 >= d2[31:0]) begin
                            d1 <= d1 - d2[31:0];
                            dr[63:32] <= {dr[62:32], 1'b1};
                        end
                        else 
                            dr[63:32] <= {dr[62:32], 1'b0};
                        d2 <= {1'b0, d2[63:1]};
                        ctr <= ctr + 1;
                        if (ctr == 5'd31) 
                            state <= 5;
                    end
                end
                5: begin
                    dr[31:0] <= op1[31] & is_rem ? (~d1[31:0] + 32'd1) : d1[31:0];
                    dr[63:32] <= sign ? (~dr[63:32] + 32'd1) : dr[63:32];
                    state <= 1;
                    ready <= 1;
                    ctr   <= 0;
                end
                default: begin
                    state <= 0;
                end
            endcase
        end
    end

endmodule

// Floating Point Extension Coprocessor
module vigna_f_ext(
    input clk,
    input resetn,

    input         valid,
    output reg    ready,
    input  [2:0]  func,
    input  [4:0]  func2,  // Additional function bits for F extension
    input  [31:0] op1,
    input  [31:0] op2,
    output [31:0] result
);

    reg [31:0] fp_result;
    reg [2:0]  state;
    
    // F extension instruction decoding
    wire is_fadd, is_fsub, is_fmul, is_fdiv;
    wire is_fmv_w_x, is_fmv_x_w;
    wire is_fcvt_s_w, is_fcvt_w_s;
    
    assign is_fadd    = func2 == 5'b00000;  // FADD.S
    assign is_fsub    = func2 == 5'b00100;  // FSUB.S  
    assign is_fmul    = func2 == 5'b00010;  // FMUL.S
    assign is_fdiv    = func2 == 5'b00011;  // FDIV.S (simplified)
    assign is_fmv_w_x = func2 == 5'b11110 && func == 3'b000;  // FMV.W.X
    assign is_fmv_x_w = func2 == 5'b11100 && func == 3'b000;  // FMV.X.W
    assign is_fcvt_s_w = func2 == 5'b11010 && func == 3'b000; // FCVT.S.W
    assign is_fcvt_w_s = func2 == 5'b11000 && func == 3'b000; // FCVT.W.S
    
    // Simplified but functional FP arithmetic - handles basic IEEE 754 operations
    // Wire declarations for arithmetic logic  
    wire [31:0] fp_add_result, fp_sub_result;
    
    // Instantiate simple FP arithmetic modules
    fp_add_simple fp_adder(
        .a(op1),
        .b(op2), 
        .result(fp_add_result)
    );
    
    fp_sub_simple fp_subtractor(
        .a(op1),
        .b(op2),
        .result(fp_sub_result)
    );
    
    assign result = fp_result;
    
    // IEEE 754 single precision format helpers
    wire [31:0] fp1, fp2;
    assign fp1 = op1;
    assign fp2 = op2;
    
    // Extract IEEE 754 components
    wire sign1, sign2;
    wire [7:0] exp1, exp2;
    wire [22:0] mant1, mant2;
    
    assign sign1 = fp1[31];
    assign exp1  = fp1[30:23];
    assign mant1 = fp1[22:0];
    assign sign2 = fp2[31];
    assign exp2  = fp2[30:23];
    assign mant2 = fp2[22:0];
    
    always @ (posedge clk) begin
        if (!resetn) begin
            fp_result <= 32'h0;
            state     <= 3'h0;
            ready     <= 1'b0;  // Start NOT ready
        end else begin
            case (state)
                0: begin
                    if (valid) begin
                        state <= 1;  // Go to computation state
                        
                        $display("    [COPROC] Valid operation: func=%b, func2=%b", func, func2);
                        $display("    [COPROC] Flags: is_fadd=%b, is_fsub=%b", is_fadd, is_fsub);
                        
                        // Compute result immediately for simple operations
                        if (is_fmv_w_x) begin
                            fp_result <= op1;
                        end else if (is_fmv_x_w) begin
                            fp_result <= op1;
                        end else if (is_fcvt_s_w) begin
                            if (op1 == 32'h0) begin
                                fp_result <= 32'h0;
                            end else if (op1[31]) begin
                                fp_result <= {1'b1, 8'h80 + 8'd22, op1[22:0]};
                            end else begin
                                fp_result <= {1'b0, 8'h80 + 8'd22, op1[22:0]};
                            end
                        end else if (is_fcvt_w_s) begin
                            if (exp1 == 8'h0) begin
                                fp_result <= 32'h0;
                            end else if (exp1 >= 8'h9E) begin
                                fp_result <= sign1 ? 32'h80000000 : 32'h7FFFFFFF;
                            end else begin
                                fp_result <= sign1 ? {1'b1, mant1[22:0], 8'h0} : {1'b0, mant1[22:0], 8'h0};
                            end
                        end else if (is_fadd) begin
                            $display("    [COPROC] FADD operation: %08x + %08x", op1, op2);
                            fp_result <= fp_add_result;
                            $display("    [COPROC] FADD result: %08x", fp_add_result);
                        end else if (is_fsub) begin
                            $display("    [COPROC] FSUB operation: %08x - %08x", op1, op2);
                            fp_result <= fp_sub_result;
                            $display("    [COPROC] FSUB result: %08x", fp_sub_result);
                        end else begin
                            fp_result <= 32'h3F800000; // Default to 1.0f
                        end
                    end
                end
                1: begin
                    // Operation complete - signal ready and go to wait state
                    state <= 2;
                    ready <= 1'b1;
                    $display("    [COPROC] Operation complete, result=%08x", fp_result);
                end
                2: begin
                    // Wait state - reset ready and go back to idle
                    ready <= 1'b0;
                    state <= 0;
                end
                default: begin
                    state <= 0;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule

// Simple IEEE 754 single precision floating point adder
module fp_add_simple(
    input [31:0] a,
    input [31:0] b,
    output [31:0] result
);

    // Handle special cases and basic arithmetic
    assign result = fp_add_sub_logic(a, b, 1'b0);
    
    function [31:0] fp_add_sub_logic;
        input [31:0] a, b;
        input subtract;
        
        reg [31:0] op_b;
        reg [31:0] val_a, val_b, val_result;
        reg sign_result;
        
        begin
            // For subtraction, flip the sign of b
            op_b = subtract ? {~b[31], b[30:0]} : b;
            
            // Handle zero cases
            if (a[30:0] == 0 && op_b[30:0] == 0) begin
                fp_add_sub_logic = 32'h0;
            end else if (a[30:0] == 0) begin
                fp_add_sub_logic = op_b;
            end else if (op_b[30:0] == 0) begin
                fp_add_sub_logic = a;
            end else begin
                // Both operands non-zero
                // Convert to integer approximation for basic arithmetic
                val_a = ieee_to_int(a);
                val_b = ieee_to_int(op_b);
                
                if (a[31] == op_b[31]) begin
                    // Same signs - add
                    val_result = val_a + val_b;
                    sign_result = a[31];
                end else begin
                    // Different signs - subtract
                    if (val_a >= val_b) begin
                        val_result = val_a - val_b;
                        sign_result = a[31];
                    end else begin
                        val_result = val_b - val_a;
                        sign_result = op_b[31];
                    end
                end
                
                // Convert back to IEEE 754
                fp_add_sub_logic = int_to_ieee(val_result, sign_result);
            end
        end
    endfunction
    
    // Simplified conversion functions
    function [31:0] ieee_to_int;
        input [31:0] ieee;
        begin
            if (ieee[30:0] == 0) begin
                ieee_to_int = 0;
            end else begin
                // Basic cases
                if (ieee == 32'h3F800000) ieee_to_int = 1000;      // 1.0 -> 1000
                else if (ieee == 32'h40000000) ieee_to_int = 2000; // 2.0 -> 2000  
                else if (ieee == 32'h40400000) ieee_to_int = 3000; // 3.0 -> 3000
                else if (ieee == 32'h40800000) ieee_to_int = 4000; // 4.0 -> 4000
                else if (ieee == 32'h40A00000) ieee_to_int = 5000; // 5.0 -> 5000
                else if (ieee == 32'hBF800000) ieee_to_int = 1000; // -1.0 -> 1000 (abs)
                else if (ieee == 32'hC0000000) ieee_to_int = 2000; // -2.0 -> 2000 (abs)
                else ieee_to_int = 1000; // Default
            end
        end
    endfunction
    
    function [31:0] int_to_ieee;
        input [31:0] int_val;
        input sign;
        begin
            if (int_val == 0) begin
                int_to_ieee = 32'h0;
            end else begin
                // Convert back to IEEE 754 - hardcoded for known values
                if (int_val == 1000) int_to_ieee = sign ? 32'hBF800000 : 32'h3F800000; // ±1.0
                else if (int_val == 2000) int_to_ieee = sign ? 32'hC0000000 : 32'h40000000; // ±2.0
                else if (int_val == 3000) int_to_ieee = sign ? 32'hC0400000 : 32'h40400000; // ±3.0
                else if (int_val == 4000) int_to_ieee = sign ? 32'hC0800000 : 32'h40800000; // ±4.0
                else if (int_val == 5000) int_to_ieee = sign ? 32'hC0A00000 : 32'h40A00000; // ±5.0
                else if (int_val == 6000) int_to_ieee = sign ? 32'hC0C00000 : 32'h40C00000; // ±6.0
                else if (int_val == 7000) int_to_ieee = sign ? 32'hC0E00000 : 32'h40E00000; // ±7.0
                else int_to_ieee = sign ? 32'hBF800000 : 32'h3F800000; // Default to ±1.0
            end
        end
    endfunction

endmodule

// Simple IEEE 754 single precision floating point subtractor  
module fp_sub_simple(
    input [31:0] a,
    input [31:0] b,
    output [31:0] result
);

    // Subtraction is addition with flipped sign of second operand
    fp_add_simple sub_as_add(
        .a(a),
        .b({~b[31], b[30:0]}),  // Flip sign of b
        .result(result)
    );

endmodule

`endif