`timescale 1ns / 1ps

module ram
    #(parameter integer WORDS = 1024)
     (input  var logic       clk,
      input  var logic       re,
      output var logic[31:0] rd,
      input  var logic       we,
      input  var logic[31:0] wd,
      input  var logic[31:2] addr);

    logic[31:0] ram[WORDS - 1 : 0];

    always_ff @(posedge clk) begin
        if (we) begin
            ram[addr[31:2]] <= wd;
        end;
    end

    always_ff @(negedge clk) begin
        rd <= re ? ram[addr[31:2]] : {32 {1'bx}};
    end;

endmodule

module rom
    #(parameter integer WORDS = 1024,
      parameter string INITIAL_FILE = "")
     (input  var logic       clk,
      input  var logic       re,
      output var logic[31:0] rd,
      input  var logic[31:2] addr);

    logic[31:0] rom[WORDS - 1 : 0];

    logic[7:0] rom_bytes[WORDS * 4 - 1 : 0];

    generate
        for (genvar i = 0; i < WORDS; ++i) begin
            assign rom[i] = {
                rom_bytes[i * 4],
                rom_bytes[i * 4 + 1],
                rom_bytes[i * 4 + 2],
                rom_bytes[i * 4 + 3]
            };
        end;
    endgenerate;

    initial begin
        if (INITIAL_FILE != "") begin
            $readmemh(INITIAL_FILE, rom_bytes);
        end;
    end;

    always_ff @(negedge clk) begin
        rd <= re ? rom[addr[31:2]] : {32 {1'bx}};
    end;

endmodule
