module uartlite #(
    parameter BAUD_RATE = 115200,
    parameter CLK_FREQ  = 100000000
)
(
    input clk,
    input resetn,

    input  s_valid,
    output s_ready,
    input  [31:0] s_addr,
    output [31:0] s_rdata,
    input  [31:0] s_wdata,
    input  [ 4:0] s_wstrb,

    input  wire uart_rxd,
    output wire uart_txd
);

    reg [31:0] receive_fifo;
    reg [31:0] transmit_fifo;

    //receive state machine

    //transmit state machine

    //ToDo

    
endmodule