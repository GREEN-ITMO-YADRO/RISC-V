`timescale 1ns / 1ps

module le_to_be #(
    parameter int WIDTH = 32
) (
    input  logic [WIDTH - 1 : 0] in,
    output logic [WIDTH - 1 : 0] out
);

    assign out = {in[7:0], in[15:8], in[23:16], in[31:24]};

endmodule
