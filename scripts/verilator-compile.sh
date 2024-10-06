#!/bin/bash

verilator --binary --unroll-count 10000 -j 0 \
  core/enums.sv \
  core/led_mmap.sv \
  core/cpu.sv \
  core/ram.sv \
  core/rom.sv \
  core/word_mmap.sv \
  sim/dut_bus_slave.sv \
  core/adder.sv \
  core/alu.sv \
  core/counter.sv \
  core/csr.sv \
  core/cu.sv \
  core/register.sv \
  core/datapath.sv \
  core/le_to_be.sv \
  core/mmu.sv \
  core/mux.sv \
  core/regfile.sv \
  sim/testbench.sv 
