`timescale 1ns / 1ps

module mux #(
    parameter int SELECTOR_WIDTH = 4,
    parameter int DATA_WIDTH = 32
) (
    input logic [DATA_WIDTH - 1 : 0] in[2**SELECTOR_WIDTH],
    input logic [SELECTOR_WIDTH - 1 : 0] sel,
    output logic [DATA_WIDTH - 1 : 0] out
);

    assign out = in[sel];

endmodule
