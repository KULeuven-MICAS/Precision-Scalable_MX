module ST_add_lvl2_v1_h #(
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
extend_v1 #(.M_out_width(M_out_width)) extend0_v1 (.mant0(mants[0]), .mant1(mants[1]), .mant2(mants[2]), .mant3(mants[3]), .sign0(sign0), .sign1(sign1), .sign2(sign2), .sign3(sign3), .prec_mode(prec_mode), .mant0_ext(mant0_ext), .mant1_ext(mant1_ext), .mant2_ext(mant2_ext), .mant3_ext(mant3_ext));

logic [7:0] big_exp;
logic [7:0] exp_diff0, exp_diff1, exp_diff2, exp_diff3;
high_exp_v1 #(.M_out_width(M_out_width)) high_exp0_v1 (.exp0_e(exp0), .exp1(exp1), .exp2(exp2), .exp3(exp3), .big_exp(big_exp), .exp_diff0(exp_diff0), .exp_diff1(exp_diff1), .exp_diff2(exp_diff2), .exp_diff3(exp_diff3));

logic [M_out_width+4:0] mant_to_normalize;
mant_add_v1 #(.M_out_width(M_out_width)) mant_add0_v1 (.mant0_ext(mant0_ext), .mant1_ext(mant1_ext), .mant2_ext(mant2_ext), .mant3_ext(mant3_ext), .exp_diff0(exp_diff0), .exp_diff1(exp_diff1), .exp_diff2(exp_diff2), .exp_diff3(exp_diff3), .mant_to_normalize(mant_to_normalize), .out_sign(out_sign),
.prec_mode(prec_mode), .sign0(sign0));

/*
reg [32:0] mant_to_normalize_reg;
reg [7:0] big_exp_reg;
reg [1:0] prec_mode_reg, FP_mode_reg;
always @(posedge clk_i, negedge rstn) begin
	if (~rstn) begin
		mant_to_normalize_reg <= '0; big_exp_reg <= '0; prec_mode_reg <= '0; FP_mode_reg <= '0;
	end else begin
		mant_to_normalize_reg <= mant_to_normalize; big_exp_reg <= big_exp; prec_mode_reg <= prec_mode; FP_mode_reg <= FP_mode;
	end
end
*/

logic [7:0] exp_fp32;
exp_bias_v1 #(.M_out_width(M_out_width)) exp_bias0_v1 (.big_exp(big_exp), .prec_mode(prec_mode), .FP_mode(FP_mode), .exp_fp32(exp_fp32));

logic [M_out_width-1:0] normalized_mant;
logic [7:0] output_exp;
normalize_v1 #(.M_out_width(M_out_width)) normalize0_v1 (.mant_to_normalize(mant_to_normalize), .exp_fp32(exp_fp32), .normalized_mant_out(normalized_mant), .output_exp(output_exp));


//Adjust exponent so in line with FP32
assign out_exp = output_exp; //temp
assign out_mant = normalized_mant;
endmodule


module extend_v1 #(
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

module high_exp_v1 #(
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


module mant_add_v1 #(
	parameter M_out_width = {M_out_width}
)
(
	input logic signed [M_out_width+2:0] mant0_ext,
	input logic signed [M_out_width+2:0] mant1_ext,
	input logic signed [M_out_width+2:0] mant2_ext,
	input logic signed [M_out_width+2:0] mant3_ext,
	input logic [7:0] exp_diff0, 
	input logic [7:0] exp_diff1,
	input logic [7:0] exp_diff2,
	input logic [7:0] exp_diff3,
	output logic [M_out_width+4:0] mant_to_normalize,
	output logic out_sign,
	input logic sign0,
	input logic [1:0] prec_mode
);

//Shift mantissas with difference and add together:
logic [M_out_width+4:0] added_mant; //2b extra for addition of 4 elements
logic signed [M_out_width+2:0] shifted_mant0, shifted_mant1, shifted_mant2, shifted_mant3;
assign shifted_mant0 = mant0_ext >>> exp_diff0;
assign shifted_mant1 = mant1_ext >>> exp_diff1;
assign shifted_mant2 = mant2_ext >>> exp_diff2;
assign shifted_mant3 = mant3_ext >>> exp_diff3;
//assign added_mant = (mant0_ext >>> exp_diff0) + (mant1_ext >>> exp_diff1) + (mant2_ext >>> exp_diff2) + (mant3_ext >>> exp_diff3);
assign added_mant = shifted_mant0 + shifted_mant1 + shifted_mant2 + shifted_mant3;
assign mant_to_normalize = (added_mant[M_out_width+4]) ? (-added_mant):added_mant;
assign out_sign = (prec_mode==2'b00) ? sign0:added_mant[M_out_width+4];

endmodule

module exp_bias_v1 #(
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
		exp_fp32 = big_exp + 135;
	end
	4'b0110: begin //E4M3xE4M3
		exp_fp32 = big_exp + 119;
	end
	4'b0101: begin //E3M2xE3M2
		exp_fp32 = big_exp + 129;
	end
	4'b0111: begin //E5M2xE5M2
		exp_fp32 = big_exp + 101;
	end
	4'b0100: begin //E2M3xE2M3
		exp_fp32 = big_exp + 127;
	end
	4'b11??: begin //E2M1xE2M1
		exp_fp32 = big_exp + 137;
	end
	default: begin
		exp_fp32 = big_exp + 127;
	end
endcase
end

endmodule

module normalize_v1 #(
	parameter M_out_width = {M_out_width}
)
(
	input logic [M_out_width+4:0] mant_to_normalize,
	input logic [7:0] exp_fp32,
	output logic [M_out_width-1:0] normalized_mant_out,
	output logic [7:0] output_exp
);
logic [M_out_width+4:0] normalized_mant;
assign normalized_mant_out = normalized_mant[M_out_width+4:5];

