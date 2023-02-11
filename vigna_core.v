//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Xuanyu Hu
// 
// Create Date: 2022/04/27 16:39:33
// Design Name: vigna_v1
// Module Name: vigna
// Project Name: vigna
// Description: A simple RV32I CPU core
// 
// Dependencies: none
// 
// Revision: 
// Revision 1.09
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef VIGNA_CORE_V 
`define VIGNA_CORE_V

`timescale 1ns / 1ps
`include "vigna_conf.vh"

`ifdef VIGNA_CORE_M_EXTENSION
`include "vigna_coproc.v"
`endif 

//vigna top module
module vigna(
    input clk,
    input resetn,

    output            i_valid,
    input             i_ready,
    output     [31:0] i_addr,
    input      [31:0] i_rdata,

    output reg        d_valid,
    input             d_ready,
    output reg [31:0] d_addr,
    input      [31:0] d_rdata,
    output reg [31:0] d_wdata,
    output reg [ 3:0] d_wstrb
`ifdef VIGNA_M_EXTENSION
    ,
    output        mext_valid,
    input         mext_ready,
    output [2:0]  mext_func,
    output [31:0] mext_op1,
    output [31:0] mext_op2,
    input  [31:0] mext_result
`endif 
);

//program counter
reg  [31:0] pc;
wire [31:0] pc_next;

//part 1: fetching unit
reg  [31:0] inst;
wire [31:0] inst_addr;
reg  [ 1:0] fetch_state;
reg  internal_valid;

wire fetched, fetch_received;
assign fetched = fetch_state == 3;



//assign inst = i_ready ? i_rdata : inst;
assign inst_addr = i_addr;
assign i_addr = pc;

assign i_valid = internal_valid;

