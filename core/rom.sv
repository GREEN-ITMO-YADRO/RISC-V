`timescale 1ns / 1ps

module rom #(
    parameter integer WORDS = 1024,
    parameter string INITIAL_FILE = ""
) (
    input  logic        clk,
    input  logic        re,
    output logic [31:0] rd,
    input  logic [31:2] addr
);

    localparam int Width = $clog2(WORDS);
    logic [31:0] rom[WORDS];
    logic [7:0] rom_bytes[WORDS * 4];
    logic [Width - 1 : 0] sel;

    assign sel = addr[2+:Width];

    generate
        for (genvar i = 0; i < WORDS; ++i) begin : gen_rom_init
            assign rom[i] = {rom_bytes[i*4], rom_bytes[i*4+1], rom_bytes[i*4+2], rom_bytes[i*4+3]};
        end
    endgenerate

    initial begin
        if (INITIAL_FILE != "") begin
            $readmemh(INITIAL_FILE, rom_bytes);
        end
    end

    always_ff @(negedge clk) begin
        rd <= re ? rom[sel] : {32{1'bx}};
    end

endmodule
