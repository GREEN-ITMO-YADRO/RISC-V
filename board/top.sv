`timescale 1ns / 1ps

module top(input var logic clk32,
           input var logic btn,
           output var logic[7:0] led);

    logic reset;
    logic mem_re, mem_we;
    logic[1:0] mem_rd_unit, mem_wd_unit;
    logic[31:0] mem_addr, mem_wd, mem_rd;

    logic[63:0] mtime, mtime_next;
    logic[63:0] mtimecmp, mtimecmp_next;

    logic access_fault, addr_misaligned;

    assign reset = ~btn;

    logic[31:2] rom_addr, ram_addr[4], led_addr, mtime_addr, mtimecmp_addr;
    logic       rom_re, ram_re[4], led_re, mtime_re, mtimecmp_re;
    logic[31:0] rom_rd, ram_rd[4], led_rd, mtime_rd, mtimecmp_rd;
    logic       rom_we, ram_we[4], led_we, mtime_we, mtimecmp_we;
    logic[31:0] rom_wd, ram_wd[4], led_wd, mtime_wd, mtimecmp_wd;

    rom #(.WORDS(8192), .INITIAL_FILE("mem/app.mem")) rom(
        .clk(clk32),
        .re(rom_re), .rd(rom_rd), .addr(rom_addr)
    );

    ram #(.WORDS(16384)) ram1(
        .clk(clk32),
        .re(ram_re[0]), .rd(ram_rd[0]),
        .we(ram_we[0]), .wd(ram_wd[0]),
        .addr(ram_addr[0])
    );
    ram #(.WORDS(8192)) ram2(
        .clk(clk32),
        .re(ram_re[1]), .rd(ram_rd[1]),
        .we(ram_we[1]), .wd(ram_wd[1]),
        .addr(ram_addr[1])
    );
    ram #(.WORDS(4096)) ram3(
        .clk(clk32),
        .re(ram_re[2]), .rd(ram_rd[2]),
        .we(ram_we[2]), .wd(ram_wd[2]),
        .addr(ram_addr[2])
    );
    ram #(.WORDS(4096)) ram4(
        .clk(clk32),
        .re(ram_re[3]), .rd(ram_rd[3]),
        .we(ram_we[3]), .wd(ram_wd[3]),
        .addr(ram_addr[3])
    );

    led_mmap led_mmap(
        .clk(clk32), .reset(reset),
        .led(led),
        .re(led_re), .rd(led_rd),
        .we(led_we), .wd(led_wd),
        .addr(led_addr)
    );
    word_mmap #(.WORDS(2)) mtime_mmap(
        .mem_rd(mtime), .mem_wd(mtime_next),
        .re(mtime_re), .rd(mtime_rd),
        .we(mtime_we), .wd(mtime_wd),
        .addr(mtime_addr)
    );
    word_mmap #(.WORDS(2)) mtimecmp_mmap(
        .mem_rd(mtimecmp), .mem_wd(mtimecmp_next),
        .re(mtimecmp_re), .rd(mtimecmp_rd),
        .we(mtimecmp_we), .wd(mtimecmp_wd),
        .addr(mtimecmp_addr)
    );

    mmu #(.DEVICE_COUNT(8)) mmu(
        .re(mem_re),
        .we(mem_we),
        .rd_unit(mem_rd_unit),
        .wd_unit(mem_wd_unit),
        .addr(mem_addr),
        .wd(mem_wd),
        .rd(mem_rd),

        .access_fault(access_fault),
        .addr_misaligned(addr_misaligned),

        .dev_addr('{rom_addr, ram_addr[0], ram_addr[1], ram_addr[2], ram_addr[3], led_addr, mtime_addr, mtimecmp_addr}),
        .dev_re('{rom_re, ram_re[0], ram_re[1], ram_re[2], ram_re[3], led_re, mtime_re, mtimecmp_re}),
        .dev_rd('{rom_rd, ram_rd[0], ram_rd[1], ram_rd[2], ram_rd[3], led_rd, mtime_rd, mtimecmp_rd}),
        .dev_we('{rom_we, ram_we[0], ram_we[1], ram_we[2], ram_we[3], led_we, mtime_we, mtimecmp_we}),
        .dev_wd('{rom_wd, ram_wd[0], ram_wd[1], ram_wd[2], ram_wd[3], led_wd, mtime_wd, mtimecmp_wd}),
        .dev_rw('{1'b0,   1'b1,      1'b1,      1'b1,      1'b1,      1'b1,   1'b1,     1'b1}),
        .dev_addr_start('{
            32'h8000_0000,
            32'h4000_0000,
            32'h4001_0000,
            32'h4001_8000,
            32'h4001_c000,
            32'ha000_0000,
            32'ha000_0010,
            32'ha000_0018
        }),
        .dev_addr_end('{
            32'h8000_7fff,
            32'h4000_ffff,
            32'h4001_7fff,
            32'h4001_bfff,
            32'h4001_ffff,
            32'ha000_0003,
            32'ha000_0017,
            32'ha000_001f
        })
    );

    cpu core(
        .clk(clk32), .reset(reset),
        .mem_re(mem_re), .mem_we(mem_we),
        .mem_addr(mem_addr), .mem_wd(mem_wd), .mem_rd(mem_rd),
        .mem_rd_unit(mem_rd_unit), .mem_wd_unit(mem_wd_unit),

        .mtime(mtime), .mtime_next(mtime_next), .mtime_we(mtime_we),
        .mtimecmp(mtimecmp), .mtimecmp_next(mtimecmp_next),

        .access_fault(access_fault),
        .addr_misaligned(addr_misaligned)
    );

endmodule
