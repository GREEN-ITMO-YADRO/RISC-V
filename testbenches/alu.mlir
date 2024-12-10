func.func @entry() {
  %c42_i32 = hw.constant 42 : i32
  %c-1234_i32 = hw.constant -1234 : i32

  %alu_op_add = hw.constant 1 : i5

  arc.sim.instantiate @alu as %model {
    arc.sim.set_input %model, "lhs" = %c42_i32 : i32, !arc.sim.instance<@alu>
    arc.sim.set_input %model, "rhs" = %c-1234_i32 : i32, !arc.sim.instance<@alu>
    arc.sim.set_input %model, "alu_op" = %alu_op_add : i5, !arc.sim.instance<@alu>

    arc.sim.step %model : !arc.sim.instance<@alu>

    %out = arc.sim.get_port %model, "out" : i32, !arc.sim.instance<@alu>
    %out_bit0 = arc.sim.get_port %model, "out_bit0" : i1, !arc.sim.instance<@alu>

    // CHECK: out value = fffffb58
    arc.sim.emit "out value", %out : i32
    // CHECK: out_bit0 value = 0
    arc.sim.emit "out_bit0 value", %out_bit0 : i1
  }

  return
}
