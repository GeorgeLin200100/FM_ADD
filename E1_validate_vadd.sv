`timescale 1ps / 1ps

module E1_validate_vadd #(
    parameter GEN_NUM = 200,
    parameter GEN_NUM_WIDTH = $clog2(GEN_NUM),
    parameter CATCH_NUM = 100,
    parameter CATCH_NUM_WIDTH = $clog2(CATCH_NUM),
    parameter N = 64,
    parameter Q = 15, // frac
    parameter INDEX_COMPUTE_BEGIN_ADDR = 0,
    parameter INDEX_REF1_BEGIN_ADDR = 0,
    parameter INDEX_REF2_BEGIN_ADDR = CATCH_NUM
)
(
    input clk,
    input rst,
    input module_en,
    output module_done,
    output reg [CATCH_NUM_WIDTH - 1 : 0] index_compute,
    output reg [GEN_NUM_WIDTH - 1 : 0] index_ref1,
    output reg [GEN_NUM_WIDTH - 1 : 0] index_ref2,
    input [N - 1 : 0] fixed_point_compute,
    input [N - 1 : 0] fixed_point_ref1,
    input [N - 1 : 0] fixed_point_ref2,
    output reg error,
    output reg [CATCH_NUM_WIDTH - 1 : 0] error_num
);

reg module_done_r;
reg module_en_r;
wire [N - 1 : 0] fixed_point_ref;


assign fixed_point_ref = (module_en_r) ? fixed_point_ref1 + fixed_point_ref2 : 0;

always @(posedge clk) begin
    if (rst) begin
        error_num <= 0;
    end else if (module_en_r & error) begin
        error_num <= error_num + 1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        error <= 0;
    end else if (module_en_r) begin
        if (fixed_point_compute != fixed_point_ref) begin
            error <= 1;
        end else begin
            error <= 0;
        end
    end
end

always @(posedge clk) begin
    if (rst) begin
        module_en_r <= 0;
    end else if (module_en) begin
        module_en_r <= 1;
    end else if (module_done) begin
        module_en_r <= 0;
    end 
end

assign module_done = module_done_r;



always @(posedge clk) begin
    if (rst) begin
        module_done_r <= 0;
    end else if (module_done_r) begin
        module_done_r <= 0;
    end else if (index_compute == CATCH_NUM - 1) begin
        module_done_r <= 1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        index_compute <= INDEX_COMPUTE_BEGIN_ADDR;
        index_ref1 <= INDEX_REF1_BEGIN_ADDR;
        index_ref2 <= INDEX_REF2_BEGIN_ADDR;
    end else if (module_en_r & (index_compute < INDEX_COMPUTE_BEGIN_ADDR + CATCH_NUM - 1)) begin
        index_compute <= index_compute + 1;
        index_ref1 <= index_ref1 + 1;
        index_ref2 <= index_ref2 + 1;
    end else if (module_done) begin
        index_compute <= 0;
        index_ref1 <= 0;
        index_ref2 <= 0;
    end
end




endmodule