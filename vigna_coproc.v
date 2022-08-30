
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

`endif 