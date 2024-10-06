`timescale 1ns / 1ps

module register #(
    parameter int WIDTH = 32,
    parameter logic [WIDTH - 1 : 0] RESET_VALUE = '0
) (
    input logic clk,
    input logic reset,
    input logic [WIDTH - 1 : 0] wd,
    output logic [WIDTH - 1 : 0] rd
);

    logic [WIDTH - 1 : 0] data;
    assign rd = data;

    always_ff @(posedge clk)
        if (reset) begin
            data <= RESET_VALUE;
        end else begin
            data <= wd;
        end
endmodule
