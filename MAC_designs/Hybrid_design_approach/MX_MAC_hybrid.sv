module MX_MAC_hybrid #(
	parameter PL_STAGES = 0,
	parameter M_out_width = {M_out_width}
)
(
  	input  logic        clk_i,
  	input  logic        rstn,
  	input  logic [7:0]  a_mant0,
  	input  logic [7:0]  a_mant1,
  	input  logic [7:0]  a_mant2,
 	input  logic [7:0]  a_mant3,
  	input  logic [7:0]  b_mant0,
  	input  logic [7:0]  b_mant1,
  	input  logic [7:0]  b_mant2,
  	input  logic [7:0]  b_mant3,
  	input  logic [9:0]  a_exp_in0, //up to 2 exponents of 2 to 5 bits OR 4 exponents of 2 bits
  	input  logic [9:0]  a_exp_in1,
  	input  logic [9:0]  a_exp_in2,
  	input  logic [9:0]  a_exp_in3,
  	input  logic [9:0]  b_exp_in0,
  	input  logic [9:0]  b_exp_in1,
  	input  logic [9:0]  b_exp_in2,
	input  logic [9:0]  b_exp_in3,
  	input  logic [3:0]  a_sign_in0, //up to 4 inputs each with a sign
	input  logic [3:0]  a_sign_in1,
	input  logic [3:0]  a_sign_in2,
	input  logic [3:0]  a_sign_in3,
  	input  logic [3:0]  b_sign_in0,
	input  logic [3:0]  b_sign_in1,
	input  logic [3:0]  b_sign_in2,
	input  logic [3:0]  b_sign_in3,
	input  logic [1:0]  prec_mode, //0 means 8-bit, 1 means 4-bit, 2 means 2-bit
	input  logic [1:0]  FP_mode,
	input  logic [7:0]  shared_exps0,
	input  logic [7:0]  shared_exps1,

	output logic [M_out_width-1:0] MAC_mant_out,
	output logic [7:0] MAC_exp_out,
	output logic MAC_sign_out
);

///////////////////////////////////////////////////////////
//Pipeline stages:
///////////////////////////////////////////////////////////
logic [7:0] a_mant0_q, a_mant1_q, a_mant2_q, a_mant3_q, b_mant0_q, b_mant1_q, b_mant2_q, b_mant3_q;
logic [9:0] a_exp_in0_q, a_exp_in1_q, a_exp_in2_q, a_exp_in3_q, b_exp_in0_q, b_exp_in1_q, b_exp_in2_q, b_exp_in3_q;
logic [3:0] a_sign_in0_q, a_sign_in1_q, a_sign_in2_q, a_sign_in3_q, b_sign_in0_q, b_sign_in1_q, b_sign_in2_q, b_sign_in3_q;
logic [1:0] prec_mode_q, FP_mode_q;
logic [7:0] shared_exps0_q, shared_exps1_q;


var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) a_mant0_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_mant0), .out(a_mant0_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) a_mant1_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_mant1), .out(a_mant1_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) a_mant2_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_mant2), .out(a_mant2_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) a_mant3_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_mant3), .out(a_mant3_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) b_mant0_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_mant0), .out(b_mant0_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) b_mant1_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_mant1), .out(b_mant1_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) b_mant2_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_mant2), .out(b_mant2_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) b_mant3_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_mant3), .out(b_mant3_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(10)) a_exp_in0_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_exp_in0), .out(a_exp_in0_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(10)) a_exp_in1_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_exp_in1), .out(a_exp_in1_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(10)) a_exp_in2_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_exp_in2), .out(a_exp_in2_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(10)) a_exp_in3_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_exp_in3), .out(a_exp_in3_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(10)) b_exp_in0_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_exp_in0), .out(b_exp_in0_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(10)) b_exp_in1_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_exp_in1), .out(b_exp_in1_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(10)) b_exp_in2_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_exp_in2), .out(b_exp_in2_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(10)) b_exp_in3_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_exp_in3), .out(b_exp_in3_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(4)) a_sign_in0_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_sign_in0), .out(a_sign_in0_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(4)) a_sign_in1_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_sign_in1), .out(a_sign_in1_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(4)) a_sign_in2_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_sign_in2), .out(a_sign_in2_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(4)) a_sign_in3_pipeline (.clk(clk_i), .rst_n(rstn), .in(a_sign_in3), .out(a_sign_in3_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(4)) b_sign_in0_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_sign_in0), .out(b_sign_in0_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(4)) b_sign_in1_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_sign_in1), .out(b_sign_in1_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(4)) b_sign_in2_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_sign_in2), .out(b_sign_in2_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(4)) b_sign_in3_pipeline (.clk(clk_i), .rst_n(rstn), .in(b_sign_in3), .out(b_sign_in3_q));

var_pipeline #(.STAGES(PL_STAGES), .WIDTH(2)) prec_mode_pipeline (.clk(clk_i), .rst_n(rstn), .in(prec_mode), .out(prec_mode_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(2)) FP_mode_pipeline (.clk(clk_i), .rst_n(rstn), .in(FP_mode), .out(FP_mode_q));

var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) shared_exps0_pipeline (.clk(clk_i), .rst_n(rstn), .in(shared_exps0), .out(shared_exps0_q));
var_pipeline #(.STAGES(PL_STAGES), .WIDTH(8)) shared_exps1_pipeline (.clk(clk_i), .rst_n(rstn), .in(shared_exps1), .out(shared_exps1_q));

