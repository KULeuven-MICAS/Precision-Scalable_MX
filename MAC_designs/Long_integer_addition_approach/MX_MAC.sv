module MX_MAC #(
	parameter fp4_impr = 1,
	parameter PL_STAGES = 0
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

	input  fpnew_pkg::roundmode_e rnd_mode_i,
	input  fpnew_pkg::fp_format_e dst_fmt_i,

	output logic [22:0] MAC_mant_out,
	output logic [7:0] MAC_exp_out,
	output logic MAC_sign_out
);

logic [22:0] out_mant;
logic [7:0]  out_exp;
logic        out_sign;
logic [22:0] accum_mant;
logic [7:0]  accum_exp;
logic        accum_sign;
logic [1:0][7:0] shared_exps;
assign shared_exps[0] = shared_exps0;
assign shared_exps[1] = shared_exps1;

generate
if (fp4_impr) begin
ST_mul_pipelined #(.PL_STAGES(PL_STAGES)) ST_mul_pipelined0 (.clk_i(clk_i), .rstn(rstn), .a_mant0(a_mant0), .a_mant1(a_mant1), .a_mant2(a_mant2), .a_mant3(a_mant3), .b_mant0(b_mant0), .b_mant1(b_mant1), .b_mant2(b_mant2), .b_mant3(b_mant3), 
.a_exp_in0(a_exp_in0), .a_exp_in1(a_exp_in1), .a_exp_in2(a_exp_in2), .a_exp_in3(a_exp_in3), .b_exp_in0(b_exp_in0), .b_exp_in1(b_exp_in1), .b_exp_in2(b_exp_in2), .b_exp_in3(b_exp_in3), 
.a_sign_in0(a_sign_in0), .a_sign_in1(a_sign_in1), .a_sign_in2(a_sign_in2), .a_sign_in3(a_sign_in3), .b_sign_in0(b_sign_in0), .b_sign_in1(b_sign_in1), .b_sign_in2(b_sign_in2), .b_sign_in3(b_sign_in3), 
.prec_mode(prec_mode), .FP_mode(FP_mode), .out_mant(out_mant), .out_exp(out_exp), .out_sign(out_sign), .shared_exps(shared_exps), .operand_d_i({accum_sign, accum_exp, accum_mant}), .rnd_mode_i(rnd_mode_i), .dst_fmt_i(dst_fmt_i));
end
else begin
ST_mul ST_mul0 (.clk_i(clk_i), .rstn(rstn), .a_mant0(a_mant0), .a_mant1(a_mant1), .a_mant2(a_mant2), .a_mant3(a_mant3), .b_mant0(b_mant0), .b_mant1(b_mant1), .b_mant2(b_mant2), .b_mant3(b_mant3), 
.a_exp_in0(a_exp_in0), .a_exp_in1(a_exp_in1), .a_exp_in2(a_exp_in2), .a_exp_in3(a_exp_in3), .b_exp_in0(b_exp_in0), .b_exp_in1(b_exp_in1), .b_exp_in2(b_exp_in2), .b_exp_in3(b_exp_in3), 
.a_sign_in0(a_sign_in0), .a_sign_in1(a_sign_in1), .a_sign_in2(a_sign_in2), .a_sign_in3(a_sign_in3), .b_sign_in0(b_sign_in0), .b_sign_in1(b_sign_in1), .b_sign_in2(b_sign_in2), .b_sign_in3(b_sign_in3), 
.prec_mode(prec_mode), .FP_mode(FP_mode), .out_mant(out_mant), .out_exp(out_exp), .out_sign(out_sign), .shared_exps(shared_exps), .operand_d_i({accum_sign, accum_exp, accum_mant}), .rnd_mode_i(rnd_mode_i), .dst_fmt_i(dst_fmt_i));
end
endgenerate

assign MAC_mant_out = accum_mant;
assign MAC_exp_out = accum_exp;
assign MAC_sign_out = accum_sign;


register reg0 (.clk_i(clk_i), .rstn(rstn), .output_mant(out_mant), .output_exp(out_exp), .output_sign(out_sign), .accum_mant(accum_mant), .accum_exp(accum_exp), .accum_sign(accum_sign));



endmodule



module register (
	input logic clk_i,
	input logic rstn,
	input logic [22:0] output_mant,
	input logic [7:0] output_exp,
	input logic output_sign,

	output logic [22:0] accum_mant,
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