//Normalize
logic [$clog2(M_out_width+2)-1:0] leading_zeros;
always_comb begin
	leading_zeros = 0;
	for (int i=(M_out_width+4); i>=0; i--) begin
		if (mant_to_normalize[i]==1'b1) begin
			leading_zeros = (M_out_width+4)-i;
			break;
		end
	end
	
	normalized_mant = mant_to_normalize << (leading_zeros+1);
	output_exp = exp_fp32-leading_zeros;
end
/*
always_comb begin
casez(mant_to_normalize)
	    28'b1???????????????????????????: begin 
			normalized_mant = mant_to_normalize << 1;
			output_exp = exp_fp32;
	    end
	    28'b01??????????????????????????: begin 
			normalized_mant = mant_to_normalize << 2;
			output_exp = exp_fp32-1;
	    end
	    28'b001?????????????????????????: begin 
			normalized_mant = mant_to_normalize << 3;
			output_exp = exp_fp32-2;
	    end
	    28'b0001????????????????????????: begin 
			normalized_mant = mant_to_normalize << 4;
			output_exp = exp_fp32-3;
	    end
	    28'b00001???????????????????????: begin 
			normalized_mant = mant_to_normalize << 5;
			output_exp = exp_fp32-4;
	    end
	    28'b000001??????????????????????: begin 
			normalized_mant = mant_to_normalize << 6;
			output_exp = exp_fp32-5;
	    end
	    28'b0000001?????????????????????: begin 
			normalized_mant = mant_to_normalize << 7;
			output_exp = exp_fp32-6;
	    end
	    28'b00000001????????????????????: begin 
			normalized_mant = mant_to_normalize << 8;
			output_exp = exp_fp32-7;
	    end
	    28'b000000001???????????????????: begin 
			normalized_mant = mant_to_normalize << 9;
			output_exp = exp_fp32-8;
	    end
	    28'b0000000001??????????????????: begin 
			normalized_mant = mant_to_normalize << 10;
			output_exp = exp_fp32-9;
	    end
	    28'b00000000001?????????????????: begin 
			normalized_mant = mant_to_normalize << 11;
			output_exp = exp_fp32-10;
	    end
	    28'b000000000001????????????????: begin 
			normalized_mant = mant_to_normalize << 12;
			output_exp = exp_fp32-11;
	    end
	    28'b0000000000001???????????????: begin 
			normalized_mant = mant_to_normalize << 13;
			output_exp = exp_fp32-12;
	    end
	    28'b00000000000001??????????????: begin 
			normalized_mant = mant_to_normalize << 14;
			output_exp = exp_fp32-13;
	    end
	    28'b000000000000001?????????????: begin 
			normalized_mant = mant_to_normalize << 15;
			output_exp = exp_fp32-14;
	    end
	    28'b0000000000000001????????????: begin 
			normalized_mant = mant_to_normalize << 16;
			output_exp = exp_fp32-15;
	    end
	    28'b00000000000000001???????????: begin 
			normalized_mant = mant_to_normalize << 17;
			output_exp = exp_fp32-16;
	    end
	    28'b000000000000000001??????????: begin 
			normalized_mant = mant_to_normalize << 18;
			output_exp = exp_fp32-17;
	    end
	    28'b0000000000000000001?????????: begin 
			normalized_mant = mant_to_normalize << 19;
			output_exp = exp_fp32-18;
	    end
	    28'b00000000000000000001????????: begin 
			normalized_mant = mant_to_normalize << 20;
			output_exp = exp_fp32-19;
	    end
	    28'b000000000000000000001???????: begin 
			normalized_mant = mant_to_normalize << 21;
			output_exp = exp_fp32-20;
	    end
	    28'b0000000000000000000001??????: begin 
			normalized_mant = mant_to_normalize << 22;
			output_exp = exp_fp32-21;
	    end
	    28'b00000000000000000000001?????: begin 
			normalized_mant = mant_to_normalize << 23;
			output_exp = exp_fp32-22;
	    end
	    28'b000000000000000000000001????: begin 
			normalized_mant = mant_to_normalize << 24;
			output_exp = exp_fp32-23;
	    end
	    28'b0000000000000000000000001???: begin 
			normalized_mant = mant_to_normalize << 25;
			output_exp = exp_fp32-24;
	    end
	    28'b00000000000000000000000001??: begin 
			normalized_mant = mant_to_normalize << 26;
			output_exp = exp_fp32-25;
	    end
	    28'b000000000000000000000000001?: begin 
			normalized_mant = mant_to_normalize << 27;
			output_exp = exp_fp32-26;
	    end
	    default: begin
		normalized_mant = '0;
		output_exp = '0;
	    end
endcase
end*/

endmodule
