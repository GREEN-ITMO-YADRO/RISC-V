module dut_bus_slave
    (input  var logic       clk,
     input  var logic[7:0]  bus_rx[$],
     input  var logic       re,
     output var logic[31:0] rd,
     input  var logic       we,
     input  var logic[31:0] wd);

    assign rd = re ? 32'b0 : {32 {1'bx}};

    always_ff @(posedge clk) begin
        if (we) begin
            bus_rx.push_back(wd[7:0]);
        end;
    end;

endmodule
