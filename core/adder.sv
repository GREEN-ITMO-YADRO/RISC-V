module adder
    #(parameter WIDTH = 32)
    (input var logic[WIDTH - 1 : 0] lhs,
     input var logic[WIDTH - 1 : 0] rhs,
     output var logic[WIDTH - 1 : 0] out);

    assign out = lhs + rhs;

endmodule
