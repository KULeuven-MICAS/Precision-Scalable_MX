module Block_PE_wrapper #(
	parameter M_out_width = 16
)
(
	input  logic        clk_i,
	input  logic        rstn,

	// 1 W CSR for all this control signals
	//Control for MACs in Block_PE
	input  logic [1:0]  prec_mode,
	input  logic [1:0]  FP_mode,

	//Control for requantization in Block_PE
	input  logic        send_output,
	input  logic [1:0]  prec_mode_quan,
	input  logic [1:0]  FP_mode_quan,

	input  logic        A_valid,
	input  logic        B_valid,
	output  logic        A_ready,
	output  logic        B_ready,

	//Data in
	// 64bits
	input  logic [0:7][7:0] A_INT8, //8-bit Mantissa
	// 64bits
	input  logic [0:7][7:0] B_INT8,

	// 256bits
	input  logic [0:7][0:3][7:0] A_FP8, //Sign,Exponent,Mantissa
	// 256bits
	input  logic [0:7][0:3][7:0] B_FP8,

	// 192bits
	input  logic [0:7][0:3][5:0] A_FP6, //Sign,Exponent,Mantissa
	input  logic [0:7][0:3][5:0] B_FP6,

	// 256bits
	input  logic [0:7][0:7][3:0] A_FP4, //Sign,Exponent,Mantissa
	input  logic [0:7][0:7][3:0] B_FP4,

	// 8bits
	input  logic [7:0]      shared_exp_A,
	// 8bits
	input  logic [7:0]      shared_exp_B,

	//Data out
	output logic [0:7][0:7][7:0] Out, //Sign,Exponent,Mantissa,padding_zeros
	output logic [7:0]           shared_exp_out

);

//Ready for inputs if we are not reseting or sending outputs
assign A_ready = (~send_output); 
assign B_ready = (~send_output);

//inputs to Block_PE
logic [0:7][7:0] a_mant0, a_mant1, a_mant2, a_mant3;
logic [0:7][9:0] a_exp_in0 ,a_exp_in1, a_exp_in2, a_exp_in3;
logic [0:7][3:0] a_sign_in0, a_sign_in1, a_sign_in2, a_sign_in3;

logic [0:7][7:0] b_mant0, b_mant1, b_mant2, b_mant3;
logic [0:7][9:0] b_exp_in0 , b_exp_in1, b_exp_in2, b_exp_in3;
logic [0:7][3:0] b_sign_in0, b_sign_in1, b_sign_in2, b_sign_in3;

always_comb begin
for (int i=0; i<8;i++) begin
//Defaults:
a_mant0[i] = 'd0;
a_mant1[i] = 'd0;
a_mant2[i] = 'd0;
a_mant3[i] = 'd0;
b_mant0[i] = 'd0;
b_mant1[i] = 'd0;
b_mant2[i] = 'd0;
b_mant3[i] = 'd0;
a_exp_in0[i] = 'd0;
a_exp_in1[i] = 'd0;
a_exp_in2[i] = 'd0;
a_exp_in3[i] = 'd0;
b_exp_in0[i] = 'd0;
b_exp_in1[i] = 'd0;
b_exp_in2[i] = 'd0;
b_exp_in3[i] = 'd0;
a_sign_in0[i] = 'd0;
a_sign_in1[i] = 'd0;
a_sign_in2[i] = 'd0;
a_sign_in3[i] = 'd0;
b_sign_in0[i] = 'd0;
b_sign_in1[i] = 'd0;
b_sign_in2[i] = 'd0;
b_sign_in3[i] = 'd0;

