module tb_MAC_simple;

timeunit 1ns;
timeprecision 10ps;

logic clk_i;
logic rstn;

localparam PL_STAGES = 0;
int i;
localparam M_out_width = 16;

always begin #2.0ns; clk_i <= ~clk_i; end

logic [7:0] a_mant [0:3];
logic [7:0] b_mant [0:3];
logic [9:0] a_exp [0:3];
logic [9:0] b_exp [0:3];
logic [3:0] a_sign [0:3];
logic [3:0] b_sign [0:3];
logic [1:0] prec_mode;
logic [1:0] FP_mode;/*
logic [22:0] out_mant;
logic [7:0]  out_exp;
logic        out_sign;*/
logic [M_out_width-1:0] MAC_mant_out;
logic [7:0] MAC_exp_out;
logic MAC_sign_out;
logic [1:0][7:0] shared_exps;

localparam EA = 0;

//DUT
/*generate
if (EA) begin
  MX_MAC_EA MX_MAC0 (.clk_i(clk_i), .rstn(rstn), .a_mant0(a_mant[0]), .a_mant1(a_mant[1]), .a_mant2(a_mant[2]), .a_mant3(a_mant[3]), 
  .b_mant0(b_mant[0]), .b_mant1(b_mant[1]), .b_mant2(b_mant[2]), .b_mant3(b_mant[3]), .a_exp_in0(a_exp[0]), .a_exp_in1(a_exp[1]), .a_exp_in2(a_exp[2]), .a_exp_in3(a_exp[3]),
  .b_exp_in0(b_exp[0]), .b_exp_in1(b_exp[1]), .b_exp_in2(b_exp[2]), .b_exp_in3(b_exp[3]), .a_sign_in0(a_sign[0]), .a_sign_in1(a_sign[1]), .a_sign_in2(a_sign[2]), .a_sign_in3(a_sign[3]),
  .b_sign_in0(b_sign[0]), .b_sign_in1(b_sign[1]), .b_sign_in2(b_sign[2]), .b_sign_in3(b_sign[3]), .prec_mode(prec_mode), .FP_mode(FP_mode), .MAC_mant_out(MAC_mant_out), .MAC_exp_out(MAC_exp_out), .MAC_sign_out(MAC_sign_out), 
  .shared_exps0(shared_exps[0]), .shared_exps1(shared_exps[1]));
end
else begin*/
  MX_MAC #(.M_out_width(M_out_width)) MX_MAC0 (.clk_i(clk_i), .rstn(rstn), .a_mant0(a_mant[0]), .a_mant1(a_mant[1]), .a_mant2(a_mant[2]), .a_mant3(a_mant[3]), 
  .b_mant0(b_mant[0]), .b_mant1(b_mant[1]), .b_mant2(b_mant[2]), .b_mant3(b_mant[3]), .a_exp_in0(a_exp[0]), .a_exp_in1(a_exp[1]), .a_exp_in2(a_exp[2]), .a_exp_in3(a_exp[3]),
  .b_exp_in0(b_exp[0]), .b_exp_in1(b_exp[1]), .b_exp_in2(b_exp[2]), .b_exp_in3(b_exp[3]), .a_sign_in0(a_sign[0]), .a_sign_in1(a_sign[1]), .a_sign_in2(a_sign[2]), .a_sign_in3(a_sign[3]),
  .b_sign_in0(b_sign[0]), .b_sign_in1(b_sign[1]), .b_sign_in2(b_sign[2]), .b_sign_in3(b_sign[3]), .prec_mode(prec_mode), .FP_mode(FP_mode), .MAC_mant_out(MAC_mant_out), .MAC_exp_out(MAC_exp_out), .MAC_sign_out(MAC_sign_out), 
  .shared_exps0(shared_exps[0]), .shared_exps1(shared_exps[1]));
/*end
endgenerate*/


