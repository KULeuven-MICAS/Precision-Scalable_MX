module ST_add_lvl1 (
	input logic [3:0] mant0,
	input logic [5:0] exp0,
	input logic sign0,
	input logic [3:0] mant1,
	input logic [5:0] exp1,
	input logic sign1,
	input logic [3:0] mant2,
	input logic [5:0] exp2,
	input logic sign2,
	input logic [3:0] mant3,
	input logic [5:0] exp3,
	input logic sign3,
	input logic [1:0] prec_mode,
	output logic [9:0] added_mant, //4+6(exp diff, E2+E2)+2(adding 4 together)+2(shifts for asymmetric muls)
	output logic [5:0] added_exp, //biggest exponent as result is not normalized here
	output logic added_sign
);

//Either mants are part of same mul then add normaly with shifts
//Or shift mants by exponent and add/subtract

logic [10:0] added_mant_signed;
logic signed [8:0] mant0_signed_shifted;
logic signed [8:0] mant1_signed_shifted;
logic signed [8:0] mant2_signed_shifted;
logic signed [8:0] mant3_signed_shifted;

logic [2:0] exp_shift [0:3];
assign exp_shift[0] = exp0[2:0]-2;
assign exp_shift[1] = exp1[2:0]-2;
assign exp_shift[2] = exp2[2:0]-2;
assign exp_shift[3] = exp3[2:0]-2; //exp shift is 0,1,2,3,4 as exponent is between 2 and 6 for FP4

logic [4:0] mant_shift [0:3];
assign mant_shift[0] = {1'b0,mant0};
assign mant_shift[1] = {1'b0,mant1};
assign mant_shift[2] = {1'b0,mant2};
assign mant_shift[3] = {1'b0,mant3};



always_comb begin
if (prec_mode == 2'b11) begin //need to shift mants
	mant0_signed_shifted = (sign0) ? (-(mant_shift[0] << exp_shift[0])):(mant_shift[0] << exp_shift[0]);
	mant1_signed_shifted = (sign1) ? (-(mant_shift[1] << exp_shift[1])):(mant_shift[1] << exp_shift[1]);
	mant2_signed_shifted = (sign2) ? (-(mant_shift[2] << exp_shift[2])):(mant_shift[2] << exp_shift[2]);
	mant3_signed_shifted = (sign3) ? (-(mant_shift[3] << exp_shift[3])):(mant_shift[3] << exp_shift[3]);

	added_mant_signed = mant0_signed_shifted + mant1_signed_shifted + mant2_signed_shifted + mant3_signed_shifted;
	
	added_mant = (added_mant_signed[10]) ? (-added_mant_signed):(added_mant_signed);
	added_sign = added_mant_signed[10];

	//added_exp:
	added_exp = '0; //because we shift all by exponent so value inside of mant

end else begin //normal for INT8 and FP8 (max 10 bits)
	added_mant = mant0 + (mant1 << 2) + (mant2 << 2) + (mant3 << 4);
	added_exp  = exp0;
	added_sign = sign0; //all have same exp and sign in this situation
end
end
endmodule
