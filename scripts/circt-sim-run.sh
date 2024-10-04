#!/bin/bash

circt-rtl-sim.py --sim=verilator --top=rv32_tb --valgrind \
  core/enums.sv \
  core/cpu.sv \
  core/adder.sv \
  core/alu.sv \
  core/counter.sv \
  core/csr.sv \
  core/cu.sv \
  core/register.sv \
  core/datapath.sv \
  core/io.sv \
  core/le_to_be.sv \
  core/mem.sv \
  core/mmu.sv \
  core/mux.sv \
  core/regfile.sv \
  sim/rv32_tb.sv \
  sim/dut_bus.sv \

