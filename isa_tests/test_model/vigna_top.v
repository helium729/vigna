`include "core.v"
`include "bus2to1.v"

module vigna_top#(
    parameter RESET_ADDR = 32'h0000_0000
    )(
    input clk,
    input resetn,

    output        valid,
    input         ready,
    output [31:0] addr,
    input  [31:0] rdata,
    output [31:0] wdata,
    output [ 3:0] wstrb
    );

wire i_valid;
wire i_ready;
wire [31:0] i_addr;
wire [31:0] i_rdata;
wire [31:0] i_wdata;
wire [3:0] i_wstrb;

wire d_valid;
wire d_ready;
wire [31:0] d_addr;
wire [31:0] d_rdata;
wire [31:0] d_wdata;
wire [3:0] d_wstrb;

//vigna core instant
vigna #(
    .RESET_ADDR(RESET_ADDR)
    )
    core_inst(
    .clk(clk),
    .resetn(resetn),
    .i_valid(i_valid),
    .i_ready(i_ready),
    .i_addr(i_addr),
    .i_rdata(i_rdata),
    .i_wdata(i_wdata),
    .i_wstrb(i_wstrb),
    .d_valid(d_valid),
    .d_ready(d_ready),
    .d_addr(d_addr),
    .d_rdata(d_rdata),
    .d_wdata(d_wdata),
    .d_wstrb(d_wstrb)
    );

//bus2to1 instant
bus2to1 b21(
    .clk(clk),
    .resetn(resetn),
    .m1_valid(i_valid),
    .m1_ready(i_ready),
    .m1_addr(i_addr),
    .m1_rdata(i_rdata),
    .m1_wdata(i_wdata),
    .m1_wstrb(i_wstrb),
    .m2_valid(d_valid),
    .m2_ready(d_ready),
    .m2_addr(d_addr),
    .m2_rdata(d_rdata),
    .m2_wdata(d_wdata),
    .m2_wstrb(d_wstrb),
    .s_valid(valid),
    .s_ready(ready),
    .s_addr(addr),
    .s_rdata(rdata),
    .s_wdata(wdata),
    .s_wstrb(wstrb)
    );
    


endmodule
