module L2_hybrid #(
	parameter M_out_width = {M_out_width}
)
(
	//INT8: inputs zijn 10 bit mantissas
	//FP8:  inputs zijn 10 bit mantissas met elk een exponent tot 6 bits lang (E5+E5)
	//FP4:  inputs zijn 10 bit mantissas met exponenten gelijk aan 0
	input  logic [9:0] mant0,
	input  logic [5:0]  exp0,
	input  logic        sign0,
	input  logic [9:0] mant1,
	input  logic [5:0]  exp1,
	input  logic        sign1,
	input  logic [9:0] mant2,
	input  logic [5:0]  exp2,
	input  logic        sign2,
	input  logic [9:0] mant3,
	input  logic [5:0]  exp3,
	input  logic        sign3,
	input  logic [1:0]  prec_mode,
	input  logic [1:0]  FP_mode,

	input  logic [M_out_width-1+9:0] accum_FP32,
	input  logic [1:0][7:0] shared_exps,

	output logic [M_out_width-1:0] out_mant,
	output logic [7:0]  out_exp,
	output logic        out_sign
);

logic [9:0] mants [0:3];
always_comb begin
if ((prec_mode == 2'b01) & (FP_mode == 2'b11)) begin
	mants[0] = mant0 << 4; mants[1] = mant1 << 4; mants[2] = mant2 << 4; mants[3] = mant3 << 4; 
end
else begin
	mants[0] = mant0; mants[1] = mant1; mants[2] = mant2; mants[3] = mant3; 
end
end

logic [M_out_width+2:0] mant0_ext, mant1_ext, mant2_ext, mant3_ext;
extend_v1_EA #(.M_out_width(M_out_width)) extend0 (.mant0(mants[0]), .mant1(mants[1]), .mant2(mants[2]), .mant3(mants[3]), .sign0(sign0), .sign1(sign1), .sign2(sign2), .sign3(sign3), .prec_mode(prec_mode), .mant0_ext(mant0_ext), .mant1_ext(mant1_ext), .mant2_ext(mant2_ext), .mant3_ext(mant3_ext));

logic [7:0] big_exp;
logic [7:0] exp_diff0, exp_diff1, exp_diff2, exp_diff3;
high_exp_v1_EA #(.M_out_width(M_out_width)) high_exp0 (.exp0_e(exp0), .exp1(exp1), .exp2(exp2), .exp3(exp3), .big_exp(big_exp), .exp_diff0(exp_diff0), .exp_diff1(exp_diff1), .exp_diff2(exp_diff2), .exp_diff3(exp_diff3));

logic signed [M_out_width+4:0] mant_to_FP_add;
logic sign_to_FP_add;
mant_add_v1_EA #(.M_out_width(M_out_width)) mant_add0 (.mant0_ext(mant0_ext), .mant1_ext(mant1_ext), .mant2_ext(mant2_ext), .mant3_ext(mant3_ext), .exp_diff0(exp_diff0), .exp_diff1(exp_diff1), .exp_diff2(exp_diff2), .exp_diff3(exp_diff3), .sign0(sign0), .prec_mode(prec_mode), .mant_to_FP_add(mant_to_FP_add), .sign_to_FP_add(sign_to_FP_add));


logic [7:0] exp_fp32;
exp_bias_v5_EA #(.M_out_width(M_out_width)) exp_bias0 (.big_exp(big_exp), .prec_mode(prec_mode), .FP_mode(FP_mode), .exp_fp32(exp_fp32));

logic [M_out_width+4+1+M_out_width+1:0] mant_to_normalize; //[52:0]
logic [7:0]  exp_to_normalize;
logic        sign_to_normalize;
logic        accum_is_out;
accum_add_EA #(.M_out_width(M_out_width)) accum_add_EA0 (.mant_in(mant_to_FP_add), .exp_in(exp_fp32), .sign_in(sign_to_FP_add), .mant_accum(accum_FP32[M_out_width-1:0]), .exp_accum(accum_FP32[M_out_width+7:M_out_width]), .sign_accum(accum_FP32[M_out_width+8]), 
.shared_exps(shared_exps), .mant_to_normalize(mant_to_normalize), .exp_to_normalize(exp_to_normalize), .sign_to_normalize(sign_to_normalize), .accum_is_out(accum_is_out));

logic [M_out_width-1:0] normalized_mant;
logic [7:0] output_exp;
normalize_v1_EA #(.M_out_width(M_out_width)) normalize0 (.mant_to_normalize(mant_to_normalize), .exp_to_normalize(exp_to_normalize), .normalized_mant_out(normalized_mant), .output_exp(output_exp));


