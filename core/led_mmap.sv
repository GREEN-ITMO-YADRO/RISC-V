`timescale 1ns / 1ps

module led_mmap (
    input  logic        clk,
    input  logic        reset,
    output logic [ 7:0] led,
    input  logic        re,
    output logic [31:0] rd,
    input  logic        we,
    input  logic [31:0] wd,
    input  logic [31:2] addr
);

    logic [7:0] led_rd, led_wd;
    assign rd = {24'b0, led_rd};
    assign led_wd = we ? wd[7:0] : led_rd;

    register #(
        .WIDTH(8),
        .RESET_VALUE(8'b0)
    ) led_reg (
        .clk(clk),
        .reset(reset),
        .rd(led_rd),
        .wd(led_wd)
    );

    assign led = led_rd;

endmodule
