func.func private @run_alu(%op : i5, %lhs : i32, %rhs : i32) {
  arc.sim.instantiate @alu as %model {
    arc.sim.set_input %model, "lhs" = %lhs : i32, !arc.sim.instance<@alu>
    arc.sim.set_input %model, "rhs" = %rhs : i32, !arc.sim.instance<@alu>
    arc.sim.set_input %model, "alu_op" = %op : i5, !arc.sim.instance<@alu>

    arc.sim.step %model : !arc.sim.instance<@alu>

    %out = arc.sim.get_port %model, "out" : i32, !arc.sim.instance<@alu>
    %out_bit0 = arc.sim.get_port %model, "out_bit0" : i1, !arc.sim.instance<@alu>

    arc.sim.emit "out", %out : i32
    arc.sim.emit "out_bit0", %out_bit0 : i1
  }

  return
}

!run_t = (i5, i32, i32) -> ()

func.func @entry() {
  %c-0x12345677 = hw.constant -0x12345677 : i32
  %c-1234 = hw.constant -1234 : i32
  %c-123 = hw.constant -123 : i32
  %c-3 = hw.constant -3 : i32
  %c0 = hw.constant 0 : i32
  %c1 = hw.constant 1 : i32
  %c3 = hw.constant 3 : i32
  %c7 = hw.constant 7 : i32
  %c42 = hw.constant 42 : i32
  %c0x12345678 = hw.constant 0x12345678 : i32
  %c0x7fffffff = hw.constant 0x7fffffff : i32
  %c0x80000001 = hw.constant 0x80000001 : i32
  %c0x87654321 = hw.constant 0x87654321 : i32
  %c0xffffffff = hw.constant 0xffffffff : i32

  // 0b01100110100110010011110011110000
  %c0x66993cf0 = hw.constant 0x66993cf0 : i32
  // 0b11110011000011001001011010010110
  %c0xf30c9696 = hw.constant 0xf30c9696 : i32

  %alu_op_zero = hw.constant 0 : i5
  %alu_op_add = hw.constant 1 : i5
  %alu_op_sub = hw.constant 2 : i5
  %alu_op_slt = hw.constant 3 : i5
  %alu_op_sltu = hw.constant 4 : i5
  %alu_op_xor = hw.constant 5 : i5
  %alu_op_or = hw.constant 6 : i5
  %alu_op_and = hw.constant 7 : i5
  %alu_op_sll = hw.constant 8 : i5
  %alu_op_srl = hw.constant 9 : i5
  %alu_op_sra = hw.constant 10 : i5
  %alu_op_seq = hw.constant 11 : i5

  // ALU_OP_ZERO (zero out) ////////////////////////////////////////////////////
  // CHECK: out = 0
  // CHECK: out_bit0 = 0
  func.call @run_alu(%alu_op_zero, %c42, %c-1234) : !run_t

  // ALU_OP_ADD (addition) /////////////////////////////////////////////////////
  // CHECK: out = fffffb58
  // CHECK: out_bit0 = 0
  func.call @run_alu(%alu_op_add, %c42, %c-1234) : !run_t

  // CHECK: out = 1
  // CHECK: out_bit0 = 1
  func.call @run_alu(%alu_op_add, %c-0x12345677, %c0x12345678) : !run_t

  // CHECK: out = 2
  // CHECK: out_bit0 = 0
  func.call @run_alu(%alu_op_add, %c0x80000001, %c0x80000001) : !run_t

  // ALU_OP_SUB (subtraction) //////////////////////////////////////////////////
  // CHECK: out = 4cf
  // CHECK: out_bit0 = 1
  func.call @run_alu(%alu_op_sub, %c-3, %c-1234) : !run_t

  // CHECK: out = ffffffd6
  // CHECK: out_bit0 = 0
  func.call @run_alu(%alu_op_sub, %c0, %c42) : !run_t

  // ALU_OP_SLT (set less-than, signed) ////////////////////////////////////////
  // CHECK: out = 0
  func.call @run_alu(%alu_op_slt, %c0, %c-3) : !run_t

  // CHECK: out = 1
  func.call @run_alu(%alu_op_slt, %c0x80000001, %c0x7fffffff) : !run_t

  // CHECK: out = 1
  func.call @run_alu(%alu_op_slt, %c-3, %c42) : !run_t

  // CHECK: out = 1
  func.call @run_alu(%alu_op_slt, %c42, %c0x12345678) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_slt, %c0x12345678, %c42) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_slt, %c42, %c42) : !run_t

  // ALU_OP_SLTU (set less-than, unsigned) /////////////////////////////////////
  // CHECK: out = 1
  func.call @run_alu(%alu_op_sltu, %c0, %c-3) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_sltu, %c0x80000001, %c0x7fffffff) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_sltu, %c-3, %c42) : !run_t

  // CHECK: out = 1
  func.call @run_alu(%alu_op_sltu, %c42, %c0x12345678) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_sltu, %c0x12345678, %c42) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_sltu, %c42, %c42) : !run_t

  // ALU_OP_XOR (bitwise exclusive or) /////////////////////////////////////////
  // CHECK: out = 9595aa66
  func.call @run_alu(%alu_op_xor, %c0x66993cf0, %c0xf30c9696) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_xor, %c0x66993cf0, %c0x66993cf0) : !run_t

  // CHECK: out = 66993cf0
  func.call @run_alu(%alu_op_xor, %c0x66993cf0, %c0) : !run_t

  // CHECK: out = 9966c30f
  func.call @run_alu(%alu_op_xor, %c0x66993cf0, %c0xffffffff) : !run_t

  // ALU_OP_OR (bitwise or) ////////////////////////////////////////////////////
  // CHECK: out = f79dbef6
  func.call @run_alu(%alu_op_or, %c0x66993cf0, %c0xf30c9696) : !run_t

  // CHECK: out = 66993cf0
  func.call @run_alu(%alu_op_or, %c0x66993cf0, %c0x66993cf0) : !run_t

  // CHECK: out = 66993cf0
  func.call @run_alu(%alu_op_or, %c0x66993cf0, %c0) : !run_t

  // CHECK: out = ffffffff
  func.call @run_alu(%alu_op_or, %c0x66993cf0, %c0xffffffff) : !run_t

  // ALU_OP_AND (bitwise and) //////////////////////////////////////////////////
  // CHECK: out = 62081490
  func.call @run_alu(%alu_op_and, %c0x66993cf0, %c0xf30c9696) : !run_t

  // CHECK: out = 66993cf0
  func.call @run_alu(%alu_op_and, %c0x66993cf0, %c0x66993cf0) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_and, %c0x66993cf0, %c0) : !run_t

  // CHECK: out = 66993cf0
  func.call @run_alu(%alu_op_and, %c0x66993cf0, %c0xffffffff) : !run_t

  // ALU_OP_SLL (shift left, logical) //////////////////////////////////////////
  // CHECK: out = 2
  func.call @run_alu(%alu_op_sll, %c1, %c1) : !run_t

  // CHECK: out = 2
  func.call @run_alu(%alu_op_sll, %c0x80000001, %c1) : !run_t

  // CHECK: out = 200
  func.call @run_alu(%alu_op_sll, %c1, %c-0x12345677) : !run_t

  // CHECK: out = ffffffff
  func.call @run_alu(%alu_op_sll, %c0xffffffff, %c0) : !run_t

  // ALU_OP_SRL (shift right, logical) /////////////////////////////////////////
  // CHECK: out = 7fffffff
  func.call @run_alu(%alu_op_srl, %c0xffffffff, %c1) : !run_t

  // CHECK: out = 334c9e
  func.call @run_alu(%alu_op_srl, %c0x66993cf0, %c-0x12345677) : !run_t

  // CHECK: out = 12345678
  func.call @run_alu(%alu_op_srl, %c0x12345678, %c0) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_srl, %c7, %c3) : !run_t

  // ALU_OP_SRA (shift right, arithmetic) //////////////////////////////////////
  // CHECK: out = f0000000
  func.call @run_alu(%alu_op_sra, %c0x80000001, %c3) : !run_t

  // CHECK: out = ffc3b2a1
  func.call @run_alu(%alu_op_sra, %c0x87654321, %c-0x12345677) : !run_t

  // CHECK: out = 12345678
  func.call @run_alu(%alu_op_sra, %c0x12345678, %c0) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_sra, %c7, %c3) : !run_t

  // ALU_OP_SEQ (set equals) ///////////////////////////////////////////////////
  // CHECK: out = 1
  func.call @run_alu(%alu_op_seq, %c0x12345678, %c0x12345678) : !run_t

  // CHECK: out = 0
  func.call @run_alu(%alu_op_seq, %c0, %c1) : !run_t

  return
}
