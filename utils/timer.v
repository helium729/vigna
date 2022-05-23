module timer(
    input clk,
    input resetn,

    input  valid,
    output ready,
    input  [31:0]  addr,
    output [31:0] rdata,
    input  [31:0] wdata,
    input  [3:0]  wstrb
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
            if (valid == 1'b1) begin
                hand_shake <= 1'b1;
            end else begin
                hand_shake <= 1'b0;
            end
        end
    end
    
    assign ready = hand_shake & valid;
    assign rdata = addr[2:0] == 3'd0 ? count[31:0] :
                   addr[2:0] == 3'd1 ? count[39:8] :
                   addr[2:0] == 3'd2 ? count[47:16] :
                   addr[2:0] == 3'd3 ? count[55:24] :
                   addr[2:0] == 3'd4 ? count[63:32] :
                   addr[2:0] == 3'd5 ? {8'd0, count[63:40]} :
                   addr[2:0] == 3'd6 ? {16'd0, count[63:48]} :
                   addr[2:0] == 3'd7 ? {24'd0, count[63:56]} : 0;


endmodule