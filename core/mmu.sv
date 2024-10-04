`timescale 1ns / 1ps

module mmu
    #(parameter integer DEVICE_COUNT = 0)
     (input  var logic       re, we,
      input  var logic[1:0]  rd_unit, wd_unit,
      input  var logic[31:0] addr,
      input  var logic[31:0] wd,
      output var logic[31:0] rd,

      output var logic access_fault,
      output var logic addr_misaligned,

      output var logic[31:2] dev_addr[DEVICE_COUNT],

      output var logic       dev_re[DEVICE_COUNT],
      input  var logic[31:0] dev_rd[DEVICE_COUNT],

      output var logic       dev_we[DEVICE_COUNT],
      output var logic[31:0] dev_wd[DEVICE_COUNT],

      input var logic       dev_rw[DEVICE_COUNT],
      input var logic[31:0] dev_addr_start[DEVICE_COUNT],
      input var logic[31:0] dev_addr_end[DEVICE_COUNT]);

    logic[31:0] local_addr;
    logic[31:0] addr_base;
    assign local_addr = addr - addr_base;

    logic[31:0] word_r, word_w;

    logic addr_misaligned_r, addr_misaligned_w;
    assign addr_misaligned = (re & addr_misaligned_r) | (we & addr_misaligned_w);

    logic access_fault_r, access_fault_w;
    assign access_fault = (re & access_fault_r) | (we & access_fault_w);

    // Prepare rd: shift word_r appropriately and cut the extra
    always_comb begin
        case (rd_unit)
            2'b00: begin
                addr_misaligned_r = 1'b0;

                case (local_addr[1:0])
                    2'b11: rd = word_r[7:0];
                    2'b10: rd = word_r[15:8];
                    2'b01: rd = word_r[23:16];
                    2'b00: rd = word_r[31:24];
                endcase;
            end

            2'b01: begin
                addr_misaligned_r = local_addr[0];

                if (~addr_misaligned_r) begin
                    case (local_addr[1])
                        1'b1: rd = word_r[15:0];
                        1'b0: rd = word_r[31:16];
                    endcase;
                end else begin
                    rd = 32'b0;
                end;
            end

            2'b10: begin
                addr_misaligned_r = local_addr[0] | local_addr[1];

                if (~addr_misaligned_r) begin
                    rd = word_r;
                end else begin
                    rd = 32'b0;
                end;
            end

            default: begin
                {rd, addr_misaligned_r} = {33 {1'bx}};
            end
        endcase;
    end;

    // Prepare word_w: update the requested bytes
    always_comb begin
        word_w = word_r;

        case (wd_unit)
            2'b00: begin
                addr_misaligned_w = 1'b0;

                case (local_addr[1:0])
                    2'b11: word_w[7:0] = wd[7:0];
                    2'b10: word_w[15:8] = wd[7:0];
                    2'b01: word_w[23:16] = wd[7:0];
                    2'b00: word_w[31:24] = wd[7:0];
                endcase;
            end

            2'b01: begin
                addr_misaligned_w = local_addr[0];

                if (~addr_misaligned_w) begin
                    case (local_addr[1])
                        1'b1: word_w[15:0] = wd[15:0];
                        1'b0: word_w[31:16] = wd[15:0];
                    endcase;
                end;
            end

            2'b10: begin
                addr_misaligned_w = local_addr[0] | local_addr[1];

                if (~addr_misaligned_w) begin
                    word_w = wd;
                end
            end

            default: begin
                {word_w, addr_misaligned_w} = {33 {1'bx}};
            end
        endcase;
    end;

    generate
        for (genvar i = 0; i < DEVICE_COUNT; ++i) begin
            assign dev_wd[i] = word_w;
        end;
    endgenerate;

    logic[31:0] addr_base_in[DEVICE_COUNT];
    logic access_fault_r_in[DEVICE_COUNT];
    logic access_fault_w_in[DEVICE_COUNT];
    logic[31:0] word_r_in[DEVICE_COUNT];
    logic[$clog2(DEVICE_COUNT + 1) - 1 : 0] chosen_dev;

    assign addr_base = addr_base_in[chosen_dev];
    assign access_fault_r = access_fault_r_in[chosen_dev];
    assign access_fault_w = access_fault_w_in[chosen_dev];
    assign word_r = word_r_in[chosen_dev];

    logic valid_addr;

    always_comb begin
        chosen_dev = '0;
        valid_addr = 1'b0;

        for (int i = 0; i < DEVICE_COUNT; ++i) begin
            if (addr inside {[dev_addr_start[i] : dev_addr_end[i]]}) begin
                chosen_dev = i;
                valid_addr = 1'b1;
            end
        end;
    end;

    generate
        for (genvar i = 0; i < DEVICE_COUNT; ++i) begin
            always_comb begin
                word_r_in[i] = {32 {1'bx}};
                addr_base_in[i] = 32'b0;
                access_fault_r_in[i] = 1'b1;
                access_fault_w_in[i] = 1'b0;
                dev_re[i] = 1'b0;
                dev_addr[i] = 32'b0;
                dev_we[i] = 1'b0;

                word_r_in[i] = dev_rd[i];
                addr_base_in[i] = dev_addr_start[i];

                if (valid_addr & (chosen_dev == i)) begin
                    dev_addr[i] = local_addr[31:2];
                    dev_re[i] = re & ~addr_misaligned_r;
                    access_fault_r_in[i] = 1'b0;

                    if (we & ~addr_misaligned_w) begin
                        if (dev_rw[i]) begin
                            access_fault_w_in[i] = 1'b0;
                            dev_we[i] = 1'b1;
                        end;
                    end;
                end;
            end;
        end;
    endgenerate;

endmodule
