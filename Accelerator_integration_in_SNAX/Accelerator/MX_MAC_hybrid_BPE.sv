module MX_MAC_hybrid_BPE #(
	parameter M_out_width = 16
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
	input  logic [7:0]  shared_exp_added,

	input  logic        A_valid,
	input  logic        B_valid,

	output logic [M_out_width-1:0] MAC_mant_out,
	output logic [7:0] MAC_exp_out,
	output logic MAC_sign_out
);


logic [M_out_width-1:0] out_mant;
logic [7:0]  out_exp;
logic        out_sign;
logic [M_out_width-1:0] accum_mant;
logic [7:0]  accum_exp;
logic        accum_sign;
logic [M_out_width-1+9:0] accum_FP32;
assign accum_FP32 = {accum_sign, accum_exp, accum_mant};

ST_mul_hybrid #(.M_out_width(M_out_width)) ST_mul_EA_0 (.a_mant0(a_mant0), .a_mant1(a_mant1), .a_mant2(a_mant2), .a_mant3(a_mant3), .b_mant0(b_mant0), .b_mant1(b_mant1), .b_mant2(b_mant2), .b_mant3(b_mant3), 
.a_exp_in0(a_exp_in0), .a_exp_in1(a_exp_in1), .a_exp_in2(a_exp_in2), .a_exp_in3(a_exp_in3), .b_exp_in0(b_exp_in0), .b_exp_in1(b_exp_in1), .b_exp_in2(b_exp_in2), .b_exp_in3(b_exp_in3), 
.a_sign_in0(a_sign_in0), .a_sign_in1(a_sign_in1), .a_sign_in2(a_sign_in2), .a_sign_in3(a_sign_in3), .b_sign_in0(b_sign_in0), .b_sign_in1(b_sign_in1), .b_sign_in2(b_sign_in2), .b_sign_in3(b_sign_in3), 
.prec_mode(prec_mode), .FP_mode(FP_mode), .shared_exp_added(shared_exp_added), .accum_FP32(accum_FP32), .out_mant(out_mant), .out_exp(out_exp), .out_sign(out_sign));


assign MAC_mant_out = accum_mant;
assign MAC_exp_out = accum_exp;
assign MAC_sign_out = accum_sign;

register #(.M_out_width(M_out_width)) reg0 (.clk_i(clk_i), .rstn(rstn), .output_mant(out_mant), .output_exp(out_exp), .output_sign(out_sign), .accum_mant(accum_mant), .accum_exp(accum_exp), .accum_sign(accum_sign), .A_valid(A_valid), .B_valid(B_valid));

endmodule


module register #(
	parameter M_out_width = 16
)
(
	input logic clk_i,
	input logic rstn,
	input logic [M_out_width-1:0] output_mant,
	input logic [7:0] output_exp,
	input logic output_sign,

	input logic A_valid,
	input logic B_valid,

	output logic [M_out_width-1:0] accum_mant,
	output logic [7:0] accum_exp,
	output logic accum_sign
);
//Accumulation reg
always @(posedge clk_i or negedge rstn) begin
	if (~rstn) begin
		accum_mant <= '0; accum_exp <= '0; accum_sign <= '0;
	end else if (A_valid & B_valid) begin
		accum_mant <= output_mant; accum_exp <= output_exp; accum_sign <= output_sign;
	end else begin
		accum_mant <= accum_mant; accum_exp <= accum_exp; accum_sign <= accum_sign;
	end
end

endmodule
