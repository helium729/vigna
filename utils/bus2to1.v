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

// Arbitration state and control
reg [1:0] arb_state;
reg [1:0] arb_next_state;
reg grant_m1, grant_m2;

// Output buffering for better timing
reg [31:0] m1_rdata_reg, m2_rdata_reg;
reg m1_rdata_valid, m2_rdata_valid;

// Round-robin arbitration counter for fairness
reg fair_toggle;

// Arbitration logic - improved with round-robin fairness
always @(*) begin
    arb_next_state = arb_state;
    grant_m1 = 1'b0;
    grant_m2 = 1'b0;
    
    case (arb_state)
        2'b00: begin // IDLE state
            if (m1_valid && m2_valid) begin
                // Both requesting - use fair arbitration
                if (fair_toggle) begin
                    arb_next_state = 2'b10; // Grant M2
                    grant_m2 = 1'b1;
                end else begin
                    arb_next_state = 2'b01; // Grant M1
                    grant_m1 = 1'b1;
                end
            end else if (m1_valid) begin
                arb_next_state = 2'b01; // Grant M1
                grant_m1 = 1'b1;
            end else if (m2_valid) begin
                arb_next_state = 2'b10; // Grant M2
                grant_m2 = 1'b1;
            end
        end
        2'b01: begin // M1 granted
            grant_m1 = 1'b1;
            if (m1_valid && s_ready) begin
                arb_next_state = 2'b00; // Transaction complete
            end else if (!m1_valid) begin
                arb_next_state = 2'b00; // M1 released
            end
        end
        2'b10: begin // M2 granted
            grant_m2 = 1'b1;
            if (m2_valid && s_ready) begin
                arb_next_state = 2'b00; // Transaction complete
            end else if (!m2_valid) begin
                arb_next_state = 2'b00; // M2 released
            end
        end
        default: begin
            arb_next_state = 2'b00;
        end
    endcase
end

// Sequential logic - using posedge for better timing
always @(posedge clk) begin
    if (!resetn) begin
        arb_state <= 2'b00;
        fair_toggle <= 1'b0;
        m1_rdata_reg <= 32'h0;
        m2_rdata_reg <= 32'h0;
        m1_rdata_valid <= 1'b0;
        m2_rdata_valid <= 1'b0;
    end else begin
        arb_state <= arb_next_state;
        
        // Update fairness toggle when both masters compete
        if (arb_state == 2'b00 && m1_valid && m2_valid) begin
            fair_toggle <= ~fair_toggle;
        end
        
        // Buffer read data to break combinational loops
        if (grant_m1 && s_ready && m1_valid && (m1_wstrb == 4'h0)) begin
            m1_rdata_reg <= s_rdata;
            m1_rdata_valid <= 1'b1;
        end else if (!m1_valid) begin
            m1_rdata_valid <= 1'b0;
        end
        
        if (grant_m2 && s_ready && m2_valid && (m2_wstrb == 4'h0)) begin
            m2_rdata_reg <= s_rdata;
            m2_rdata_valid <= 1'b1;
        end else if (!m2_valid) begin
            m2_rdata_valid <= 1'b0;
        end
    end
end

// Output assignments - fixed blocking issues
assign m1_ready = grant_m1 & s_ready;
assign m2_ready = grant_m2 & s_ready;

assign s_valid = (grant_m1 & m1_valid) | (grant_m2 & m2_valid);
assign s_addr  = grant_m1 ? m1_addr : 
                 grant_m2 ? m2_addr : 32'h0;
assign s_wdata = grant_m1 ? m1_wdata :
                 grant_m2 ? m2_wdata : 32'h0;
assign s_wstrb = grant_m1 ? m1_wstrb :
                 grant_m2 ? m2_wstrb : 4'h0;

// Fixed read data assignments - no more combinational loops
assign m1_rdata = m1_rdata_valid ? m1_rdata_reg : 32'h0;
assign m2_rdata = m2_rdata_valid ? m2_rdata_reg : 32'h0;

endmodule