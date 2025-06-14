//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Xuanyu Hu
// 
// Create Date: 2024/06/13
// Design Name: vigna_axi
// Module Name: vigna_axi
// Project Name: vigna
// Description: AXI4-Lite wrapper for Vigna CPU core
// 
// Dependencies: vigna_core.v
// 
// Revision: 
// Revision 1.0 - AXI4-Lite interface wrapper
// Additional Comments:
// This module provides an AXI4-Lite interface wrapper around the Vigna core
// while maintaining the same functionality as the simple interface version.
//////////////////////////////////////////////////////////////////////////////////

`ifndef VIGNA_AXI_V 
`define VIGNA_AXI_V

`timescale 1ns / 1ps
`include "vigna_conf.vh"
`include "vigna_core.v"

// AXI4-Lite wrapper for Vigna processor
module vigna_axi(
    input clk,
    input resetn,

    // AXI4-Lite Instruction Read Interface
    output reg        i_arvalid,
    input             i_arready,
    output reg [31:0] i_araddr,
    output     [2:0]  i_arprot,
    
    input             i_rvalid,
    output            i_rready,
    input      [31:0] i_rdata,
    input      [1:0]  i_rresp,

    // AXI4-Lite Data Read Interface
    output reg        d_arvalid,
    input             d_arready,
    output reg [31:0] d_araddr,
    output     [2:0]  d_arprot,
    
    input             d_rvalid,
    output            d_rready,
    input      [31:0] d_rdata,
    input      [1:0]  d_rresp,

    // AXI4-Lite Data Write Interface
    output reg        d_awvalid,
    input             d_awready,
    output reg [31:0] d_awaddr,
    output     [2:0]  d_awprot,
    
    output reg        d_wvalid,
    input             d_wready,
    output reg [31:0] d_wdata,
    output reg [3:0]  d_wstrb,
    
    input             d_bvalid,
    output            d_bready,
    input      [1:0]  d_bresp
);

// Simple interface signals to connect to vigna core
wire        core_i_valid;
reg         core_i_ready;
wire [31:0] core_i_addr;
reg  [31:0] core_i_rdata;

wire        core_d_valid;
reg         core_d_ready;
wire [31:0] core_d_addr;
reg  [31:0] core_d_rdata;
wire [31:0] core_d_wdata;
wire [3:0]  core_d_wstrb;

// Instantiate the Vigna core with simple interface
vigna vigna_core_inst(
    .clk(clk),
    .resetn(resetn),
    
    .i_valid(core_i_valid),
    .i_ready(core_i_ready),
    .i_addr(core_i_addr),
    .i_rdata(core_i_rdata),
    
    .d_valid(core_d_valid),
    .d_ready(core_d_ready),
    .d_addr(core_d_addr),
    .d_rdata(core_d_rdata),
    .d_wdata(core_d_wdata),
    .d_wstrb(core_d_wstrb)
);

// AXI4-Lite protocol constants
assign i_arprot = 3'b000; // Normal, non-secure, data access
assign d_arprot = 3'b000; // Normal, non-secure, data access
assign d_awprot = 3'b000; // Normal, non-secure, data access

// Instruction interface AXI4-Lite to simple conversion
// State machine for instruction read
reg [1:0] i_state;
parameter I_IDLE = 2'b00, I_ADDR = 2'b01, I_DATA = 2'b10;

always @(posedge clk) begin
    if (!resetn) begin
        i_arvalid <= 1'b0;
        i_araddr <= 32'h0;
        core_i_ready <= 1'b0;
        core_i_rdata <= 32'h0;
        i_state <= I_IDLE;
    end else begin
        
        // Ready signal follows the protocol: assert when data is available, deassert when valid goes low
        if (!core_i_valid && core_i_ready) begin
            core_i_ready <= 1'b0;
        end
        
        case (i_state)
            I_IDLE: begin
                if (core_i_valid && !core_i_ready) begin
                    i_arvalid <= 1'b1;
                    i_araddr <= core_i_addr;
                    i_state <= I_ADDR;
                end
            end
            I_ADDR: begin
                if (i_arready) begin
                    i_arvalid <= 1'b0;
                    i_state <= I_DATA;
                end
            end
            I_DATA: begin
                if (i_rvalid && !core_i_ready) begin
                    core_i_ready <= 1'b1;
                    core_i_rdata <= i_rdata;
                    i_state <= I_IDLE;
                end
            end
        endcase
    end
end

assign i_rready = (i_state == I_DATA);

// Data interface AXI4-Lite to simple conversion
// State machine for data read/write
reg [2:0] d_state;
parameter D_IDLE = 3'b000, D_READ_ADDR = 3'b001, D_READ_DATA = 3'b010, 
          D_WRITE_ADDR = 3'b011, D_WRITE_DATA = 3'b100, D_WRITE_RESP = 3'b101;

always @(posedge clk) begin
    if (!resetn) begin
        d_arvalid <= 1'b0;
        d_araddr <= 32'h0;
        d_awvalid <= 1'b0;
        d_awaddr <= 32'h0;
        d_wvalid <= 1'b0;
        d_wdata <= 32'h0;
        d_wstrb <= 4'h0;
        core_d_ready <= 1'b0;
        core_d_rdata <= 32'h0;
        d_state <= D_IDLE;
    end else begin
        
        // Ready signal follows the protocol: assert when data is available, deassert when valid goes low
        if (!core_d_valid && core_d_ready) begin
            core_d_ready <= 1'b0;
        end
        
        case (d_state)
            D_IDLE: begin
                if (core_d_valid && !core_d_ready) begin
                    if (core_d_wstrb == 4'h0) begin
                        // Read operation
                        d_arvalid <= 1'b1;
                        d_araddr <= core_d_addr;
                        d_state <= D_READ_ADDR;
                    end else begin
                        // Write operation
                        d_awvalid <= 1'b1;
                        d_awaddr <= core_d_addr;
                        d_wvalid <= 1'b1;
                        d_wdata <= core_d_wdata;
                        d_wstrb <= core_d_wstrb;
                        d_state <= D_WRITE_ADDR;
                    end
                end
            end
            D_READ_ADDR: begin
                if (d_arready) begin
                    d_arvalid <= 1'b0;
                    d_state <= D_READ_DATA;
                end
            end
            D_READ_DATA: begin
                if (d_rvalid && !core_d_ready) begin
                    core_d_ready <= 1'b1;
                    core_d_rdata <= d_rdata;
                    d_state <= D_IDLE;
                end
            end
            D_WRITE_ADDR: begin
                if (d_awready && d_wready) begin
                    // Both address and data channels are ready, proceed to response state
                    d_awvalid <= 1'b0;
                    d_wvalid <= 1'b0;
                    d_state <= D_WRITE_RESP;
                end
                // Wait for both d_awready and d_wready to be asserted
            end
            D_WRITE_DATA: begin
                if (d_awready && d_awvalid) begin
                    d_awvalid <= 1'b0;
                end
                if (d_wready && d_wvalid) begin
                    d_wvalid <= 1'b0;
                end
                if (!d_awvalid && !d_wvalid) begin
                    d_state <= D_WRITE_RESP;
                end
            end
            D_WRITE_RESP: begin
                if (d_bvalid && !core_d_ready) begin
                    core_d_ready <= 1'b1;
                    d_state <= D_IDLE;
                end
            end
        endcase
    end
end

assign d_rready = (d_state == D_READ_DATA);
assign d_bready = (d_state == D_WRITE_RESP);

endmodule

`endif