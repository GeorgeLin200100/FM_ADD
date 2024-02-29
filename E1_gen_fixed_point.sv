`timescale 1ps / 1ps

module E1_gen_fixed_point #(
    parameter GEN_NUM = 200,
    parameter GEN_NUM_WIDTH = $clog2(GEN_NUM),
    parameter N = 64,
    parameter Q = 15 // frac
)
(
    input clk,
    input rst,
    input module_en,
    output module_done,
    input [GEN_NUM_WIDTH - 1 : 0] index,
    output [N - 1 : 0] fixed_point,
    input [GEN_NUM_WIDTH - 1 : 0] index1,
    output [N - 1 : 0] fixed_point1,
    input [GEN_NUM_WIDTH - 1 : 0] index2,
    output [N - 1 : 0] fixed_point2
);

reg [N - 1 : 0] buffer [0 : GEN_NUM - 1];

reg [GEN_NUM_WIDTH - 1 : 0] wr_num;
reg module_done_r;
reg we;

integer seed1 = 101;
integer seed2 = 107;

assign fixed_point = buffer[index];
assign fixed_point1 = buffer[index1];
assign fixed_point2 = buffer[index2];

always @(posedge clk) begin
    if(rst) begin
        we <= 0;
    end else if (module_en) begin
        we <= 1;
    end else if (wr_num == GEN_NUM - 1) begin
        we <= 0;
    end
end

always @(posedge clk) begin
    if(rst) begin
        wr_num <= 0;
    end else if (we) begin
        wr_num <= wr_num + 1;
    end else if (module_done) begin
        wr_num <= 0;
    end
end

always @(posedge clk) begin
    if(we) begin
        buffer[wr_num][N - 1: Q] <= $random(seed1) % (N - Q - 2);
        buffer[wr_num][Q - 1 : 0] <= $random(seed2) % (Q - 1);
    end
end

assign module_done = module_done_r;
always @(posedge clk) begin
    if (rst) begin
        module_done_r <= 0;
    end else if (wr_num == GEN_NUM - 1) begin
        module_done_r <= 1;
    end else if (module_done) begin
        module_done_r <= 0;
    end
end




endmodule
