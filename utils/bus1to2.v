module bus1to2#(
    parameter S1_ADDR_BEGIN=32'h0000_0000,
    parameter S1_ADDR_END  =32'h0fff_ffff,
    parameter S2_ADDR_BEGIN=32'h1000_0000,
    parameter S2_ADDR_END  =32'h1fff_ffff
)(
    input  mvalid,
    output mready,
    input  [31:0] maddr,
    output [31:0] mrdata,
    input  [31:0] mwdata,
    input  [ 3:0] mwstrb,

    output s1valid,
    input  s1ready,
    output [31:0] s1addr,
    input  [31:0] s1rdata,
    output [31:0] s1wdata,
    output [ 3:0] s1wstrb,

    output s2valid,
    input  s2ready,
    output [31:0] s2addr,
    input  [31:0] s2rdata,
    output [31:0] s2wdata,
    output [ 3:0] s2wstrb
);

    wire s1, s2;
    assign s1 = (maddr >= S1_ADDR_BEGIN) & (maddr <= S1_ADDR_END);
    assign s2 = (maddr >= S2_ADDR_BEGIN) & (maddr <= S2_ADDR_END);

    assign s1valid = s1 ? mvalid : 1'b0;
    assign s1addr  = s1 ? maddr  : 32'd0;
    assign s1wdata = s1 ? mwdata : 32'd0;
    assign s1wstrb = s1 ? mwstrb : 4'd0;

    assign s2valid = s2 ? mvalid : 1'b0;
    assign s2addr  = s2 ? maddr  : 32'd0;
    assign s2wdata = s2 ? mwdata : 32'd0;
    assign s2wstrb = s2 ? mwstrb : 4'd0;

    assign mready = (s1 | s2) ? (s2 ? s2ready : s1ready) : 1'b0;
    assign mrdata = (s1 | s2) ? (s2 ? s2rdata : s1rdata) : 32'd0;

endmodule