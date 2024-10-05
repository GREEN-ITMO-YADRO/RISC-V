module dut_bus_slave (
    input  logic        clk,
    ref    logic [ 7:0] bus_rx[$],
    input  logic        re,
    output logic [31:0] rd,
    input  logic        we,
    input  logic [31:0] wd
);

    assign rd = re ? 32'b0 : {32{1'bx}};

    always_ff @(posedge clk) begin
        if (we) begin
            bus_rx.push_back(wd[7:0]);
        end
    end

endmodule
