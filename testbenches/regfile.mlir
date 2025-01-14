!regfile_t = !arc.sim.instance<@regfile>
!addr_t = i5

!tick_t = (!regfile_t) -> ()
!set_inputs_t = (!regfile_t, i1, !addr_t, i32, !addr_t, !addr_t) -> ()
!emit_outputs_t = (!regfile_t) -> ()
!run_read_t = (!regfile_t, !addr_t, !addr_t) -> ()
!run_write_t = (!regfile_t, !addr_t, i32) -> ()

func.func private @tick(%model : !regfile_t) {
  %hi = hw.constant 1 : i1
  %lo = hw.constant 0 : i1

  arc.sim.set_input %model, "clk" = %hi : i1, !regfile_t
  arc.sim.step %model : !regfile_t

  arc.sim.set_input %model, "clk" = %lo : i1, !regfile_t
  arc.sim.step %model : !regfile_t

  return
}

func.func private @set_inputs(%model : !regfile_t, %we : i1, %wa : !addr_t, %wd : i32, %ra1 : !addr_t, %ra2 : !addr_t) {
  arc.sim.set_input %model, "we" = %we : i1, !regfile_t
  arc.sim.set_input %model, "wa" = %wa : !addr_t, !regfile_t
  arc.sim.set_input %model, "wd" = %wd : i32, !regfile_t
  arc.sim.set_input %model, "ra1" = %ra1 : !addr_t, !regfile_t
  arc.sim.set_input %model, "ra2" = %ra2 : !addr_t, !regfile_t

  return
}

func.func private @emit_outputs(%model : !regfile_t) {
  %rd1 = arc.sim.get_port %model, "rd1" : i32, !regfile_t
  %rd2 = arc.sim.get_port %model, "rd2" : i32, !regfile_t

  arc.sim.emit "rd1", %rd1 : i32
  arc.sim.emit "rd2", %rd2 : i32

  return
}

func.func private @run_read(%model : !regfile_t, %ra1 : !addr_t, %ra2 : !addr_t) {
  %lo = hw.constant 0 : i1
  %r0 = hw.constant 0 : !addr_t
  %i0 = hw.constant 0 : i32

  func.call @set_inputs(%model, %lo, %r0, %i0, %ra1, %ra2) : !set_inputs_t
  func.call @tick(%model) : !tick_t
  func.call @emit_outputs(%model) : !emit_outputs_t

  return
}

func.func private @run_write(%model : !regfile_t, %wa : !addr_t, %wd : i32) {
  %hi = hw.constant 1 : i1
  %r0 = hw.constant 0 : !addr_t
  func.call @set_inputs(%model, %hi, %wa, %wd, %r0, %r0) : !set_inputs_t
  func.call @tick(%model) : !tick_t

  return
}

func.func @entry() {
  %lo = hw.constant 0 : i1
  %hi = hw.constant 1 : i1

  %r0 = hw.constant 0 : !addr_t
  %r1 = hw.constant 1 : !addr_t
  %r2 = hw.constant 2 : !addr_t
  %r3 = hw.constant 3 : !addr_t
  %r4 = hw.constant 4 : !addr_t

  %i0 = hw.constant 0 : i32
  %i24 = hw.constant 24 : i32
  %i42 = hw.constant 42 : i32
  // 0b11110011000011001001011010010110
  %i0xf30c9696 = hw.constant 0xf30c9696 : i32

  // zero register read ///////////////////////////////////////////////////////
  arc.sim.instantiate @regfile as %model {
    // CHECK: rd1 = 0
    func.call @run_read(%model, %r0, %r1) : !run_read_t

    // CHECK: rd2 = 0
    func.call @run_read(%model, %r1, %r0) : !run_read_t

    // CHECK: rd1 = 0
    // CHECK: rd2 = 0
    func.call @run_read(%model, %r0, %r0) : !run_read_t
  }

  // register write ///////////////////////////////////////////////////////////
  arc.sim.instantiate @regfile as %model {
    func.call @run_write(%model, %r1, %i42) : !run_write_t
    func.call @tick(%model) : !tick_t

    // CHECK: rd1 = 2a
    func.call @run_read(%model, %r1, %r0) : !run_read_t

    // ensure that the register is only overwritten on a clock tick
    func.call @set_inputs(%model, %hi, %r1, %i0xf30c9696, %r1, %r0) : !set_inputs_t
    arc.sim.step %model : !regfile_t
    // CHECK: rd1 = 2a
    func.call @emit_outputs(%model) : !emit_outputs_t
    func.call @tick(%model) : !tick_t
    // CHECK: rd1 = f30c9696
    func.call @emit_outputs(%model) : !emit_outputs_t
  }

  // dual-port read ///////////////////////////////////////////////////////////
  arc.sim.instantiate @regfile as %model {
    func.call @run_write(%model, %r1, %i24) : !run_write_t
    func.call @run_write(%model, %r2, %i42) : !run_write_t

    // CHECK: rd1 = 18
    // CHECK: rd2 = 2a
    func.call @run_read(%model, %r1, %r2) : !run_read_t

    // CHECK: rd1 = 18
    // CHECK: rd2 = 18
    func.call @run_read(%model, %r1, %r1) : !run_read_t
  }

  return
}
