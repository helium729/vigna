`include "vigna_top.v"
`include "mem_sim.v"
`include "bus1to2.v"
`include "gpio.v"

module tb();

reg clk;
reg resetn;

wire valid;
wire ready;
wire [31:0] addr;
wire [31:0] rdata;
wire [31:0] wdata;
wire [3:0] wstrb;

wire s1valid;
wire s1ready;
wire [31:0] s1addr;
wire [31:0] s1rdata;
wire [31:0] s1wdata;
wire [3:0] s1wstrb;

wire s2valid;
wire s2ready;
wire [31:0] s2addr;
wire [31:0] s2rdata;
wire [31:0] s2wdata;
wire [3:0] s2wstrb;

wire [31:0] odata;

initial begin
    $dumpfile("tb.vcd");
    $dumpvars;
    clk = 1;
    resetn = 0;

    #25
    resetn = 1;

    #2000 $finish;
end

vigna_top uut(
    .clk(clk),
    .resetn(resetn),
    .valid(valid),
    .ready(ready),
    .addr(addr),
    .rdata(rdata),
    .wdata(wdata),
    .wstrb(wstrb)
);

bus1to2 #(
    .S1_ADDR_BEGIN(32'h0000_0000),
    .S1_ADDR_END(32'h0000_ffff),
    .S2_ADDR_BEGIN(32'h1000_0000),
    .S2_ADDR_END(32'h1000_ffff)
)
bus12(
    .mvalid(valid),
    .mready(ready),
    .maddr(addr),
    .mrdata(rdata),
    .mwdata(wdata),
    .mwstrb(wstrb),
    .s1valid(s1valid),
    .s1ready(s1ready),
    .s1addr(s1addr),
    .s1rdata(s1rdata),
    .s1wdata(s1wdata),
    .s1wstrb(s1wstrb),
    .s2valid(s2valid),
    .s2ready(s2ready),
    .s2addr(s2addr),
    .s2rdata(s2rdata),
    .s2wdata(s2wdata),
    .s2wstrb(s2wstrb)
);


mem_sim mut(
    .clk(clk),
    .resetn(resetn),
    .valid(s1valid),
    .ready(s1ready),
    .addr(s1addr),
    .rdata(s1rdata),
    .wdata(s1wdata),
    .wstrb(s1wstrb)
);

gpio_o gpword(
    .clk(clk),
    .reset_n(resetn),
    .valid(s2valid),
    .ready(s2ready),
    .addr(s2addr),
    .rdata(s2rdata),
    .wdata(s2wdata),
    .wstrb(s2wstrb),
    .gpo(odata)
);

always #5 clk = ~clk;

always @ (posedge clk) begin
    if (s2valid) begin
        $display("%c", s2wdata[7:0]);
    end
end

endmodule