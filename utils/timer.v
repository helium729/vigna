module timer(
    input clk,
    input resetn,

    input  s_valid,
    output s_ready,
    input  [31:0] s_addr,
    output [31:0] s_rdata,
    input  [31:0] s_wdata,
    input  [3:0]  s_wstrb
);

    reg [63:0] count, hand_shake;

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            count <= 0;
        end else begin
            count <= count + 64'd1;
        end
    end

    always @(posedge clk) begin
        if (resetn == 1'b0) begin
            hand_shake <= 1'b0;
        end else begin
            if (s_valid == 1'b1) begin
                hand_shake <= 1'b1;
            end else begin
                hand_shake <= 1'b0;
            end
        end
    end
    
    assign s_ready = hand_shake & s_valid;
    assign s_rdata = s_addr[2:0] == 3'd0 ? count[31:0] :
                     s_addr[2:0] == 3'd1 ? count[39:8] :
                     s_addr[2:0] == 3'd2 ? count[47:16] :
                     s_addr[2:0] == 3'd3 ? count[55:24] :
                     s_addr[2:0] == 3'd4 ? count[63:32] :
                     s_addr[2:0] == 3'd5 ? {8'd0, count[63:40]} :
                     s_addr[2:0] == 3'd6 ? {16'd0, count[63:48]} :
                     s_addr[2:0] == 3'd7 ? {24'd0, count[63:56]} : 0;


endmodule