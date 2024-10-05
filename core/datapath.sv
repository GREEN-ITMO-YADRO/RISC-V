`timescale 1ns / 1ps

import enums::*;

module datapath (
    input logic clk,
    input logic reset,

    output proc_state_t proc_state,
    input  proc_state_t proc_state_next,

    output logic [31:0] instr,
    input instr_type_t instr_type,

    output logic [31:0] mem_addr,
    output logic [31:0] mem_wd,
    input logic [31:0] mem_rd,
    input logic [1:0] mem_rd_unit,
    input logic mem_zero_extend,

    input alu_op_t alu_op,
    input logic [1:0] alu_lhs_src,
    input logic [1:0] alu_rhs_src,
    output logic alu_bit0,

    input logic instr_next_sel,
    input logic mem_addr_sel,

    input logic reg_we,
    input logic [1:0] reg_wd_src,
    output logic reg_wa_is_x0,

    input logic pc_next_base_src,
    input logic pc_next_offset_src,
    input logic [1:0] pc_next_sel,

    input logic [2:0] csr_wd_sel,
    input logic [1:0] mie_next_sel,
    input logic [1:0] mpie_next_sel,

    input logic mcycle_next_sel,
    input logic [63:0] mcycle_next_mem,
    input logic mcycle_we,
    output logic [63:0] mcycle,

    input logic minstret_we,
    input logic instr_retired,

    input logic mepc_next_sel,
    input logic mcause_next_sel,
    input logic [2:0] mtval_next_sel,

    output logic [63:0] mtimecmp,
    input logic [63:0] mtimecmp_next,
    output logic timer_went_off,

    input csr_t csr_id,
    input mcause_t mcause_next_cu,
    input logic mtip,
    input logic msip,
    input logic meip,
    output logic mie,
    output logic mtie,
    output logic msie,
    output logic meie
);

    // processor state
    register #(
        .WIDTH(1),
        .RESET_VALUE({PROC_STATE_INSTR_FETCH})
    ) proc_state_reg (
        .clk(clk),
        .reset(reset),
        .rd({proc_state}),
        .wd({proc_state_next})
    );

    // immediate decoding
    logic [31:0] imm;
    imm_decoder imm_decoder (
        .instr(instr[31:7]),
        .instr_type(instr_type),
        .imm(imm)
    );

    // memory read
    logic [31:0] mem_read_extended;
    mem_extender mem_read_extender (
        .in(mem_rd),
        .out(mem_read_extended),
        .unit(mem_rd_unit),
        .zero_extend(mem_zero_extend)
    );

    // program counter
    logic [31:0] pc, pc_next;
    register #(
        .WIDTH(32),
        .RESET_VALUE(32'h8000_0100)
    ) pc_reg (
        .clk(clk),
        .reset(reset),
        .rd(pc),
        .wd(pc_next)
    );

    // register file
    logic [31:0] reg_rd1, reg_rd2, reg_wd;
    logic [4:0] reg_ra1, reg_ra2, reg_wa;
    regfile regfile (
        .clk(clk),
        .we (reg_we),
        .wa (reg_wa),
        .wd (reg_wd),
        .ra1(reg_ra1),
        .rd1(reg_rd1),
        .ra2(reg_ra2),
        .rd2(reg_rd2)
    );
    assign reg_wa_is_x0 = reg_wa == 5'b0;
    assign reg_ra1 = instr[19:15];
    assign reg_ra2 = instr[24:20];
    assign reg_wa = instr[11:7];

    // instr register
    logic [31:0] instr_next;
    logic [31:0] instr_be;
    le_to_be #(
        .WIDTH(32)
    ) instr_le_to_be (
        .in (mem_rd),
        .out(instr_be)
    );
    mux #(
        .SELECTOR_WIDTH(1),
        .DATA_WIDTH(32)
    ) instr_next_mux (
        .in ('{instr, instr_be}),
        .sel(instr_next_sel),
        .out(instr_next)
    );
    register #(
        .WIDTH(32),
        .RESET_VALUE(32'b0)
    ) instr_reg (
        .clk(clk),
        .reset(reset),
        .rd(instr),
        .wd(instr_next)
    );

    // memory access
    logic [31:0] mem_addr_reg;
    adder mem_addr_adder (
        .lhs(imm),
        .rhs(reg_rd1),
        .out(mem_addr_reg)
    );
    mux #(
        .SELECTOR_WIDTH(1),
        .DATA_WIDTH(32)
    ) mem_addr_mux (
        .in ('{mem_addr_reg, pc}),
        .sel(mem_addr_sel),
        .out(mem_addr)
    );
    assign mem_wd = reg_rd2;

    // ALU
    logic [31:0] alu_lhs, alu_rhs, alu_out;
    mux #(
        .SELECTOR_WIDTH(2),
        .DATA_WIDTH(32)
    ) alu_lhs_mux (
        .in ('{32'b0, pc, reg_rd1, {{32{1'bx}}}}),
        .sel(alu_lhs_src),
        .out(alu_lhs)
    );
    mux #(
        .SELECTOR_WIDTH(2),
        .DATA_WIDTH(32)
    ) alu_rhs_mux (
        .in ('{imm, 32'd4, reg_rd2, {{32{1'bx}}}}),
        .sel(alu_rhs_src),
        .out(alu_rhs)
    );
    alu alu (
        .lhs(alu_lhs),
        .rhs(alu_rhs),
        .alu_op(alu_op),
        .out(alu_out),
        .out_bit0(alu_bit0)
    );

    // register file write
    logic [31:0] csr_rd;
    mux #(
        .SELECTOR_WIDTH(2),
        .DATA_WIDTH(32)
    ) reg_wd_mux (
        .in ('{alu_out, mem_read_extended, imm, csr_rd}),
        .sel(reg_wd_src),
        .out(reg_wd)
    );

    // program counter increment
    logic [31:0] pc_next_base, pc_next_offset, pc_next_unaligned_adder, pc_next_unaligned;
    logic [31:0] mepc;
    logic [31:2] mtvec_base;
    mux #(
        .SELECTOR_WIDTH(1),
        .DATA_WIDTH(32)
    ) pc_next_base_mux (
        .in ('{pc, reg_rd1}),
        .sel(pc_next_base_src),
        .out(pc_next_base)
    );
    mux #(
        .SELECTOR_WIDTH(1),
        .DATA_WIDTH(32)
    ) pc_next_offset_mux (
        .in ('{32'd4, imm}),
        .sel(pc_next_offset_src),
        .out(pc_next_offset)
    );
    adder #(
        .WIDTH(32)
    ) pc_next_adder (
        .lhs(pc_next_base),
        .rhs(pc_next_offset),
        .out(pc_next_unaligned_adder)
    );
    mux #(
        .SELECTOR_WIDTH(2),
        .DATA_WIDTH(32)
    ) pc_next_unaligned_mux (
        .in ('{pc_next_unaligned_adder, {mtvec_base[31:2], 2'b00}, mepc, pc}),
        .sel(pc_next_sel),
        .out(pc_next_unaligned)
    );
    assign pc_next = {pc_next_unaligned[31:1], 1'b0};

    // interrupt registers
    logic mie_next, mie_next_csr;
    logic mpie, mpie_next, mpie_next_csr;
    logic mtie_next, msie_next, meie_next;
    logic mcycle_inhibit, mcycle_inhibit_next;
    logic minstret_inhibit, minstret_inhibit_next;

    register #(
        .WIDTH(1),
        .RESET_VALUE(1'b1)
    ) mie_reg (
        .clk(clk),
        .reset(reset),
        .rd(mie),
        .wd(mie_next)
    );
    mux #(
        .SELECTOR_WIDTH(2),
        .DATA_WIDTH(1)
    ) mie_next_mux (
        .in ('{mie_next_csr, 1'b0, mpie, 1'bx}),
        .sel(mie_next_sel),
        .out(mie_next)
    );

    register #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
    ) mpie_reg (
        .clk(clk),
        .reset(reset),
        .rd(mpie),
        .wd(mpie_next)
    );
    mux #(
        .SELECTOR_WIDTH(2),
        .DATA_WIDTH(1)
    ) mpie_next_mux (
        .in ('{mpie_next_csr, mie, 1'b1, 1'bx}),
        .sel(mpie_next_sel),
        .out(mpie_next)
    );

    register #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
    ) mtie_reg (
        .clk(clk),
        .reset(reset),
        .rd(mtie),
        .wd(mtie_next)
    );
    register #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
    ) msie_reg (
        .clk(clk),
        .reset(reset),
        .rd(msie),
        .wd(msie_next)
    );
    register #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
    ) meie_reg (
        .clk(clk),
        .reset(reset),
        .rd(meie),
        .wd(meie_next)
    );

    register #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
    ) mcycle_inhibit_reg (
        .clk(clk),
        .reset(reset),
        .rd(mcycle_inhibit),
        .wd(mcycle_inhibit_next)
    );
    register #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
    ) minstret_inhibit_reg (
        .clk(clk),
        .reset(reset),
        .rd(minstret_inhibit),
        .wd(minstret_inhibit_next)
    );

    // CSRs
    logic [63:0] mcycle_next, mcycle_next_csr;
    logic [63:0] minstret, minstret_next;
    logic [31:0] mscratch, mscratch_next;
    logic [31:0] mepc_next, mepc_next_csr;
    mcause_t mcause, mcause_next, mcause_next_csr;
    logic [31:0] mtval, mtval_next, mtval_next_csr;
    logic [31:2] mtvec_base_next;
    logic [31:0] csr_wd;
    logic [31:0] uimm;
    assign uimm = {27'b0, reg_ra1};

    csr csr_iface (
        .csr_id(csr_id),
        .rd(csr_rd),
        .wd(csr_wd),

        .mie(mie),
        .mpie(mpie),
        .mie_next(mie_next_csr),
        .mpie_next(mpie_next_csr),

        .mtip(mtip),
        .msip(msip),
        .meip(meip),

        .mtie(mtie),
        .msie(msie),
        .meie(meie),
        .mtie_next(mtie_next),
        .msie_next(msie_next),
        .meie_next(meie_next),

        .mtvec_base(mtvec_base),
        .mtvec_base_next(mtvec_base_next),

        .mcycle(mcycle),
        .mcycle_next(mcycle_next_csr),
        .minstret(minstret),
        .minstret_next(minstret_next),

        .mcycle_inhibit(mcycle_inhibit),
        .mcycle_inhibit_next(mcycle_inhibit_next),
        .minstret_inhibit(minstret_inhibit),
        .minstret_inhibit_next(minstret_inhibit_next),

        .mscratch(mscratch),
        .mscratch_next(mscratch_next),

        .mepc(mepc),
        .mepc_next(mepc_next_csr),
        .mcause(mcause),
        .mcause_next(mcause_next_csr),
        .mtval(mtval),
        .mtval_next(mtval_next_csr)
    );
    mux #(
        .SELECTOR_WIDTH(3),
        .DATA_WIDTH(32)
    ) csr_wd_mux (
        .in(
        '{
            reg_rd1,
            csr_rd | reg_rd1,
            csr_rd & ~reg_rd1,
            uimm,
            csr_rd | uimm,
            csr_rd & ~uimm,
            {32{1'bx}},
            {32{1'bx}}
        }
        ),
        .sel(csr_wd_sel),
        .out(csr_wd)
    );

    counter #(
        .WIDTH(64)
    ) mcycle_ctr (
        .clk(clk),
        .reset(reset),
        .rd(mcycle),
        .wd(mcycle_next),
        .we(mcycle_we),
        .enable(~mcycle_inhibit)
    );
    counter #(
        .WIDTH(64)
    ) minstret_ctr (
        .clk(clk),
        .reset(reset),
        .rd(minstret),
        .wd(minstret_next),
        .we(minstret_we),
        .enable(~minstret_inhibit & instr_retired)
    );

    mux #(
        .SELECTOR_WIDTH(1),
        .DATA_WIDTH(64)
    ) mcycle_next_mux (
        .in ('{mcycle_next_mem, mcycle_next_csr}),
        .sel(mcycle_next_sel),
        .out(mcycle_next)
    );

    register #(
        .WIDTH(32),
        .RESET_VALUE(32'b0)
    ) mscratch_reg (
        .clk(clk),
        .reset(reset),
        .rd(mscratch),
        .wd(mscratch_next)
    );

    register #(
        .WIDTH(32),
        .RESET_VALUE(32'b0)
    ) mepc_reg (
        .clk(clk),
        .reset(reset),
        .rd(mepc),
        .wd(mepc_next)
    );
    mux #(
        .SELECTOR_WIDTH(1),
        .DATA_WIDTH(32)
    ) mepc_next_mux (
        .in ('{mepc_next_csr, pc}),
        .sel(mepc_next_sel),
        .out(mepc_next)
    );

    register #(
        .WIDTH(5)
    ) mcause_reg (
        .clk(clk),
        .reset(reset),
        .rd({mcause}),
        .wd({mcause_next})
    );
    mux #(
        .SELECTOR_WIDTH(1),
        .DATA_WIDTH(5)
    ) mcause_next_mux (
        .in ('{{mcause_next_csr}, {mcause_next_cu}}),
        .sel(mcause_next_sel),
        .out({mcause_next})
    );

    register #(
        .WIDTH(32),
        .RESET_VALUE(32'b0)
    ) mtval_reg (
        .clk(clk),
        .reset(reset),
        .rd(mtval),
        .wd(mtval_next)
    );
    mux #(
        .SELECTOR_WIDTH(3),
        .DATA_WIDTH(32)
    ) mtval_next_mux (
        .in ('{mtval_next_csr, pc, mem_addr, instr, 32'b0, {32{1'bx}}, {32{1'bx}}, {32{1'bx}}}),
        .sel(mtval_next_sel),
        .out(mtval_next)
    );

    register #(
        .WIDTH(30),
        .RESET_VALUE(30'h2000_0000)
    ) mtvec_base_reg (
        .clk(clk),
        .reset(reset),
        .rd(mtvec_base),
        .wd(mtvec_base_next)
    );

    register #(
        .WIDTH(64),
        .RESET_VALUE(64'hffff_ffff_ffff_ffff)
    ) mtimecmp_reg (
        .clk(clk),
        .reset(reset),
        .rd(mtimecmp),
        .wd(mtimecmp_next)
    );
    assign timer_went_off = mtimecmp <= mcycle;

endmodule

module imm_decoder (
    input logic [31:7] instr,
    input instr_type_t instr_type,
    output logic [31:0] imm
);

    logic sign;
    assign sign = instr[31];

    always_comb begin
        case (instr_type)
            INSTR_TYPE_R: imm = {32{1'bx}};
            INSTR_TYPE_I: imm = {{20{sign}}, instr[31:20]};
            INSTR_TYPE_S: imm = {{20{sign}}, instr[31:25], instr[11:7]};
            INSTR_TYPE_B: imm = {{20{sign}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            INSTR_TYPE_U: imm = {instr[31:12], {12{1'b0}}};
            INSTR_TYPE_J: imm = {{12{sign}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm = {32{1'bx}};
        endcase
    end

endmodule

module mem_extender (
    input logic [31:0] in,
    output logic [31:0] out,
    input logic [1:0] unit,
    input logic zero_extend
);

    always_comb begin
        case (unit)
            2'b00:   out = {{24{~zero_extend & in[7]}}, in[7:0]};  // byte
            2'b01:   out = {{16{~zero_extend & in[15]}}, in[15:0]};  // half
            2'b10:   out = in;  // word
            default: out = {32{1'bx}};
        endcase
    end

endmodule
