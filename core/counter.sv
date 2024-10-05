`timescale 1ns / 1ps

module counter #(
    parameter int WIDTH = 32
) (
    input logic clk,
    input logic reset,
    output logic [WIDTH - 1 : 0] rd,
    input logic [WIDTH - 1 : 0] wd,
    input logic we,
    input logic enable
);

    logic [WIDTH - 1 : 0] next;

    register #(
        .WIDTH(WIDTH)
    ) ctr_reg (
        .clk(clk),
        .reset(reset),
        .rd(rd),
        .wd(next)
    );

    always_comb begin
        if (we) begin
            next = wd;
        end else if (enable) begin
            next = rd + 1;
        end else begin
            next = rd;
        end
    end

endmodule
