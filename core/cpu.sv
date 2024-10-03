import enums::*;

module cpu(input var logic clk,
           input var logic reset,
           output var logic mem_re, mem_we,
           output var logic[31:0] mem_addr, mem_wd,
           input var logic[31:0] mem_rd,
           output var logic[1:0] mem_rd_unit, mem_wd_unit,

           output var logic[63:0] mtime, mtimecmp,
           input var logic[63:0] mtime_next, mtimecmp_next,
           input var logic mtime_we,

           input var logic access_fault, addr_misaligned);

    proc_state_t proc_state, proc_state_next;

    logic[1:0] alu_lhs_src;
    logic[1:0] alu_rhs_src;

    alu_op_t alu_op;
    instr_type_t instr_type;

    logic instr_next_sel;
    logic mem_addr_sel;

    logic reg_we;
    logic[1:0] reg_wd_src;
    logic reg_wa_is_x0;

    logic pc_next_base_src, pc_next_offset_src;
    logic[1:0] pc_next_sel;
    logic alu_bit0;

    logic mem_zero_extend;

    logic[2:0] csr_wd_sel;
    logic[1:0] mie_next_sel, mpie_next_sel;
    logic mcycle_next_sel, mcycle_we;
    logic minstret_we, instr_retired;
    logic mepc_next_sel, mcause_next_sel;
    logic[2:0] mtval_next_sel;

    csr_t csr_id;
    mcause_t mcause_next_cu;
    logic mtip, msip, meip;
    logic mie, mtie, msie, meie;

    logic timer_went_off;

    logic[31:0] instr;

    cu controller(
        .proc_state(proc_state), .proc_state_next(proc_state_next),
        .opcode(instr[6:0]), .funct3(instr[14:12]), .funct7(instr[31:25]), .csr(instr[31:20]),
        .instr_reg_addr({instr[24:15], instr[11:7]}),
        .instr_type(instr_type),
        .mem_re(mem_re), .mem_we(mem_we),
        .mem_rd_unit(mem_rd_unit), .mem_wd_unit(mem_wd_unit), .mem_zero_extend(mem_zero_extend),
        .alu_op(alu_op), .alu_lhs_src(alu_lhs_src), .alu_rhs_src(alu_rhs_src),
        .alu_bit0(alu_bit0),
        .instr_next_sel(instr_next_sel), .mem_addr_sel(mem_addr_sel),
        .reg_we(reg_we), .reg_wd_src(reg_wd_src), .reg_wa_is_x0(reg_wa_is_x0),
        .pc_next_base_src(pc_next_base_src), .pc_next_offset_src(pc_next_offset_src),
        .pc_next_sel(pc_next_sel),
        .csr_wd_sel(csr_wd_sel),
        .mie_next_sel(mie_next_sel), .mpie_next_sel(mpie_next_sel),
        .mcycle_we_mem(mtime_we),
        .mcycle_next_sel(mcycle_next_sel), .mcycle_we(mcycle_we),
        .minstret_we(minstret_we), .instr_retired(instr_retired),
        .mepc_next_sel(mepc_next_sel), .mcause_next_sel(mcause_next_sel),
        .mtval_next_sel(mtval_next_sel),

        .csr_id(csr_id),
        .mcause_next(mcause_next_cu),
        .mtip(mtip), .msip(msip), .meip(meip),
        .mie(mie), .mtie(meie), .msie(msie), .meie(meie),

        .access_fault(access_fault),
        .addr_misaligned(addr_misaligned),
        .timer_went_off(timer_went_off)
    );
    datapath datapath(
        .clk(clk), .reset(reset),
        .proc_state(proc_state), .proc_state_next(proc_state_next),
        .instr(instr), .instr_type(instr_type),
        .mem_addr(mem_addr), .mem_wd(mem_wd), .mem_rd(mem_rd),
        .mem_rd_unit(mem_rd_unit), .mem_zero_extend(mem_zero_extend),
        .alu_op(alu_op), .alu_lhs_src(alu_lhs_src), .alu_rhs_src(alu_rhs_src),
        .alu_bit0(alu_bit0),
        .instr_next_sel(instr_next_sel), .mem_addr_sel(mem_addr_sel),
        .reg_we(reg_we), .reg_wd_src(reg_wd_src), .reg_wa_is_x0(reg_wa_is_x0),
        .pc_next_base_src(pc_next_base_src), .pc_next_offset_src(pc_next_offset_src),
        .pc_next_sel(pc_next_sel),
        .csr_wd_sel(csr_wd_sel),
        .mie_next_sel(mie_next_sel), .mpie_next_sel(mpie_next_sel),
        .mcycle(mtime), .mcycle_next_mem(mtime_next),
        .mcycle_next_sel(mcycle_next_sel), .mcycle_we(mcycle_we),
        .minstret_we(minstret_we), .instr_retired(instr_retired),
        .mepc_next_sel(mepc_next_sel), .mcause_next_sel(mcause_next_sel),
        .mtval_next_sel(mtval_next_sel),
        .mtimecmp(mtimecmp), .mtimecmp_next(mtimecmp_next),
        .timer_went_off(timer_went_off),

        .csr_id(csr_id),
        .mcause_next_cu(mcause_next_cu),
        .mtip(mtip), .msip(msip), .meip(meip),
        .mie(mie), .mtie(mtie), .msie(msie), .meie(meie)
    );

endmodule
