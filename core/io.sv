module word_mmap
    #(parameter WORDS = 1)
     (input  var logic[32 * WORDS - 1 : 0] mem_rd,
      output var logic[32 * WORDS - 1 : 0] mem_wd,

      input  var logic       re,
      output var logic[31:0] rd,
      input  var logic       we,
      input  var logic[31:0] wd,
      input  var logic[31:2] addr);

    logic[WORDS - 1 : 0][31:0] rd_words;
    logic[WORDS - 1 : 0][31:0] wd_words;

    assign rd_words = mem_rd;
    assign mem_wd = wd_words;

    assign rd = rd_words[addr[31:2]];

    always_comb begin
        wd_words = rd_words;

        if (we) begin
            wd_words[addr[31:2]] = wd;
        end;
    end;

endmodule

module led_mmap
    (input  var logic       clk, reset,
     output var logic[7:0]  led,
     input  var logic       re,
     output var logic[31:0] rd,
     input  var logic       we,
     input  var logic[31:0] wd,
     input  var logic[31:2] addr);

    logic[7:0] led_rd, led_wd;
    assign rd = {24'b0, led_rd};
    assign led_wd = we ? wd[7:0] : led_rd;

    register #(.WIDTH(8), .RESET_VALUE(8'b0)) led_reg(
        .clk(clk), .reset(reset),
        .rd(led_rd), .wd(led_wd)
    );

    assign led = led_rd;

endmodule
