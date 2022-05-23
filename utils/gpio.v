//output module
module gpio_o#(
    parameter WIDTH=32,
    parameter DEFAULT_VALUE=32'h0000_0000
)(
    input clk,
    input reset_n,

    input valid,
    output ready,

    input  [31:0] addr,
    output [31:0] rdata,
    input  [31:0] wdata,
    input  [ 3:0] wstrb,

    output [WIDTH-1:0] gpo
);

    reg [WIDTH-1:0] buff=DEFAULT_VALUE;
    reg hand_shake=1'b0;

    assign ready = valid & hand_shake;
    assign gpo = buff;

    assign rdata = 32'd0;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            hand_shake <= 1'b0;
            buff <= DEFAULT_VALUE;
        end 
        else begin
            if (valid) begin
                hand_shake <= 1'b1;
                buff <= wdata[WIDTH-1:0];
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

    input valid,
    output ready,
    input [31:0] addr,
    output [31:0] rdata,
    input [31:0] wdata,
    input [ 3:0] wstrb,

    input [WIDTH-1:0] gpi
);

    reg [WIDTH-1:0] buff=DEFAULT_VALUE;
    assign rdata = buff;

    reg hand_shake=1'b0;
    assign ready = valid & hand_shake;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            hand_shake <= 1'b0;
            buff <= DEFAULT_VALUE;
        end
        else begin
            if (valid) begin
                hand_shake <= 1'b1;
                buff <= gpi;
            end
            else begin
                hand_shake <= 1'b0;
            end
        end
    end

endmodule

