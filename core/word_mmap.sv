`timescale 1ns / 1ps

module word_mmap #(
    parameter int WORDS = 1
) (
    input  logic [32 * WORDS - 1 : 0] mem_rd,
    output logic [32 * WORDS - 1 : 0] mem_wd,

    input  logic        re,
    output logic [31:0] rd,
    input  logic        we,
    input  logic [31:0] wd,
    input  logic [31:2] addr
);

    logic [WORDS - 1 : 0][31:0] rd_words;
    logic [WORDS - 1 : 0][31:0] wd_words;

    assign rd_words = mem_rd;
    assign mem_wd = wd_words;

    assign rd = rd_words[addr[31:2]];

    always_comb begin
        wd_words = rd_words;

        if (we) begin
            wd_words[addr[31:2]] = wd;
        end
    end

endmodule
