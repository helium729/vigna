//output module
module gpio_o#(
    parameter WIDTH=32,
    parameter DEFAULT_VALUE=32'h0000_0000
)(
    input clk,
    input reset_n,

    input  s_valid,
    output s_ready,
    input  [31:0] s_addr,
    output [31:0] s_rdata,
    input  [31:0] s_wdata,
    input  [ 3:0] s_wstrb,

    output [WIDTH-1:0] gpo
);

    reg [WIDTH-1:0] buff=DEFAULT_VALUE;
    reg hand_shake=1'b0;

    assign s_ready = s_valid & hand_shake;
    assign gpo = buff;

    assign s_rdata = 32'd0;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            hand_shake <= 1'b0;
            buff <= DEFAULT_VALUE;
        end 
        else begin
            if (s_valid) begin
                hand_shake <= 1'b1;
                buff <= s_wdata[WIDTH-1:0];
            end 
            else begin
                hand_shake <= 1'b0;
            end
        end
    end

endmodule

//input module
module gpio_i#(
    parameter WIDTH=32,
    parameter DEFAULT_VALUE=32'h0000_0000
)
(
    input clk,
    input reset_n,

    input  s_valid,
    output s_ready,
    input  [31:0] s_addr,
    output [31:0] s_rdata,
    input  [31:0] s_wdata,
    input  [ 3:0] s_wstrb,

    input [WIDTH-1:0] gpi
);

    reg [WIDTH-1:0] buff=DEFAULT_VALUE;
    assign s_rdata = buff;

    reg hand_shake=1'b0;
    assign s_ready = s_valid & hand_shake;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            hand_shake <= 1'b0;
            buff <= DEFAULT_VALUE;
        end
        else begin
            if (s_valid) begin
                hand_shake <= 1'b1;
                buff <= gpi;
            end
            else begin
                hand_shake <= 1'b0;
            end
        end
    end

endmodule

