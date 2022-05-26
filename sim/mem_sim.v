module mem_sim(
    input clk,
    input resetn,

    input         valid,
    output        ready,
    input  [31:0] addr,
    output [31:0] rdata,
    input  [31:0] wdata,
    input  [ 3:0] wstrb
);

initial begin
    //$readmemh("mem.hex", mem_data, 0, 1024);
end

reg [7:0] mem_data[4095:0];

wire [11:0] true_addr = addr[11:0];

reg [1:0] state;

assign ready = state == 2'b01;    

assign rdata = {mem_data[true_addr+3], mem_data[true_addr+2], mem_data[true_addr+1], mem_data[true_addr]};

//state machine
always @(posedge clk) begin
    if (resetn == 1'b0) begin
        state <= 2'b00;
    end 
    else begin
        if (state == 0) begin
            if (valid == 1'b1) begin
                state <= 2'b01;
                if (wstrb == 4'b1111) begin 
                    mem_data[true_addr+3] <= wdata[31:24];
                    mem_data[true_addr+2] <= wdata[23:16];
                    mem_data[true_addr+1] <= wdata[15:8];
                    mem_data[true_addr] <= wdata[7:0];
                end
                else if (wstrb == 4'b0011) begin
                    mem_data[true_addr+1] <= wdata[15:8];
                    mem_data[true_addr] <= wdata[7:0];
                end
                else if (wstrb == 4'b0001) begin 
                    mem_data[true_addr] <= wdata[7:0];
                end
            end
        end
        else state <= 2'b00;
    end
end

endmodule