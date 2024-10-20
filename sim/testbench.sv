`timescale 1ns / 1ps

module testbench;

    logic clk;
    logic [7:0] led;

    logic reset;
    logic mem_re;
    logic mem_we;
    logic [1:0] mem_rd_unit, mem_wd_unit;
    logic [31:0] mem_addr, mem_wd, mem_rd;

    logic [63:0] mtime, mtime_next;
    logic [63:0] mtimecmp, mtimecmp_next;

    logic access_fault, addr_misaligned;

    logic [7:0] dut_bus_rx[$];

    logic [31:2] rom_addr, ram_addr, led_addr, mtime_addr, mtimecmp_addr, dut_bus_addr;
    logic rom_re, ram_re, led_re, mtime_re, mtimecmp_re, dut_bus_re;
    logic [31:0] rom_rd, ram_rd, led_rd, mtime_rd, mtimecmp_rd, dut_bus_rd;
    logic rom_we, ram_we, led_we, mtime_we, mtimecmp_we, dut_bus_we;
    logic [31:0] rom_wd, ram_wd, led_wd, mtime_wd, mtimecmp_wd, dut_bus_wd;

    rom #(
        .WORDS(8192),
        .INITIAL_FILE("rv32_tb1.mem")
    ) rom (
        .clk (clk),
        .re  (rom_re),
        .rd  (rom_rd),
        .addr(rom_addr)
    );
    ram #(
        .WORDS(32768)
    ) ram (
        .clk (clk),
        .re  (ram_re),
        .rd  (ram_rd),
        .we  (ram_we),
        .wd  (ram_wd),
        .addr(ram_addr)
    );
    led_mmap led_mmap (
        .clk(clk),
        .reset(reset),
        .led(led),
        .re(led_re),
        .rd(led_rd),
        .we(led_we),
        .wd(led_wd),
        .addr(led_addr)
    );
    word_mmap #(
        .WORDS(2)
    ) mtime_mmap (
        .mem_rd(mtime),
        .mem_wd(mtime_next),
        .re(mtime_re),
        .rd(mtime_rd),
        .we(mtime_we),
        .wd(mtime_wd),
        .addr(mtime_addr)
    );
    word_mmap #(
        .WORDS(2)
    ) mtimecmp_mmap (
        .mem_rd(mtimecmp),
        .mem_wd(mtimecmp_next),
        .re(mtimecmp_re),
        .rd(mtimecmp_rd),
        .we(mtimecmp_we),
        .wd(mtimecmp_wd),
        .addr(mtimecmp_addr)
    );
    dut_bus_slave dut_bus_slave (
        .clk(clk),
        .bus_rx(dut_bus_rx),
        .re(dut_bus_re),
        .rd(dut_bus_rd),
        .we(dut_bus_we),
        .wd(dut_bus_wd)
    );

    mmu #(
        .DEVICE_COUNT(6)
    ) mmu (
        .re(mem_re),
        .we(mem_we),
        .rd_unit(mem_rd_unit),
        .wd_unit(mem_wd_unit),
        .addr(mem_addr),
        .wd(mem_wd),
        .rd(mem_rd),

        .access_fault(access_fault),
        .addr_misaligned(addr_misaligned),

        .dev_addr('{rom_addr, ram_addr, led_addr, mtime_addr, mtimecmp_addr, dut_bus_addr}),
        .dev_re('{rom_re, ram_re, led_re, mtime_re, mtimecmp_re, dut_bus_re}),
        .dev_rd('{rom_rd, ram_rd, led_rd, mtime_rd, mtimecmp_rd, dut_bus_rd}),
        .dev_we('{rom_we, ram_we, led_we, mtime_we, mtimecmp_we, dut_bus_we}),
        .dev_wd('{rom_wd, ram_wd, led_wd, mtime_wd, mtimecmp_wd, dut_bus_wd}),
        .dev_rw('{1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1}),
        .dev_addr_start(
        '{32'h8000_0000, 32'h4000_0000, 32'ha000_0000, 32'ha000_0010, 32'ha000_0018, 32'hc000_0000}
        ),
        .dev_addr_end(
        '{32'h8000_7fff, 32'h4001_ffff, 32'ha000_0003, 32'ha000_0017, 32'ha000_001f, 32'hc000_0003}
        )
    );

    cpu dut (
        .clk(clk),
        .reset(reset),
        .mem_re(mem_re),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wd(mem_wd),
        .mem_rd(mem_rd),
        .mem_rd_unit(mem_rd_unit),
        .mem_wd_unit(mem_wd_unit),

        .mtime(mtime),
        .mtime_next(mtime_next),
        .mtime_we(mtime_we),
        .mtimecmp(mtimecmp),
        .mtimecmp_next(mtimecmp_next),

        .access_fault(access_fault),
        .addr_misaligned(addr_misaligned)
    );

    task automatic read(input int count, ref string str);

        int rx_size = dut_bus_rx.size();

        for (int i = 0; i < count && i < rx_size; ++i) begin
            logic [7:0] rx_byte = dut_bus_rx.pop_front();
            str = {str, string'(rx_byte)};
        end

    endtask

    initial begin
        clk = 1'b1;

        forever begin
            #5 clk = ~clk;
        end
    end

    string buffer;

    initial begin
        reset = 1'b1;
        #100 reset = 1'b0;
        #250000;
        read(13, buffer);
        $display("%d", dut_bus_rx.size());
        if (buffer != "hello, rv32i!") begin
            $fatal(2, "tb failed: got '%s'", buffer);
        end
        $finish;
    end

endmodule
