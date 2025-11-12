module MX_MAC #(
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

logic [M_out_width-1:0] out_mant;
logic [7:0]  out_exp;
logic        out_sign;

ST_mul #(.M_out_width(M_out_width)) ST_mul0 (.a_mant0(a_mant0), .a_mant1(a_mant1), .a_mant2(a_mant2), .a_mant3(a_mant3), .b_mant0(b_mant0), .b_mant1(b_mant1), .b_mant2(b_mant2), .b_mant3(b_mant3), 
.a_exp_in0(a_exp_in0), .a_exp_in1(a_exp_in1), .a_exp_in2(a_exp_in2), .a_exp_in3(a_exp_in3), .b_exp_in0(b_exp_in0), .b_exp_in1(b_exp_in1), .b_exp_in2(b_exp_in2), .b_exp_in3(b_exp_in3), 
.a_sign_in0(a_sign_in0), .a_sign_in1(a_sign_in1), .a_sign_in2(a_sign_in2), .a_sign_in3(a_sign_in3), .b_sign_in0(b_sign_in0), .b_sign_in1(b_sign_in1), .b_sign_in2(b_sign_in2), .b_sign_in3(b_sign_in3), 
.prec_mode(prec_mode), .FP_mode(FP_mode), .out_mant(out_mant), .out_exp(out_exp), .out_sign(out_sign));




logic [M_out_width-1:0] output_mant;
logic [7:0] output_exp;
logic output_sign;
logic [M_out_width-1:0] accum_mant;
logic [7:0]  accum_exp;
logic        accum_sign;
logic [7:0] new_out_exp;
FP_Add #(.M_out_width(M_out_width)) FP_Add0 (.accum_mant(accum_mant), .accum_exp(accum_exp), .accum_sign(accum_sign), .input_mant(out_mant), .input_exp(new_out_exp), .input_sign(out_sign), .output_mant(output_mant), .output_exp(output_exp), .output_sign(output_sign));



assign MAC_mant_out = accum_mant;
assign MAC_exp_out = accum_exp;
assign MAC_sign_out = accum_sign;


register #(.M_out_width(M_out_width)) reg0 (.clk_i(clk_i), .rstn(rstn), .output_mant(output_mant), .output_exp(output_exp), .output_sign(output_sign), .accum_mant(accum_mant), .accum_exp(accum_exp), .accum_sign(accum_sign));

sh_exp sh_exp0 (.shared_exps0(shared_exps0), .shared_exps1(shared_exps1), .out_exp(out_exp), .new_out_exp(new_out_exp));
endmodule



module register #(
	parameter M_out_width = 23
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