//Adjust exponent so in line with FP32
assign out_exp = output_exp; //temp
assign out_mant = (accum_is_out) ? accum_FP32[M_out_width-1:0]:normalized_mant;
assign out_sign = sign_to_normalize;
endmodule


module extend_v1_EA #(
	parameter M_out_width = {M_out_width}
)
(
	input  logic [9:0] mant0,
	input  logic [9:0] mant1,
	input  logic [9:0] mant2,
	input  logic [9:0] mant3,
	input  logic sign0,
	input  logic sign1,
	input  logic sign2,
	input  logic sign3,
	input  logic [1:0] prec_mode,
	output logic [M_out_width+2:0] mant0_ext,
	output logic [M_out_width+2:0] mant1_ext,
	output logic [M_out_width+2:0] mant2_ext,
	output logic [M_out_width+2:0] mant3_ext
);
//Extend mantissas with 22 bits (so sure FP32 accuracy)
//Also shift if needed
//input mants are positive, sign comes from sign input
always_comb begin
if (prec_mode == 2'b00) begin
	mant0_ext = {1'b0,mant0, {(M_out_width-8){1'b0}}} >> 8;
	mant1_ext = {1'b0,mant1, {(M_out_width-8){1'b0}}} >> 4;
	mant2_ext = {1'b0,mant2, {(M_out_width-8){1'b0}}} >> 4;
	mant3_ext = {1'b0,mant3, {(M_out_width-8){1'b0}}};
end else begin
	mant0_ext = (sign0) ? (-({1'b0,mant0, {(M_out_width-8){1'b0}}})):({1'b0,mant0, {(M_out_width-8){1'b0}}});
	mant1_ext = (sign1) ? (-({1'b0,mant1, {(M_out_width-8){1'b0}}})):({1'b0,mant1, {(M_out_width-8){1'b0}}});
	mant2_ext = (sign2) ? (-({1'b0,mant2, {(M_out_width-8){1'b0}}})):({1'b0,mant2, {(M_out_width-8){1'b0}}});
	mant3_ext = (sign3) ? (-({1'b0,mant3, {(M_out_width-8){1'b0}}})):({1'b0,mant3, {(M_out_width-8){1'b0}}});
end
end
endmodule

module high_exp_v1_EA #(
	parameter M_out_width = {M_out_width}
)
(
	input logic [5:0] exp0_e,
	input logic [5:0] exp1,
	input logic [5:0] exp2,
	input logic [5:0] exp3,
	output logic [7:0] big_exp,
	output logic [7:0] exp_diff0,
	output logic [7:0] exp_diff1,
	output logic [7:0] exp_diff2,
	output logic [7:0] exp_diff3
);
//Find exponent difference with largest one
always_comb begin
if ((exp0_e >= exp1) & (exp0_e >= exp2) & (exp0_e >= exp3)) begin
	big_exp = exp0_e;
end else if ((exp1 >= exp0_e) & (exp1 >= exp2) & (exp1 >= exp3)) begin
	big_exp = exp1;
end else if ((exp2 >= exp0_e) & (exp2 >= exp1) & (exp2 >= exp3)) begin
	big_exp = exp2;
end else begin
	big_exp = exp3;
end

exp_diff0 = big_exp - exp0_e;
exp_diff1 = big_exp - exp1;
exp_diff2 = big_exp - exp2;
exp_diff3 = big_exp - exp3;
end
endmodule

