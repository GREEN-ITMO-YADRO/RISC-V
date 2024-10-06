This repository contains the source code of a painfully awful RISC-V core named "menace" — a synonym for risk and an apt descriptor for the design quality.

- Menace uses a non-pipelined, two-cycle design (instruction fetch and execution).
- Provides complete support for the base rv32i instruction set with CSR (modulo bugs present in the design).
- Features a minimal implementation of the privileged ISA as allowed by the specification:
  - machine mode (no supervisor/hypervisor modes)
  - direct trap vector mode
- Contains a memory bus that supports memory-mapped I/O.
- Has been tested (sloppily) on a dev board with a Xilinx FPGA (Artix 7 IIRC).
- Also important to understanding the odd design choices is the fact that the whole project had to be finished in under a month.
  Here are some implications:
  - The implementation commits a heinous crime: it does memory write on the rising clock edge and memory read on the falling edge.
  - The memory bus module is inappropriately named MMU.
    Though it was supposed to become that, it didn't due to the lack of time.
  - The code poses difficuly in comprehension as feature completeness was prioritized over readability.

The directory is structured as follows:

- [`core`](./core) contains SystemVerilog files of the actual processor core implementation
- [`board`](./board) contains the top module tailored to the FPGA dev board that was used for testing the device as well as a constraint file for that board (used for implementation)
- [`rom`](./rom) contains a sample Verilog hex file that is written to the ROM; the provided ROM image contains a compiled C program that toggles a LED pin periodically
- [`sim`](./sim) contains files used for simulation: a testbench and a ROM image with the test program; also included is a primitive unidirectional 8-bit bus module that allows the test program to communicate with the testbench with a MMIO interface

Additionally, [`firmware`](./firmware) provides support for compiling C programs for the processor.
Refer to [its README file](./firmware/README.md) for more information.
