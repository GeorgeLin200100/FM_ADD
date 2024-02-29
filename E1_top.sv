`timescale 1ps/1ps
module E1_top #(
    parameter DDR_ADDR_WIDTH = 32,
    parameter DDR_DATA_WIDTH = 64,
    parameter DDR_DATA_WIDTH_BYTE = DDR_DATA_WIDTH / 8,
    parameter FM_COL = 128,
    parameter FM_ROW = 4,
    parameter DDR_TS_MAX_WIDTH = $clog2(FM_COL * FM_ROW * 2),
    parameter BRAM_DDR_RATIO = 4,
    parameter BRAM_DATA_WIDTH = DDR_DATA_WIDTH * BRAM_DDR_RATIO,
    parameter BRAM_DEPTH = FM_COL * FM_ROW / BRAM_DDR_RATIO,
    parameter BRAM_ADDR_WIDTH = $clog2(BRAM_DEPTH),
    parameter DDR_BEGIN_ADDR = 0,
    parameter BRAM_BEGIN_ADDR = 0,
    parameter QADD_WIDTH = 64,
    parameter QADD_Q = 15,
    parameter GEN_NUM = FM_ROW * FM_COL * 2,
    parameter GEN_NUM_WIDTH = $clog2(GEN_NUM),
    parameter CATCH_NUM = FM_ROW * FM_COL,
    parameter CATCH_NUM_WIDTH = $clog2(CATCH_NUM),
    parameter INDEX_COMPUTE_BEGIN_ADDR = 0,
    parameter INDEX_REF1_BEGIN_ADDR = 0,
    parameter INDEX_REF2_BEGIN_ADDR = CATCH_NUM
);

wire [DDR_TS_MAX_WIDTH : 0] ddr_ts_max;
reg [DDR_TS_MAX_WIDTH : 0] ddr_ts_max_r;

reg module_en_d2o_r;
reg rd_wr_d2o_r;
wire [DDR_ADDR_WIDTH - 1 : 0] ddr_begin_addr_d2o;
reg [DDR_ADDR_WIDTH - 1 : 0] ddr_begin_addr_d2o_r;

reg module_en_db_r;


reg bram_cs;

reg rd_wr_db_r;

wire [3:0] op_cs_b2o;
reg [3:0] op_cs_b2o_r;
wire bram0_rd_en_b2o;
wire bram1_rd_en_b2o;
wire bram0_wr_en_b2o;
wire bram1_wr_en_b2o;
wire bram0_we_b2o;
wire bram1_we_b2o;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram0_rd_addr_b2o;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram1_rd_addr_b2o;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram0_wr_addr_b2o;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram1_wr_addr_b2o;
wire [BRAM_DATA_WIDTH - 1 : 0] bram0_din_b2o;
wire [BRAM_DATA_WIDTH - 1 : 0] bram1_din_b2o;
wire [BRAM_DATA_WIDTH - 1 : 0] bram0_dout_b2o;
wire [BRAM_DATA_WIDTH - 1 : 0] bram1_dout_b2o;
wire module_en_b2o;
wire module_done_b2o;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram0_begin_addr_b2o;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram1_begin_addr_b2o;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram0_begin_addr_b2o_r;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram1_begin_addr_b2o_r;
wire [BRAM_ADDR_WIDTH : 0] max_b2o;
reg [BRAM_ADDR_WIDTH : 0] max_b2o_r;
reg module_en_b2o_r;

wire [BRAM_DATA_WIDTH - 1 : 0] qadd_a_g_b2o;
wire [BRAM_DATA_WIDTH - 1 : 0] qadd_b_g_b2o;
wire qadd_a_g_en_b2o;
wire qadd_b_g_en_b2o;
wire [BRAM_DATA_WIDTH - 1 : 0] qadd_c_g_b2o;
wire qadd_c_valid_g_b2o;



wire [DDR_ADDR_WIDTH - 1 : 0] app_addr;
wire [2:0] app_cmd;
wire app_en;
wire [DDR_DATA_WIDTH - 1 : 0] app_wdf_data;
wire app_wdf_end;
wire [DDR_DATA_WIDTH_BYTE - 1 : 0] app_wdf_mask;
wire app_wdf_wren;
wire [DDR_DATA_WIDTH - 1 : 0] app_rd_data;
wire app_rd_data_end;
wire app_rd_data_valid;
wire app_rdy;
wire app_wdf_rdy;

wire bram0_rd_en;
wire bram0_wr_en;
wire bram1_rd_en;
wire bram1_wr_en;
wire bram0_we;
wire bram1_we;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram0_rd_addr;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram0_wr_addr;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram1_rd_addr;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram1_wr_addr;
wire [BRAM_DATA_WIDTH - 1 : 0] bram0_din;
wire [BRAM_DATA_WIDTH - 1 : 0] bram1_din;
wire [BRAM_DATA_WIDTH - 1 : 0] bram0_dout;
wire [BRAM_DATA_WIDTH - 1 : 0] bram1_dout;

wire bram_rd_en_db;
wire bram_wr_en_db;
wire bram_we_db;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram_rd_addr_db;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram_wr_addr_db;
wire [BRAM_DATA_WIDTH - 1 : 0] bram_din_db;


wire [DDR_DATA_WIDTH - 1 : 0] bram0_din_p0;
wire [DDR_DATA_WIDTH - 1 : 0] bram0_din_p1;
wire [DDR_DATA_WIDTH - 1 : 0] bram0_din_p2;
wire [DDR_DATA_WIDTH - 1 : 0] bram0_din_p3;

wire [DDR_DATA_WIDTH - 1 : 0] bram1_din_p0;
wire [DDR_DATA_WIDTH - 1 : 0] bram1_din_p1;
wire [DDR_DATA_WIDTH - 1 : 0] bram1_din_p2;
wire [DDR_DATA_WIDTH - 1 : 0] bram1_din_p3;

assign max_b2o = max_b2o_r;
assign bram0_begin_addr_b2o = bram0_begin_addr_b2o_r;
assign bram1_begin_addr_b2o = bram1_begin_addr_b2o_r;

assign bram0_din_p0 = bram0_din[DDR_DATA_WIDTH * 0 +: DDR_DATA_WIDTH];
assign bram0_din_p1 = bram0_din[DDR_DATA_WIDTH * 1 +: DDR_DATA_WIDTH];
assign bram0_din_p2 = bram0_din[DDR_DATA_WIDTH * 2 +: DDR_DATA_WIDTH];
assign bram0_din_p3 = bram0_din[DDR_DATA_WIDTH * 3 +: DDR_DATA_WIDTH];

assign bram1_din_p0 = bram1_din[DDR_DATA_WIDTH * 0 +: DDR_DATA_WIDTH];
assign bram1_din_p1 = bram1_din[DDR_DATA_WIDTH * 1 +: DDR_DATA_WIDTH];
assign bram1_din_p2 = bram1_din[DDR_DATA_WIDTH * 2 +: DDR_DATA_WIDTH];
assign bram1_din_p3 = bram1_din[DDR_DATA_WIDTH * 3 +: DDR_DATA_WIDTH];

wire [BRAM_DATA_WIDTH - 1 : 0] bram_dout_db;

wire [DDR_DATA_WIDTH - 1 : 0] bram0_dout_p0;
wire [DDR_DATA_WIDTH - 1 : 0] bram0_dout_p1;
wire [DDR_DATA_WIDTH - 1 : 0] bram0_dout_p2;
wire [DDR_DATA_WIDTH - 1 : 0] bram0_dout_p3;

wire [DDR_DATA_WIDTH - 1 : 0] bram1_dout_p0;
wire [DDR_DATA_WIDTH - 1 : 0] bram1_dout_p1;
wire [DDR_DATA_WIDTH - 1 : 0] bram1_dout_p2;
wire [DDR_DATA_WIDTH - 1 : 0] bram1_dout_p3;

assign bram0_dout_p0 = bram0_dout[DDR_DATA_WIDTH * 0 +: DDR_DATA_WIDTH];
assign bram0_dout_p1 = bram0_dout[DDR_DATA_WIDTH * 1 +: DDR_DATA_WIDTH];
assign bram0_dout_p2 = bram0_dout[DDR_DATA_WIDTH * 2 +: DDR_DATA_WIDTH];
assign bram0_dout_p3 = bram0_dout[DDR_DATA_WIDTH * 3 +: DDR_DATA_WIDTH];

assign bram1_dout_p0 = bram1_dout[DDR_DATA_WIDTH * 0 +: DDR_DATA_WIDTH];
assign bram1_dout_p1 = bram1_dout[DDR_DATA_WIDTH * 1 +: DDR_DATA_WIDTH];
assign bram1_dout_p2 = bram1_dout[DDR_DATA_WIDTH * 2 +: DDR_DATA_WIDTH];
assign bram1_dout_p3 = bram1_dout[DDR_DATA_WIDTH * 3 +: DDR_DATA_WIDTH];

wire clk;
wire rst;
wire init_calib_complete;
wire module_en_d2o;
wire module_done_d2o;
wire [DDR_ADDR_WIDTH - 1 : 0] app_addr_d2o;
wire [2:0] app_cmd_d2o;
wire app_en_d2o;
wire [DDR_DATA_WIDTH - 1 : 0] app_wdf_data_d2o;
wire app_wdf_end_d2o;
wire [DDR_DATA_WIDTH_BYTE - 1 : 0] app_wdf_mask_d2o;
wire app_wdf_wren_d2o;
wire [DDR_DATA_WIDTH - 1 : 0] app_rd_data_d2o;
wire app_rd_data_end_d2o;
wire app_rd_data_valid_d2o;
wire app_rdy_d2o;
wire app_wdf_rdy_d2o;

wire module_en_db;
wire rd_wr_db;
wire [DDR_ADDR_WIDTH - 1 : 0] ddr_begin_addr_db;
reg [DDR_ADDR_WIDTH - 1 : 0] ddr_begin_addr_db_r;
wire [BRAM_ADDR_WIDTH - 1 : 0] bram_begin_addr_db;
reg [BRAM_ADDR_WIDTH - 1 : 0] bram_begin_addr_db_r;
wire module_done_db;
wire [DDR_ADDR_WIDTH - 1 : 0] app_addr_db;
wire [2:0] app_cmd_db;
wire app_en_db;
wire [DDR_DATA_WIDTH - 1 : 0] app_wdf_data_db;
wire app_wdf_end_db;
wire [DDR_DATA_WIDTH_BYTE - 1 : 0] app_wdf_mask_db;
wire app_wdf_wren_db;
wire [DDR_DATA_WIDTH - 1 : 0] app_rd_data_db;
wire app_rd_data_end_db;
wire app_rd_data_valid_db;
wire app_rdy_db;
wire app_wdf_rdy_db;


wire module_en_gfp;
reg module_en_gfp_r;
wire module_done_gfp;
reg [QADD_WIDTH - 1 : 0] gen_fixed_point;
reg [GEN_NUM_WIDTH - 1 : 0] gen_fixed_point_index;

wire module_en_cfp;
reg module_en_cfp_r;
wire module_done_cfp;
wire catch_en;
wire [QADD_WIDTH - 1 : 0] catch_fixed_point;

wire module_en_vld_vadd;
reg module_en_vld_vadd_r;
wire module_done_vld_vadd;
wire [CATCH_NUM_WIDTH - 1 : 0] index_compute;
wire [GEN_NUM_WIDTH - 1 : 0] index_ref1;
wire [GEN_NUM_WIDTH - 1 : 0] index_ref2;
wire [QADD_WIDTH - 1 : 0] fixed_point_compute;
wire [QADD_WIDTH - 1 : 0] fixed_point_ref1;
wire [QADD_WIDTH - 1 : 0] fixed_point_ref2;
wire error;
reg [CATCH_NUM_WIDTH - 1 : 0] error_num;


assign module_en_vld_vadd = module_en_vld_vadd_r;
assign module_en_cfp = module_en_cfp_r;
assign module_en_gfp = module_en_gfp_r;
assign module_en_d2o = module_en_d2o_r;
assign module_en_db = module_en_db_r;
assign module_en_b2o = module_en_b2o_r;
assign rd_wr_db = rd_wr_db_r;
assign rd_wr_d2o = rd_wr_d2o_r;
assign op_cs_b2o = op_cs_b2o_r;

initial begin
    // initialize
    $display("INITIALIZE START ...... TIME = %d", $time);
    wait (rst);
    wait (!rst);
    wait (init_calib_complete);
    module_en_d2o_r = 0;
    rd_wr_d2o_r = 0;
    module_en_db_r = 0;
    rd_wr_db_r = 0;
    bram_cs = 0;
    module_en_b2o_r = 0;
    ddr_ts_max_r = 0;
    module_en_cfp_r = 0;
    module_en_gfp_r = 0;
    module_en_vld_vadd_r = 0;
    $display("INITIALIZE FINISHED ...... TIME = %d", $time);

    //fixed point generation
    repeat (10) @(posedge clk);
    module_en_gfp_r = 1;
    @(posedge clk);
    module_en_gfp_r = 0;
    wait (module_done_gfp);
    $display("MODULE GFP DONE ...... TIME = %d", $time);

    //outside --> ddr
    repeat (5) @(posedge clk);
    module_en_d2o_r = 1;
    rd_wr_d2o_r = 1;
    ddr_ts_max_r = FM_COL * FM_ROW * 2;
    ddr_begin_addr_d2o_r = DDR_BEGIN_ADDR;
    @(posedge clk);
    module_en_d2o_r = 0;
    wait (module_done_d2o);
    $display("MODULE D2O DONE ...... TIME = %d", $time);

    //ddr --> bram0
    @(posedge clk);
    rd_wr_db_r = 0;
    bram_cs = 0;
    ddr_begin_addr_db_r = DDR_BEGIN_ADDR;
    bram_begin_addr_db_r = BRAM_BEGIN_ADDR;
    module_en_db_r = 1;
    @(posedge clk);
    module_en_db_r = 0;
    wait (module_done_db);
    $display("MODULE DB DONE ...... TIME = %d", $time);

    //ddr --> bram1
    @(posedge clk);
    rd_wr_db_r = 0;
    bram_cs = 1;
    ddr_begin_addr_db_r = DDR_BEGIN_ADDR + FM_COL * FM_ROW * DDR_DATA_WIDTH_BYTE;
    bram_begin_addr_db_r = BRAM_BEGIN_ADDR;
    module_en_db_r = 1;
    @(posedge clk);
    module_en_db_r = 0;
    wait (module_done_db);
    $display("MODULE DB DONE ...... TIME = %d", $time);

    //bram0 --> qadd
    @(posedge clk);
    module_en_b2o_r = 1;
    op_cs_b2o_r = 4'b0001; //qadd
    bram0_begin_addr_b2o_r = BRAM_BEGIN_ADDR;
    bram1_begin_addr_b2o_r = BRAM_BEGIN_ADDR;
    max_b2o_r = FM_ROW * FM_COL / BRAM_DDR_RATIO;
    @(posedge clk);
    module_en_b2o_r = 0;
    wait (module_done_b2o);
    $display("MODULE B2O DONE ...... TIME = %d", $time);

    //bram0 --> ddr
    @(posedge clk);
    module_en_db_r = 1;
    rd_wr_db_r = 1;
    bram_cs = 0;
    ddr_begin_addr_db_r = DDR_BEGIN_ADDR + FM_COL * FM_ROW * 2 * DDR_DATA_WIDTH_BYTE;
    bram_begin_addr_db_r = BRAM_BEGIN_ADDR;
    @(posedge clk);
    module_en_db_r = 0;
    wait (module_done_db);
    $display("MODULE DB DONE ...... TIME = %d", $time);

    //fixed point catching
    @(posedge clk);
    module_en_cfp_r = 1;
    @(posedge clk);
    module_en_cfp_r = 0;
    
    //ddr --> outside
    @(posedge clk);
    module_en_d2o_r = 1;
    rd_wr_d2o_r = 0;
    ddr_ts_max_r = FM_COL * FM_ROW;
    ddr_begin_addr_d2o_r = DDR_BEGIN_ADDR + FM_COL * FM_ROW * 2 * DDR_DATA_WIDTH_BYTE;
    @(posedge clk);
    module_en_d2o_r = 0;
    wait (module_done_cfp);
    $display("MODULE CFP DONE ...... TIME = %d", $time);
    wait (module_done_d2o);
    $display("MODULE D2O DONE ...... TIME = %d", $time);

    //validate_add
    @(posedge clk);
    module_en_vld_vadd_r = 1;
    @(posedge clk);
    module_en_vld_vadd_r = 0;
    wait (module_done_vld_vadd);
    $display("TEST FINISHED ...... ERROR_NUM = %d, TIME = %d", error_num, $time);
    

    //end
    repeat (5) @(posedge clk);


    $finish;
end




reg module_cs_d2o;
always @(posedge clk) begin
    if (rst) begin
        module_cs_d2o <= 1'b0;
    end else if (module_en_d2o) begin
        module_cs_d2o <= 1'b1;
    end else if (module_done_d2o) begin
        module_cs_d2o <= 1'b0;
    end
end

reg module_cs_db;
always @(posedge clk) begin
    if (rst) begin
        module_cs_db <= 1'b0;
    end else if (module_en_db) begin
        module_cs_db <= 1'b1;
    end else if (module_done_db) begin
        module_cs_db <= 1'b0;
    end
end

reg module_cs_b2o;
always @(posedge clk) begin
    if (rst) begin
        module_cs_b2o <= 1'b0;
    end else if (module_en_b2o) begin
        module_cs_b2o <= 1'b1;
    end else if (module_done_b2o) begin
        module_cs_b2o <= 1'b0;
    end
end



assign app_addr = (module_cs_d2o)  ? app_addr_d2o : 
                  (module_cs_db)        ? app_addr_db       :  0;
assign app_cmd = (module_cs_d2o)   ? app_cmd_d2o : 
                 (module_cs_db)         ? app_cmd_db       :  0;
assign app_en = (module_cs_d2o)    ? app_en_d2o :
                (module_cs_db)          ? app_en_db       :  0;
assign app_wdf_data = (module_cs_d2o) ? app_wdf_data_d2o : 
                      (module_cs_db)       ? app_wdf_data_db       :  0;
assign app_wdf_end = (module_cs_d2o)  ? app_wdf_end_d2o :
                        (module_cs_db)        ? app_wdf_end_db       :  0;
assign app_wdf_mask = (module_cs_d2o) ? app_wdf_mask_d2o :
                        (module_cs_db)        ? app_wdf_mask_db       :  0;
assign app_wdf_wren = (module_cs_d2o) ? app_wdf_wren_d2o :
                        (module_cs_db)        ? app_wdf_wren_db       :  0;

assign app_rd_data_d2o = module_cs_d2o ? app_rd_data : 0;
assign app_rd_data_db = module_cs_db ? app_rd_data : 0;
assign app_rd_data_end_d2o = module_cs_d2o ? app_rd_data_end : 0;
assign app_rd_data_end_db = module_cs_db ? app_rd_data_end : 0;
assign app_rd_data_valid_d2o = module_cs_d2o ? app_rd_data_valid : 0;
assign app_rd_data_valid_db = module_cs_db ? app_rd_data_valid : 0;
assign app_rdy_d2o = module_cs_d2o ? app_rdy : 0;
assign app_rdy_db = module_cs_db ? app_rdy : 0;
assign app_wdf_rdy_d2o = module_cs_d2o ? app_wdf_rdy : 0;
assign app_wdf_rdy_db = module_cs_db ? app_wdf_rdy : 0;


assign catch_fixed_point = app_rd_data_d2o;
assign catch_en = app_rd_data_valid_d2o;




assign bram0_rd_en = (module_cs_db & ~bram_cs) ? bram_rd_en_db : 
                    (module_cs_b2o) ? bram0_rd_en_b2o : 0;
assign bram0_wr_en = (module_cs_db & ~bram_cs) ? bram_wr_en_db : 
                    (module_cs_b2o) ? bram0_wr_en_b2o : 0;
assign bram1_rd_en = (module_cs_db & bram_cs) ? bram_rd_en_db : 
                    (module_cs_b2o) ? bram1_rd_en_b2o: 0;
assign bram1_wr_en = (module_cs_db & bram_cs) ? bram_wr_en_db :
                    (module_cs_b2o) ? bram1_wr_en_b2o : 0;
assign bram0_we = (module_cs_db & ~bram_cs) ? bram_we_db :
                    (module_cs_b2o) ? bram0_we_b2o : 0;
assign bram1_we = (module_cs_db & bram_cs) ? bram_we_db : 
                    (module_cs_b2o) ? bram1_we_b2o : 0;
assign bram0_rd_addr = (module_cs_db & ~bram_cs) ? bram_rd_addr_db : 
                    (module_cs_b2o) ? bram0_rd_addr_b2o : 0;
assign bram0_wr_addr = (module_cs_db & ~bram_cs) ? bram_wr_addr_db :
                    (module_cs_b2o) ? bram0_wr_addr_b2o : 0;
assign bram1_rd_addr = (module_cs_db & bram_cs) ? bram_rd_addr_db : 
                    (module_cs_b2o) ? bram1_rd_addr_b2o : 0;
assign bram1_wr_addr = (module_cs_db & bram_cs) ? bram_wr_addr_db :
                    (module_cs_b2o) ? bram1_wr_addr_b2o : 0;
assign bram0_din = (module_cs_db & ~bram_cs) ? bram_din_db : 
                    (module_cs_b2o) ? bram0_din_b2o : 0;
assign bram1_din = (module_cs_db & bram_cs) ? bram_din_db : 
                    (module_cs_b2o) ? bram1_din_b2o : 0;

assign bram_dout_db = (module_cs_db & bram_cs) ? bram1_dout : 
                        (module_cs_db & ~bram_cs) ? bram0_dout : 0;
assign bram0_dout_b2o = (module_cs_b2o) ? bram0_dout : 0;

assign bram1_dout_b2o = (module_cs_b2o) ? bram1_dout : 0;

assign ddr_begin_addr_d2o = ddr_begin_addr_d2o_r;
assign ddr_begin_addr_db = ddr_begin_addr_db_r;
assign bram_begin_addr_db = bram_begin_addr_db_r;
assign bram0_begin_addr_b2o = bram0_begin_addr_b2o_r;
assign bram1_begin_addr_b2o = bram1_begin_addr_b2o_r;

assign ddr_ts_max = ddr_ts_max_r;



E1_gen_fixed_point #(
    .GEN_NUM(GEN_NUM),
    .GEN_NUM_WIDTH(GEN_NUM_WIDTH),
    .N(QADD_WIDTH),
    .Q(QADD_Q)
)
E1_gen_fixed_point_inst
(
    .clk(clk),
    .rst(rst),
    .module_en(module_en_gfp),
    .module_done(module_done_gfp),
    .fixed_point(gen_fixed_point),
    .index(gen_fixed_point_index),
    .fixed_point1(fixed_point_ref1),
    .index1(index_ref1),
    .fixed_point2(fixed_point_ref2),
    .index2(index_ref2)
);

E1_ddr_to_out #(
    .APP_DATA_WIDTH(DDR_DATA_WIDTH),
    .APP_ADDR_WIDTH(DDR_ADDR_WIDTH),
    .APP_MASK_WIDTH(DDR_DATA_WIDTH_BYTE),
    .DDR_ADDR_STRIDE(DDR_DATA_WIDTH_BYTE),
    .DDR_TS_MAX_WIDTH(DDR_TS_MAX_WIDTH),
    .N(QADD_WIDTH),
    .Q(QADD_Q),
    .GEN_NUM(GEN_NUM),
    .GEN_NUM_WIDTH(GEN_NUM_WIDTH)
)
E1_ddr_to_out_inst
(
    .clk(clk),
    .rst(rst),
    .init_calib_complete(init_calib_complete),
    .module_en(module_en_d2o),
    .rd_wr(rd_wr_d2o),
    .ddr_begin_addr(ddr_begin_addr_d2o),
    .module_done(module_done_d2o),

    .app_addr(app_addr_d2o),
    .app_cmd(app_cmd_d2o),
    .app_en(app_en_d2o),
    .app_wdf_data(app_wdf_data_d2o),
    .app_wdf_end(app_wdf_end_d2o),
    .app_wdf_mask(app_wdf_mask_d2o),
    .app_wdf_wren(app_wdf_wren_d2o),
    .app_rd_data(app_rd_data_d2o),
    .app_rd_data_end(app_rd_data_end_d2o),
    .app_rd_data_valid(app_rd_data_valid_d2o),
    .app_rdy(app_rdy_d2o),
    .app_wdf_rdy(app_wdf_rdy_d2o),

    .max(ddr_ts_max),

    .fixed_point(gen_fixed_point),
    .index(gen_fixed_point_index)
);

E1_catch_fixed_point #(
    .CATCH_NUM(CATCH_NUM),
    .CATCH_NUM_WIDTH(CATCH_NUM_WIDTH),
    .N(QADD_WIDTH),
    .Q(QADD_Q)
)
E1_catch_fixed_point_inst
(
    .clk(clk),
    .rst(rst),
    .module_en(module_en_cfp),
    .module_done(module_done_cfp),
    .catch_en(catch_en),
    .catch_fixed_point(catch_fixed_point),
    .index0(index_compute),
    .fixed_point0(fixed_point_compute)
);

E1_validate_vadd #(
    .GEN_NUM(GEN_NUM),
    .GEN_NUM_WIDTH(GEN_NUM_WIDTH),
    .CATCH_NUM(CATCH_NUM),
    .CATCH_NUM_WIDTH(CATCH_NUM_WIDTH),
    .N(QADD_WIDTH),
    .Q(QADD_Q),
    .INDEX_COMPUTE_BEGIN_ADDR(INDEX_COMPUTE_BEGIN_ADDR),
    .INDEX_REF1_BEGIN_ADDR(INDEX_REF1_BEGIN_ADDR),
    .INDEX_REF2_BEGIN_ADDR(INDEX_REF2_BEGIN_ADDR)
)
E1_validate_vadd_inst
(
    .clk(clk),
    .rst(rst),
    .module_en(module_en_vld_vadd),
    .module_done(module_done_vld_vadd),
    .index_compute(index_compute),
    .index_ref1(index_ref1),
    .index_ref2(index_ref2),
    .fixed_point_compute(fixed_point_compute),
    .fixed_point_ref1(fixed_point_ref1),
    .fixed_point_ref2(fixed_point_ref2),
    .error(error),
    .error_num(error_num)
);



E1_bram_wr_rd #(
    .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
    .BRAM_DEPTH(BRAM_DEPTH),
    .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH)
)
E1_bram_wr_rd_inst
(
    .clk(clk),
    .bram0_rd_en(bram0_rd_en),
    .bram0_wr_en(bram0_wr_en),
    .bram0_we(bram0_we),
    .bram0_rd_addr(bram0_rd_addr),
    .bram0_wr_addr(bram0_wr_addr),
    .bram0_din(bram0_din),
    .bram0_dout(bram0_dout),
    .bram1_rd_en(bram1_rd_en),
    .bram1_wr_en(bram1_wr_en),
    .bram1_we(bram1_we),
    .bram1_rd_addr(bram1_rd_addr),
    .bram1_wr_addr(bram1_wr_addr),
    .bram1_din(bram1_din),
    .bram1_dout(bram1_dout)
);




E1_ddr_to_bram #(
    .APP_DATA_WIDTH(DDR_DATA_WIDTH),
    .APP_MASK_WIDTH(DDR_DATA_WIDTH_BYTE),
    .APP_ADDR_WIDTH(DDR_ADDR_WIDTH),
    .FM_COL(FM_COL),
    .FM_ROW(FM_ROW),
    .DDR_TS_MAX_WIDTH($clog2(FM_COL * FM_ROW)),
    .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
    .BRAM_DEPTH(BRAM_DEPTH),
    .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH)
)
E1_ddr_to_bram_inst
(
    .clk(clk),
    .rst(rst),
    .init_calib_complete(init_calib_complete),

    .module_en(module_en_db),
    .rd_wr(rd_wr_db),
    .ddr_begin_addr(ddr_begin_addr_db),
    .bram_begin_addr(bram_begin_addr_db),
    .module_done(module_done_db),

    .app_addr(app_addr_db),
    .app_cmd(app_cmd_db),
    .app_en(app_en_db),
    .app_wdf_data(app_wdf_data_db),
    .app_wdf_end(app_wdf_end_db),
    .app_wdf_mask(app_wdf_mask_db),
    .app_wdf_wren(app_wdf_wren_db),
    .app_rd_data(app_rd_data_db),
    .app_rd_data_end(app_rd_data_end_db),
    .app_rd_data_valid(app_rd_data_valid_db),
    .app_rdy(app_rdy_db),
    .app_wdf_rdy(app_wdf_rdy_db),

    .bram_rd_en(bram_rd_en_db),
    .bram_wr_en(bram_wr_en_db),
    .bram_we(bram_we_db),
    .bram_rd_addr(bram_rd_addr_db),
    .bram_wr_addr(bram_wr_addr_db),
    .bram_din(bram_din_db),
    .bram_dout(bram_dout_db)
);

E1_bram_to_op #(
    .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
    .BRAM_DEPTH(BRAM_DEPTH),
    .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
    .QADD_WIDTH(QADD_WIDTH),
    .QADD_Q(QADD_Q)
)
E1_bram_to_op_inst
(
    .clk(clk),
    .rst(rst),
    .init_calib_complete(init_calib_complete),
    .op_cs(op_cs_b2o),
    .module_en(module_en_b2o),
    .module_done(module_done_b2o),

    .bram0_begin_addr(bram0_begin_addr_b2o),
    .bram1_begin_addr(bram1_begin_addr_b2o),
    .max(max_b2o),

    .bram0_dout(bram0_dout_b2o),
    .bram1_dout(bram1_dout_b2o),
    .bram0_din(bram0_din_b2o),
    .bram1_din(bram1_din_b2o),
    .bram0_rd_en(bram0_rd_en_b2o),
    .bram1_rd_en(bram1_rd_en_b2o),
    .bram0_wr_en(bram0_wr_en_b2o),
    .bram1_wr_en(bram1_wr_en_b2o),
    .bram0_we(bram0_we_b2o),
    .bram1_we(bram1_we_b2o),
    .bram0_rd_addr(bram0_rd_addr_b2o),
    .bram1_rd_addr(bram1_rd_addr_b2o),
    .bram0_wr_addr(bram0_wr_addr_b2o),
    .bram1_wr_addr(bram1_wr_addr_b2o),
    
    .qadd_a_g(qadd_a_g_b2o),
    .qadd_b_g(qadd_b_g_b2o),
    .qadd_a_g_en(qadd_a_g_en_b2o),
    .qadd_b_g_en(qadd_b_g_en_b2o),
    .qadd_c_g(qadd_c_g_b2o),
    .qadd_c_g_valid(qadd_c_valid_g_b2o)
);

E1_qadd_g #(
    .Q(QADD_Q),
    .N(DDR_DATA_WIDTH),
    .NUM(BRAM_DDR_RATIO)
)
E1_qadd_g_inst
(
    .clk(clk),
    .rst(rst),
    .a(qadd_a_g_b2o),
    .a_en(qadd_a_g_en_b2o),
    .b(qadd_b_g_b2o),
    .b_en(qadd_b_g_en_b2o),
    .c(qadd_c_g_b2o),
    .c_valid(qadd_c_valid_g_b2o)
);

wire [QADD_WIDTH - 1 : 0] qadd_a_g_b2o_p0;
wire [QADD_WIDTH - 1 : 0] qadd_a_g_b2o_p1;
wire [QADD_WIDTH - 1 : 0] qadd_a_g_b2o_p2;
wire [QADD_WIDTH - 1 : 0] qadd_a_g_b2o_p3;
wire [QADD_WIDTH - 1 : 0] qadd_b_g_b2o_p0; 
wire [QADD_WIDTH - 1 : 0] qadd_b_g_b2o_p1;
wire [QADD_WIDTH - 1 : 0] qadd_b_g_b2o_p2;
wire [QADD_WIDTH - 1 : 0] qadd_b_g_b2o_p3;
wire [QADD_WIDTH - 1 : 0] qadd_c_g_b2o_p0;
wire [QADD_WIDTH - 1 : 0] qadd_c_g_b2o_p1;
wire [QADD_WIDTH - 1 : 0] qadd_c_g_b2o_p2;
wire [QADD_WIDTH - 1 : 0] qadd_c_g_b2o_p3;

assign qadd_a_g_b2o_p0 = qadd_a_g_b2o[QADD_WIDTH * 0 +: QADD_WIDTH];
assign qadd_a_g_b2o_p1 = qadd_a_g_b2o[QADD_WIDTH * 1 +: QADD_WIDTH];
assign qadd_a_g_b2o_p2 = qadd_a_g_b2o[QADD_WIDTH * 2 +: QADD_WIDTH];
assign qadd_a_g_b2o_p3 = qadd_a_g_b2o[QADD_WIDTH * 3 +: QADD_WIDTH];
assign qadd_b_g_b2o_p0 = qadd_b_g_b2o[QADD_WIDTH * 0 +: QADD_WIDTH];
assign qadd_b_g_b2o_p1 = qadd_b_g_b2o[QADD_WIDTH * 1 +: QADD_WIDTH];
assign qadd_b_g_b2o_p2 = qadd_b_g_b2o[QADD_WIDTH * 2 +: QADD_WIDTH];
assign qadd_b_g_b2o_p3 = qadd_b_g_b2o[QADD_WIDTH * 3 +: QADD_WIDTH];
assign qadd_c_g_b2o_p0 = qadd_c_g_b2o[QADD_WIDTH * 0 +: QADD_WIDTH];
assign qadd_c_g_b2o_p1 = qadd_c_g_b2o[QADD_WIDTH * 1 +: QADD_WIDTH];
assign qadd_c_g_b2o_p2 = qadd_c_g_b2o[QADD_WIDTH * 2 +: QADD_WIDTH];
assign qadd_c_g_b2o_p3 = qadd_c_g_b2o[QADD_WIDTH * 3 +: QADD_WIDTH];



E1_ddr_wrapper_top #(
    .APP_ADDR_WIDTH(DDR_ADDR_WIDTH),
    .APP_DATA_WIDTH(DDR_DATA_WIDTH),
    .APP_MASK_WIDTH(DDR_DATA_WIDTH_BYTE)
)
E1_ddr_wrapper_top_inst
(
    .app_addr(app_addr),
    .app_cmd(app_cmd),
    .app_en(app_en),
    .app_wdf_data(app_wdf_data),
    .app_wdf_end(app_wdf_end),
    .app_wdf_mask(app_wdf_mask),
    .app_wdf_wren(app_wdf_wren),
    .app_rd_data(app_rd_data),
    .app_rd_data_end(app_rd_data_end),
    .app_rd_data_valid(app_rd_data_valid),
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy),

    .clk(clk),
    .rst(rst),
    .init_calib_complete(init_calib_complete)
);


endmodule