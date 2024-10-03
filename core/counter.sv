module counter
    #(parameter WIDTH = 32)
    (input var logic clk, reset,
     output var logic[WIDTH - 1 : 0] rd,
     input var logic[WIDTH - 1 : 0] wd,
     input var logic we,
     input var logic enable);

    logic[WIDTH - 1 : 0] next;

    register #(.WIDTH(WIDTH), .RESET_VALUE(1'b0)) ctr_reg(
        .clk(clk), .reset(reset),
        .rd(rd), .wd(next)
    );

    always_comb begin
        if (we) begin
            next = wd;
        end else if (enable) begin
            next = rd + 1;
        end else begin
            next = rd;
        end;
    end;

endmodule
