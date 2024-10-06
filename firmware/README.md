This directory contains files used to bootstrap a C environment and compile C programs for the Menace processor.

- [`boot`](./boot) contains a bootloader ([`start.c`](./boot/start.c)) with supporting Assembly code.
- [`app`](./app) contains the actual source code of the compiled application.
  The provided example implements an 8-bit binary counter that shows the current value on the LEDs via MMIO.
- [`rv32.ld`](./rv32.ld) is a linker script that sets up the memory map and exports symbols used in the bootloader.

## Building
First you'll need to build a RISC-V toolchain:

```
$ git clone https://github.com/riscv/riscv-gnu-toolchain
$ cd riscv-gnu-toolchain
$ mkdir target
$ ./configure \
    --prefix="$(pwd)/target" \
    --disable-gdb \
    --with-arch=rv32i_zicsr_zifencei \
    --with-abi=ilp32 \
    --disable-multilib \
    --with-target-cflags='-mbig-endian -mstrict-align -Wl,-melf32briscv'
$ make -j$(nproc)
```

Then, in this directory, build the application by running `make`:

```
$ make TOOLCHAIN_BIN_DIR="$TOOLCHAIN_DIR/target/bin"
```

The built ROM image will be written to `./build/app.mem`.
