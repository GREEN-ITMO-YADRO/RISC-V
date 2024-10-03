OUTPUT_FORMAT("elf32-bigriscv", "elf32-bigriscv", "elf32-bigriscv")
OUTPUT_ARCH(riscv)
ENTRY(_reset)
SEARCH_DIR("/hdd1/riscv/riscv32-unknown-elf/lib");

MEMORY {
    rom (rx) : ORIGIN = 0x80000000, LENGTH = 0x8000
    ram (rwx) : ORIGIN = 0x40000000, LENGTH = 0x20000
    led (rw) : ORIGIN = 0xa0000000, LENGTH = 0x4
    mtime (rw) : ORIGIN = 0xa0000010, LENGTH = 0x8
    mtimecmp (rw) : ORIGIN = 0xa0000018, LENGTH = 0x8
    dut_bus (w) : ORIGIN = 0xc0000000, LENGTH = 0x4
}

STACK_SIZE = 0x800;

PROVIDE(__ram_end = ORIGIN(ram) + LENGTH(ram));
PROVIDE(__led_start = ORIGIN(led));
PROVIDE(__mtime_start = ORIGIN(mtime));
PROVIDE(__dut_bus_start = ORIGIN(dut_bus));

SECTIONS {
    .text : {
        PROVIDE(__trap_base = .);
        KEEP(*(.trap))
        . = ORIGIN(rom) + 0x100;
        KEEP(*(.reset))

        . = ALIGN(4);
        *(.text .text.* .gnu.linkonce.t.*)
        . = ALIGN(4);
        *(.rodata .rodata.* .gnu.linkonce.r.*)
        . = ALIGN(4);

        KEEP(*(.init));
        . = ALIGN(4);

        PROVIDE_HIDDEN(__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE_HIDDEN(__preinit_array_end = .);

        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP(*(.init_array EXCLUDE_FILE(*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o) .ctors))
        PROVIDE_HIDDEN(__init_array_end = .);

        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
        KEEP(*(.fini_array EXCLUDE_FILE(*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o) .dtors))
        PROVIDE_HIDDEN(__fini_array_end = .);

        KEEP(*crtbegin.o(.ctors))
        KEEP(*crtbegin?.o(.ctors))
        KEEP(*(EXCLUDE_FILE(*crtend.o *crtend?.o) .dtors))
        KEEP(*(SORT(.dtors.*)))
        KEEP(*(.dtors))

        PROVIDE(__text_end = .);
    } > rom

    .bss (NOLOAD) : {
        PROVIDE(__bss_start = .);
        *(.bss*)
        *(COMMON)
        PROVIDE(__bss_end = .);
    } > ram

    .data : {
        . = ALIGN(4);

        PROVIDE(__data_start = .);

        *(.data .data.* .gnu.linkonce.d.*)
        SORT(CONSTRUCTORS);

        PROVIDE(__sdata_start = .);
        *(.srodata .srodata.*)
        *(.sdata .sdata.* .gnu.linkonce.s.*)

        PROVIDE(__data_end = .);
    } > ram AT > rom

    PROVIDE(__data_rom_start = LOADADDR(.data));
    PROVIDE(__global_pointer =
        MIN(__sdata_start + 0x800, MAX(__data_start + 0x800, __bss_end - 0x800)));

    .stack (NOLOAD) : {
        . = . + STACK_SIZE;
        . = ALIGN(16);
        PROVIDE(__stack_top = .);
    } > ram

    PROVIDE(__end = .);
}

/* vim: set expandtab tabstop=4 shiftwidth=4 smartindent : */
