
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
            ready     <= 1'b1;
        end else begin
            case (state)
                0: begin
                    if (valid) begin
                        ready <= 1'b0;
                        state <= 1;
                        
                        // Simple FP operations (not fully IEEE 754 compliant)
                        if (is_fmv_w_x) begin
                            // Move integer to FP register (bit copy)
                            fp_result <= op1;
                        end else if (is_fmv_x_w) begin
                            // Move FP to integer register (bit copy)
                            fp_result <= op1;
                        end else if (is_fcvt_s_w) begin
                            // Convert signed integer to float (simplified)
                            // This is a simplified conversion - not full IEEE 754
                            if (op1 == 32'h0) begin
                                fp_result <= 32'h0;  // +0.0
                            end else if (op1[31]) begin
                                // Negative number - simplified conversion
                                fp_result <= {1'b1, 8'h80 + 8'd22, op1[22:0]};
                            end else begin
                                // Positive number - simplified conversion  
                                fp_result <= {1'b0, 8'h80 + 8'd22, op1[22:0]};
                            end
                        end else if (is_fcvt_w_s) begin
                            // Convert float to signed integer (simplified)
                            if (exp1 == 8'h0) begin
                                fp_result <= 32'h0;  // Zero or denormal -> 0
                            end else if (exp1 >= 8'h9E) begin
                                // Large number - saturate
                                fp_result <= sign1 ? 32'h80000000 : 32'h7FFFFFFF;
                            end else begin
                                // Simplified conversion - extract integer part
                                fp_result <= sign1 ? {1'b1, mant1[22:0], 8'h0} : {1'b0, mant1[22:0], 8'h0};
                            end
                        end else if (is_fadd || is_fsub) begin
                            $display("    [COPROC] FADD/FSUB operation detected: is_fadd=%b, is_fsub=%b", is_fadd, is_fsub);
                            $display("    [COPROC] Input: fp1=%08x, fp2=%08x", fp1, fp2);
                            $display("    [COPROC] Extracted: sign1=%b, exp1=%02x, mant1=%06x", sign1, exp1, mant1);
                            $display("    [COPROC] Extracted: sign2=%b, exp2=%02x, mant2=%06x", sign2, exp2, mant2);
                            
                            // Simplified IEEE 754 single precision add/subtract
                            // Handle special cases first
                            if (fp1 == 32'h0 && fp2 == 32'h0) begin
                                fp_result <= 32'h0;  // 0 + 0 = 0
                                $display("    [COPROC] Case: Both zero -> 0");
                            end else if (fp1 == 32'h0) begin
                                fp_result <= is_fsub ? (fp2 ^ 32'h80000000) : fp2;  // 0 + x = x, 0 - x = -x
                                $display("    [COPROC] Case: fp1 zero -> result=%08x", is_fsub ? (fp2 ^ 32'h80000000) : fp2);
                            end else if (fp2 == 32'h0) begin
                                fp_result <= fp1;  // x + 0 = x, x - 0 = x
                                $display("    [COPROC] Case: fp2 zero -> result=%08x", fp1);
                            end else if (exp1 == exp2) begin
                                $display("    [COPROC] Case: Same exponent");
                                // Same exponent - simplified arithmetic
                                if (is_fsub && (sign1 != sign2)) begin
                                    // Different signs for subtraction = addition
                                    fp_result <= {sign1, exp1, (mant1 + mant2)};
                                    $display("    [COPROC] FSUB diff signs -> ADD: result=%08x", {sign1, exp1, (mant1 + mant2)});
                                end else if (is_fadd && (sign1 == sign2)) begin
                                    // Same signs for addition
                                    fp_result <= {sign1, exp1, (mant1 + mant2)};
                                    $display("    [COPROC] FADD same signs: result=%08x", {sign1, exp1, (mant1 + mant2)});
                                end else begin
                                    // Subtraction of same signs or addition of different signs
                                    if (mant1 >= mant2) begin
                                        fp_result <= {sign1, exp1, (mant1 - mant2)};
                                        $display("    [COPROC] SUB case 1: result=%08x", {sign1, exp1, (mant1 - mant2)});
                                    end else begin
                                        fp_result <= {sign2, exp1, (mant2 - mant1)};
                                        $display("    [COPROC] SUB case 2: result=%08x", {sign2, exp1, (mant2 - mant1)});
                                    end
                                end
                            end else begin
                                $display("    [COPROC] Case: Different exponent");
                                // Different exponents - return the operand with larger magnitude
                                if (exp1 > exp2) begin
                                    fp_result <= fp1;
                                    $display("    [COPROC] exp1 > exp2 -> result=%08x", fp1);
                                end else begin
                                    fp_result <= is_fsub ? (fp2 ^ 32'h80000000) : fp2;
                                    $display("    [COPROC] exp2 >= exp1 -> result=%08x", is_fsub ? (fp2 ^ 32'h80000000) : fp2);
                                end
                            end
                        end else begin
                                    // Subtraction of same signs or addition of different signs
                                    if (mant1 >= mant2) begin
                                        fp_result <= {sign1, exp1, (mant1 - mant2)};
                                    end else begin
                                        fp_result <= {sign2, exp1, (mant2 - mant1)};
                                    end
                                end
                            end else begin
                                // Different exponents - return the operand with larger magnitude
                                if (exp1 > exp2) begin
                                    fp_result <= fp1;
                                end else begin
                                    fp_result <= is_fsub ? (fp2 ^ 32'h80000000) : fp2;
                                end
                            end
                        end else begin
                            // For other arithmetic operations, use simplified logic
                            fp_result <= 32'h3F800000; // Default to 1.0f
                        end
                    end else begin
                        ready <= 1'b1;
                    end
                end
                1: begin
                    // Complete operation
                    ready <= 1'b1;
                    state <= 0;
                end
                default: begin
                    state <= 0;
                    ready <= 1'b1;
                end
            endcase
        end
    end

endmodule

`endif