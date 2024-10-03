module mux
    #(parameter SELECTOR_WIDTH = 4,
      parameter DATA_WIDTH = 32)
    (input var logic[DATA_WIDTH - 1 : 0] in[0 : (2**SELECTOR_WIDTH) - 1],
     input var logic[SELECTOR_WIDTH - 1 : 0] sel,
     output var logic[DATA_WIDTH - 1 : 0] out);

    assign out = in[sel];

endmodule
