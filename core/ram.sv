`timescale 1ns / 1ps

module ram #(
    parameter int WORDS = 1024
) (
    input  logic        clk,
    input  logic        re,
    output logic [31:0] rd,
    input  logic        we,
    input  logic [31:0] wd,
    input  logic [31:2] addr
);

    localparam int Width = $clog2(WORDS);
    logic [31:0] ram[WORDS];
    logic [Width - 1 : 0] sel;
    
    assign sel = addr[2+:Width];

    always_ff @(posedge clk) begin
        if (we) begin
            ram[sel] <= wd;
        end
    end

    always_ff @(negedge clk) begin
        rd <= re ? ram[sel] : {32{1'bx}};
    end

endmodule
