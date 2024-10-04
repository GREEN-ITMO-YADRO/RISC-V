`timescale 1ns / 1ps

import enums::*;

module cu(input var proc_state_t proc_state,
          output var proc_state_t proc_state_next,

          input var logic[6:0] opcode,
          input var logic[2:0] funct3,
          input var logic[6:0] funct7,
          input var logic[11:0] csr,
          input var logic[14:0] instr_reg_addr,

          output var instr_type_t instr_type,

          output var logic mem_re, mem_we,
          output var logic[1:0] mem_rd_unit, mem_wd_unit,
          output var logic mem_zero_extend,

          output var alu_op_t alu_op,
          output var logic[1:0] alu_lhs_src,
          output var logic[1:0] alu_rhs_src,
          input var logic alu_bit0,

          output var logic instr_next_sel,
          output var logic mem_addr_sel,

          output var logic reg_we,
          output var logic[1:0] reg_wd_src,
          input var logic reg_wa_is_x0,

          output var logic pc_next_base_src,
          output var logic pc_next_offset_src,
          output var logic[1:0] pc_next_sel,

          output var logic[2:0] csr_wd_sel,
          output var logic[1:0] mie_next_sel, mpie_next_sel,
          input var logic mcycle_we_mem,
          output var logic mcycle_next_sel, mcycle_we,
          output var logic minstret_we, instr_retired,
          output var logic mepc_next_sel, mcause_next_sel,
          output var logic[2:0] mtval_next_sel,

          output var csr_t csr_id,
          output var mcause_t mcause_next,
          output var logic mtip, msip, meip,
          input var logic mie, mtie, msie, meie,

          input var logic access_fault,
          input var logic addr_misaligned,
          input var logic timer_went_off);

    alu_op_t instr_alu_op;
    logic illegal_instr_idec, illegal_instr_adec;

    logic csr_ro, csr_valid;
    logic ebreak, ecall;

    logic trapped;

    logic[1:0] mie_next_sel_instr, mpie_next_sel_instr;
    logic[1:0] pc_next_sel_instr;
    logic reg_we_instr;

    logic mcycle_we_csr;

    mux #(.DATA_WIDTH(2), .SELECTOR_WIDTH(1)) mie_next_sel_mux(
        .in('{mie_next_sel_instr, 2'b01}),
        .sel(trapped),
        .out(mie_next_sel)
    );
    mux #(.DATA_WIDTH(2), .SELECTOR_WIDTH(1)) mpie_next_sel_mux(
        .in('{mpie_next_sel_instr, 2'b01}),
        .sel(trapped),
        .out(mpie_next_sel)
    );
    mux #(.DATA_WIDTH(2), .SELECTOR_WIDTH(1)) pc_next_sel_mux(
        .in('{pc_next_sel_instr, 2'b01}),
        .sel(trapped),
        .out(pc_next_sel)
    );
    mux #(.DATA_WIDTH(1), .SELECTOR_WIDTH(1)) reg_we_mux(
        .in('{reg_we_instr, 1'b0}),
        .sel(trapped),
        .out(reg_we)
    );

    instr_decoder idec(
        .proc_state(proc_state), .proc_state_next(proc_state_next),
        .opcode(opcode), .funct3(funct3), .funct7(funct7), .instr_reg_addr(instr_reg_addr),
        .instr_type(instr_type),
        .mem_re(mem_re), .mem_we(mem_we),
        .mem_rd_unit(mem_rd_unit), .mem_wd_unit(mem_wd_unit), .mem_zero_extend(mem_zero_extend),
        .alu_op(instr_alu_op), .alu_lhs_src(alu_lhs_src), .alu_rhs_src(alu_rhs_src),
        .alu_bit0(alu_bit0),
        .instr_next_sel(instr_next_sel), .mem_addr_sel(mem_addr_sel),
        .reg_we(reg_we_instr), .reg_wd_src(reg_wd_src), .reg_wa_is_x0(reg_wa_is_x0),
        .pc_next_base_src(pc_next_base_src), .pc_next_offset_src(pc_next_offset_src),
        .pc_next_sel(pc_next_sel_instr),

        .csr_id(csr_id),
        .csr_ro(csr_ro), .csr_valid(csr_valid),
        .csr_wd_sel(csr_wd_sel),

        .mcycle_we_csr(mcycle_we_csr),
        .mcycle_we_mem(mcycle_we_mem),
        .mcycle_we(mcycle_we),
        .mcycle_next_sel(mcycle_next_sel),

        .instr_retired(instr_retired),

        .mpie_next_sel(mpie_next_sel_instr),
        .mie_next_sel(mie_next_sel_instr),
        .trapped(trapped),

        .illegal_instr(illegal_instr_idec),
        .ecall(ecall),
        .ebreak(ebreak)
    );
    csr_decoder cdec(
        .csr(csr),
        .csr_id(csr_id), .ro(csr_ro), .valid(csr_valid),
        .mcycle_we(mcycle_we_csr), .minstret_we(minstret_we)
    );
    alu_decoder adec(
        .proc_state(proc_state),
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .instr_alu_op(instr_alu_op), .alu_op(alu_op),
        .illegal_instr(illegal_instr_adec)
    );
    trap_handler trap(
        .proc_state(proc_state),
        .access_fault(access_fault),
        .addr_misaligned(addr_misaligned),
        .illegal_instr(illegal_instr_idec | illegal_instr_adec),
        .ecall(ecall),
        .ebreak(ebreak),
        .timer_went_off(timer_went_off),

        .mem_re(mem_re),
        .mem_we(mem_we),

        .mcause_next(mcause_next),
        .trapped(trapped),

        .mepc_next_sel(mepc_next_sel),
        .mcause_next_sel(mcause_next_sel),
        .mtval_next_sel(mtval_next_sel),

        .mtip(mtip), .msip(msip), .meip(meip),
        .mie(mie), .mtie(mtie), .msie(msie), .meie(meie)
    );

endmodule

module instr_decoder(input var proc_state_t proc_state,
                     output var proc_state_t proc_state_next,

                     input var logic[6:0] opcode,
                     input var logic[2:0] funct3,
                     input var logic[6:0] funct7,
                     input var logic[14:0] instr_reg_addr,

                     output var instr_type_t instr_type,

                     output var logic mem_re,
                     output var logic mem_we,
                     output var logic[1:0] mem_rd_unit, mem_wd_unit,
                     output var logic mem_zero_extend,

                     output var alu_op_t alu_op,
                     output var logic[1:0] alu_lhs_src,
                     output var logic[1:0] alu_rhs_src,
                     input var logic alu_bit0,

                     output var logic instr_next_sel,
                     output var logic mem_addr_sel,

                     output var logic reg_we,
                     output var logic[1:0] reg_wd_src,
                     input var logic reg_wa_is_x0,

                     output var logic pc_next_base_src,
                     output var logic pc_next_offset_src,
                     output var logic[1:0] pc_next_sel,

                     input var csr_t csr_id,
                     input var logic csr_ro, csr_valid,
                     output var logic[2:0] csr_wd_sel,

                     input var logic mcycle_we_csr,
                     input var logic mcycle_we_mem,
                     output var logic mcycle_we,
                     output var logic mcycle_next_sel,

                     output var logic instr_retired,

                     output var logic[1:0] mpie_next_sel, mie_next_sel,
                     input var logic trapped,

                     output var logic illegal_instr,
                     output var logic ecall, ebreak);

    logic[2:0] reg_control;
    assign {reg_we, reg_wd_src} = reg_control;

    logic[1:0] pc_control;
    assign {pc_next_base_src, pc_next_offset_src} = pc_control;

    logic branch;
    logic csr_instr;

    assign mcycle_we = (csr_instr & mcycle_we_csr) | mcycle_we_mem;
    assign mcycle_next_sel = csr_instr & mcycle_we_csr;

    proc_state_t proc_state_next_comb;
    assign proc_state_next = trapped
            ? PROC_STATE_INSTR_FETCH
            : proc_state_next_comb;

    always_comb begin
        instr_type = INSTR_TYPE_R;
        branch = 1'b0;
        csr_instr = 1'b0;

        reg_control = {1'b0, 2'b00};
        {mem_re, mem_we, mem_zero_extend, mem_rd_unit, mem_wd_unit} = {1'b0, 1'b0, 1'b0, 2'b10, 2'b10};
        pc_control = {1'b0, 1'b0};
        {alu_op, alu_lhs_src, alu_rhs_src} = {ALU_OP_ZERO, 2'b00, 2'b00};

        csr_wd_sel = 3'b000;
        {ecall, ebreak} = 2'b00;
        pc_next_sel = 2'b00;

        illegal_instr = 1'b0;

        mie_next_sel = 2'b00;
        mpie_next_sel = 2'b00;

        instr_retired = 1'b0;

        case (proc_state)
            PROC_STATE_INSTR_FETCH: begin
                instr_next_sel = 1'b1;
                mem_addr_sel = 1'b1;
                mem_re = 1'b1;
                pc_next_sel = 2'b11;
                proc_state_next_comb = PROC_STATE_INSTR_DECODING;
            end

            PROC_STATE_INSTR_DECODING: begin
                instr_retired = 1'b1;
                instr_next_sel = 1'b0;
                mem_addr_sel = 1'b0;
                proc_state_next_comb = PROC_STATE_INSTR_FETCH;

                case (opcode)
                    7'b011_0111: begin // LUI
                        instr_type = INSTR_TYPE_U;
                        reg_control = {1'b1, 2'b10};
                    end
                    7'b001_0111: begin // AUIPC
                        instr_type = INSTR_TYPE_U;
                        reg_control = {1'b1, 2'b00};
                        {alu_op, alu_lhs_src, alu_rhs_src} = {ALU_OP_ADD, 2'b01, 2'b00};
                    end

                    7'b110_1111: begin // JAL
                        instr_type = INSTR_TYPE_J;
                        reg_control = {1'b1, 2'b00};
                        pc_control = {1'b0, 1'b1};
                        {alu_op, alu_lhs_src, alu_rhs_src} = {ALU_OP_ADD, 2'b01, 2'b01};
                    end
                    7'b110_0111: begin // JALR
                        instr_type = INSTR_TYPE_I;
                        reg_control = {1'b1, 2'b00};
                        pc_control = {1'b1, 1'b1};
                        {alu_op, alu_lhs_src, alu_rhs_src} = {ALU_OP_ADD, 2'b01, 2'b01};
                    end

                    7'b110_0011: begin
                        instr_type = INSTR_TYPE_B;
                        {alu_lhs_src, alu_rhs_src} = {2'b10, 2'b10};

                        case (funct3)
                            3'b000: {alu_op, branch} = {ALU_OP_SEQ, alu_bit0}; // BEQ
                            3'b001: {alu_op, branch} = {ALU_OP_SEQ, ~alu_bit0}; // BNE
                            3'b100: {alu_op, branch} = {ALU_OP_SLT, alu_bit0}; // BLT
                            3'b101: {alu_op, branch} = {ALU_OP_SLT, ~alu_bit0}; // BGE
                            3'b110: {alu_op, branch} = {ALU_OP_SLTU, alu_bit0}; // BLTU
                            3'b111: {alu_op, branch} = {ALU_OP_SLTU, ~alu_bit0}; // BGEU
                            default: illegal_instr = 1'b1; // illop
                        endcase;

                        if (branch) begin
                            pc_control = {1'b0, 1'b1};
                        end;
                    end

                    7'b000_0011: begin
                        instr_type = INSTR_TYPE_I;
                        reg_control = {1'b1, 2'b01};

                        case (funct3) inside
                            3'b000, 3'b100: begin // LB (U)
                                {mem_re, mem_zero_extend, mem_rd_unit} = {1'b1, funct3[2], 2'b00};
                            end

                            3'b001, 3'b101: begin // LH (U)
                                {mem_re, mem_zero_extend, mem_rd_unit} = {1'b1, funct3[2], 2'b01};
                            end

                            3'b010: begin // LW
                                {mem_re, mem_zero_extend, mem_rd_unit} = {1'b1, 1'b0, 2'b10};
                            end

                            default: illegal_instr = 1'b1; // illop
                        endcase;
                    end

                    7'b010_0011: begin
                        instr_type = INSTR_TYPE_S;

                        case (funct3)
                            3'b000: {mem_re, mem_we, mem_rd_unit, mem_wd_unit} =
                                {1'b1, 1'b1, {2 {2'b00}}}; // SB
                            3'b001: {mem_re, mem_we, mem_rd_unit, mem_wd_unit} =
                                {1'b1, 1'b1, {2 {2'b01}}}; // SH
                            3'b010: {mem_re, mem_we, mem_rd_unit, mem_wd_unit} =
                                {1'b0, 1'b1, {2 {2'b10}}}; // SW
                            default: illegal_instr = 1'b1; // illop
                        endcase;
                    end

                    7'b001_0011: begin // ALU (immediate)
                        instr_type = INSTR_TYPE_I;
                        reg_control = {1'b1, 2'b00};
                        {alu_op, alu_lhs_src, alu_rhs_src} = {ALU_OP_ZERO, 2'b10, 2'b00};
                    end

                    7'b0110011: begin // ALU (register)
                        instr_type = INSTR_TYPE_R;
                        reg_control = {1'b1, 2'b00};
                        {alu_op, alu_lhs_src, alu_rhs_src} = {ALU_OP_ZERO, 2'b10, 2'b10};
                    end

                    7'b000_1111: instr_type = INSTR_TYPE_I; // FENCE (acts as NOP)

                    7'b111_0011: begin
                        instr_type = INSTR_TYPE_I;

                        if (funct3 == 3'b000) begin
                            case ({funct7, instr_reg_addr})
                                {7'b0, 5'b0, 10'b0}: ecall = 1'b1; // ECALL
                                {7'b1, 5'b0, 10'b0}: ebreak = 1'b1; // EBREAK

                                {7'b001_1000, 5'b00010, 10'b0}: begin // MRET
                                    pc_next_sel = 2'b10;
                                    mie_next_sel = 2'b10;
                                    mpie_next_sel = 2'b10;
                                end

                                {7'b000_1000, 5'b00101, 10'b0}: ; // WFI (NOP)

                                default: illegal_instr = 1'b1; // illop
                            endcase
                        end else begin
                            reg_control = {1'b1, 2'b11};
                            csr_instr = 1'b1;

                            case (funct3)
                                3'b001: begin // CSRRW
                                    csr_wd_sel = 3'd0;

                                    if (csr_ro | ~csr_valid) begin
                                        illegal_instr = 1'b1;
                                    end;
                                end

                                3'b010: begin // CSRRS
                                    csr_wd_sel = 3'd1;

                                    if ((csr_ro & ~reg_wa_is_x0) | ~csr_valid) begin
                                        illegal_instr = 1'b1;
                                    end;
                                end

                                3'b011: begin // CSRRC
                                    csr_wd_sel = 3'd2;

                                    if ((csr_ro & ~reg_wa_is_x0) | ~csr_valid) begin
                                        illegal_instr = 1'b1;
                                    end;
                                end

                                3'b101: begin // CSRRWI
                                    csr_wd_sel = 3'd3;

                                    if (csr_ro | ~csr_valid) begin
                                        illegal_instr = 1'b1;
                                    end;
                                end

                                3'b110: begin // CSRRSI
                                    csr_wd_sel = 3'd4;

                                    if ((csr_ro & ~reg_wa_is_x0) | ~csr_valid) begin
                                        illegal_instr = 1'b1;
                                    end;
                                end

                                3'b111: begin // CSRRCI
                                    csr_wd_sel = 3'd5;

                                    if ((csr_ro & ~reg_wa_is_x0) | ~csr_valid) begin
                                        illegal_instr = 1'b1;
                                    end;
                                end

                                default: begin // illop
                                    reg_control = {1'b0, 2'b00};
                                    csr_instr = 1'b0;
                                    illegal_instr = 1'b1;
                                end
                            endcase;
                         end;
                    end

                    default: illegal_instr = 1'b1; // illop
                endcase;
            end
        endcase;
    end;

endmodule

module csr_decoder(input var logic[11:0] csr,
                   output var csr_t csr_id,
                   output var logic ro, valid,
                   output var logic mcycle_we, minstret_we);

    always_comb begin
        valid = 1'b1;

        case (csr)
            12'h301: csr_id = CSR_MISA;
            12'hf11: csr_id = CSR_MVENDORID;
            12'hf12: csr_id = CSR_MARCHID;
            12'hf13: csr_id = CSR_MIMPID;
            12'hf14: csr_id = CSR_MHARTID;
            12'h300: csr_id = CSR_MSTATUS;
            12'h305: csr_id = CSR_MTVEC;
            12'h344: csr_id = CSR_MIP;
            12'h304: csr_id = CSR_MIE;
            12'hb00,
            12'hc00,
            12'hc01: csr_id = CSR_MCYCLE;
            12'hb80,
            12'hc80,
            12'hc81: csr_id = CSR_MCYCLEH;
            12'hb02,
            12'hc02: csr_id = CSR_MINSTRET;
            12'hb82,
            12'hc82: csr_id = CSR_MINSTRETH;
            12'h306: csr_id = CSR_MCOUNTEREN;
            12'h320: csr_id = CSR_MCOUNTINHIBIT;
            12'h340: csr_id = CSR_MSCRATCH;
            12'h341: csr_id = CSR_MEPC;
            12'h342: csr_id = CSR_MCAUSE;
            12'h343: csr_id = CSR_MTVAL;

            default: begin
                valid = 1'b0;
                csr_id = CSR_NONE;
            end
        endcase;
    end;

    always_comb begin
        ro = 1'b0;
        mcycle_we = 1'b0;
        minstret_we = 1'b0;

        case (csr_id) inside
            CSR_MVENDORID, CSR_MARCHID, CSR_MIMPID, CSR_MHARTID: ro = 1'b1;
        endcase;

        case (csr_id) inside
            CSR_MCYCLE, CSR_MCYCLEH: mcycle_we = 1'b1;
            CSR_MINSTRET, CSR_MINSTRETH: minstret_we = 1'b1;
        endcase;
    end;

endmodule

module alu_decoder(input var proc_state_t proc_state,
                   input var logic[6:0] opcode,
                   input var alu_op_t instr_alu_op,
                   input var logic[2:0] funct3,
                   input var logic[6:0] funct7,
                   output var alu_op_t alu_op,

                   output var logic illegal_instr);

    always_comb begin
        alu_op = ALU_OP_ZERO;
        illegal_instr = 1'b0;

        case (proc_state)
            PROC_STATE_INSTR_FETCH: ; // nop

            PROC_STATE_INSTR_DECODING: begin
                case (instr_alu_op)
                    5'b00000: case (opcode)
                        7'b001_0011: case (funct3)
                            3'b000: alu_op = ALU_OP_ADD; // ADDI
                            3'b010: alu_op = ALU_OP_SLT; // SLTI
                            3'b011: alu_op = ALU_OP_SLTU; // SLTIU
                            3'b100: alu_op = ALU_OP_XOR; // XORI
                            3'b110: alu_op = ALU_OP_OR; // ORI
                            3'b111: alu_op = ALU_OP_AND; // ANDI

                            3'b001: if (funct7 == 7'b000_0000) begin
                                 alu_op = ALU_OP_SLL; // SLLI
                            end else begin // illop
                                illegal_instr = 1'b1;
                            end
                            3'b101: case (funct7)
                                7'b000_0000: alu_op = ALU_OP_SRL; // SRLI
                                7'b010_0000: alu_op = ALU_OP_SRA; // SRAI
                                default: illegal_instr = 1'b1; // illop
                            endcase
                        endcase

                        7'b011_0011: case (funct7)
                            7'b000_0000: case (funct3)
                                3'b000: alu_op = ALU_OP_ADD; // ADD
                                3'b001: alu_op = ALU_OP_SLL; // SLL
                                3'b010: alu_op = ALU_OP_SLT; // SLT
                                3'b011: alu_op = ALU_OP_SLTU; // SLTU
                                3'b100: alu_op = ALU_OP_XOR; // XOR
                                3'b101: alu_op = ALU_OP_SRL; // SRL
                                3'b110: alu_op = ALU_OP_OR; // OR
                                3'b111: alu_op = ALU_OP_AND; // AND
                            endcase

                            7'b010_0000: case (funct3)
                                3'b000: alu_op = ALU_OP_SUB; // SUB
                                3'b101: alu_op = ALU_OP_SRA; // SRA
                                default: illegal_instr = 1'b1; // illop
                            endcase

                            default: illegal_instr = 1'b1; // illop
                        endcase
                    endcase

                    default: alu_op = instr_alu_op;
                endcase;
            end
        endcase;
    end;

endmodule

module trap_handler(input var proc_state_t proc_state,
                    input var logic access_fault,
                    input var logic addr_misaligned,
                    input var logic illegal_instr,
                    input var logic ecall,
                    input var logic ebreak,
                    input var logic timer_went_off,

                    input var logic mem_re, mem_we,

                    output var mcause_t mcause_next,
                    output var logic trapped,
                    output var logic mepc_next_sel,
                    output var logic mcause_next_sel,
                    output var logic[2:0] mtval_next_sel,

                    output var logic mtip, msip, meip,
                    input var logic mie, mtie, msie, meie);

    assign {
        mepc_next_sel,
        mcause_next_sel
    } = {2 {trapped}};

    assign mtip = timer_went_off;
    assign msip = 1'b0;
    assign meip = 1'b0;

    always_comb begin
        trapped = 1'b0;
        mtval_next_sel = 3'b100;
        // per the spec this exception code doubles as an "unknown exception" code
        // ¯\_(ツ)_/¯
        mcause_next = MCAUSE_INSTR_ADDR_MISALIGN;


        if (mie) begin
            if (meie & meip) begin
                trapped = 1'b1;
                mcause_next = MCAUSE_MEI;
            end else if (msie & msip) begin
                trapped = 1'b1;
                mcause_next = MCAUSE_MSI;
            end else if (mtie & mtip) begin
                trapped = 1'b1;
                mcause_next = MCAUSE_MTI;
            end
        end else if (proc_state == PROC_STATE_INSTR_FETCH & access_fault) begin
            trapped = 1'b1;
            mcause_next = MCAUSE_INSTR_ADDR_FAULT;
            mtval_next_sel = 3'b010;
        end else if (illegal_instr) begin
            trapped = 1'b1;
            mcause_next = MCAUSE_ILLEGAL_INSTR;
            mtval_next_sel = 3'b011;
        end else if (proc_state == PROC_STATE_INSTR_FETCH & addr_misaligned) begin
            trapped = 1'b1;
            mcause_next = MCAUSE_INSTR_ADDR_MISALIGN;
            mtval_next_sel = 3'b010;
        end else if (ecall) begin
            trapped = 1'b1;
            mcause_next = MCAUSE_M_ECALL;
        end else if (ebreak) begin
            trapped = 1'b1;
            mcause_next = MCAUSE_BREAKPOINT;
            mtval_next_sel = 3'b010;
        end else if (addr_misaligned) begin
            trapped = 1'b1;
            mtval_next_sel = 3'b010;

            if (mem_we) begin
                mcause_next = MCAUSE_STORE_ADDR_MISALIGN;
            end else begin
                mcause_next = MCAUSE_LOAD_ADDR_MISALIGN;
            end;
        end else if (access_fault) begin
            trapped = 1'b1;
            mtval_next_sel = 3'b010;

            if (mem_we) begin
                mcause_next = MCAUSE_STORE_ACCESS_FAULT;
            end else begin
                mcause_next = MCAUSE_LOAD_ACCESS_FAULT;
            end;
        end;
    end;

endmodule