/*
MX_MAC MX_MAC0 (.clk_i(clk_i), .rstn(rstn), .a_mant0(a_mant[0]), .a_mant1(a_mant[1]), .a_mant2(a_mant[2]), .a_mant3(a_mant[3]), 
.b_mant0(b_mant[0]), .b_mant1(b_mant[1]), .b_mant2(b_mant[2]), .b_mant3(b_mant[3]), .a_exp_in0(a_exp[0]), .a_exp_in1(a_exp[1]), .a_exp_in2(a_exp[2]), .a_exp_in3(a_exp[3]),
.b_exp_in0(b_exp[0]), .b_exp_in1(b_exp[1]), .b_exp_in2(b_exp[2]), .b_exp_in3(b_exp[3]), .a_sign_in0(a_sign[0]), .a_sign_in1(a_sign[1]), .a_sign_in2(a_sign[2]), .a_sign_in3(a_sign[3]),
.b_sign_in0(b_sign[0]), .b_sign_in1(b_sign[1]), .b_sign_in2(b_sign[2]), .b_sign_in3(b_sign[3]), .prec_mode(prec_mode), .FP_mode(FP_mode), .MAC_mant_out(MAC_mant_out), .MAC_exp_out(MAC_exp_out), .MAC_sign_out(MAC_sign_out), 
.shared_exps0(shared_exps[0]), .shared_exps1(shared_exps[1]), .rnd_mode_i(rnd_mode_i), .dst_fmt_i(dst_fmt_i));
*/

/*
MX_MAC #(.PL_STAGES(PL_STAGES)) MX_MAC0 (.clk_i(clk_i), .rstn(rstn), .a_mant0(a_mant[0]), .a_mant1(a_mant[1]), .a_mant2(a_mant[2]), .a_mant3(a_mant[3]), 
.b_mant0(b_mant[0]), .b_mant1(b_mant[1]), .b_mant2(b_mant[2]), .b_mant3(b_mant[3]), .a_exp_in0(a_exp[0]), .a_exp_in1(a_exp[1]), .a_exp_in2(a_exp[2]), .a_exp_in3(a_exp[3]),
.b_exp_in0(b_exp[0]), .b_exp_in1(b_exp[1]), .b_exp_in2(b_exp[2]), .b_exp_in3(b_exp[3]), .a_sign_in0(a_sign[0]), .a_sign_in1(a_sign[1]), .a_sign_in2(a_sign[2]), .a_sign_in3(a_sign[3]),
.b_sign_in0(b_sign[0]), .b_sign_in1(b_sign[1]), .b_sign_in2(b_sign[2]), .b_sign_in3(b_sign[3]), .prec_mode(prec_mode), .FP_mode(FP_mode), .MAC_mant_out(MAC_mant_out), .MAC_exp_out(MAC_exp_out), .MAC_sign_out(MAC_sign_out), 
.shared_exps0(shared_exps[0]), .shared_exps1(shared_exps[1]), .rnd_mode_i(rnd_mode_i), .dst_fmt_i(dst_fmt_i));
*/

/*
ST_mul ST_mul0 (.clk_i(clk_i), .rstn(rstn), .a_mant0(a_mant[0]), .a_mant1(a_mant[1]), .a_mant2(a_mant[2]), .a_mant3(a_mant[3]), 
.b_mant0(b_mant[0]), .b_mant1(b_mant[1]), .b_mant2(b_mant[2]), .b_mant3(b_mant[3]), .a_exp_in0(a_exp[0]), .a_exp_in1(a_exp[1]), .a_exp_in2(a_exp[2]), .a_exp_in3(a_exp[3]),
.b_exp_in0(b_exp[0]), .b_exp_in1(b_exp[1]), .b_exp_in2(b_exp[2]), .b_exp_in3(b_exp[3]), .a_sign_in0(a_sign[0]), .a_sign_in1(a_sign[1]), .a_sign_in2(a_sign[2]), .a_sign_in3(a_sign[3]),
.b_sign_in0(b_sign[0]), .b_sign_in1(b_sign[1]), .b_sign_in2(b_sign[2]), .b_sign_in3(b_sign[3]), .prec_mode(prec_mode), .FP_mode(FP_mode), .out_mant(out_mant), .out_exp(out_exp), .out_sign(out_sign));*/



