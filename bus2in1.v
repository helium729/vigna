module bus2in1(
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

reg pull_down_reg = 1'b1;

always @ (posedge clk) begin
    if (!resetn) pull_down_reg <= 1'b1;
    else if (m1_valid && m1_ready) pull_down_reg <= 1'b0;
    else if (m2_valid && m2_ready) pull_down_reg <= 1'b0;
    else pull_down_reg <= 1'b1;
end

assign s_valid = pull_down_reg & (m1_valid | m2_valid);

//rs logic
wire rs_m1;
wire rs_m2;
wire rs_qm1;
wire rs_qm2;
assign rs_qm1 = ~(rs_qm2 & rs_m2);
assign rs_qm2 = ~(rs_qm1 & rs_m1);

assign rs_m1 = (!m1_valid && !m2_valid) ? 1'b1 : m1_valid;
assign rs_m2 = (!m1_valid && !m2_valid) ? 1'b1 : m2_valid;

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