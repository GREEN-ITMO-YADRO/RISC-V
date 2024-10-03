`timescale 1ns / 1ps

module rv32_tb();

    logic clk;
    logic[7:0] led;

    logic reset;
    logic mem_re;
    logic mem_we;
    logic[1:0] mem_rd_unit, mem_wd_unit;
    logic[31:0] mem_addr, mem_wd, mem_rd;

    logic[63:0] mtime, mtime_next;
    logic[63:0] mtimecmp, mtimecmp_next;

    logic access_fault, addr_misaligned;

    dut_bus bus();

    mmap_dev #(
        .ADDR_START(32'h8000_0000), .ADDR_END(32'h8000_7fff), .RW(1'b0)
    ) rom_if();
    mmap_dev #(.ADDR_START(32'h4000_0000), .ADDR_END(32'h4001_ffff)) ram_if();
    mmap_dev #(.ADDR_START(32'ha000_0000), .ADDR_END(32'ha000_0003)) led_if();
    mmap_dev #(.ADDR_START(32'ha000_0010), .ADDR_END(32'ha000_0017)) mtime_if();
    mmap_dev #(.ADDR_START(32'ha000_0018), .ADDR_END(32'ha000_001f)) mtimecmp_if();
    mmap_dev #(.ADDR_START(32'hc000_0000), .ADDR_END(32'hc000_0003)) dut_bus_if();

    rom #(.WORDS(8192), .INITIAL_FILE("rv32_tb1.mem")) rom(
        .clk(clk),
        .iface(rom_if.slave)
    );
    ram #(.WORDS(32768)) ram(
        .clk(clk),
        .iface(ram_if.slave)
    );
    led_mmap led_mmap(
        .clk(clk), .reset(reset),
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
    dut_bus_slave dut_bus_slave(
        .clk(clk),
        .bus(bus.slave),
        .mmap(dut_bus_if.slave)
    );

    mmu #(.DEVICE_COUNT(6)) mmu(
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
            ram_if.master,
            led_if.master,
            mtime_if.master,
            mtimecmp_if.master,
            dut_bus_if.master
        })
    );

    cpu dut(
        .clk(clk), .reset(reset),
        .mem_re(mem_re), .mem_we(mem_we),
        .mem_addr(mem_addr), .mem_wd(mem_wd), .mem_rd(mem_rd),
        .mem_rd_unit(mem_rd_unit), .mem_wd_unit(mem_wd_unit),

        .mtime(mtime), .mtime_next(mtime_next), .mtime_we(mtime_if.we),
        .mtimecmp(mtimecmp), .mtimecmp_next(mtimecmp_next),

        .access_fault(access_fault),
        .addr_misaligned(addr_misaligned)
    );

    initial begin
        clk = 1'b1;

        forever begin
            #5 clk = ~clk;
        end;
    end;

    string buffer;

    initial begin
        reset = 1'b1;
        #100 reset = 1'b0;
        #250000;
        bus.read(13, buffer);
        assert (buffer == "hello, rv32i!") else $fatal(2, "tb failed");
        $finish;
    end;

endmodule
