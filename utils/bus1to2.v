module bus1to2#(
    parameter S1_ADDR_BEGIN=32'h0000_0000,
    parameter S1_ADDR_END  =32'h0fff_ffff,
    parameter S2_ADDR_BEGIN=32'h1000_0000,
    parameter S2_ADDR_END  =32'h1fff_ffff
)(
    input  m_valid,
    output m_ready,
    input  [31:0] m_addr,
    output [31:0] m_rdata,
    input  [31:0] m_wdata,
    input  [ 3:0] m_wstrb,

    output s1_valid,
    input  s1_ready,
    output [31:0] s1_addr,
    input  [31:0] s1_rdata,
    output [31:0] s1_wdata,
    output [ 3:0] s1_wstrb,

    output s2_valid,
    input  s2_ready,
    output [31:0] s2_addr,
    input  [31:0] s2_rdata,
    output [31:0] s2_wdata,
    output [ 3:0] s2_wstrb
);

    wire s1, s2;
    assign s1 = (m_addr >= S1_ADDR_BEGIN) & (m_addr <= S1_ADDR_END);
    assign s2 = (m_addr >= S2_ADDR_BEGIN) & (m_addr <= S2_ADDR_END);

    assign s1_valid = s1 ? m_valid : 1'b0;
    assign s1_addr  = s1 ? m_addr  : 32'd0;
    assign s1_wdata = s1 ? m_wdata : 32'd0;
    assign s1_wstrb = s1 ? m_wstrb : 4'd0;

    assign s2_valid = s2 ? m_valid : 1'b0;
    assign s2_addr  = s2 ? m_addr  : 32'd0;
    assign s2_wdata = s2 ? m_wdata : 32'd0;
    assign s2_wstrb = s2 ? m_wstrb : 4'd0;

    assign m_ready = (s1 | s2) ? (s2 ? s2_ready : s1_ready) : 1'b0;
    assign m_rdata = (s1 | s2) ? (s2 ? s2_rdata : s1_rdata) : 32'd0;

endmodule