#!/bin/bash

circt-rtl-sim.py --sim=verilator core/cpu.sv core/adder.sv core/alu.sv core/counter.sv core/csr.sv core/cu.sv core/datapath.sv core/enums.sv core/io.sv core/le_to_be.sv core/mem.sv core/mmu.sv core/mux.sv core/regfile.

