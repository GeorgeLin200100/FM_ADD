`timescale 1ps / 1ps

// qadd module group
module E1_qadd_g #(
    parameter Q = 15,
    parameter N = 64,
    parameter NUM = 4 //content of the group
)
(
    input clk,
    input rst,
    input [N * NUM - 1 : 0] a,
    input a_en,
    input [N * NUM - 1 : 0] b,
    input b_en,
    output [N * NUM - 1 : 0] c,
    output c_valid
);

reg [NUM - 1 : 0] c_valid_g;
//instantiation of 4 qadd modules using "generate" statement
genvar i;
generate
    for (i = 0; i < NUM; i = i + 1) begin : qadd_inst
        E1_qadd #(
            .Q(Q),
            .N(N)
        )
        qadd (
            .clk(clk),
            .rst(rst),
            .a(a[N * (i + 1) - 1 : N * i]),
            .a_en(a_en),
            .b(b[N * (i + 1) - 1 : N * i]),
            .b_en(b_en),
            .c(c[N * (i + 1) - 1 : N * i]),
            .c_valid(c_valid_g[i])
        );
    end
endgenerate

assign c_valid = &c_valid_g;

endmodule