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

func.func @entry() {
  %c-1234_i32 = hw.constant -1234 : i32
  %c-123_i32 = hw.constant -123 : i32
  %c-3_i32 = hw.constant -3 : i32
  %c42_i32 = hw.constant 42 : i32

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

  // CHECK: out = fffffb58
  // CHECK: out_bit0 = 0
  func.call @run_alu(%alu_op_add, %c42_i32, %c-1234_i32) : (i5, i32, i32) -> ()

  return
}
