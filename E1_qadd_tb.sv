`timescale 1ps / 1ps

module E1_qadd_tb;

localparam N = 15;
localparam Q = 49;

localparam DELAY = 1;

reg clk;
reg rst;
wire [N + Q - 1 : 0] a;
reg [N - 1 : 0] a_int;
reg [Q - 1 : 0] a_frac;
reg a_en;
wire [N + Q - 1 : 0] b;
reg [N - 1 : 0] b_int;
reg [Q - 1 : 0] b_frac;
reg b_en;
wire [N + Q - 1 : 0] c;
wire c_valid;
real a_real;
real b_real;
real c_real;
real c_ref;
integer seed1;
integer seed2;
integer right_num;
integer err_num;

function real fixedToFloat;
    input [N + Q - 1 : 0] fixed;
    input integer WI;
    input integer WF;

    integer idx;
    real retVal;



    begin
        retVal = 0;
        for (idx = 0; idx < WI + WF - 1; idx = idx + 1) begin
            if (fixed[idx] == 1'b1) begin
                retVal = retVal + (2.0**(idx - WF));
            end
        end

        fixedToFloat = retVal - (fixed[WI + WF - 1] * (2.0**(WI - 1)));
    end
endfunction

initial begin
    clk = 1;
    forever #5 clk = ~clk;
end

initial begin
    right_num = 0;
    err_num = 0;
    rst = 0;
    a_en = 0;
    b_en = 0;
    repeat (2) @(posedge clk); #DELAY;;
    rst = 1;
    @(posedge clk); #DELAY;;
    rst = 0;
    @(posedge clk); #DELAY;;
    seed1 = 100;
    seed2 = 300;
    repeat(100) begin
        a_int = $random(seed1) % (2**(N-2));
        a_frac = $random(seed1) % (2**(Q-1));
        b_int = $random(seed2) % (2**(N-2));
        b_frac = $random(seed2) % (2**(Q-1));
        a_en = 1;
        b_en = 1;
        @(posedge clk); #DELAY;;
        a_en = 0;
        b_en = 0;
        wait(c_valid); #DELAY;
        $display("a = %f, b = %f, c = %f, c_ref = %f", a_real, b_real, c_real, c_ref);
        if (((c_real - c_ref) > -0.000001) & ((c_real - c_ref) < 0.000001)) begin
            $display("Case passed");
            right_num = right_num + 1;
        end else begin
            $display("Test failed");
            err_num = err_num + 1;
        end
        @(posedge clk); #DELAY;;
    end
    $display("Test finished, %d cases passed, %d cases failed", right_num, err_num);
    $finish;
end

always @(a) a_real = fixedToFloat(a, N, Q);
always @(b) b_real = fixedToFloat(b, N, Q);
always @(c) c_real = fixedToFloat(c, N, Q);
always @(a_real or b_real) c_ref = a_real + b_real;

assign a = {a_int, a_frac};
assign b = {b_int, b_frac};

//instatiation of qadd module
E1_qadd #(
    .Q(N),
    .N(N + Q)
)
qadd_inst
(
    .clk(clk),
    .rst(rst),
    .a(a),
    .a_en(a_en),
    .b(b),
    .b_en(b_en),
    .c(c),
    .c_valid(c_valid)
);

endmodule