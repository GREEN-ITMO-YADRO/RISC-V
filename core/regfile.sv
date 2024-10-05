`timescale 1ns / 1ps

module regfile (
    input logic clk,

    input logic we,
    input logic [4:0] wa,
    input logic [31:0] wd,

    input  logic [ 4:0] ra1,
    input  logic [ 4:0] ra2,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);

    logic [31:0] registers[1:31];

    assign rd1 = (ra1 == 0) ? 0 : registers[ra1];
    assign rd2 = (ra2 == 0) ? 0 : registers[ra2];

    always_ff @(posedge clk) begin
        if (we) begin
            if (wa != 0) begin
                registers[wa] <= wd;
            end
        end
    end

endmodule
