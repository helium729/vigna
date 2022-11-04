module bus2to1(
    input clk,
    input resetn,

    input         m1_valid,
    output        m1_ready,
    input  [31:0] m1_addr,
    output [31:0] m1_rdata,
    input  [31:0] m1_wdata,
    input  [ 3:0] m1_wstrb,

    input         m2_valid,
    output        m2_ready,
    input  [31:0] m2_addr,
    output [31:0] m2_rdata,
    input  [31:0] m2_wdata,
    input  [ 3:0] m2_wstrb,

    output        s_valid,
    input         s_ready,
    output [31:0] s_addr,
    input  [31:0] s_rdata,
    output [31:0] s_wdata,
    output [ 3:0] s_wstrb
);

reg [1:0] state;
reg rotate;

assign s_valid = state != 2'b00;

always @ (posedge clk) begin
    if (resetn == 1'b0) begin
        state <= 2'b00;
        rotate <= 1'b0;
    end else begin
        if (s_ready) begin
            case (state)
                2'b00: begin
                    if (m1_valid & m2_valid) begin
                        if (rotate) begin
                            state <= 2'b10;
                        end else begin
                            state <= 2'b01;
                        end
                        rotate <= ~rotate;
                    end
                    else if (m1_valid) begin
                        state <= 2'b01;
                    end
                    else if (m2_valid) begin
                        state <= 2'b10;
                    end
                end
                2'b01: begin
                    if (m2_valid) begin
                        state <= 2'b10;
                    end else begin
                        state <= 2'b00;
                    end
                end
                2'b10: begin
                    if (m1_valid) begin
                        state <= 2'b01;
                    end else begin
                        state <= 2'b00;
                    end
                end
                2'b11: begin
                    //fault
                    state <= 2'b00;
                end
            endcase
        end
    end
end

assign rs_qm1 = state == 2'b01;
assign rs_qm2 = state == 2'b10;

assign m1_ready = rs_qm1 ? s_ready : 1'b0;
assign m2_ready = rs_qm2 ? s_ready : 1'b0;
assign s_addr   = rs_qm1 ? m1_addr :
                  rs_qm2 ? m2_addr : 32'h0;
assign m1_rdata = rs_qm1 ? s_rdata : m1_rdata;
assign m2_rdata = rs_qm2 ? s_rdata : m2_rdata;
assign s_wdata  = rs_qm1 ? m1_wdata :
                  rs_qm2 ? m2_wdata : 32'h0;
assign s_wstrb  = rs_qm1 ? m1_wstrb : 
                  rs_qm2 ? m2_wstrb : 4'h0;

endmodule