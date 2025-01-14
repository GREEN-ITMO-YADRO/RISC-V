!addr_t = i5
!rw_independent_t = !arc.sim.instance<@rw_independent>

func.func private @tick.rw_independent(%model : !rw_independent_t) {
  %hi = hw.constant 1 : i1
  %lo = hw.constant 0 : i1

  arc.sim.set_input %model, "clk" = %hi : i1, !rw_independent_t
  arc.sim.step %model : !rw_independent_t

  arc.sim.set_input %model, "clk" = %lo : i1, !rw_independent_t
  arc.sim.step %model : !rw_independent_t

  return
}

hw.module @rw_independent(in %clk : i1, in %rst : i1, out rd : i32) {
  %clk.clk = seq.to_clock %clk

  %lo = hw.constant 0 : i1
  %hi = hw.constant 1 : i1

  %r0 = hw.constant 0 : !addr_t
  %r1 = hw.constant 1 : !addr_t
  %r2 = hw.constant 2 : !addr_t

  %i1 = hw.constant 1 : i32

  %state.1 = hw.constant 1 : i2

  %state.init = hw.constant 0 : i2
  %state.write = hw.constant 1 : i2
  %state.read = hw.constant 2 : i2

  %rd1, %rd2 = hw.instance "regfile" @regfile(clk: %clk: i1, we: %we: i1, wa: %r1: !addr_t, wd: %wd: i32, ra1: %r1: !addr_t, ra2: %r2: !addr_t) -> (rd1: i32, rd2: i32)

  // %state.init -> %state.write (-> %state.read)*
  %state = seq.compreg %state.next, %clk.clk reset %rst, %state.init : i2
  %state.inc = comb.add %state, %state.1 : i2
  %state.next = comb.mux %is_state_read, %state.read, %state.inc : i2

  %is_state_init = comb.icmp eq %state, %state.init : i2
  %is_state_write = comb.icmp eq %state, %state.write : i2
  %is_state_read = comb.icmp eq %state, %state.read : i2

  %we = comb.or %is_state_init, %is_state_write : i1

  %wd.init = hw.constant 42 : i32
  %wd.write = comb.add %rd2, %i1 : i32
  %wd = comb.mux %is_state_init, %wd.init, %wd.write : i32

  hw.output %rd1 : i32
}

func.func @entry() {
  %lo = hw.constant 0 : i1
  %hi = hw.constant 1 : i1

  // read-write (independent registers) ///////////////////////////////////////
  arc.sim.instantiate @rw_independent as %model {
    // reset
    arc.sim.set_input %model, "rst" = %hi : i1, !rw_independent_t
    func.call @tick.rw_independent(%model) : (!rw_independent_t) -> ()

    // init
    arc.sim.set_input %model, "rst" = %lo : i1, !rw_independent_t
    func.call @tick.rw_independent(%model) : (!rw_independent_t) -> ()

    // write
    func.call @tick.rw_independent(%model) : (!rw_independent_t) -> ()

    // read
    func.call @tick.rw_independent(%model) : (!rw_independent_t) -> ()

    %rd = arc.sim.get_port %model, "rd" : i32, !rw_independent_t

    // CHECK: rd = 2b
    arc.sim.emit "rd", %rd : i32
  }

  return
}
