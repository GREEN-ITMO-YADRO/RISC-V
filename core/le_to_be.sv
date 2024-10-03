module le_to_be
    #(parameter WIDTH = 32)
    (input var logic[WIDTH - 1 : 0] in,
     output var logic[WIDTH - 1 : 0] out);

    assign out = {in[7:0], in[15:8], in[23:16], in[31:24]};
endmodule
