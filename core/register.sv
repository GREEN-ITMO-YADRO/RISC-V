module register
    #(parameter WIDTH = 32,
      parameter logic[WIDTH - 1 : 0] RESET_VALUE = 0)
    (input var logic clk,
     input var logic reset,
     input var logic[WIDTH - 1 : 0] wd,
     output var logic[WIDTH - 1 : 0] rd);

    logic[WIDTH - 1 : 0] data;
    assign rd = data;

    always_ff @(posedge clk)
        if (reset) begin
            data <= RESET_VALUE;
        end else begin
            data <= wd;
        end;
endmodule
