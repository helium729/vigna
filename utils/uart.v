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
    output reg  uart_txd
);

    reg [7:0] r_fifo  [31:0];
    reg [7:0] t_fifo [31:0];
    reg [4:0] r_fifo_head_pointer;
    reg [4:0] t_fifo_head_pointer;
    reg [4:0] r_fifo_tail_pointer;
    reg [4:0] t_fifo_tail_pointer;
    
    wire [4:0] r_fifo_head_pointer_next;
    wire [4:0] t_fifo_head_pointer_next;

    assign t_fifo_head_pointer_next = t_fifo_head_pointer + 1;
    assign r_fifo_head_pointer_next = r_fifo_head_pointer + 1;
    
    //control signals
    wire r_fifo_empty;
    wire r_fifo_full;
    wire t_fifo_empty;
    wire t_fifo_full;
    wire [31:0] ctrl_sig;
    assign r_fifo_empty = (r_fifo_head_pointer == r_fifo_tail_pointer);
    assign r_fifo_full  = (r_fifo_tail_pointer == r_fifo_head_pointer_next);
    assign t_fifo_empty = (t_fifo_head_pointer == t_fifo_tail_pointer);
    assign t_fifo_full  = (t_fifo_tail_pointer == t_fifo_head_pointer_next);
    assign ctrl_sig = {27'd0, r_fifo_empty, r_fifo_full, t_fifo_empty, t_fifo_full};

    wire [31:0] r_uart_data;
    wire [31:0] t_uart_data;

    //bus state machine
    reg hand_shake;
    always @(posedge clk) begin
        if(resetn == 0) begin
            hand_shake <= 0;
        end else begin
            if (s_valid) begin
                hand_shake <= 1'b1;
            end else if (hand_shake) begin
                r_fifo_tail_pointer <= r_fifo_tail_pointer + 1;
                hand_shake <= 0;
            end
        end 
    end
    assign s_ready = hand_shake & s_valid;
    assign s_rdata = s_addr[3:0] == 4'b0000 ? ctrl_sig :
                     s_addr[3:0] == 4'b0100 ? r_uart_data :
                     s_addr[3:0] == 4'b1000 ? t_uart_data : 0;

    //receive state machine
    reg [1:0] r_state;
    reg [31:0] r_counter;
    reg [3:0] r_bit_count;
    reg [7:0] r_temp_data;
    always @ (posedge clk) begin
        if (!resetn) begin
            r_state <= 2'b00;
            r_counter <= 0;
            r_fifo_head_pointer <= 0;
        end
        else begin
            if (r_state == 2'b00) begin 
                if (uart_rxd == 1'b0) begin
                    r_state <= 2'b01;
                    r_counter <= 0;
                end
            end
            else if (r_state == 2'b01) begin 
                r_counter <= r_counter + 32'd1;
                if (r_counter == (CLK_FREQ/BAUD_RATE)/2) begin
                    r_state <= 2'b11;
                    r_counter <= 0;
                    r_bit_count <= 0;
                    r_temp_data <= 0;
                end
            end
            else if (r_state == 2'b11) begin 
                if (r_counter == (CLK_FREQ/BAUD_RATE)) begin
                    r_counter <= 0;
                    if (r_bit_count < 8) r_temp_data[r_bit_count] <= uart_rxd;
                    if (r_bit_count == 9) begin
                        r_state <= 2'b10;
                    end
                    r_bit_count <= r_bit_count + 1;
                end
                else r_counter <= r_counter + 1;
            end
            else if (r_state == 2'b10) begin 
                if (!r_fifo_full) begin
                    r_fifo[r_fifo_head_pointer] <= r_temp_data;
                    r_fifo_head_pointer <= r_fifo_head_pointer_next;
                end
                r_state <= 2'b00;
            end
        end
    end
    assign r_uart_data = r_fifo_empty ? 32'd0 : r_fifo[r_fifo_tail_pointer];

    //transmit state machine
    reg [1:0] t_state;
    reg [31:0] t_counter;
    reg [3:0] t_bit_count;
    wire [7:0] t_temp_data;
    assign t_temp_data = t_fifo_empty ? 8'b0 : t_fifo[t_fifo_tail_pointer];
    always @ (posedge clk) begin
        if (!resetn) begin
            uart_txd <= 1'b1;
            t_state <= 2'b00;
            t_counter <= 0;
            t_fifo_tail_pointer <= 0;
        end
        else begin
            if (t_state == 2'b00) begin
                if (!t_fifo_empty) begin
                    t_state <= 2'b01;
                    t_counter <= 0;
                    uart_txd <= 1'b0;
                end
                else
                    uart_txd <= 1'b1;
            end
            else if (t_state == 2'b01) begin
                if (t_counter == (CLK_FREQ/BAUD_RATE)) begin
                    t_counter <= 0;
                    if (t_bit_count < 8) uart_txd <= t_temp_data[t_bit_count];
                    if (t_bit_count == 8) begin
                        t_state <= 2'b11;
                        t_fifo_tail_pointer <= t_fifo_tail_pointer + 1;
                        uart_txd <= 1'b1;
                    end
                    t_bit_count <= t_bit_count + 1;
                end
                else t_counter <= t_counter + 1;
            end
        end
    end
    

    
endmodule