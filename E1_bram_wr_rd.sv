`timescale 1ps/1ps
module E1_bram_wr_rd #(
    parameter BRAM_DATA_WIDTH = 64,
    parameter BRAM_DEPTH = 64,
    parameter BRAM_ADDR_WIDTH = clog2(BRAM_DEPTH)
)
(
    input clk,
    input bram0_rd_en,
    input bram0_wr_en,
    input bram0_we,
    input [BRAM_ADDR_WIDTH - 1 : 0] bram0_rd_addr,
    input [BRAM_ADDR_WIDTH - 1 : 0] bram0_wr_addr,
    input [BRAM_DATA_WIDTH - 1 : 0] bram0_din,
    output [BRAM_DATA_WIDTH - 1 : 0] bram0_dout,
    input bram1_rd_en,
    input bram1_wr_en,
    input bram1_we,
    input [BRAM_ADDR_WIDTH - 1 : 0] bram1_rd_addr,
    input [BRAM_ADDR_WIDTH - 1 : 0] bram1_wr_addr,
    input [BRAM_DATA_WIDTH - 1 : 0] bram1_din,
    output [BRAM_DATA_WIDTH - 1 : 0] bram1_dout
);

    E1_BRAM #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .BRAM_DEPTH(BRAM_DEPTH)
    )
    E1_BRAM_inst0
    (
        .clk(clk),
        .we_a(bram0_we),
        .en_a(bram0_wr_en),
        .addr_a(bram0_wr_addr),
        .din_a(bram0_din),
        .en_b(bram0_rd_en),
        .addr_b(bram0_rd_addr),
        .dout_b(bram0_dout)
    );

    E1_BRAM #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .BRAM_DEPTH(BRAM_DEPTH)
    )
    E1_BRAM_inst1
    (
        .clk(clk),
        .we_a(bram1_we),
        .en_a(bram1_wr_en),
        .addr_a(bram1_wr_addr),
        .din_a(bram1_din),
        .en_b(bram1_rd_en),
        .addr_b(bram1_rd_addr),
        .dout_b(bram1_dout)
    );

endmodule

