`timescale 1ps / 1ps

module E1_catch_fixed_point #(
    parameter CATCH_NUM = 100,
    parameter CATCH_NUM_WIDTH = $clog2(CATCH_NUM),
    parameter N = 64,
    parameter Q = 15 // frac
)
(
    input clk,
    input rst,
    input module_en,
    output module_done,
    input catch_en,
    input [N - 1 : 0] catch_fixed_point,
    
    input [CATCH_NUM_WIDTH - 1 : 0] index0,
    output [N - 1 : 0] fixed_point0
    // input [GEN_NUM_WIDTH - 1 : 0] index1,
    // output [N - 1 : 0] fixed_point1,
    // input [GEN_NUM_WIDTH - 1 : 0] index2,
    // output [N - 1 : 0] fixed_point2
);

reg [N - 1 : 0] buffer [0 : CATCH_NUM - 1];
reg [CATCH_NUM_WIDTH - 1 : 0] self_index;
reg module_done_r;
assign module_done = module_done_r;

assign fixed_point0 = buffer[index0];

always @(posedge clk) begin
    if (rst) begin
        module_done_r <= 0;
    end else if (self_index == CATCH_NUM - 1) begin
        module_done_r <= 1;
    end else if (module_done_r) begin
        module_done_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst) begin
        self_index <= 0;
    end else if (catch_en) begin
        self_index <= self_index + 1;
    end
end

always @(posedge clk) begin
    if (catch_en) begin
        buffer[self_index] <= catch_fixed_point;
    end
end



endmodule