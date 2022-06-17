`include "vigna_core.v"
`include "utils/bus2to1.v"

module vigna_top(
    input clk,
    input resetn,

`ifdef VIGNA_TOP_BUS_BINDING
    output        m_valid,
    input         m_ready,
    output [31:0] m_addr,
    input  [31:0] m_rdata,
    output [31:0] m_wdata,
    output [ 3:0] m_wstrb
`else 
    output        i_valid,
    input         i_ready,
    output [31:0] i_addr,
    input  [31:0] i_rdata,

    output        d_valid,
    input         d_ready,
    output [31:0] d_addr,
    input  [31:0] d_rdata,
    output [31:0] d_wdata,
    output [ 3:0] d_wstrb
`endif 
    );

`ifdef VIGNA_TOP_BUS_BINDING

wire        int_i_valid;
wire        int_i_ready;
wire [31:0] int_i_addr;
wire [31:0] int_i_rdata;

wire        int_d_valid;
wire        int_d_ready;
wire [31:0] int_d_addr;
wire [31:0] int_d_rdata;
wire [31:0] int_d_wdata;
wire [ 3:0] int_d_wstrb;

//vigna core instant
vigna core_inst(
    .clk     (clk),
    .resetn  (resetn),
    .i_valid (int_i_valid),
    .i_ready (int_i_ready),
    .i_addr  (int_i_addr),
    .i_rdata (int_i_rdata),
    .d_valid (int_d_valid),
    .d_ready (int_d_ready),
    .d_addr  (int_d_addr),
    .d_rdata (int_d_rdata),
    .d_wdata (int_d_wdata),
    .d_wstrb (int_d_wstrb)
    );


//bus2to1 instant
bus2to1 b21(
    .clk      (clk),
    .resetn   (resetn),
    .m1_valid (int_i_valid),
    .m1_ready (int_i_ready),
    .m1_addr  (int_i_addr),
    .m1_rdata (int_i_rdata),
    .m1_wdata (32'd0),
    .m1_wstrb (4'd0),
    .m2_valid (int_d_valid),
    .m2_ready (int_d_ready),
    .m2_addr  (int_d_addr),
    .m2_rdata (int_d_rdata),
    .m2_wdata (int_d_wdata),
    .m2_wstrb (int_d_wstrb),
    .s_valid  (m_valid),
    .s_ready  (m_ready),
    .s_addr   (m_addr),
    .s_rdata  (m_rdata),
    .s_wdata  (m_wdata),
    .s_wstrb  (m_wstrb)
    );

`else
    vigna core_inst(
    .clk     (clk),
    .resetn  (resetn),
    .i_valid (i_valid),
    .i_ready (i_ready),
    .i_addr  (i_addr),
    .i_rdata (i_rdata),
    .d_valid (d_valid),
    .d_ready (d_ready),
    .d_addr  (d_addr),
    .d_rdata (d_rdata),
    .d_wdata (d_wdata),
    .d_wstrb (d_wstrb)
    );

`endif


endmodule