//Wiring of inputs in different computing modes
casez ({prec_mode, FP_mode})
	4'b00??: begin //INT8xINT8
		a_mant0[i] = A_INT8[i];
		b_mant0[i] = B_INT8[i];
	end
	4'b0111: begin //FP8xFP8 (E5M2xE5M2)
		a_mant0[i] = {2'd0, A_FP8[i][0][1:0], 2'd0, A_FP8[i][1][1:0]};
		a_mant1[i] = {2'd0, A_FP8[i][2][1:0], 2'd0, A_FP8[i][3][1:0]};
		b_mant0[i] = {2'd0, B_FP8[i][3][1:0], 2'd0, B_FP8[i][1][1:0]};
		b_mant1[i] = {2'd0, B_FP8[i][2][1:0], 2'd0, B_FP8[i][0][1:0]};

		a_exp_in0[i] = {A_FP8[i][0][6:2], A_FP8[i][1][6:2]};
		a_exp_in1[i] = {A_FP8[i][2][6:2], A_FP8[i][3][6:2]};
		b_exp_in0[i] = {B_FP8[i][3][6:2], B_FP8[i][1][6:2]};
		b_exp_in1[i] = {B_FP8[i][2][6:2], B_FP8[i][0][6:2]};

		a_sign_in0[i] = {2'd0,A_FP8[i][0][7], A_FP8[i][1][7]};
		a_sign_in1[i] = {2'd0,A_FP8[i][2][7], A_FP8[i][3][7]};
		b_sign_in0[i] = {2'd0,B_FP8[i][3][7], B_FP8[i][1][7]};
		b_sign_in1[i] = {2'd0,B_FP8[i][2][7], B_FP8[i][0][7]};
	end
	4'b0110: begin //FP8xFP8 (E4M3xE4M3)
		a_mant0[i] = {1'd0, A_FP8[i][0][2:0], 1'd0, A_FP8[i][1][2:0]};
		a_mant1[i] = {1'd0, A_FP8[i][2][2:0], 1'd0, A_FP8[i][3][2:0]};
		b_mant0[i] = {1'd0, B_FP8[i][3][2:0], 1'd0, B_FP8[i][1][2:0]};
		b_mant1[i] = {1'd0, B_FP8[i][2][2:0], 1'd0, B_FP8[i][0][2:0]};

		a_exp_in0[i] = {1'd0, A_FP8[i][0][6:3], 1'd0, A_FP8[i][1][6:3]};
		a_exp_in1[i] = {1'd0, A_FP8[i][2][6:3], 1'd0, A_FP8[i][3][6:3]};
		b_exp_in0[i] = {1'd0, B_FP8[i][3][6:3], 1'd0, B_FP8[i][1][6:3]};
		b_exp_in1[i] = {1'd0, B_FP8[i][2][6:3], 1'd0, B_FP8[i][0][6:3]};

		a_sign_in0[i] = {2'd0, A_FP8[i][0][7], A_FP8[i][1][7]};
		a_sign_in1[i] = {2'd0, A_FP8[i][2][7], A_FP8[i][3][7]};
		b_sign_in0[i] = {2'd0, B_FP8[i][3][7], B_FP8[i][1][7]};
		b_sign_in1[i] = {2'd0, B_FP8[i][2][7], B_FP8[i][0][7]};
	end
	4'b0101: begin //FP6xFP6 (E3M2xE3M2)
		a_mant0[i] = {2'd0, A_FP6[i][0][1:0], 2'd0, A_FP6[i][1][1:0]};
		a_mant1[i] = {2'd0, A_FP6[i][2][1:0], 2'd0, A_FP6[i][3][1:0]};
		b_mant0[i] = {2'd0, B_FP6[i][3][1:0], 2'd0, B_FP6[i][1][1:0]};
		b_mant1[i] = {2'd0, B_FP6[i][2][1:0], 2'd0, B_FP6[i][0][1:0]};

		a_exp_in0[i] = {2'd0, A_FP6[i][0][4:2], 2'd0, A_FP6[i][1][4:2]};
		a_exp_in1[i] = {2'd0, A_FP6[i][2][4:2], 2'd0, A_FP6[i][3][4:2]};
		b_exp_in0[i] = {2'd0, B_FP6[i][3][4:2], 2'd0, B_FP6[i][1][4:2]};
		b_exp_in1[i] = {2'd0, B_FP6[i][2][4:2], 2'd0, B_FP6[i][0][4:2]};

		a_sign_in0[i] = {2'd0, A_FP6[i][0][5], A_FP6[i][1][5]};
		a_sign_in1[i] = {2'd0, A_FP6[i][2][5], A_FP6[i][3][5]};
		b_sign_in0[i] = {2'd0, B_FP6[i][3][5], B_FP6[i][1][5]};
		b_sign_in1[i] = {2'd0, B_FP6[i][2][5], B_FP6[i][0][5]};
	end
	4'b0100: begin //FP6xFP6 (E2M3xE2M3)
		a_mant0[i] = {1'd0, A_FP6[i][0][2:0], 1'd0, A_FP6[i][1][2:0]};
		a_mant1[i] = {1'd0, A_FP6[i][2][2:0], 1'd0, A_FP6[i][3][2:0]};
		b_mant0[i] = {1'd0, B_FP6[i][3][2:0], 1'd0, B_FP6[i][1][2:0]};
		b_mant1[i] = {1'd0, B_FP6[i][2][2:0], 1'd0, B_FP6[i][0][2:0]};

		a_exp_in0[i] = {3'd0, A_FP6[i][0][4:3], 3'd0, A_FP6[i][1][4:3]};
		a_exp_in1[i] = {3'd0, A_FP6[i][2][4:3], 3'd0, A_FP6[i][3][4:3]};
		b_exp_in0[i] = {3'd0, B_FP6[i][3][4:3], 3'd0, B_FP6[i][1][4:3]};
		b_exp_in1[i] = {3'd0, B_FP6[i][2][4:3], 3'd0, B_FP6[i][0][4:3]};

		a_sign_in0[i] = {2'd0, A_FP6[i][0][5], A_FP6[i][1][5]};
		a_sign_in1[i] = {2'd0, A_FP6[i][2][5], A_FP6[i][3][5]};
		b_sign_in0[i] = {2'd0, B_FP6[i][3][5], B_FP6[i][1][5]};
		b_sign_in1[i] = {2'd0, B_FP6[i][2][5], B_FP6[i][0][5]};
	end
	4'b11??: begin //FP4xFP4 (E2M1xE2M1)
		a_mant0[i] = {4'd0, 1'd0, A_FP4[i][2][0], 1'd0, A_FP4[i][0][0]};
		a_mant1[i] = {4'd0, 1'd0, A_FP4[i][3][0], 1'd0, A_FP4[i][1][0]};
		a_mant2[i] = {1'd0, A_FP4[i][6][0], 1'd0, A_FP4[i][4][0], 4'd0};
		a_mant3[i] = {1'd0, A_FP4[i][7][0], 1'd0, A_FP4[i][5][0], 4'd0};
		b_mant0[i] = {4'd0, 1'd0, B_FP4[i][1][0], 1'd0, B_FP4[i][0][0]};
		b_mant1[i] = {4'd0, 1'd0, B_FP4[i][3][0], 1'd0, B_FP4[i][2][0]};
		b_mant2[i] = {1'd0, B_FP4[i][5][0], 1'd0, B_FP4[i][4][0], 4'd0};
		b_mant3[i] = {1'd0, B_FP4[i][7][0], 1'd0, B_FP4[i][6][0], 4'd0};

		a_exp_in0[i] = {6'd0, A_FP4[i][2][2:1], A_FP4[i][0][2:1]};
		a_exp_in1[i] = {6'd0, A_FP4[i][3][2:1], A_FP4[i][1][2:1]};
		a_exp_in2[i] = {2'd0, A_FP4[i][6][2:1], A_FP4[i][4][2:1], 4'd0};
		a_exp_in3[i] = {2'd0, A_FP4[i][7][2:1], A_FP4[i][5][2:1], 4'd0};
		b_exp_in0[i] = {6'd0, B_FP4[i][1][2:1], B_FP4[i][0][2:1]};
		b_exp_in1[i] = {6'd0, B_FP4[i][3][2:1], B_FP4[i][2][2:1]};
		b_exp_in2[i] = {2'd0, B_FP4[i][5][2:1], B_FP4[i][4][2:1], 4'd0};
		b_exp_in3[i] = {2'd0, B_FP4[i][7][2:1], B_FP4[i][6][2:1], 4'd0};

		a_sign_in0[i] = {2'd0, A_FP4[i][2][3], A_FP4[i][0][3]};
		a_sign_in1[i] = {2'd0, A_FP4[i][3][3], A_FP4[i][1][3]};
		a_sign_in2[i] = {A_FP4[i][6][3], A_FP4[i][4][3], 2'd0};
		a_sign_in3[i] = {A_FP4[i][7][3], A_FP4[i][5][3], 2'd0};
		b_sign_in0[i] = {2'd0, B_FP4[i][1][3], B_FP4[i][0][3]};
		b_sign_in1[i] = {2'd0, B_FP4[i][3][3], B_FP4[i][2][3]};
		b_sign_in2[i] = {B_FP4[i][5][3], B_FP4[i][4][3], 2'd0};
		b_sign_in3[i] = {B_FP4[i][7][3], B_FP4[i][6][3], 2'd0};
	end
endcase
end
end

Block_PE #(.M_out_width(M_out_width)) Block_PE0(.clk_i(clk_i), .rstn(rstn), 
.a_mant0(a_mant0), .a_mant1(a_mant1), .a_mant2(a_mant2), .a_mant3(a_mant3), 
.b_mant0(b_mant0), .b_mant1(b_mant1), .b_mant2(b_mant2), .b_mant3(b_mant3), 
.a_exp_in0(a_exp_in0), .a_exp_in1(a_exp_in1), .a_exp_in2(a_exp_in2), .a_exp_in3(a_exp_in3), 
.b_exp_in0(b_exp_in0), .b_exp_in1(b_exp_in1), .b_exp_in2(b_exp_in2), .b_exp_in3(b_exp_in3), 
.a_sign_in0(a_sign_in0), .a_sign_in1(a_sign_in1), .a_sign_in2(a_sign_in2), .a_sign_in3(a_sign_in3), 
.b_sign_in0(b_sign_in0), .b_sign_in1(b_sign_in1), .b_sign_in2(b_sign_in2), .b_sign_in3(b_sign_in3),
.prec_mode(prec_mode), .FP_mode(FP_mode), .prec_mode_quan(prec_mode_quan), .FP_mode_quan(FP_mode_quan),
.send_output(send_output), .shared_exp0(shared_exp_A), .shared_exp1(shared_exp_B), .quantized_outputs(Out), .shared_exp_out(shared_exp_out),
.A_valid(A_valid), .B_valid(B_valid)
);

endmodule
