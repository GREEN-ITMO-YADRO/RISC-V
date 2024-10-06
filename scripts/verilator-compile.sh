#!/bin/bash

verilator --binary --exe -j 0 --unroll-count 10000 --top-module testbench -Wno-ENUMVALUE \
  core/adder.sv \
  core/enums.sv \
  core/led_mmap.sv \
  core/cpu.sv \
  core/ram.sv \
  core/rom.sv \
  core/word_mmap.sv \
  sim/dut_bus_slave.sv \
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

cd sim 

./../obj_dir/Vtestbench

# cd core.sv.d 
