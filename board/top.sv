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

    mmap_dev #(
        .ADDR_START(32'h8000_0000), .ADDR_END(32'h8000_7fff), .RW(1'b0)
    ) rom_if();

    mmap_dev #(.ADDR_START(32'h4000_0000), .ADDR_END(32'h4000_ffff)) ram1_if();
    mmap_dev #(.ADDR_START(32'h4001_0000), .ADDR_END(32'h4001_7fff)) ram2_if();
    mmap_dev #(.ADDR_START(32'h4001_8000), .ADDR_END(32'h4001_bfff)) ram3_if();
    mmap_dev #(.ADDR_START(32'h4001_c000), .ADDR_END(32'h4001_ffff)) ram4_if();

    mmap_dev #(.ADDR_START(32'ha000_0000), .ADDR_END(32'ha000_0003)) led_if();
    mmap_dev #(.ADDR_START(32'ha000_0010), .ADDR_END(32'ha000_0017)) mtime_if();
    mmap_dev #(.ADDR_START(32'ha000_0018), .ADDR_END(32'ha000_001f)) mtimecmp_if();

    rom #(.WORDS(8192), .INITIAL_FILE("../mem/app.mem")) rom(.clk(clk32), .iface(rom_if.slave));

    ram #(.WORDS(16384)) ram1(.clk(clk32), .iface(ram1_if.slave));
    ram #(.WORDS(8192)) ram2(.clk(clk32), .iface(ram2_if.slave));
    ram #(.WORDS(4096)) ram3(.clk(clk32), .iface(ram3_if.slave));
    ram #(.WORDS(4096)) ram4(.clk(clk32), .iface(ram4_if.slave));

    led_mmap led_mmap(
        .clk(clk32), .reset(reset),
        .led(led), .iface(led_if.slave)
    );
    word_mmap #(.WORDS(2)) mtime_mmap(
        .rd(mtime), .wd(mtime_next),
        .iface(mtime_if.slave)
    );
    word_mmap #(.WORDS(2)) mtimecmp_mmap(
        .rd(mtimecmp), .wd(mtimecmp_next),
        .iface(mtimecmp_if.slave)
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

        .dev_ifs('{
            rom_if.master,

            ram1_if.master,
            ram2_if.master,
            ram3_if.master,
            ram4_if.master,

            led_if.master,
            mtime_if.master,
            mtimecmp_if.master
        })
    );

    cpu core(
        .clk(clk32), .reset(reset),
        .mem_re(mem_re), .mem_we(mem_we),
        .mem_addr(mem_addr), .mem_wd(mem_wd), .mem_rd(mem_rd),
        .mem_rd_unit(mem_rd_unit), .mem_wd_unit(mem_wd_unit),

        .mtime(mtime), .mtime_next(mtime_next), .mtime_we(mtime_if.we),
        .mtimecmp(mtimecmp), .mtimecmp_next(mtimecmp_next),

        .access_fault(access_fault),
        .addr_misaligned(addr_misaligned)
    );

endmodule