always @ (posedge clk) begin
    //reset logic
    if (!resetn) begin
        pc              <= `VIGNA_CORE_RESET_ADDR;
        fetch_state     <= 0;
        internal_valid  <= 0;
    end else begin
        //fetch logic
        case (fetch_state)
            0: begin
                internal_valid     <= 1;
                fetch_state <= 1;
            end
            1: begin
                if (i_ready) begin
                    inst            <= i_rdata;
                    internal_valid  <= 0;
                    fetch_state     <= 3;
                end
            end
            3: begin
                if (fetch_received) begin
                    internal_valid  <= 1;
                    pc              <= pc_next;
                    fetch_state     <= 1;
                end
            end
            default: begin
                internal_valid  <= 0;
                fetch_state     <= 0;
            end
        endcase
    end
end

//decode logic
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;

assign opcode = inst[6:0];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign rd     = inst[11:7];
assign rs1    = inst[19:15];
assign rs2    = inst[24:20];

//r
wire is_add, is_sub, is_sll, is_slt, is_sltu, is_xor, is_srl, is_sra, is_or, is_and;
//i
wire is_addi, is_slli, is_slti, is_sltiu, is_xori, is_srli, is_srai, is_ori, is_andi;
wire is_jalr, is_lb, is_lh, is_lw, is_lbu, is_lhu;
//s
wire is_sb, is_sh, is_sw;
//b
wire is_beq, is_bne, is_blt, is_bge, is_bltu, is_bgeu;
//u
wire is_lui, is_auipc;
//j
wire is_jal;

wire funct7_zero, funct7_sub_sra;
assign funct7_zero = funct7 == 0;
assign funct7_sub_sra = funct7 == 7'b0100000;

wire i_type_alu, i_type_jalr, i_type_load;
assign i_type_alu  = opcode == 7'b0010011;
assign i_type_jalr = opcode == 7'b1100111;
assign i_type_load = opcode == 7'b0000011;

wire r_type, i_type, s_type, u_type, b_type, j_type;
assign r_type = opcode == 7'b0110011;
assign i_type = i_type_alu || i_type_jalr || i_type_load;
assign s_type = opcode == 7'b0100011;
assign u_type = is_lui || is_auipc;
assign b_type = opcode == 7'b1100011;
assign j_type = opcode == 7'b1101111;

wire [31:0] imm;
assign imm[31]    = inst[31];
assign imm[30:20] = u_type           ? inst[30:20] : {11{inst[31]}};
assign imm[19:12] = u_type || j_type ? inst[19:12] : {8{inst[31]}};
assign imm[11]    = u_type           ? 1'b0 :
                    j_type           ? inst[20] :
                    b_type           ? inst[7] : inst[31];
assign imm[10:5]  = u_type           ? 6'b000000 : inst[30:25];
assign imm[4:1]   = u_type           ? 5'b00000 :
                    u_type           ? 4'b0000 :
                    i_type || j_type ? inst[24:21] : inst[11:8];
assign imm[0]     = i_type           ? inst[20] :
                    s_type           ? inst[7] : 1'b0;


wire [4:0] shamt;
assign shamt = inst[24:20];

//r type
assign is_add  = funct3 == 3'b000 && funct7_zero    && r_type;
assign is_sub  = funct3 == 3'b000 && funct7_sub_sra && r_type;
assign is_sll  = funct3 == 3'b001 && funct7_zero    && r_type;
assign is_slt  = funct3 == 3'b010 && funct7_zero    && r_type;
assign is_sltu = funct3 == 3'b011 && funct7_zero    && r_type;
assign is_xor  = funct3 == 3'b100 && funct7_zero    && r_type;
assign is_srl  = funct3 == 3'b101 && funct7_zero    && r_type;
assign is_sra  = funct3 == 3'b101 && funct7_sub_sra && r_type;
assign is_or   = funct3 == 3'b110 && funct7_zero    && r_type;
assign is_and  = funct3 == 3'b111 && funct7_zero    && r_type;

//i type
assign is_addi  = i_type_alu  && funct3 == 3'b000;
assign is_slli  = i_type_alu  && funct3 == 3'b001;
assign is_slti  = i_type_alu  && funct3 == 3'b010;
assign is_sltiu = i_type_alu  && funct3 == 3'b011;
assign is_xori  = i_type_alu  && funct3 == 3'b100;
assign is_srli  = i_type_alu  && funct3 == 3'b101 && funct7_zero;
assign is_srai  = i_type_alu  && funct3 == 3'b101 && funct7_sub_sra;
assign is_ori   = i_type_alu  && funct3 == 3'b110;
assign is_andi  = i_type_alu  && funct3 == 3'b111;
assign is_jalr  = i_type_jalr && funct3 == 3'b000;
assign is_lb    = i_type_load && funct3 == 3'b000;
assign is_lh    = i_type_load && funct3 == 3'b001;
assign is_lw    = i_type_load && funct3 == 3'b010;
assign is_lbu   = i_type_load && funct3 == 3'b100;
assign is_lhu   = i_type_load && funct3 == 3'b101;

wire is_load;
assign is_load = is_lb || is_lh || is_lw || is_lbu || is_lhu;

//s type
assign is_sb = funct3 == 3'b000 && s_type;
assign is_sh = funct3 == 3'b001 && s_type;
assign is_sw = funct3 == 3'b010 && s_type;

//b type
assign is_beq  = funct3 == 3'b000 && b_type;
assign is_bne  = funct3 == 3'b001 && b_type;
assign is_blt  = funct3 == 3'b100 && b_type;
assign is_bge  = funct3 == 3'b101 && b_type;
assign is_bltu = funct3 == 3'b110 && b_type;
assign is_bgeu = funct3 == 3'b111 && b_type;

//u type
assign is_lui   = opcode == 7'b0110111;
assign is_auipc = opcode == 7'b0010111;

//j type
assign is_jal = j_type;

`ifdef VIGNA_CORE_M_EXTENSION
//m type
wire is_m_coproc;
assign is_m_coproc = r_type && funct7 == 7'b0000001;
`endif

//rs1 from reg
wire [31:0] rs1_val;
//rs2 from reg
wire [31:0] rs2_val;

//cpu regs
`ifdef VIGNA_CORE_E_EXTENSION
    reg [31:0] cpu_regs[15:1];
    assign rs1_val = rs1 == 0 ? 32'd0 : cpu_regs[rs1[3:0]];
    assign rs2_val = rs2 == 0 ? 32'd0 : cpu_regs[rs2[3:0]];