/*
module mant_add_v5_EA (
	input logic [9:0] mant0,
	input logic [9:0] mant1,
	input logic [9:0] mant2,
	input logic [9:0] mant3,
	input logic       sign0,
	input logic       sign1,
	input logic       sign2,
	input logic       sign3,
	input logic [1:0] prec_mode,
	input logic signed [25:0] mant0_ext,
	input logic signed [25:0] mant1_ext,
	input logic signed [25:0] mant2_ext,
	input logic signed [25:0] mant3_ext,
	input logic signed [7:0] exp_diff0, 
	input logic signed [7:0] exp_diff1,
	input logic signed [7:0] exp_diff2,
	input logic signed [7:0] exp_diff3,
	output logic [27:0] mant_to_FP_add,
	output logic sign_to_FP_add
);

//Shift mantissas with difference and add together:

logic [27:0] added_mant; //1b extra for addition
logic signed [11:0] mant_signed [0:3];
logic signed [25:0] mant_sig_ext [0:3];

always_comb begin
	//Make negative for FP4
	mant_signed[0] = (sign0) ? -{2'b00,mant0}:{2'b00,mant0};
	mant_signed[1] = (sign1) ? -{2'b00,mant1}:{2'b00,mant1};
	mant_signed[2] = (sign2) ? -{2'b00,mant2}:{2'b00,mant2};
	mant_signed[3] = (sign3) ? -{2'b00,mant3}:{2'b00,mant3};
	

	mant_sig_ext[0] = ({8'd0,mant_signed[0],7'd0} << 8);
	mant_sig_ext[1] = ({8'd0,mant_signed[1],7'd0} << 4);
	mant_sig_ext[2] = ({8'd0,mant_signed[2],7'd0} << 4);
	mant_sig_ext[3] = {8'd0,mant_signed[3],7'd0};

	case(prec_mode)
		2'b00: begin //part of 0's may reduce the switching in the normalize module as needs to shift less to be normalized
			added_mant = mant_sig_ext[0] + mant_sig_ext[1] + mant_sig_ext[2] + mant_sig_ext[3]; //needs only 20 bits of adder (10+8(shifts) +2(adds))
		end
		2'b01: begin
			added_mant = (mant0_ext >>> exp_diff0) + (mant1_ext >>> exp_diff1) + (mant2_ext >>> exp_diff2) + (mant3_ext >>> exp_diff3);
		end
		2'b11: begin
			added_mant = {mant_signed[0],17'd0} + {mant_signed[3],17'd0}; //needs only 12 bits of adder
		end
		default: begin
			added_mant = '0;
		end
	endcase
end
//assign mant_to_normalize = (added_mant[27]) ? (-added_mant):added_mant;
assign mant_to_FP_add = added_mant;
assign sign_to_FP_add = (prec_mode==2'b00) ? sign0:added_mant[27];


endmodule*/

module mant_add_v1_EA #(
	parameter M_out_width = {M_out_width}
)
(
	input logic signed [M_out_width+2:0] mant0_ext,
	input logic signed [M_out_width+2:0] mant1_ext,
	input logic signed [M_out_width+2:0] mant2_ext,
	input logic signed [M_out_width+2:0] mant3_ext,
	input logic signed [7:0] exp_diff0, 
	input logic signed [7:0] exp_diff1,
	input logic signed [7:0] exp_diff2,
	input logic signed [7:0] exp_diff3,
	input logic sign0,
	input logic [1:0] prec_mode,
	output logic [M_out_width+4:0] mant_to_FP_add,
	output logic sign_to_FP_add
);

//Shift mantissas with difference and add together:

logic [M_out_width+4:0] added_mant; //2b extra for addition of 4 elements
logic signed [M_out_width+2:0] shifted_mant0, shifted_mant1, shifted_mant2, shifted_mant3;
assign shifted_mant0 = mant0_ext >>> exp_diff0;
assign shifted_mant1 = mant1_ext >>> exp_diff1;
assign shifted_mant2 = mant2_ext >>> exp_diff2;
assign shifted_mant3 = mant3_ext >>> exp_diff3;
//assign mant_to_normalize = (added_mant[27]) ? (-added_mant):added_mant;
assign added_mant = shifted_mant0 + shifted_mant1 + shifted_mant2 + shifted_mant3;
assign mant_to_FP_add = ((prec_mode==2'b00) & (sign0)) ? -added_mant:added_mant;
assign sign_to_FP_add = (prec_mode==2'b00) ? sign0:added_mant[M_out_width+4];
endmodule


module exp_bias_v5_EA #(
	parameter M_out_width = {M_out_width}
)
(
	input logic [7:0] big_exp,
	input logic [1:0] prec_mode,
	input logic [1:0] FP_mode,
	output logic [7:0] exp_fp32
);

always_comb begin
casez({prec_mode,FP_mode})
	4'b00??: begin //INT8xINT8
		exp_fp32 = 127-1+8;
	end
	4'b0110: begin //E4M3xE4M3
		exp_fp32 = big_exp + 119-1;
	end
	4'b0101: begin //E3M2xE3M2
		exp_fp32 = big_exp + 129-1;
	end
	4'b0111: begin //E5M2xE5M2
		exp_fp32 = big_exp + 101-1;
	end
	4'b0100: begin //E2M3xE2M3
		exp_fp32 = big_exp + 127-1;
	end
	4'b11??: begin //E2M1xE2M1
		exp_fp32 = 135-1+2;
	end
	default: begin
		exp_fp32 = 127;
	end
endcase
end

endmodule

module accum_add_EA #(
	parameter M_out_width = {M_out_width}
)
(
	input  logic signed [M_out_width+4:0] mant_in,
	input  logic [7:0]  exp_in,
	input  logic        sign_in,
	input  logic [M_out_width-1:0] mant_accum,
	input  logic [7:0]  exp_accum,
	input  logic        sign_accum,
	input  logic [1:0][7:0] shared_exps,
	output logic [M_out_width+4+1+M_out_width+1:0] mant_to_normalize,
	output logic [7:0]  exp_to_normalize,
	output logic        sign_to_normalize,
	output logic        accum_is_out
);


logic [7:0] exp_tot_in;
assign exp_tot_in = exp_in + (shared_exps[0] + shared_exps[1] - 127) - 127;

logic [M_out_width:0] mant_accum_full;
logic signed [M_out_width+4:0] mant_accum_2_comp;
assign mant_accum_full = (exp_accum == '0) ? {1'b0, mant_accum}:{1'b1, mant_accum};
assign mant_accum_2_comp = (sign_accum) ? -{1'b0, mant_accum_full, 3'd0}:{1'b0, mant_accum_full, 3'd0};

logic signed [M_out_width+4+1+M_out_width+1:0] mant_accum_ext;
logic signed [M_out_width+4+1+M_out_width+1:0] mant_in_ext;
logic signed [M_out_width+4+1+M_out_width+1:0] added_mants;

logic signed [8:0] exp_diff;
assign exp_diff = exp_accum - exp_tot_in;

localparam int signed MAX = M_out_width+1; //(24 from mantissa length of FP32 accurate addition and 4 from difference in . place between in and accum)
localparam int signed MIN = M_out_width+1+4 + M_out_width+2;

localparam int PADD = M_out_width+2;

logic signed [M_out_width+4+1+M_out_width+1:0] temp;

always_comb begin
  accum_is_out = 1'b0;
  mant_in_ext = '0;
  mant_accum_ext = '0;
  added_mants = '0;
  if ((~exp_diff[8]) & (exp_diff < MAX)) begin
    //place mant_in on right and shift mant_accum accordingly to exponent difference
    //Avoid shifting mant_in (variably)
    mant_in_ext = (sign_in) ? {{PADD{1'b1}}, mant_in}:{{PADD{1'b0}}, mant_in};
    mant_accum_ext = mant_accum_2_comp << exp_diff;

    added_mants = mant_in_ext + mant_accum_ext;
    mant_to_normalize = (added_mants[M_out_width+4+1+M_out_width+1]) ? -added_mants:added_mants;
    exp_to_normalize = exp_accum; //+25?
    sign_to_normalize = added_mants[M_out_width+4+1+M_out_width+1];
  end
  else if ((~exp_diff[8]) & (exp_diff >= MAX)) begin
    accum_is_out = 1'b1;
    mant_to_normalize = '0;
    exp_to_normalize = '0;
    sign_to_normalize = '0;
  end
  else if ((exp_diff[8]) & ((-exp_diff) < MIN)) begin
    //place mant_in on left and shift mant_accum accordingly to exponent difference
    mant_in_ext = {mant_in, {PADD{1'b0}}}; //extra bit for add
    temp = {mant_accum_2_comp, {PADD{1'b0}}};
    mant_accum_ext = temp >>> (-exp_diff); //works
    //mant_accum_ext = {mant_accum_2_comp, 25'd0} >>> (-exp_diff); //doesnt work ????
    
    added_mants = mant_in_ext + mant_accum_ext;
    mant_to_normalize = (added_mants[M_out_width+4+1+M_out_width+1]) ? -added_mants:added_mants;
    exp_to_normalize = exp_tot_in;
    sign_to_normalize = added_mants[M_out_width+4+1+M_out_width+1];
  end
  else begin //((exp_diff[8]) & (-exp_diff >= MIN))
    mant_to_normalize = (sign_in) ? ({-mant_in, {PADD{1'b0}}}):{mant_in, {PADD{1'b0}}};
    exp_to_normalize = exp_tot_in;
    sign_to_normalize = sign_in;
  end
end

endmodule


module normalize_v1_EA #(
	parameter M_out_width = {M_out_width}
)
(
	input logic [M_out_width+4+1+M_out_width+1:0] mant_to_normalize,
	input logic [7:0] exp_to_normalize,
	output logic [M_out_width-1:0] normalized_mant_out,
	output logic [7:0] output_exp
);
logic [M_out_width+4+1+M_out_width+1:0] normalized_mant;
assign normalized_mant_out = normalized_mant[M_out_width+4+1+M_out_width+1:M_out_width+4+1+M_out_width+1 - M_out_width + 1];

//Normalize
logic [$clog2(M_out_width+4+1+M_out_width+1 - 2)-1:0] leading_zeros;
always_comb begin
	leading_zeros = 0;
	for (int i=(M_out_width+4+1+M_out_width+1); i>=0; i--) begin
		if (mant_to_normalize[i]==1'b1) begin
			leading_zeros = (M_out_width+4+1+M_out_width+1)-i;
			break;
		end
	end
	
	normalized_mant = mant_to_normalize << (leading_zeros+1);
	output_exp = exp_to_normalize-leading_zeros+1;
end
endmodule

module normalize_v5_EA #(
	parameter M_out_width = {M_out_width}
)
(
	input logic [52:0] mant_to_normalize,
	input logic [7:0] exp_to_normalize,
	output logic [22:0] normalized_mant_out,
	output logic [7:0] output_exp
);
logic [52:0] normalized_mant;
assign normalized_mant_out = normalized_mant[52:30];
//Normalize
always_comb begin
casez(mant_to_normalize)
	    53'b1????????????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 1;
			output_exp = exp_to_normalize+1;
	    end
	    53'b01???????????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 2;
			output_exp = exp_to_normalize-1+1;
	    end
	    53'b001??????????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 3;
			output_exp = exp_to_normalize-2+1;
	    end
	    53'b0001?????????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 4;
			output_exp = exp_to_normalize-3+1;
	    end
	    53'b00001????????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 5;
			output_exp = exp_to_normalize-4+1;
	    end
	    53'b000001???????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 6;
			output_exp = exp_to_normalize-5+1;
	    end
	    53'b0000001??????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 7;
			output_exp = exp_to_normalize-6+1;
	    end
	    53'b00000001?????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 8;
			output_exp = exp_to_normalize-7+1;
	    end
	    53'b000000001????????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 9;
			output_exp = exp_to_normalize-8+1;
	    end
	    53'b0000000001???????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 10;
			output_exp = exp_to_normalize-9+1;
	    end
	    53'b00000000001??????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 11;
			output_exp = exp_to_normalize-10+1;
	    end
	    53'b000000000001?????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 12;
			output_exp = exp_to_normalize-11+1;
	    end
	    53'b0000000000001????????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 13;
			output_exp = exp_to_normalize-12+1;
	    end
	    53'b00000000000001???????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 14;
			output_exp = exp_to_normalize-13+1;
	    end
	    53'b000000000000001??????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 15;
			output_exp = exp_to_normalize-14+1;
	    end
	    53'b0000000000000001?????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 16;
			output_exp = exp_to_normalize-15+1;
	    end
	    53'b00000000000000001????????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 17;
			output_exp = exp_to_normalize-16+1;
	    end
	    53'b000000000000000001???????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 18;
			output_exp = exp_to_normalize-17+1;
	    end
	    53'b0000000000000000001??????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 19;
			output_exp = exp_to_normalize-18+1;
	    end
	    53'b00000000000000000001?????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 20;
			output_exp = exp_to_normalize-19+1;
	    end
	    53'b000000000000000000001????????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 21;
			output_exp = exp_to_normalize-20+1;
	    end
	    53'b0000000000000000000001???????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 22;
			output_exp = exp_to_normalize-21+1;
	    end
	    53'b00000000000000000000001??????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 23;
			output_exp = exp_to_normalize-22+1;
	    end
	    53'b000000000000000000000001?????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 24;
			output_exp = exp_to_normalize-23+1;
	    end
	    53'b0000000000000000000000001????????????????????????????: begin 
			normalized_mant = mant_to_normalize << 25;
			output_exp = exp_to_normalize-24+1;
	    end
	    53'b00000000000000000000000001???????????????????????????: begin 
			normalized_mant = mant_to_normalize << 26;
			output_exp = exp_to_normalize-25+1;
	    end
	    53'b000000000000000000000000001??????????????????????????: begin 
			normalized_mant = mant_to_normalize << 27;
			output_exp = exp_to_normalize-26+1;
	    end
	    53'b0000000000000000000000000001?????????????????????????: begin 
			normalized_mant = mant_to_normalize << 28;
			output_exp = exp_to_normalize-27+1;
	    end
	    53'b00000000000000000000000000001????????????????????????: begin 
			normalized_mant = mant_to_normalize << 29;
			output_exp = exp_to_normalize-28+1;
	    end
	    53'b000000000000000000000000000001???????????????????????: begin 
			normalized_mant = mant_to_normalize << 30;
			output_exp = exp_to_normalize-29+1;
	    end
	    53'b0000000000000000000000000000001??????????????????????: begin 
			normalized_mant = mant_to_normalize << 31;
			output_exp = exp_to_normalize-30+1;
	    end
	    53'b00000000000000000000000000000001?????????????????????: begin 
			normalized_mant = mant_to_normalize << 32;
			output_exp = exp_to_normalize-31+1;
	    end
	    53'b000000000000000000000000000000001????????????????????: begin 
			normalized_mant = mant_to_normalize << 33;
			output_exp = exp_to_normalize-32+1;
	    end
	    53'b0000000000000000000000000000000001???????????????????: begin 
			normalized_mant = mant_to_normalize << 34;
			output_exp = exp_to_normalize-33+1;
	    end
	    53'b00000000000000000000000000000000001??????????????????: begin 
			normalized_mant = mant_to_normalize << 35;
			output_exp = exp_to_normalize-34+1;
	    end
	    53'b000000000000000000000000000000000001?????????????????: begin 
			normalized_mant = mant_to_normalize << 36;
			output_exp = exp_to_normalize-35+1;
	    end
	    53'b0000000000000000000000000000000000001????????????????: begin 
			normalized_mant = mant_to_normalize << 37;
			output_exp = exp_to_normalize-36+1;
	    end
	    53'b00000000000000000000000000000000000001???????????????: begin 
			normalized_mant = mant_to_normalize << 38;
			output_exp = exp_to_normalize-37+1;
	    end
	    53'b000000000000000000000000000000000000001??????????????: begin 
			normalized_mant = mant_to_normalize << 39;
			output_exp = exp_to_normalize-38+1;
	    end
	    53'b0000000000000000000000000000000000000001?????????????: begin 
			normalized_mant = mant_to_normalize << 40;
			output_exp = exp_to_normalize-39+1;
	    end
	    53'b00000000000000000000000000000000000000001????????????: begin 
			normalized_mant = mant_to_normalize << 41;
			output_exp = exp_to_normalize-40+1;
	    end
	    53'b000000000000000000000000000000000000000001???????????: begin 
			normalized_mant = mant_to_normalize << 42;
			output_exp = exp_to_normalize-41+1;
	    end
	    53'b0000000000000000000000000000000000000000001??????????: begin 
			normalized_mant = mant_to_normalize << 43;
			output_exp = exp_to_normalize-42+1;
	    end
	    53'b00000000000000000000000000000000000000000001?????????: begin 
			normalized_mant = mant_to_normalize << 44;
			output_exp = exp_to_normalize-43+1;
	    end
	    53'b000000000000000000000000000000000000000000001???????: begin 
			normalized_mant = mant_to_normalize << 45;
			output_exp = exp_to_normalize-44+1;
	    end
	    53'b0000000000000000000000000000000000000000000001??????: begin 
			normalized_mant = mant_to_normalize << 46;
			output_exp = exp_to_normalize-45+1;
	    end
	    53'b00000000000000000000000000000000000000000000001?????: begin 
			normalized_mant = mant_to_normalize << 47;
			output_exp = exp_to_normalize-46+1;
	    end
	    53'b000000000000000000000000000000000000000000000001????: begin 
			normalized_mant = mant_to_normalize << 48;
			output_exp = exp_to_normalize-47+1;
	    end
	    53'b0000000000000000000000000000000000000000000000001???: begin 
			normalized_mant = mant_to_normalize << 49;
			output_exp = exp_to_normalize-48+1;
	    end
	    53'b00000000000000000000000000000000000000000000000001??: begin 
			normalized_mant = mant_to_normalize << 50;
			output_exp = exp_to_normalize-49+1;
	    end
	    53'b000000000000000000000000000000000000000000000000001?: begin 
			normalized_mant = mant_to_normalize << 51;
			output_exp = exp_to_normalize-50+1;
	    end
	    53'b0000000000000000000000000000000000000000000000000001: begin 
			normalized_mant = mant_to_normalize << 52;
			output_exp = exp_to_normalize-51+1;
	    end
	    default: begin
		normalized_mant = '0;
		output_exp = '0;
	    end
endcase
end

endmodule