///////////////////////////////////////////////////////////
logic [M_out_width-1:0] out_mant;
logic [7:0]  out_exp;
logic        out_sign;
logic [M_out_width-1:0] accum_mant;
logic [7:0]  accum_exp;
logic        accum_sign;
logic [1:0][7:0] shared_exps;
assign shared_exps[0] = shared_exps0_q;
assign shared_exps[1] = shared_exps1_q;
logic [M_out_width-1+9:0] accum_FP32;
assign accum_FP32 = {accum_sign, accum_exp, accum_mant};

ST_mul_hybrid #(.M_out_width(M_out_width)) ST_mul_EA_0 (.a_mant0(a_mant0_q), .a_mant1(a_mant1_q), .a_mant2(a_mant2_q), .a_mant3(a_mant3_q), .b_mant0(b_mant0_q), .b_mant1(b_mant1_q), .b_mant2(b_mant2_q), .b_mant3(b_mant3_q), 
.a_exp_in0(a_exp_in0_q), .a_exp_in1(a_exp_in1_q), .a_exp_in2(a_exp_in2_q), .a_exp_in3(a_exp_in3_q), .b_exp_in0(b_exp_in0_q), .b_exp_in1(b_exp_in1_q), .b_exp_in2(b_exp_in2_q), .b_exp_in3(b_exp_in3_q), 
.a_sign_in0(a_sign_in0_q), .a_sign_in1(a_sign_in1_q), .a_sign_in2(a_sign_in2_q), .a_sign_in3(a_sign_in3_q), .b_sign_in0(b_sign_in0_q), .b_sign_in1(b_sign_in1_q), .b_sign_in2(b_sign_in2_q), .b_sign_in3(b_sign_in3_q), 
.prec_mode(prec_mode_q), .FP_mode(FP_mode_q), .shared_exps(shared_exps), .accum_FP32(accum_FP32), .out_mant(out_mant), .out_exp(out_exp), .out_sign(out_sign));



/*
logic [22:0] output_mant;
logic [7:0] output_exp;
logic output_sign;

logic [7:0] new_out_exp;
FP_Add FP_Add0 (.accum_mant(accum_mant), .accum_exp(accum_exp), .accum_sign(accum_sign), .input_mant(out_mant), .input_exp(new_out_exp), .input_sign(out_sign), .output_mant(output_mant), .output_exp(output_exp), .output_sign(output_sign));
*/


assign MAC_mant_out = accum_mant;
assign MAC_exp_out = accum_exp;
assign MAC_sign_out = accum_sign;


register #(.M_out_width(M_out_width)) reg0 (.clk_i(clk_i), .rstn(rstn), .output_mant(out_mant), .output_exp(out_exp), .output_sign(out_sign), .accum_mant(accum_mant), .accum_exp(accum_exp), .accum_sign(accum_sign));


//sh_exp sh_exp0 (.shared_exps0(shared_exps0_q), .shared_exps1(shared_exps1_q), .out_exp(out_exp), .new_out_exp(new_out_exp));

endmodule



module register #(
	parameter M_out_width = {M_out_width}
)
(
	input logic clk_i,
	input logic rstn,
	input logic [M_out_width-1:0] output_mant,
	input logic [7:0] output_exp,
	input logic output_sign,

	output logic [M_out_width-1:0] accum_mant,
	output logic [7:0] accum_exp,
	output logic accum_sign
);
//Accumulation reg
always @(posedge clk_i or negedge rstn) begin
	if (~rstn) begin
		accum_mant <= '0; accum_exp <= '0; accum_sign <= '0;
	end else begin
		accum_mant <= output_mant; accum_exp <= output_exp; accum_sign <= output_sign;
	end

end

endmodule


module sh_exp (
	input  logic [7:0]  shared_exps0,
	input  logic [7:0]  shared_exps1,
	input  logic [7:0]  out_exp,
	output logic [7:0]  new_out_exp
);
logic [7:0] shared_exp_added;

assign shared_exp_added = shared_exps0 + shared_exps1 - 127;
assign new_out_exp = shared_exp_added + out_exp - 127;


endmodule

//-------------------------------------------------------------
// Variable pipeline
// STAGES : number of register stages (can be 0)
// WIDTH  : bit-width of the path
//-------------------------------------------------------------
module var_pipeline #(
    parameter int STAGES = 3,
    parameter int WIDTH  = 32
) (
    input  logic                     clk,
    input  logic                     rst_n,   // active-low reset
    input  logic [WIDTH-1:0]         in,
    output logic [WIDTH-1:0]         out
);

    // 2-D arrays hold the taps for every stage, including the input (index 0)
    logic [WIDTH-1:0] pipe [0:STAGES];


    // Stage 0 is just the inputs
    assign pipe[0] = in;

    // ---------------------------------------------------------
    // genvar loop builds STAGES sequential flops for each path
    // ---------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < STAGES; i++) begin : g_pipe
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipe[i+1] <= '0;
                end else begin
                    pipe[i+1] <= pipe[i];
                end
            end
        end
    endgenerate

    // Final taps become the module outputs
    assign out = pipe[STAGES];

endmodule