`else
    reg [31:0] cpu_regs[31:1];
    assign rs1_val = rs1 == 0 ? 32'd0 : cpu_regs[rs1];
    assign rs2_val = rs2 == 0 ? 32'd0 : cpu_regs[rs2];
`endif

wire [31:0] op1, op2;
assign op1 = is_jal || u_type   ? imm : rs1_val;
assign op2 = r_type || b_type   ? rs2_val :
             is_auipc || j_type ? inst_addr :
             is_slli || is_srli ? {27'b0, shamt} :
             is_lui             ? 32'd0 : imm; 

//backend state
reg [3:0] exec_state;

//source regex_jump
reg [31:0] d1, d2, d3;

//result
wire [31:0] dr;

//write back
`ifdef VIGNA_CORE_E_EXTENSION
    reg [3:0] wb_reg;
`else
    reg [4:0] wb_reg;
`endif 

    reg [4:0] shift_cnt;
    reg [2:0] l_sll_srl_sra;
    wire [31:0] shift_val;
    wire is_shift;
    assign is_shift = is_sll || is_slli || is_srl || is_srli || is_sra || is_srai;
`ifdef VIGNA_CORE_TWO_STAGE_SHIFT
    wire first_shift_stage;
    assign first_shift_stage = shift_cnt[4:2] != 0;
`endif

wire cmp_eq;
wire abs_lt;
wire signed_lt;
wire unsigned_lt;
assign cmp_eq      = d1 == d2;
assign abs_lt      = d1[30:0] < d2[30:0];
assign signed_lt   = (d1[31] ^ d2[31]) ? d1[31] : abs_lt;
assign unsigned_lt = (d1[31] ^ d2[31]) ? d2[31] : abs_lt;

wire [31:0] add_result;
`ifdef VIGNA_CORE_PRELOAD_NEGATIVE
assign add_result = d1 + d2 + is_sub;
`else
assign add_result = d1 + (is_sub ? {~d2 + 32'd1} : d2);
`endif

//alu comb logic
assign dr = 
    is_add || is_addi || is_jal || s_type
     || is_jalr || is_load || u_type
     || is_sub                      ? add_result : 
    is_slt || is_slti || is_blt     ? {31'd0, signed_lt} :
    is_bge                          ? {31'd0, ~signed_lt} :
    is_sltu || is_sltiu || is_bltu  ? {31'd0, unsigned_lt} : 
    is_bgeu                         ? {31'd0, ~unsigned_lt} :
    is_xor || is_xori               ? d1 ^ d2 :  
    is_or || is_ori                 ? d1 | d2 : 
    is_and || is_andi               ? d1 & d2 : 
    is_beq                          ? {31'd0, cmp_eq} : 
    is_bne                          ? {31'd0, ~cmp_eq} : 32'd0;

assign shift_val =
`ifdef  VIGNA_CORE_TWO_STAGE_SHIFT
    l_sll_srl_sra[2]  ? (first_shift_stage ? {d3[27:0], 4'b0000} : {d3[30:0], 1'b0}) :
    l_sll_srl_sra[1]  ? (first_shift_stage ? {4'b0000, d3[31:4]} : {1'b0, d3[31:1]}) :
    l_sll_srl_sra[0]  ? (first_shift_stage ? {{4{d3[31]}}, d3[31:4]} : {d3[31], d3[31:1]}) : 32'd0;
`else 
    l_sll_srl_sra[2]  ? {d3[30:0], 1'b0} :
    l_sll_srl_sra[1]  ? {1'b0, d3[31:1]} :
    l_sll_srl_sra[0]  ? {d3[31], d3[31:1]} : 32'd0;
`endif

wire [31:0] inst_add_result;
assign inst_add_result = inst_addr + (b_type ? imm: 32'd4);

reg ex_branch;
reg ex_jump;
reg [3:0] ex_type;
reg [3:0] ls_strb;
reg ls_sign_extend;

assign pc_next =  ex_jump           ? dr :
                  ex_branch & dr[0] ? d3 : pc + 32'd4;

reg write_mem;

wire is_jump = is_jal || is_jalr;

`ifdef VIGNA_CORE_M_EXTENSION
    reg m_valid;
    wire m_ready;
    wire [31:0] m_result;
    vigna_m_ext mul_unit(
        .clk(clk),
        .resetn(resetn),
        .valid(m_valid),
        .ready(m_ready),
        .op1(d1),
        .op2(d2),
        .result(m_result),
        .func(d3[2:0])
    );
`endif


//part2. executon unit
always @ (posedge clk) begin
    //reset logic
    if (!resetn) begin
        d_valid        <= 0;
        d_addr         <= 0;
        d_wdata        <= 0;
        d_wstrb        <= 0;
        d1             <= 0;
        d2             <= 0;
        d3             <= 0;
        exec_state     <= 0;
        wb_reg         <= 0;
        ex_jump        <= 0;
        ex_branch      <= 0;
        write_mem      <= 0;
        ls_strb        <= 0;
        ls_sign_extend <= 0;
        `ifdef VIGNA_CORE_STACK_ADDR_RESET_ENABLE
            cpu_regs[2] <= `VIGNA_CORE_STACK_ADDR_RESET_VALUE;
        `endif
        shift_cnt <= 0;
        l_sll_srl_sra <= 0;
    end else begin
        //state machine
        case (exec_state)
            4'b0000: begin
                if (fetched) begin
                    d1 <= op1;
                    `ifdef VIGNA_CORE_PRELOAD_NEGATIVE
                    d2 <= (is_sub ? ~op2 : op2);
                    `else
                    d2 <= op2;
                    `endif
                    if (s_type) begin
                        d3 <= rs2_val;
                    end else if (b_type) begin
                        d3 <= inst_add_result;
                    end else if (is_jal || is_jalr) begin
                        d3 <= inst_add_result;
                    end else if (is_shift) begin
                        l_sll_srl_sra <= {is_sll || is_slli, is_srl || is_srli, is_sra || is_srai};
                        d3 <= op1;
                        shift_cnt <= op2[4:0];
                    `ifdef VIGNA_CORE_M_EXTENSION
                    end else if (is_m_coproc) begin 
                        d3[2:0] <= funct3;

                        m_valid   <= 1;
                    `endif
                    end
                                    
                    if (u_type || j_type || i_type || r_type) begin
                        `ifdef VIGNA_CORE_E_EXTENSION
                            wb_reg <= rd[3:0];
                        `else 
                            wb_reg <= rd;
                        `endif
                    end else begin
                        wb_reg <= 0;
                    end
                    ex_branch   <= b_type;
                    ex_jump     <= is_jal || is_jalr;

                    //next state logic
                    if (is_load || s_type) begin
                        exec_state <= 4'b0001;
                        write_mem <= is_load ? 1'b0 : 1'b1;
                    end
                    else if (is_jal || is_jalr) begin
                        exec_state <= 4'b0100;
                    end
                    else if (b_type) begin
                        exec_state <= 4'b1000;
                    end
                    else if (is_shift) begin
                        exec_state <= 4'b0110;
                    end
                    `ifdef VIGNA_CORE_M_EXTENSION
                    else if (is_m_coproc) begin
                        exec_state <= 4'b1001;
                    end
                    `endif 
                    else begin
                        exec_state <= 4'b0010;
                    end

                    //set strobe
                    if (is_lw || is_sw) ls_strb <= 4'b1111;
                    else if (is_lh || is_lhu || is_sh) ls_strb <= 4'b0011;
                    else if (is_lb || is_lbu || is_sb) ls_strb <= 4'b0001;

                    if (is_lw || is_lh || is_lb) ls_sign_extend <= 1;
                    else ls_sign_extend <= 0;
                end
            end
            4'b0001: begin
                //load/store func
                if (!write_mem) begin
                    d_valid    <= 1;
                    `ifdef VIGNA_CORE_ALIGNMENT 
                        d_addr <= dr & 32'hfffffffc;
                        shift_cnt <= dr[1:0];
                    `else
                        d_addr <= dr;  
                    `endif
                    d_wstrb    <= 0;
                    exec_state <= 4'b0011;
                end else begin
                    d_valid    <= 1;
                    `ifdef VIGNA_CORE_ALIGNMENT 
                        d_addr <= dr & 32'hfffffffc;
                        shift_cnt[1:0] <= dr[1:0];
                        d_wdata    <= d3 << ({3'b000, dr[1:0]} << 3);
                    `else
                        d_addr <= dr;  
                        d_wdata    <= d3;
                    `endif
                    d_wstrb    <= ls_strb << dr[1:0];
                    exec_state <= 4'b0101;
                end
            end
            4'b0010: begin
                //calc func
                exec_state <= 0;
                if (wb_reg != 0) begin
                    cpu_regs[wb_reg] <= dr;
                end
            end
            4'b0100: begin
                //jump func
                exec_state <= 0;
                ex_jump    <= 0;
                if (wb_reg != 0) begin
                    cpu_regs[wb_reg] <= d3;
                end
            end
            4'b1000: begin
                //branch func
                exec_state     <= 0;
                ex_branch      <= 0;
            end
            4'b0011: begin
                //load wait stage
                if (d_ready) begin
                    exec_state <= 0;
                    d_valid    <= 0;
                    if (wb_reg != 0) begin
                        `ifdef VIGNA_CORE_ALIGNMENT
                            case ({shift_cnt[1:0], ls_strb})
                                6'b000001: cpu_regs[wb_reg] <= {ls_sign_extend ? {24{d_rdata[ 7]}} : 24'd0, d_rdata[ 7: 0]};
                                6'b010010: cpu_regs[wb_reg] <= {ls_sign_extend ? {24{d_rdata[15]}} : 24'd0, d_rdata[15: 8]};
                                6'b100100: cpu_regs[wb_reg] <= {ls_sign_extend ? {24{d_rdata[23]}} : 24'd0, d_rdata[23:16]};
                                6'b111000: cpu_regs[wb_reg] <= {ls_sign_extend ? {24{d_rdata[31]}} : 24'd0, d_rdata[31:24]};
                                6'b000011: cpu_regs[wb_reg] <= {ls_sign_extend ? {16{d_rdata[15]}} : 16'd0, d_rdata[15: 0]};
                                6'b101100: cpu_regs[wb_reg] <= {ls_sign_extend ? {16{d_rdata[31]}} : 16'd0, d_rdata[31:16]};
                                6'b001111: cpu_regs[wb_reg] <= d_rdata;
                                default: cpu_regs[wb_reg] <= 32'd0;
                            endcase
                        `else 
                            if      (!ls_sign_extend)    cpu_regs[wb_reg] <= d_rdata & {{8{ls_strb[3]}}, {8{ls_strb[2]}}, {8{ls_strb[1]}}, {8{ls_strb[0]}}};
                            else if (ls_strb == 4'b0001) cpu_regs[wb_reg] <= {{24{d_rdata[7]}}, d_rdata[7:0]};
                            else if (ls_strb == 4'b0011) cpu_regs[wb_reg] <= {{16{d_rdata[15]}}, d_rdata[15:0]};
                            else                         cpu_regs[wb_reg] <= d_rdata;
                        `endif      
                    end
                end
            end
            4'b0101: begin
                //store wait stage
                if (d_ready) begin
                    exec_state <= 0;
                    d_valid    <= 0;
                    d_wstrb    <= 4'd0;
                    d_wdata    <= 0;
                end
            end
            4'b0110: begin
                //shift func
                if (shift_cnt == 0) begin
                    exec_state <= 0;
                    cpu_regs[wb_reg] <= d3;
                end else begin
                    `ifdef VIGNA_CORE_TWO_STAGE_SHIFT
                    if (first_shift_stage)
                        shift_cnt <= shift_cnt - 4;
                    else
                    `endif
                        shift_cnt <= shift_cnt - 1;
                    d3 <= shift_val;
                end
            end 
            `ifdef VIGNA_CORE_M_EXTENSION
            4'b1001: begin
                m_valid <= 0;
                if (m_ready) begin
                    cpu_regs[wb_reg] <= m_result;
                    exec_state <= 0;
                end
            end
            `endif
            default: begin
                exec_state <= 0;
            end
        endcase
    end
end

wire is_branch;
assign is_branch = is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu;

assign fetch_received = (exec_state == 4'b0000 && !is_jump && !is_branch)
                        || (exec_state == 4'b0100)
                        || (exec_state == 4'b1000);

endmodule

`endif