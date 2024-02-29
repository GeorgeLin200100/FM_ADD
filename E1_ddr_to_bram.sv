`timescale 1ps/1ps
/*
Description: transfer data from ddr to bram
*/
module E1_ddr_to_bram #(
        parameter APP_DATA_WIDTH = 64,
        parameter APP_MASK_WIDTH = APP_DATA_WIDTH / 8,
        parameter APP_ADDR_WIDTH = 32,
        parameter FM_COL = 16,
        parameter FM_ROW = 4,
        parameter DDR_TS_MAX_WIDTH = $clog2(FM_COL * FM_ROW),
        parameter BRAM_DDR_RATIO = 4,
        parameter BRAM_DATA_WIDTH = APP_DATA_WIDTH * BRAM_DDR_RATIO,
        parameter BRAM_DEPTH = 64,
        parameter BRAM_ADDR_WIDTH = $clog2(BRAM_DEPTH)
    )
    (
        input clk,
        input rst,
        input init_calib_complete,
        input module_en,
        input rd_wr, //0: read, 1: write
        input [APP_ADDR_WIDTH - 1 : 0] ddr_begin_addr,
        input [BRAM_ADDR_WIDTH - 1 : 0] bram_begin_addr,
        output reg module_done,

        output [APP_ADDR_WIDTH - 1 : 0] app_addr,
        output [2:0] app_cmd,
        output app_en,
        output [APP_DATA_WIDTH - 1 : 0] app_wdf_data,
        output app_wdf_end,
        output [APP_MASK_WIDTH - 1 : 0] app_wdf_mask,
        output app_wdf_wren,
        input [APP_DATA_WIDTH - 1 : 0] app_rd_data,
        input app_rd_data_end,
        input app_rd_data_valid,
        input app_rdy,
        input app_wdf_rdy,

        //bram control 
        output bram_rd_en,
        output bram_wr_en,
        output bram_we,
        output [BRAM_ADDR_WIDTH - 1 : 0] bram_rd_addr,
        output [BRAM_ADDR_WIDTH - 1 : 0] bram_wr_addr,
        output [BRAM_DATA_WIDTH - 1 : 0] bram_din,
        input [BRAM_DATA_WIDTH - 1 : 0] bram_dout
    ); 

    reg init_calib_complete_r;

    reg [APP_ADDR_WIDTH - 1 : 0] ddr_begin_addr_r;
    reg [BRAM_ADDR_WIDTH - 1 : 0] bram_begin_addr_r;


    reg [1:0] state;
    reg [1:0] nxt_state;

    reg [DDR_TS_MAX_WIDTH - 1 : 0] wr_data_cnt;
    reg [DDR_TS_MAX_WIDTH - 1 : 0] rd_data_cnt;
    //reg wr_en;
    reg [DDR_TS_MAX_WIDTH - 1 : 0] rd_cmd_cnt;
    reg [DDR_TS_MAX_WIDTH - 1 : 0] wr_cmd_cnt;
    reg cmd_en;
    reg [APP_ADDR_WIDTH - 1 : 0] app_addr_r;
    reg [2:0] app_cmd_r;

    reg bram_rd_en_r;
    reg bram_wr_en_r;
    reg [BRAM_ADDR_WIDTH - 1 : 0] bram_rd_addr_r;
    reg [BRAM_ADDR_WIDTH - 1 : 0] bram_wr_addr_r;
    reg par_en_r;
    reg [DDR_TS_MAX_WIDTH - 1 : 0] ddr_p2s_cnt;
    reg [DDR_TS_MAX_WIDTH - 1 : 0] par_en_cnt;


    localparam IDLE = 2'b00;
    localparam RD = 2'b01;
    localparam WR = 2'b10;

    localparam RD_MAX = FM_COL * FM_ROW;
    localparam WR_MAX = FM_COL * FM_ROW;

    localparam DDR_ADDR_STRIDE = APP_DATA_WIDTH / 8;

    localparam RD_CMD = 3'b001;
    localparam WR_CMD = 3'b000;

    assign app_addr = app_addr_r;
    assign app_cmd = app_cmd_r;


    always @(posedge clk) begin
        init_calib_complete_r <= init_calib_complete;
    end

    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            ddr_begin_addr_r <= 0;
        end else if (module_en) begin
        ddr_begin_addr_r <= ddr_begin_addr;
        end
    end

    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            bram_begin_addr_r <= 0;
        end else if (module_en) begin
            bram_begin_addr_r <= bram_begin_addr;
        end
    end


    //bram_rd_en
    assign bram_rd_en = bram_rd_en_r;
    always @(posedge clk) begin
        if (rst) begin
            bram_rd_en_r <= 0;
        end else if(module_en & rd_wr) begin
            bram_rd_en_r <= 1;
        end else if (module_done) begin
            bram_rd_en_r <= 0;
        end
    end

    //bram_wr_en
    assign bram_wr_en = bram_wr_en_r;
    always @(posedge clk) begin
        if (rst) begin
            bram_wr_en_r <= 0;
        end else if(module_en & ~rd_wr) begin
            bram_wr_en_r <= 1;
        end else if (module_done) begin
            bram_wr_en_r <= 0;
        end
    end

    //bram_rd_addr
    assign bram_rd_addr = bram_rd_addr_r;
    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            bram_rd_addr_r <= 0;
        end else if (state == IDLE & (nxt_state != state)) begin
            bram_rd_addr_r <= bram_begin_addr_r;
        end else if (state == WR & par_en) begin
            bram_rd_addr_r <= bram_rd_addr_r + 1;
        end
    end

    //bram_wr_addr
    assign bram_wr_addr = bram_wr_addr_r;
    always @(posedge clk) begin
        if(rst | ~init_calib_complete_r) begin
            bram_wr_addr_r <= 0;
        end else if (state == IDLE & nxt_state != state) begin
            bram_wr_addr_r <= bram_begin_addr_r;
        end else if (state == RD & bram_we & bram_wr_en) begin
            bram_wr_addr_r <= bram_wr_addr_r + 1;
        end else if (state == RD & (nxt_state != state)) begin
            bram_wr_addr_r <= bram_begin_addr_r;
        end
    end

    //par_en_cnt
    always @(posedge clk) begin
        if (rst | ~init_calib_complete) begin
            par_en_cnt <= 0;
        end else if (state == WR) begin
            if (par_en & (par_en_cnt < (FM_ROW * FM_COL / BRAM_DDR_RATIO))) begin
                par_en_cnt <= par_en_cnt + 1;
            end else if (par_en_cnt == (FM_ROW * FM_COL / BRAM_DDR_RATIO) & (nxt_state != state)) begin
                par_en_cnt <= 0;
            end
        end
    end


    assign par_en = par_en_r;
    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            par_en_r <= 0;
        end else if (state == WR) begin
            if (app_wdf_rdy & (ddr_p2s_cnt == BRAM_DDR_RATIO - 1) & (par_en_cnt < (FM_ROW * FM_COL / BRAM_DDR_RATIO))) begin
                par_en_r <= 1;
            end else begin
                par_en_r <= 0;
            end
        end else begin
            par_en_r <= 0;
        end
    end

    //ddr_p2s_cnt
    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            ddr_p2s_cnt <= 0;
        end else if (state == WR) begin
            if (par_en) begin
                ddr_p2s_cnt <= 0;
            end else if ((ddr_p2s_cnt == BRAM_DDR_RATIO - 1) & app_wdf_rdy) begin
                ddr_p2s_cnt <= 0;
            end else if (app_wdf_rdy) begin
                ddr_p2s_cnt <= ddr_p2s_cnt + 1;
            end
        end
    end


    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            wr_data_cnt <= 0;
        end else if (state == WR & (wr_data_cnt < WR_MAX - 1) & seq_valid & app_wdf_rdy) begin
            wr_data_cnt <= wr_data_cnt + 1;
        end else if (state == WR & (wr_data_cnt == WR_MAX - 1) & (nxt_state != state)) begin
            wr_data_cnt <= 0;
        end
    end

    //rd_data_cnt

    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            rd_data_cnt <= 0;
        end else if (state == RD & (rd_data_cnt < RD_MAX - 1) & app_rd_data_valid) begin
            rd_data_cnt <= rd_data_cnt + 1;
        end else if (state == RD & (rd_data_cnt == RD_MAX - 1) & (nxt_state != state)) begin
            rd_data_cnt <= 0;
        end
    end
    
    always @(posedge clk) begin
        if(rst | ~init_calib_complete_r) begin
            nxt_state <= IDLE;
        end else if (module_en) begin
            if (rd_wr) begin
                nxt_state <= WR;
            end else begin
                nxt_state <= RD;
            end
        end else if (state == RD & (rd_data_cnt == RD_MAX - 1) & app_rd_data_valid ) begin
            nxt_state <= IDLE;
        end else if (state == WR & (wr_cmd_cnt == WR_MAX - 1) & cmd_en & app_rdy) begin
            nxt_state <= IDLE;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end else begin
            state <= nxt_state;
        end
    end

    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            module_done <= 0;
        end else if (nxt_state == IDLE & (nxt_state != state)) begin
            module_done <= 1;
        end else begin
            module_done <= 0;
        end
    end
    //rd_cmd_cnt 
    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            rd_cmd_cnt <= 0;
        end else if (state == RD & (rd_cmd_cnt < RD_MAX - 1) & cmd_en & app_rdy) begin
            rd_cmd_cnt <= rd_cmd_cnt + 1;
        end else if (state == RD & (rd_cmd_cnt == RD_MAX - 1) & (nxt_state == IDLE)) begin
            rd_cmd_cnt <= 0;
        end
    end

    //wr_cmd_cnt
    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            wr_cmd_cnt <= 0;
        end else if (state == WR & (wr_cmd_cnt < WR_MAX - 1) & cmd_en & app_rdy) begin
            wr_cmd_cnt <= wr_cmd_cnt + 1;
        end else if (state == WR & (wr_cmd_cnt == WR_MAX - 1) & (nxt_state == IDLE)) begin
            wr_cmd_cnt <= 0;
        end
    end

    //cmd_en
    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            cmd_en <= 0;
        end else if (state == RD & (rd_cmd_cnt < RD_MAX - 1)) begin
            cmd_en <= app_rdy;
        end else if (state == RD & (rd_cmd_cnt == RD_MAX - 1)) begin
            if (cmd_en & app_rdy) begin
                cmd_en <= 0;
            end
        end else if (state == WR & (wr_cmd_cnt < WR_MAX - 1) & (wr_data_cnt < WR_MAX - 1)) begin
            cmd_en <= app_rdy & app_wdf_wren; //cope with the discontinuity of write data
        end else if (state == WR & (wr_cmd_cnt < WR_MAX - 1) & (wr_data_cnt == WR_MAX - 1)) begin
            cmd_en <= app_rdy;
        end else if (state == WR & (wr_cmd_cnt == WR_MAX - 1)) begin
            if (cmd_en & app_rdy) begin
                cmd_en <= 0;
            end
        end
    end




    // wire [APP_ADDR_WIDTH-1:0]        app_addr;

    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            app_addr_r <= 0;
        end else if (state == IDLE & (nxt_state != state)) begin
            app_addr_r <= ddr_begin_addr_r;
        end else if (state == WR & (wr_cmd_cnt < WR_MAX - 1) & cmd_en & app_rdy) begin
            app_addr_r <= app_addr_r + DDR_ADDR_STRIDE;
        end else if (state == WR & (wr_cmd_cnt == WR_MAX - 1) & (nxt_state != state)) begin
            app_addr_r <= 0;
        end else if (state == RD & (rd_cmd_cnt < RD_MAX - 1) & cmd_en & app_rdy) begin
            app_addr_r <= app_addr_r + DDR_ADDR_STRIDE;
        end else if (state == RD & (rd_cmd_cnt == RD_MAX - 1) & (nxt_state != state)) begin
            app_addr_r <= 0;
        end
    end

    // wire [2:0]                       app_cmd;
    always @(posedge clk) begin
        if (rst | ~init_calib_complete_r) begin
            app_cmd_r <= RD_CMD;
        end else if (nxt_state == RD) begin
            app_cmd_r <= RD_CMD;
        end else if (nxt_state == WR) begin
            app_cmd_r <= WR_CMD;
        end
    end
    
    // wire                             app_en;
    assign app_en = cmd_en & app_rdy;

    // wire [APP_DATA_WIDTH-1:0]        app_wdf_data;
    // reg [APP_DATA_WIDTH-1:0] app_wdf_data_r;
    // assign app_wdf_data = app_wdf_data_r;
    // always @(posedge clk) begin
    //     if (rst | ~init_calib_complete_r) begin
    //         app_wdf_data_r <= 0;
    //     end else begin
    //         app_wdf_data_r <= app_wdf_data;
    //     end 
    // end
    // wire                             app_wdf_end;
    assign app_wdf_end = app_wdf_rdy & seq_valid;
    // wire [APP_MASK_WIDTH-1:0]        app_wdf_mask;
    assign app_wdf_mask = 0;
    // wire                             app_wdf_wren;
    assign app_wdf_wren = app_wdf_rdy & seq_valid; //considering the seperate nature of ddr wr cmd & wr data channel
    

    E1_s2p #(
        .SEQ_CNT(BRAM_DDR_RATIO),
        .APP_DATA_WIDTH(APP_DATA_WIDTH)
    )
    E1_s2p_inst
    (
        .clk(clk),
        .rst(rst),
        .seq_en(app_rd_data_valid),
        .seq(app_rd_data),
        .par(bram_din),
        .par_valid(bram_we)
    );

    E1_p2s #(
        .SEQ_CNT(BRAM_DDR_RATIO),
        .APP_DATA_WIDTH(APP_DATA_WIDTH)
    )
    E1_p2s_inst
    (
        .clk(clk),
        .rst(rst),
        .par_en(par_en),
        .par(bram_dout),
        .app_wdf_rdy(app_wdf_rdy),
        .seq(app_wdf_data),
        .seq_valid(seq_valid),
        .seq_last(seq_last)
    );



    

endmodule

