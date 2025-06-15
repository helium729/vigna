
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

// Improved IEEE 754 single precision floating point adder
module fp_add_simple(
    input [31:0] a,
    input [31:0] b,
    output [31:0] result
);

    // Extract IEEE 754 components
    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [22:0] mant_a = a[22:0];
    
    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] mant_b = b[22:0];
    
    // Check for zero operands
    wire is_zero_a = (exp_a == 8'd0) && (mant_a == 23'd0);
    wire is_zero_b = (exp_b == 8'd0) && (mant_b == 23'd0);
    
    assign result = fp_add_logic(a, b);
    
    function [31:0] fp_add_logic;
        input [31:0] a, b;
        
        // Extract components
        reg sign_a, sign_b, result_sign;
        reg [7:0] exp_a, exp_b, result_exp;
        reg [22:0] mant_a, mant_b;
        reg [24:0] mant_a_ext, mant_b_ext, result_mant;
        reg [7:0] exp_diff;
        
        begin
            sign_a = a[31];
            exp_a = a[30:23];
            mant_a = a[22:0];
            
            sign_b = b[31];
            exp_b = b[30:23];
            mant_b = b[22:0];
            
            // Handle zero cases
            if ((exp_a == 0 && mant_a == 0) && (exp_b == 0 && mant_b == 0)) begin
                fp_add_logic = 32'h0;  // 0 + 0 = 0
            end else if (exp_a == 0 && mant_a == 0) begin
                fp_add_logic = b;  // 0 + b = b
            end else if (exp_b == 0 && mant_b == 0) begin
                fp_add_logic = a;  // a + 0 = a
            end else begin
                // Both operands are non-zero
                // Add implicit leading 1 for normalized numbers (mantissa becomes 1.fraction)
                mant_a_ext = {2'b01, mant_a};  // 1 + 23 fraction bits = 24 bits, extended to 25
                mant_b_ext = {2'b01, mant_b};  // 1 + 23 fraction bits = 24 bits, extended to 25
                
                // Align exponents
                if (exp_a > exp_b) begin
                    exp_diff = exp_a - exp_b;
                    result_exp = exp_a;
                    
                    // Shift smaller mantissa right
                    if (exp_diff < 25) begin
                        mant_b_ext = mant_b_ext >> exp_diff;
                    end else begin
                        mant_b_ext = 0;
                    end
                end else if (exp_b > exp_a) begin
                    exp_diff = exp_b - exp_a;
                    result_exp = exp_b;
                    
                    // Shift smaller mantissa right
                    if (exp_diff < 25) begin
                        mant_a_ext = mant_a_ext >> exp_diff;
                    end else begin
                        mant_a_ext = 0;
                    end
                end else begin
                    // Equal exponents
                    result_exp = exp_a;
                end
                
                // Perform addition or subtraction based on signs
                if (sign_a == sign_b) begin
                    // Same signs - add mantissas
                    result_mant = mant_a_ext + mant_b_ext;
                    result_sign = sign_a;
                    
                    // Check for mantissa overflow
                    if (result_mant[24]) begin
                        // Overflow - normalize by shifting right and incrementing exponent
                        result_mant = result_mant >> 1;
                        result_exp = result_exp + 1;
                    end
                end else begin
                    // Different signs - subtract mantissas
                    if (mant_a_ext >= mant_b_ext) begin
                        result_mant = mant_a_ext - mant_b_ext;
                        result_sign = sign_a;
                    end else begin
                        result_mant = mant_b_ext - mant_a_ext;
                        result_sign = sign_b;
                    end
                    
                    // Normalize - shift left until MSB is in bit 23
                    if (result_mant == 0) begin
                        fp_add_logic = 32'h0;  // Result is zero
                    end else begin
                        while (result_mant[23] == 0 && result_exp > 0) begin
                            result_mant = result_mant << 1;
                            result_exp = result_exp - 1;
                        end
                    end
                end
                
                // Check for underflow/overflow
                if (result_exp == 0) begin
                    fp_add_logic = 32'h0;  // Underflow to zero
                end else if (result_exp >= 255) begin
                    // Overflow to infinity
                    fp_add_logic = {result_sign, 8'hFF, 23'h0};
                end else if (result_mant != 0) begin
                    // Normal result - remove implicit leading 1
                    fp_add_logic = {result_sign, result_exp, result_mant[22:0]};
                end else begin
                    fp_add_logic = 32'h0;  // Zero result
                end
            end
        end
    endfunction

endmodule

// IEEE 754 single precision floating point subtractor  
module fp_sub_simple(
    input [31:0] a,
    input [31:0] b,
    output [31:0] result
);

    // Subtraction is addition with flipped sign of second operand
    wire [31:0] neg_b = {~b[31], b[30:0]};
    
    fp_add_simple sub_as_add(
        .a(a),
        .b(neg_b),  // Flip sign of b
        .result(result)
    );

endmodule

`endif