initial begin
clk_i = 0;
rstn = 0;
shared_exps[0] = 'd127;
shared_exps[1] = 'd127;

@(posedge clk_i);

rstn = 1;

//INT8xINT8
prec_mode = 2'b00;
FP_mode = 2'b00;

a_mant[0] = 8'd11;
b_mant[0] = 8'd8;
a_exp[0] = '0;
b_exp[0] = '0;
a_sign[0] = '0;
b_sign[0] = '0;
//INT8 has implicit 2^(-6) scale -> 20*2^(-12)
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b", MAC_mant_out);
assert(MAC_mant_out == {15'b011000000000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd121);
assert(MAC_sign_out == 'd0);

@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;

//Negatives
a_mant[0] = -8'd11;
b_mant[0] = 8'd8;
a_exp[0] = '0;
b_exp[0] = '0;
a_sign[0] = '1;
b_sign[0] = '0;
//INT8 has implicit 2^(-6) scale -> 2^(-12)
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b", MAC_mant_out);
assert(MAC_mant_out == {15'b011000000000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd121);
assert(MAC_sign_out == 'd1);

@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;

//E4M3xE4M3
prec_mode = 2'b01;
FP_mode = 2'b10;

a_mant[0] = {4'd5,4'd2}; //1.101 => 1.625*2^(1-7) [1]z| 1.010 => 1.25*2^(1-7) [0]x
b_mant[0] = {4'd4,4'd1}; //1.100 => 1.5*2^(3-7)    y  | 1.001 => 1.125*2^(3-7) x
a_mant[1] = {4'd3,4'd6}; //1.011 => 1.375*2^(2-7)  w  | 1.110 => 1.75*2^(1-7)  y
b_mant[1] = {4'd2,4'd7}; //1.010 => 1.25*2^(5-7)   w  | 1.111 => 1.875*2^(2-7) z
a_exp[0]  = {5'd1,5'd1};
b_exp[0]  = {5'd3,5'd3};
a_exp[1]  = {5'd2,5'd1};
b_exp[1]  = {5'd5,5'd2};
a_sign[0] = '0;
b_sign[0] = '0;
a_sign[1] = '0;
b_sign[1] = '0;
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

//a_mant[0][0]*b_mant[0][0]+a_mant[1][0]*b_mant[0][1]+a_mant[0][1]*b_mant[1][0]+a_mant[1][1]*b_mant[1][1] => 
//1.40625*2^(-10)+2.625*2^(-10)+3.046875*2^(-11)+1.71875*2^(-7) = 0.01885223388
@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b001101001110000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd121);
assert(MAC_sign_out == 'd0);
@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;

//Negative
a_mant[0] = {4'd5,4'd2}; //1.101 => 1.625*2^(1-7) [1]z| 1.010 => 1.25*2^(1-7) [0]x
b_mant[0] = {4'd4,4'd1}; //1.100 => 1.5*2^(3-7)    y  | 1.001 => 1.125*2^(3-7) x
a_mant[1] = {4'd3,4'd6}; //1.011 => 1.375*2^(2-7)  w  | 1.110 => 1.75*2^(1-7)  y
b_mant[1] = {4'd2,4'd7}; //1.010 => 1.25*2^(5-7)   w  | 1.111 => 1.875*2^(2-7) z
a_exp[0]  = {5'd1,5'd1};
b_exp[0]  = {5'd3,5'd3};
a_exp[1]  = {5'd2,5'd1};
b_exp[1]  = {5'd5,5'd2};
a_sign[0] = '1;
b_sign[0] = '0;
a_sign[1] = '1;
b_sign[1] = '0;
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

//a_mant[0][0]*b_mant[0][0]+a_mant[1][0]*b_mant[0][1]+a_mant[0][1]*b_mant[1][0]+a_mant[1][1]*b_mant[1][1] => 
//1.40625*2^(-10)+2.625*2^(-10)+3.046875*2^(-11)+1.71875*2^(-7) = 0.01885223388
@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b001101001110000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd121);
assert(MAC_sign_out == 'd1);
@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;

//E3M2xE3M2
prec_mode = 2'b01;
FP_mode = 2'b01;

a_mant[0] = {4'd3,4'd2}; //1.11 => 1.75*2^(1-3) [1]z| 1.10 => 1.5*2^(1-3) [0]x
b_mant[0] = {4'd2,4'd1}; //1.10 => 1.5*2^(3-3)     y| 1.01 => 1.25*2^(3-3)   x
a_mant[1] = {4'd3,4'd2}; //1.11 => 1.75*2^(2-3)    w| 1.10 => 1.5*2^(1-3)    y
b_mant[1] = {4'd2,4'd3}; //1.10 => 1.5*2^(5-3)     w| 1.11 => 1.75*2^(2-3)   z
a_exp[0]  = {5'd1,5'd1};
b_exp[0]  = {5'd3,5'd3};
a_exp[1]  = {5'd2,5'd1};
b_exp[1]  = {5'd5,5'd2};
a_sign[0] = '0;
b_sign[0] = '0;
a_sign[1] = '0;
b_sign[1] = '0;
//1.875*2^(-2)+2.25*2^(-2)+3.0625*2^(-3)+2.625*2^(1) = 6.6640625
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b101010101000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd129);
assert(MAC_sign_out == 'd0);
@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;
//E2M1xE2M1
prec_mode = 2'b11;
FP_mode = 2'b00;
a_mant[0] = {2'd1,2'd0,2'd1,2'd0}; //1.1 => 1.5*2^(1-1) [3]yz|1.0 => 1.0*2^(1-1) [2]yx|1.1 => 1.5*2^(1-1) [1]xz|1.0 => 1.0*2^(1-1) [0]xx|
b_mant[0] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(3-1)    zy|1.1 => 1.5*2^(3-1)    zx|1.1 => 1.5*2^(1-1)    xy|1.0 => 1.0*2^(1-1)    xx|
a_mant[1] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(2-1)    yw|1.1 => 1.5*2^(1-1)    yy|1.1 => 1.5*2^(1-1)    xw|1.0 => 1.0*2^(1-1)    xy|
b_mant[1] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    zw|1.1 => 1.5*2^(2-1)    zz|1.1 => 1.5*2^(1-1)    xw|1.0 => 1.0*2^(1-1)    xz|
a_mant[2] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(2-1)    wz|1.1 => 1.5*2^(1-1)    wx|1.1 => 1.5*2^(1-1)    zz|1.0 => 1.0*2^(1-1)    zx|
b_mant[2] = {2'd1,2'd0,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    wy|1.0 => 1.0*2^(2-1)    wx|1.1 => 1.5*2^(1-1)    yy|1.0 => 1.0*2^(1-1)    yx|
a_mant[3] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(2-1)    ww|1.1 => 1.5*2^(1-1)    wy|1.1 => 1.5*2^(1-1)    zw|1.0 => 1.0*2^(1-1)    zy|
b_mant[3] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    ww|1.1 => 1.5*2^(2-1)    wz|1.1 => 1.5*2^(1-1)    yw|1.0 => 1.0*2^(1-1)    yz|
a_exp[0]  = {2'b00, 2'd1,2'd1,2'd1,2'd1};
b_exp[0]  = {2'b00, 2'd3,2'd3,2'd1,2'd1};
a_exp[1]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[1]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_exp[2]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[2]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_exp[3]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[3]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_sign[0] = '0;
b_sign[0] = '0;
a_sign[1] = '0;
b_sign[1] = '0;
a_sign[2] = '0;
b_sign[2] = '0;
a_sign[3] = '0;
b_sign[3] = '0;
//x=>1+1.5+1.5+2.25=6.25
//y=>1+2.25+1.5+3=7.75 -> 0 because utilization /2
//z=>6+4+4.5+9=23.5 -> 0 because utilization /2
//w=>3+9+9+12=33
//=>70.5 -> 39.25 
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b001110100000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd132);
assert(MAC_sign_out == 'd0);
@(posedge clk_i);

@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;

//Negative
a_mant[0] = {2'd1,2'd0,2'd1,2'd0}; //1.1 => 1.5*2^(1-1) [3]yz|1.0 => 1.0*2^(1-1) [2]yx|1.1 => 1.5*2^(1-1) [1]xz|1.0 => 1.0*2^(1-1) [0]xx|
b_mant[0] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(3-1)    zy|1.1 => 1.5*2^(3-1)    zx|1.1 => 1.5*2^(1-1)    xy|1.0 => 1.0*2^(1-1)    xx|
a_mant[1] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(2-1)    yw|1.1 => 1.5*2^(1-1)    yy|1.1 => 1.5*2^(1-1)    xw|1.0 => 1.0*2^(1-1)    xy|
b_mant[1] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    zw|1.1 => 1.5*2^(2-1)    zz|1.1 => 1.5*2^(1-1)    xw|1.0 => 1.0*2^(1-1)    xz|
a_mant[2] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(2-1)    wz|1.1 => 1.5*2^(1-1)    wx|1.1 => 1.5*2^(1-1)    zz|1.0 => 1.0*2^(1-1)    zx|
b_mant[2] = {2'd1,2'd0,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    wy|1.0 => 1.0*2^(2-1)    wx|1.1 => 1.5*2^(1-1)    yy|1.0 => 1.0*2^(1-1)    yx|
a_mant[3] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(2-1)    ww|1.1 => 1.5*2^(1-1)    wy|1.1 => 1.5*2^(1-1)    zw|1.0 => 1.0*2^(1-1)    zy|
b_mant[3] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    ww|1.1 => 1.5*2^(2-1)    wz|1.1 => 1.5*2^(1-1)    yw|1.0 => 1.0*2^(1-1)    yz|
a_exp[0]  = {2'b00, 2'd1,2'd1,2'd1,2'd1};
b_exp[0]  = {2'b00, 2'd3,2'd3,2'd1,2'd1};
a_exp[1]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[1]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_exp[2]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[2]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_exp[3]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[3]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_sign[0] = '1;
b_sign[0] = '0;
a_sign[1] = '1;
b_sign[1] = '0;
a_sign[2] = '1;
b_sign[2] = '0;
a_sign[3] = '1;
b_sign[3] = '0;
//x=>1+1.5+1.5+2.25=6.25
//y=>1+2.25+1.5+3=7.75 -> 0 because utilization /2
//z=>6+4+4.5+9=23.5 -> 0 because utilization /2
//w=>3+9+9+12=33
//=>70.5 -> 39.25 
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b001110100000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd132);
assert(MAC_sign_out == 'd1);
@(posedge clk_i);

@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);
rstn = 0;
@(posedge clk_i);
rstn = 1;

//Mul: Adding only, both + and - results
////////////////////////////////////
//Mul: Subtracting at L1 and L2

//L1: (E2M1)
prec_mode = 2'b11;
FP_mode = 2'b00;
a_mant[0] = {2'd1,2'd0,2'd1,2'd0}; //1.1 => 1.5*2^(1-1) [3]yz|1.0 => 1.0*2^(1-1) [2]yx|1.1 => 1.5*2^(1-1) [1]xz|1.0 => 1.0*2^(1-1) [0]xx|
b_mant[0] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(3-1)    zy|1.1 => 1.5*2^(3-1)    zx|1.1 => 1.5*2^(1-1)    xy|1.0 => 1.0*2^(1-1)    xx|
a_mant[1] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(2-1)    yw|1.1 => 1.5*2^(1-1)    yy|1.1 => 1.5*2^(1-1)    xw|1.0 => 1.0*2^(1-1)    xy|
b_mant[1] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    zw|1.1 => 1.5*2^(2-1)    zz|1.1 => 1.5*2^(1-1)    xw|1.0 => 1.0*2^(1-1)    xz|
a_mant[2] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(2-1)    wz|1.1 => 1.5*2^(1-1)    wx|1.1 => 1.5*2^(1-1)    zz|1.0 => 1.0*2^(1-1)    zx|
b_mant[2] = {2'd1,2'd0,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    wy|1.0 => 1.0*2^(2-1)    wx|1.1 => 1.5*2^(1-1)    yy|1.0 => 1.0*2^(1-1)    yx|
a_mant[3] = {2'd0,2'd1,2'd1,2'd0}; //1.0 => 1.0*2^(2-1)    ww|1.1 => 1.5*2^(1-1)    wy|1.1 => 1.5*2^(1-1)    zw|1.0 => 1.0*2^(1-1)    zy|
b_mant[3] = {2'd1,2'd1,2'd1,2'd0}; //1.1 => 1.5*2^(3-1)    ww|1.1 => 1.5*2^(2-1)    wz|1.1 => 1.5*2^(1-1)    yw|1.0 => 1.0*2^(1-1)    yz|
a_exp[0]  = {2'b00, 2'd1,2'd1,2'd1,2'd1};
b_exp[0]  = {2'b00, 2'd3,2'd3,2'd1,2'd1};
a_exp[1]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[1]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_exp[2]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[2]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_exp[3]  = {2'b00, 2'd2,2'd1,2'd1,2'd1};
b_exp[3]  = {2'b00, 2'd3,2'd2,2'd1,2'd1};
a_sign[0] = 4'b0000;
b_sign[0] = '0;
a_sign[1] = 4'b0000;
b_sign[1] = '0;
a_sign[2] = 4'b1000;
b_sign[2] = 4'b0000;
a_sign[3] = 4'b1000;
b_sign[3] = 4'b0000;
//x=>1+1.5+1.5+2.25=6.25
//y=> 0 because utilization /2
//z=> 0 because utilization /2
//w=>3+9-9-12=-9
//=>-2.75
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b011000000000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd128);
assert(MAC_sign_out == 'd1);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;

//L2: (E3M2)
prec_mode = 2'b01;
FP_mode = 2'b01;

a_mant[0] = {4'd3,4'd2}; //1.11 => 1.75*2^(1-3) [1]z| 1.10 => 1.5*2^(1-3) [0]x
b_mant[0] = {4'd2,4'd1}; //1.10 => 1.5*2^(3-3)     y| 1.01 => 1.25*2^(3-3)   x
a_mant[1] = {4'd3,4'd2}; //1.11 => 1.75*2^(2-3)    w| 1.10 => 1.5*2^(1-3)    y
b_mant[1] = {4'd2,4'd3}; //1.10 => 1.5*2^(5-3)     w| 1.11 => 1.75*2^(2-3)   z
a_exp[0]  = {5'd1,5'd1};
b_exp[0]  = {5'd3,5'd3};
a_exp[1]  = {5'd2,5'd1};
b_exp[1]  = {5'd5,5'd2};
a_sign[0] = '0;
b_sign[0] = '0;
a_sign[1] = '0;
b_sign[1] = 4'b1110;
//1.875*2^(-2)+2.25*2^(-2)+3.0625*2^(-3)-2.625*2^(1) = -3.8359375
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b111010110000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd128);
assert(MAC_sign_out == 'd1);
@(posedge clk_i);
rstn = 0;
@(posedge clk_i);
rstn = 1;

//Mul: Subtracting at L1 and L2
////////////////////////////////////
//FP32 Accum: Adding and subtracting

//Addition positive numbers
a_sign[0] = '1;
b_sign[0] = '0;
a_sign[1] = '1;
b_sign[1] = 4'b1110;
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b111010110000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd128);
assert(MAC_sign_out == 'd0);
@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b111010110000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd129);
assert(MAC_sign_out == 'd0);
@(posedge clk_i);
rstn = 0;
@(posedge clk_i);
rstn = 1;

//Checks if negative numbers can be added together (addition)
//previous x2
//-3.8359375*2
a_sign[0] = '0;
b_sign[0] = '0;
a_sign[1] = '0;
b_sign[1] = 4'b1110;
//1.875*2^(-2)+2.25*2^(-2)+3.0625*2^(-3)-2.625*2^(1) = -3.8359375 
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
  if (i==1) begin
    a_sign[0] = '1;
    b_sign[0] = '0;
    a_sign[1] = '1;
    b_sign[1] = 4'b1110;
  end
end



@(posedge clk_i);

if (PL_STAGES == 1) begin
  a_sign[0] = '1;
  b_sign[0] = '0;
  a_sign[1] = '1;
  b_sign[1] = 4'b1110;
end

#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b111010110000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd128);
assert(MAC_sign_out == 'd1);
@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b111010110000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd129);
assert(MAC_sign_out == 'd1);

//Checks if positive can be added to negative number (subtraction)
if (PL_STAGES == 0) begin
    a_sign[0] = '1;
    b_sign[0] = '0;
    a_sign[1] = '1;
    b_sign[1] = 4'b1110;
end

//inverting signs of a to get +3.8359375 as output of mul
@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b111010110000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd128);
assert(MAC_sign_out == 'd1);

@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);
rstn = 0;
@(posedge clk_i);
rstn = 1;

//E5M2xE5M2
prec_mode = 2'b01;
FP_mode = 2'b11;

a_mant[0] = {4'd0,4'd2}; //1.00 => 1.00*2^(22-15) [1]z| 1.10 => 1.50*2^(2-15) [0]x
b_mant[0] = {4'd1,4'd3}; //1.01 => 1.25*2^(28-15)    y| 1.11 => 1.75*2^(6-15)    x
a_mant[1] = {4'd1,4'd0}; //1.01 => 1.25*2^(13-15)    w| 1.00 => 1.00*2^(11-15)   y
b_mant[1] = {4'd2,4'd2}; //1.10 => 1.50*2^(5-15)     w| 1.10 => 1.50*2^(2-15)    z
a_exp[0]  = {5'd22,5'd2};
b_exp[0]  = {5'd28,5'd6};
a_exp[1]  = {5'd13,5'd11};
b_exp[1]  = {5'd5,5'd2};
a_sign[0] = '0;
b_sign[0] = '0;
a_sign[1] = '0;
b_sign[1] = '0;
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

//a_mant[0][0]*b_mant[0][0]+a_mant[1][0]*b_mant[0][1]+a_mant[0][1]*b_mant[1][0]+a_mant[1][1]*b_mant[1][1] => 
//2.625*2^(-22)+1.25*2^(9)+1.50*2^(-6)+1.875*2^(-12) = 640.02389589
@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b010000000000001,{(M_out_width-15){1'b0}}}); //assert(MAC_mant_out == 23'b01000000000000110000111);
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd136);
assert(MAC_sign_out == 'd0);
@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;


//E2M3xE2M3
prec_mode = 2'b01;
FP_mode = 2'b00;

a_mant[0] = {4'd3,4'd1}; //1.011 => 1.375*2^(1-3) [1]z| 1.001 => 1.125*2^(1-3) [0]x
b_mant[0] = {4'd6,4'd4}; //1.110 => 1.750*2^(3-3)    y| 1.100 => 1.500*2^(3-3)    x
a_mant[1] = {4'd3,4'd7}; //1.011 => 1.375*2^(2-3)    w| 1.111 => 1.875*2^(1-3)    y
b_mant[1] = {4'd5,4'd3}; //1.101 => 1.625*2^(1-3)    w| 1.011 => 1.375*2^(2-3)    z
a_exp[0]  = {5'd1,5'd1};
b_exp[0]  = {5'd3,5'd3};
a_exp[1]  = {5'd2,5'd1};
b_exp[1]  = {5'd1,5'd2};
a_sign[0] = '0;
b_sign[0] = '0;
a_sign[1] = '0;
b_sign[1] = '0;
//1.6875*2^(-2)+3.28125*2^(-2)+1.890625*2^(-3)+2.234375*2^(-3) = 1.7578125
for (i=0;i<PL_STAGES;i++) begin
@(posedge clk_i);
end

@(posedge clk_i);
#0.1ns;
$display("%b",MAC_mant_out);
assert(MAC_mant_out == {15'b110000100000000,{(M_out_width-15){1'b0}}});
$display("%d",MAC_exp_out);
assert(MAC_exp_out  == 8'd127);
assert(MAC_sign_out == 'd0);
@(posedge clk_i);
@(posedge clk_i);
@(posedge clk_i);

rstn = 0;
@(posedge clk_i);
rstn = 1;


$finish;

end
endmodule
