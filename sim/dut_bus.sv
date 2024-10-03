interface dut_bus;

    logic[7:0] rx[$];

    modport master(output rx);
    modport slave(input rx);

    task automatic read(input var int count, ref var string str);

        int rx_size = rx.size();

        for (int i = 0; i < count && i < rx_size; ++i) begin
            logic[7:0] rx_byte = rx.pop_front();
            str = {str, rx_byte};
        end;

    endtask;

endinterface

module dut_bus_slave(input var logic clk,
                     dut_bus.slave bus,
                     mmap_dev.slave mmap);

    assign mmap.rd = mmap.re ? 32'b0 : {32 {1'bx}};

    always_ff @(posedge clk) begin
        if (mmap.we) begin
            bus.rx.push_back(mmap.wd[7:0]);
        end;
    end;

endmodule
