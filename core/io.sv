module word_mmap
    #(parameter WORDS = 1)
    (input var logic[32 * WORDS - 1 : 0] rd,
     output var logic[32 * WORDS - 1 : 0] wd,
     mmap_dev.slave iface);

    logic[WORDS - 1 : 0][31:0] rd_words;
    logic[WORDS - 1 : 0][31:0] wd_words;

    assign rd_words = rd;
    assign wd = wd_words;

    assign iface.rd = rd_words[iface.addr[31:2]];

    always_comb begin
        wd_words = rd_words;

        if (iface.we) begin
            wd_words[iface.addr[31:2]] = iface.wd;
        end;
    end;

endmodule

module led_mmap(input var logic clk, reset,
                output var logic[7:0] led,
                mmap_dev.slave iface);

    logic[7:0] rd, wd;
    assign iface.rd = {24'b0, rd};
    assign wd = iface.we ? iface.wd[7:0] : rd;

    register #(.WIDTH(8), .RESET_VALUE(8'b0)) led_reg(
        .clk(clk), .reset(reset),
        .rd(rd), .wd(wd)
    );

    assign led = rd;

endmodule
