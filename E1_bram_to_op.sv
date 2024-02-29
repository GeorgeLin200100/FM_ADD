`timescale 1ps/1ps
module E1_bram_to_op #(
    parameter BRAM_DATA_WIDTH = 64 * 4,
    parameter BRAM_DEPTH = 64,
    parameter BRAM_ADDR_WIDTH = clog2(BRAM_DEPTH),
    parameter QADD_WIDTH = 64,
    parameter QADD_Q = 15
    // parameter max_r = 4 * 16 / 4
)
(
    input clk,
    input rst,
    input init_calib_complete,

    input [3:0] op_cs, //op module chip select. 4'b0001: qadd
    
    input module_en,
    output module_done,

    input [BRAM_ADDR_WIDTH - 1 : 0] bram0_begin_addr,
    input [BRAM_ADDR_WIDTH - 1 : 0] bram1_begin_addr,
    // input rd_wr, //0: read, 1: write
    // input bram_sel,//0: bram0, 1: bram1
    input [BRAM_ADDR_WIDTH : 0] max, // additional 1 bit for "max" like variable
    
    input [BRAM_DATA_WIDTH - 1 : 0] bram0_dout,
    input [BRAM_DATA_WIDTH - 1 : 0] bram1_dout,
    output [BRAM_DATA_WIDTH - 1 : 0] bram0_din,
    output [BRAM_DATA_WIDTH - 1 : 0] bram1_din,
    output bram0_rd_en,
    output bram1_rd_en,
    output bram0_wr_en,
    output bram1_wr_en,
    output bram0_we,
    output bram1_we,
    output [BRAM_ADDR_WIDTH - 1 : 0] bram0_rd_addr,
    output [BRAM_ADDR_WIDTH - 1 : 0] bram1_rd_addr,
    output [BRAM_ADDR_WIDTH - 1 : 0] bram0_wr_addr,
    output [BRAM_ADDR_WIDTH - 1 : 0] bram1_wr_addr,
    
    output [BRAM_DATA_WIDTH - 1 : 0] qadd_a_g,
    output [BRAM_DATA_WIDTH - 1 : 0] qadd_b_g,
    output qadd_a_g_en,
    output qadd_b_g_en,
    input [BRAM_DATA_WIDTH - 1 : 0] qadd_c_g,
    input qadd_c_g_valid
);

localparam IDLE = 4'b0000;
localparam QADD = 4'b0001;

reg [3:0] state;
reg [3:0] nxt_state;

reg [BRAM_ADDR_WIDTH : 0] max_r;

reg [BRAM_ADDR_WIDTH - 1 : 0] bram0_rd_cmd_cnt;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram1_rd_cmd_cnt;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram0_rd_data_cnt;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram1_rd_data_cnt;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram0_wr_cmd_cnt;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram1_wr_cmd_cnt;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram0_wr_data_cnt;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram1_wr_data_cnt;


reg bram0_rd_en_r;
reg bram1_rd_en_r;
reg bram0_wr_en_r;
reg bram1_wr_en_r;

reg [BRAM_ADDR_WIDTH - 1 : 0] bram0_rd_addr_r;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram1_rd_addr_r;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram0_wr_addr_r;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram1_wr_addr_r;

reg bram0_we_r;
reg bram1_we_r;

reg [BRAM_DATA_WIDTH - 1 : 0] bram0_din_r;
reg [BRAM_DATA_WIDTH - 1 : 0] bram1_din_r;

reg [BRAM_DATA_WIDTH - 1 : 0] qadd_c_g_d1;

reg bram0_rd_en_d1;
reg bram1_rd_en_d1;

reg module_done_r;

assign qadd_a_g = (state == QADD) ? bram0_dout : 0;
assign qadd_b_g = (state == QADD) ? bram1_dout: 0;

assign qadd_a_g_en = (state == QADD) ? bram0_rd_en_d1 : 0;
assign qadd_b_g_en = (state == QADD) ? bram1_rd_en_d1 : 0;

always @(posedge clk) begin
    bram0_rd_en_d1 <= bram0_rd_en;
    bram1_rd_en_d1 <= bram1_rd_en;
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        max_r <= 0;
    end else if (module_en) begin
        max_r <= max;
    end
end

assign bram0_din = bram0_din_r;
assign bram1_din = bram1_din_r;


always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_din_r <= 0;
    end else if (state == QADD & qadd_c_g_valid & bram0_wr_en) begin
        bram0_din_r <= qadd_c_g;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_din_r <= 0;
    end else if (state == QADD & qadd_c_g_valid & bram1_wr_en) begin
        bram1_din_r <= qadd_c_g;
    end
end

assign bram0_we = bram0_we_r;
assign bram1_we = bram1_we_r;

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_we_r <= 0;
    end else if (state == QADD & qadd_c_g_valid & bram0_wr_en) begin
        bram0_we_r <= 1;
    end else if (state == QADD & (bram0_wr_cmd_cnt == max_r - 1) & bram0_wr_en & bram0_we) begin
        bram0_we_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_we_r <= 0;
    end else if (state == QADD & qadd_c_g_valid & bram1_wr_en) begin
        bram1_we_r <= 1;
    end else if (state == QADD & (bram1_wr_cmd_cnt == max_r - 1) & bram1_wr_en & bram1_we) begin
        bram1_we_r <= 0;
    end
end

assign bram0_rd_addr = bram0_rd_addr_r;
assign bram1_rd_addr = bram1_rd_addr_r;
assign bram0_wr_addr = bram0_wr_addr_r;
assign bram1_wr_addr = bram1_wr_addr_r;

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_rd_addr_r <= 0;
    end else if (state == IDLE & module_en) begin
        bram0_rd_addr_r <= bram0_begin_addr;
    end else if (state == QADD & (bram0_rd_cmd_cnt < max_r - 1) & bram0_rd_en) begin
        bram0_rd_addr_r <= bram0_rd_addr_r + 1;
    end else if ((state != IDLE) & (state != nxt_state)) begin
        bram0_rd_addr_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_wr_addr_r <= 0;
    end else if (state == IDLE & module_en) begin
        bram0_wr_addr_r <= bram0_begin_addr;
    end else if (state == QADD & (bram0_wr_cmd_cnt < max_r - 1) & bram0_wr_en & bram0_we) begin
        bram0_wr_addr_r <= bram0_wr_addr_r + 1;
    end else if ((state != IDLE) & (state != nxt_state)) begin
        bram0_wr_addr_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_rd_addr_r <= 0;
    end else if (state == IDLE & module_en) begin
        bram1_rd_addr_r <= bram1_begin_addr;
    end else if (state == QADD & (bram1_rd_cmd_cnt < max_r - 1) & bram1_rd_en) begin
        bram1_rd_addr_r <= bram1_rd_addr_r + 1;
    end else if ((state != IDLE) & (state != nxt_state)) begin
        bram1_rd_addr_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_wr_addr_r <= 0;
    end else if (state == IDLE & module_en) begin
        bram1_wr_addr_r <= bram1_begin_addr;
    end else if (state == QADD & (bram1_wr_cmd_cnt < max_r - 1) & bram1_wr_en & bram1_we) begin
        bram1_wr_addr_r <= bram1_wr_addr_r + 1;
    end else if ((state != IDLE) & (state != nxt_state)) begin
        bram1_wr_addr_r <= 0;
    end
end



//bram_addr


assign bram0_rd_en = bram0_rd_en_r;
assign bram1_rd_en = bram1_rd_en_r;
assign bram0_wr_en = bram0_wr_en_r;
assign bram1_wr_en = bram1_wr_en_r;

//bram0_rd_en used like bram0_we
always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_rd_en_r <= 0;
    //end else if (state == IDLE & module_en) 
    end else if (state == IDLE & (nxt_state != state)) begin
        bram0_rd_en_r <= 1;
    end else if (state == QADD & (bram0_rd_cmd_cnt == max_r - 1)) begin
        bram0_rd_en_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_rd_en_r <= 0;
    end else if (state == IDLE & module_en) begin
        bram1_rd_en_r <= 1;
    end else if (state == QADD & (bram1_rd_cmd_cnt == max_r - 1)) begin
        bram1_rd_en_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_wr_en_r <= 0;
    end else if (state == IDLE & module_en) begin
        bram0_wr_en_r <= 1;
    end else if ((state != IDLE) & (state != nxt_state)) begin
        bram0_wr_en_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_wr_en_r <= 0;
    end else if (state == IDLE & module_en) begin
        bram1_wr_en_r <= 0; // not used in QADD
    end else if ((state != IDLE) & (state != nxt_state)) begin
        bram1_wr_en_r <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_rd_cmd_cnt <= 0;
    end else if (state == QADD & (bram0_rd_cmd_cnt < max_r - 1) & bram0_rd_en) begin
        bram0_rd_cmd_cnt <= bram0_rd_cmd_cnt + 1;
    end else if ((state != IDLE) & (nxt_state != state)) begin
        bram0_rd_cmd_cnt <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_rd_cmd_cnt <= 0;
    end else if (state == QADD & (bram1_rd_cmd_cnt < max_r - 1) & bram1_rd_en) begin
        bram1_rd_cmd_cnt <= bram1_rd_cmd_cnt + 1;
    end else if ((state != IDLE) & (nxt_state != state)) begin
        bram1_rd_cmd_cnt <= 0;
    end
end

//rd data cnt delays rd_cmd_cnt by 1 cycle 
always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_rd_data_cnt <= 0;
    end else if (state == QADD & (state != nxt_state))begin
        bram0_rd_data_cnt <= 0;
    end else begin
        bram0_rd_data_cnt <= bram0_rd_cmd_cnt;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_rd_data_cnt <= 0;
    end else if (state == QADD & (state != nxt_state))begin
        bram1_rd_data_cnt <= 0;
    end else begin
        bram1_rd_data_cnt <= bram1_rd_cmd_cnt;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram0_wr_cmd_cnt <= 0;
    end else if (state == QADD & (bram0_wr_cmd_cnt < max_r - 1) & bram0_wr_en & bram0_we) begin
        bram0_wr_cmd_cnt <= bram0_wr_cmd_cnt + 1;
    end else if ((state != IDLE) & (nxt_state != state)) begin
        bram0_wr_cmd_cnt <= 0;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        bram1_wr_cmd_cnt <= 0;
    end else if (state == QADD & (bram1_wr_cmd_cnt < max_r - 1) & bram1_wr_en & bram1_we) begin
        bram1_wr_cmd_cnt <= bram1_wr_cmd_cnt + 1;
    end else if ((state != IDLE) & (nxt_state != state)) begin
        bram1_wr_cmd_cnt <= 0;
    end
end

assign bram0_wr_data_cnt = bram0_wr_cmd_cnt;
assign bram1_wr_data_cnt = bram1_wr_cmd_cnt;


always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        nxt_state <= IDLE;
    end else if (module_en & (state == IDLE) & (op_cs == 4'b0001)) begin
        nxt_state <= QADD;
    end else if (state == QADD & (bram0_wr_data_cnt == max_r - 1) & bram0_wr_en) begin
        nxt_state <= IDLE;
    end
end

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        state <= IDLE;
    end else begin
        state <= nxt_state;
    end

end

assign module_done = module_done_r;

always @(posedge clk) begin
    if (rst | ~init_calib_complete) begin
        module_done_r <= 0;
    end else if (state == QADD & (nxt_state != state)) begin
        module_done_r <= 1;
    end else begin
        module_done_r <= 0;
    end
end

endmodule