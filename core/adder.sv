`timescale 1ns / 1ps

module adder #(
    parameter int WIDTH = 32
) (
    input  logic [WIDTH - 1 : 0] lhs,
    input  logic [WIDTH - 1 : 0] rhs,
    output logic [WIDTH - 1 : 0] out
);

    assign out = lhs + rhs;

endmodule
