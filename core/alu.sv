`timescale 1ns / 1ps

import enums::*;

module alu(input var logic signed[31:0] lhs,
           input var logic signed[31:0] rhs,
           input var alu_op_t alu_op,
           output var logic[31:0] out,
           output var logic out_bit0);

    assign out_bit0 = out[0];

    typedef logic unsigned[31:0] uword_t;

    always_comb begin
        case (alu_op)
            ALU_OP_ZERO: out = 32'b0; // ZERO
            ALU_OP_ADD: out = lhs + rhs; // ADD
            ALU_OP_SUB: out = lhs - rhs; // SUB
            ALU_OP_SLT: out = (lhs < rhs) ? 32'b1 : 32'b0; // SLT
            ALU_OP_SLTU: out = (uword_t'(lhs) < uword_t'(rhs)) ? 32'b1 : 32'b0; // SLTU
            ALU_OP_XOR: out = lhs ^ rhs; // XOR
            ALU_OP_OR: out = lhs | rhs; // OR
            ALU_OP_AND: out = lhs & rhs; // AND
            ALU_OP_SLL: out = uword_t'(lhs) << uword_t'(rhs[4:0]); // SLL
            ALU_OP_SRL: out = uword_t'(lhs) >> uword_t'(rhs[4:0]); // SRL
            ALU_OP_SRA: out = lhs >> rhs[4:0]; // SRA
            ALU_OP_SEQ: out = (lhs == rhs) ? 32'b1 : 32'b0; // SEQ

            default: out = {32 {1'bx}};
        endcase;
    end;

endmodule
