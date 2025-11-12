module ST_mul #(
  parameter M_out_width = {M_out_width}
)
//Only symmetrical, FP4 is undertutilized by /2
(
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
  input  logic [1:0]  FP_mode, //if 4-bit precision mode: which type is our input; E5M2=11,E4M3=10,E3M2=01,E2M3=00
  output logic [M_out_width-1:0] out_mant,
  output logic [7:0]  out_exp,
  output logic        out_sign
);

logic [1:0] a [0:3][0:3];
logic [1:0] b [0:3][0:3];
logic [4:0] a_exp [0:3][0:3];
logic [4:0] b_exp [0:3][0:3];
logic a_sign [0:3][0:3];
logic b_sign [0:3][0:3];
preprocessing preprocessing0 (.a_mant0(a_mant0), .a_mant1(a_mant1), .a_mant2(a_mant2), .a_mant3(a_mant3), .b_mant0(b_mant0), .b_mant1(b_mant1), .b_mant2(b_mant2), .b_mant3(b_mant3), .a_exp_in0(a_exp_in0), .a_exp_in1(a_exp_in1), 
.a_exp_in2(a_exp_in2), .a_exp_in3(a_exp_in3), .b_exp_in0(b_exp_in0), .b_exp_in1(b_exp_in1), .b_exp_in2(b_exp_in2), .b_exp_in3(b_exp_in3), .a_sign_in0(a_sign_in0), .a_sign_in1(a_sign_in1), .a_sign_in2(a_sign_in2), .a_sign_in3(a_sign_in3), 
.b_sign_in0(b_sign_in0), .b_sign_in1(b_sign_in1), .b_sign_in2(b_sign_in2), .b_sign_in3(b_sign_in3), .prec_mode(prec_mode), .FP_mode(FP_mode), .a(a), .b(b), .a_exp(a_exp), .b_exp(b_exp), .a_sign(a_sign), .b_sign(b_sign));

logic [3:0] m00_o, m01_o, m02_o, m03_o, m10_o, m11_o, m12_o, m13_o, m20_o, m21_o, m22_o, m23_o, m30_o, m31_o, m32_o, m33_o; 
logic [5:0] exp_interm [0:3][0:3];
logic       sign_interm [0:3][0:3];
multiplication multiplication0 (.a(a), .b(b), .m00_o(m00_o), .m01_o(m01_o), .m02_o(m02_o), .m03_o(m03_o), .m10_o(m10_o), .m11_o(m11_o), .m12_o(m12_o), .m13_o(m13_o), .m20_o(m20_o), .m21_o(m21_o), .m22_o(m22_o), .m23_o(m23_o), .m30_o(m30_o), .m31_o(m31_o), .m32_o(m32_o), .m33_o(m33_o), .a_exp(a_exp), .b_exp(b_exp), .a_sign(a_sign), .b_sign(b_sign), .exp_interm(exp_interm), .sign_interm(sign_interm));

logic [9:0] added_mant0, added_mant1, added_mant2, added_mant3;
logic [5:0] added_exp0, added_exp1, added_exp2, added_exp3;
logic added_sign0, added_sign1, added_sign2, added_sign3;
lvl1_adders lvl1_adders0 (.m00_o(m00_o), .m01_o(m01_o), .m02_o(m02_o), .m03_o(m03_o), .m10_o(m10_o), .m11_o(m11_o), .m12_o(m12_o), .m13_o(m13_o), .m20_o(m20_o), .m21_o(m21_o), .m22_o(m22_o), .m23_o(m23_o), .m30_o(m30_o), .m31_o(m31_o), .m32_o(m32_o), .m33_o(m33_o), .exp_interm(exp_interm), .sign_interm(sign_interm), .prec_mode(prec_mode), 
.added_mant0(added_mant0), .added_mant1(added_mant1), .added_mant2(added_mant2), .added_mant3(added_mant3), .added_exp0(added_exp0), .added_exp1(added_exp1), .added_exp2(added_exp2), .added_exp3(added_exp3), .added_sign0(added_sign0), .added_sign1(added_sign1), .added_sign2(added_sign2), .added_sign3(added_sign3));


/////
reg [9:0] added_mant0_reg, added_mant1_reg, added_mant2_reg, added_mant3_reg;
reg [5:0] added_exp0_reg, added_exp1_reg, added_exp2_reg, added_exp3_reg;
reg added_sign0_reg, added_sign1_reg, added_sign2_reg, added_sign3_reg;
reg [1:0] prec_mode_reg, FP_mode_reg;


ST_add_lvl2_v1_h #(.M_out_width(M_out_width)) ST_add_lvl2_v1_0 (.mant0(added_mant0), .exp0(added_exp0), .sign0(added_sign0), .mant1(added_mant1), .exp1(added_exp1), .sign1(added_sign1), .mant2(added_mant2), .exp2(added_exp2), .sign2(added_sign2), .mant3(added_mant3), .exp3(added_exp3), .sign3(added_sign3), .prec_mode(prec_mode), .FP_mode(FP_mode), .out_mant(out_mant), .out_exp(out_exp), .out_sign(out_sign));
//extend with 23 bits instead of normalizing 4 mants then can shift with diff_exp without M23 accuracy or more
// !!! should test vs normalize up front approach at low freq to see which is best!!!
endmodule


module preprocessing (
	input logic [7:0] a_mant0,
	input logic [7:0] a_mant1,
	input logic [7:0] a_mant2,
	input logic [7:0] a_mant3,
	input logic [7:0] b_mant0,
	input logic [7:0] b_mant1,
	input logic [7:0] b_mant2,
	input logic [7:0] b_mant3,
	input logic [9:0] a_exp_in0,
	input logic [9:0] a_exp_in1,
	input logic [9:0] a_exp_in2,
	input logic [9:0] a_exp_in3,
	input logic [9:0] b_exp_in0,
	input logic [9:0] b_exp_in1,
	input logic [9:0] b_exp_in2,
	input logic [9:0] b_exp_in3,
	input logic [3:0] a_sign_in0,
	input logic [3:0] a_sign_in1,
	input logic [3:0] a_sign_in2,
	input logic [3:0] a_sign_in3,
	input logic [3:0] b_sign_in0,
	input logic [3:0] b_sign_in1,
	input logic [3:0] b_sign_in2,
	input logic [3:0] b_sign_in3,
	input logic [1:0] prec_mode,
	input logic [1:0] FP_mode,
	output logic [1:0] a [0:3][0:3],
	output logic [1:0] b [0:3][0:3],
	output logic [4:0] a_exp [0:3][0:3],
	output logic [4:0] b_exp [0:3][0:3],
	output logic a_sign [0:3][0:3],
	output logic b_sign [0:3][0:3]
);		
//Right values sent to multipliers:
//INT8 needs to be converted from 2's complement to sign and positive value for multiplication
//FP needs to have the implicit 1 bit explicitly applied
logic [7:0] a_mant [0:3];
assign a_mant[0] = a_mant0; assign a_mant[1] = a_mant1; assign a_mant[2] = a_mant2; assign a_mant[3] = a_mant3;
logic [7:0] b_mant [0:3];
assign b_mant[0] = b_mant0; assign b_mant[1] = b_mant1; assign b_mant[2] = b_mant2; assign b_mant[3] = b_mant3;
logic [9:0]  a_exp_in [0:3];
assign a_exp_in[0] = a_exp_in0; assign a_exp_in[1] = a_exp_in1; assign a_exp_in[2] = a_exp_in2; assign a_exp_in[3] = a_exp_in3; 
logic [9:0]  b_exp_in [0:3];
assign b_exp_in[0] = b_exp_in0; assign b_exp_in[1] = b_exp_in1; assign b_exp_in[2] = b_exp_in2; assign b_exp_in[3] = b_exp_in3; 
logic [3:0]  a_sign_in [0:3];
assign a_sign_in[0] = a_sign_in0; assign a_sign_in[1] = a_sign_in1; assign a_sign_in[2] = a_sign_in2; assign a_sign_in[3] = a_sign_in3; 
logic [3:0]  b_sign_in [0:3];
assign b_sign_in[0] = b_sign_in0; assign b_sign_in[1] = b_sign_in1; assign b_sign_in[2] = b_sign_in2; assign b_sign_in[3] = b_sign_in3;
/////

logic [7:0]  a_mant_ [0:3];
logic [7:0]  b_mant_ [0:3];
logic [9:0]  a_exp_in_ [0:3];
logic [9:0]  b_exp_in_ [0:3];
logic [3:0]  a_sign_in_ [0:3];
logic [3:0]  b_sign_in_ [0:3];

//Utilization
always_comb begin
  case (prec_mode)
    2'b00: begin //INT8
	a_mant_ = a_mant;
	b_mant_ = b_mant;
	a_exp_in_ = a_exp_in;
	b_exp_in_ = b_exp_in;
	a_sign_in_ = a_sign_in;
	b_sign_in_ = b_sign_in;
    end
    2'b01: begin //FP8
	a_mant_ = a_mant;
	b_mant_ = b_mant;
	a_exp_in_ = a_exp_in;
	b_exp_in_ = b_exp_in;
	a_sign_in_ = a_sign_in;
	b_sign_in_ = b_sign_in;
    end
    2'b11: begin //FP4 with U/2
	a_mant_[0] = {4'd0,a_mant[0][3:0]}; a_exp_in_[0] = {6'd0,a_exp_in[0][3:0]}; a_sign_in_[0] = a_sign_in[0];
	a_mant_[1] = {4'd0,a_mant[1][3:0]}; a_exp_in_[1] = {6'd0,a_exp_in[1][3:0]}; a_sign_in_[1] = a_sign_in[1];
	a_mant_[2] = {a_mant[2][7:4],4'd0}; a_exp_in_[2] = {a_exp_in[2][9:4],4'd0}; a_sign_in_[2] = a_sign_in[2];
	a_mant_[3] = {a_mant[3][7:4],4'd0}; a_exp_in_[3] = {a_exp_in[3][9:4],4'd0}; a_sign_in_[3] = a_sign_in[3];
	b_mant_[0] = {4'd0,b_mant[0][3:0]}; b_exp_in_[0] = {6'd0,b_exp_in[0][3:0]}; b_sign_in_[0] = b_sign_in[0];
	b_mant_[1] = {4'd0,b_mant[1][3:0]}; b_exp_in_[1] = {6'd0,b_exp_in[1][3:0]}; b_sign_in_[1] = b_sign_in[1];
	b_mant_[2] = {b_mant[2][7:4],4'd0}; b_exp_in_[2] = {b_exp_in[2][9:4],4'd0}; b_sign_in_[2] = b_sign_in[2];
	b_mant_[3] = {b_mant[3][7:4],4'd0}; b_exp_in_[3] = {b_exp_in[3][9:4],4'd0}; b_sign_in_[3] = b_sign_in[3];
    end
    default: begin
	a_mant_[0] = '0; a_exp_in_[0] = '0; a_sign_in_[0] = '0;
	a_mant_[1] = '0; a_exp_in_[1] = '0; a_sign_in_[1] = '0;
	a_mant_[2] = '0; a_exp_in_[2] = '0; a_sign_in_[2] = '0;
	a_mant_[3] = '0; a_exp_in_[3] = '0; a_sign_in_[3] = '0;
	b_mant_[0] = '0; b_exp_in_[0] = '0; b_sign_in_[0] = '0;
	b_mant_[1] = '0; b_exp_in_[1] = '0; b_sign_in_[1] = '0;
	b_mant_[2] = '0; b_exp_in_[2] = '0; b_sign_in_[2] = '0;
	b_mant_[3] = '0; b_exp_in_[3] = '0; b_sign_in_[3] = '0;
    end
  endcase
end

////////

integer i,j;
always_comb begin
	if (prec_mode == 2'b00) begin //INT8
		{a[0][3],a[0][2],a[0][1],a[0][0]} = (a_mant_[0][7]) ? (~a_mant_[0])+1:a_mant_[0];
		{a[1][3],a[1][2],a[1][1],a[1][0]} = (a_mant_[0][7]) ? (~a_mant_[0])+1:a_mant_[0];
		{a[2][3],a[2][2],a[2][1],a[2][0]} = (a_mant_[0][7]) ? (~a_mant_[0])+1:a_mant_[0];
		{a[3][3],a[3][2],a[3][1],a[3][0]} = (a_mant_[0][7]) ? (~a_mant_[0])+1:a_mant_[0];
		{b[0][3],b[0][2],b[0][1],b[0][0]} = (b_mant_[0][7]) ? (~b_mant_[0])+1:b_mant_[0];
		{b[1][3],b[1][2],b[1][1],b[1][0]} = (b_mant_[0][7]) ? (~b_mant_[0])+1:b_mant_[0];
		{b[2][3],b[2][2],b[2][1],b[2][0]} = (b_mant_[0][7]) ? (~b_mant_[0])+1:b_mant_[0];
		{b[3][3],b[3][2],b[3][1],b[3][0]} = (b_mant_[0][7]) ? (~b_mant_[0])+1:b_mant_[0];
		for (i=0;i<4;i=i+1) begin
		for (j=0;j<4;j=j+1) begin
			a_exp[i][j] = '0;
			b_exp[i][j] = '0;
			a_sign[i][j] = a_sign_in[0];
			b_sign[i][j] = b_sign_in[0];
		end
		end
	end else if (prec_mode == 2'b01) begin
    		if (FP_mode[0]) begin //means Mantissa is 2-bit
			for (i=0;i<2;i=i+1) begin
			for (j=0;j<2;j=j+1) begin
				//a
				{a[i][3],a[i][2]} = (a_exp_in_[0][9:5] == 0) ? {2'b00,a_mant_[0][5:4]}:{2'b01,a_mant_[0][5:4]};
				{a[i][1],a[i][0]} = (a_exp_in_[0][4:0] == 0) ? {2'b00,a_mant_[0][1:0]}:{2'b01,a_mant_[0][1:0]};

      				a_exp[i][j+2] = (a_exp_in_[0][9:5] == 0) ? 5'd1:a_exp_in_[0][9:5];
      				a_exp[i][j] = (a_exp_in_[0][4:0] == 0) ? 5'd1:a_exp_in_[0][4:0];

				a_sign[i][j+2] = a_sign_in_[0][1];
				a_sign[i][j] = a_sign_in_[0][0];

				{a[i+2][3],a[i+2][2]} = (a_exp_in_[1][9:5] == 0) ? {2'b00,a_mant_[1][5:4]}:{2'b01,a_mant_[1][5:4]};
				{a[i+2][1],a[i+2][0]} = (a_exp_in_[1][4:0] == 0) ? {2'b00,a_mant_[1][1:0]}:{2'b01,a_mant_[1][1:0]};

      				a_exp[i+2][j+2] = (a_exp_in_[1][9:5] == 0) ? 5'd1:a_exp_in_[1][9:5];
      				a_exp[i+2][j] = (a_exp_in_[1][4:0] == 0) ? 5'd1:a_exp_in_[1][4:0];

				a_sign[i+2][j+2] = a_sign_in_[1][1];
				a_sign[i+2][j] = a_sign_in_[1][0];

				//b
				{b[i][3],b[i][2]} = (b_exp_in_[0][9:5] == 0) ? {2'b00,b_mant_[0][5:4]}:{2'b01,b_mant_[0][5:4]};
				{b[i][1],b[i][0]} = (b_exp_in_[0][4:0] == 0) ? {2'b00,b_mant_[0][1:0]}:{2'b01,b_mant_[0][1:0]};

      				b_exp[i][j+2] = (b_exp_in_[0][9:5] == 0) ? 5'd1:b_exp_in_[0][9:5];
      				b_exp[i][j] = (b_exp_in_[0][4:0] == 0) ? 5'd1:b_exp_in_[0][4:0];

				b_sign[i][j+2] = b_sign_in_[0][1];
				b_sign[i][j] = b_sign_in_[0][0];

				{b[i+2][3],b[i+2][2]} = (b_exp_in_[1][9:5] == 0) ? {2'b00,b_mant_[1][5:4]}:{2'b01,b_mant_[1][5:4]};
				{b[i+2][1],b[i+2][0]} = (b_exp_in_[1][4:0] == 0) ? {2'b00,b_mant_[1][1:0]}:{2'b01,b_mant_[1][1:0]};

      				b_exp[i+2][j+2] = (b_exp_in_[1][9:5] == 0) ? 5'd1:b_exp_in_[1][9:5];
      				b_exp[i+2][j] = (b_exp_in_[1][4:0] == 0) ? 5'd1:b_exp_in_[1][4:0];

				b_sign[i+2][j+2] = b_sign_in_[1][1];
				b_sign[i+2][j] = b_sign_in_[1][0];
			end
			end
    		end else begin //means Mantissa is 3-bit
			for (i=0;i<2;i=i+1) begin
			for (j=0;j<2;j=j+1) begin
				//a
				{a[i][3],a[i][2]} = (a_exp_in_[0][9:5] == 0) ? {1'b0,a_mant_[0][6:4]}:{1'b1,a_mant_[0][6:4]};
				{a[i][1],a[i][0]} = (a_exp_in_[0][4:0] == 0) ? {1'b0,a_mant_[0][2:0]}:{1'b1,a_mant_[0][2:0]};

      				a_exp[i][j+2] = (a_exp_in_[0][9:5] == 0) ? 5'd1:a_exp_in_[0][9:5];
      				a_exp[i][j] = (a_exp_in_[0][4:0] == 0) ? 5'd1:a_exp_in_[0][4:0];

				a_sign[i][j+2] = a_sign_in_[0][1];
				a_sign[i][j] = a_sign_in_[0][0];

				{a[i+2][3],a[i+2][2]} = (a_exp_in_[1][9:5] == 0) ? {1'b0,a_mant_[1][6:4]}:{1'b1,a_mant_[1][6:4]};
				{a[i+2][1],a[i+2][0]} = (a_exp_in_[1][4:0] == 0) ? {1'b0,a_mant_[1][2:0]}:{1'b1,a_mant_[1][2:0]};

      				a_exp[i+2][j+2] = (a_exp_in_[1][9:5] == 0) ? 5'd1:a_exp_in_[1][9:5];
      				a_exp[i+2][j] = (a_exp_in_[1][4:0] == 0) ? 5'd1:a_exp_in_[1][4:0];

				a_sign[i+2][j+2] = a_sign_in_[1][1];
				a_sign[i+2][j] = a_sign_in_[1][0];

				//b
				{b[i][3],b[i][2]} = (b_exp_in_[0][9:5] == 0) ? {1'b0,b_mant_[0][6:4]}:{1'b1,b_mant_[0][6:4]};
				{b[i][1],b[i][0]} = (b_exp_in_[0][4:0] == 0) ? {1'b0,b_mant_[0][2:0]}:{1'b1,b_mant_[0][2:0]};

      				b_exp[i][j+2] = (b_exp_in_[0][9:5] == 0) ? 5'd1:b_exp_in_[0][9:5];
      				b_exp[i][j] = (b_exp_in_[0][4:0] == 0) ? 5'd1:b_exp_in_[0][4:0];

				b_sign[i][j+2] = b_sign_in_[0][1];
				b_sign[i][j] = b_sign_in_[0][0];

				{b[i+2][3],b[i+2][2]} = (b_exp_in_[1][9:5] == 0) ? {1'b0,b_mant_[1][6:4]}:{1'b1,b_mant_[1][6:4]};
				{b[i+2][1],b[i+2][0]} = (b_exp_in_[1][4:0] == 0) ? {1'b0,b_mant_[1][2:0]}:{1'b1,b_mant_[1][2:0]};

      				b_exp[i+2][j+2] = (b_exp_in_[1][9:5] == 0) ? 5'd1:b_exp_in_[1][9:5];
      				b_exp[i+2][j] = (b_exp_in_[1][4:0] == 0) ? 5'd1:b_exp_in_[1][4:0];

				b_sign[i+2][j+2] = b_sign_in_[1][1];
				b_sign[i+2][j] = b_sign_in_[1][0];
			end
			end
		end
	end else if (prec_mode == 2'b11) begin
		for (i=0;i<2;i=i+1) begin
			//a
    			a[i][3] = '0;
    			a[i][2] = '0;
    			a[i][1] = (a_exp_in_[i][3:2] == 0) ? {1'b0,a_mant_[i][2]}:{1'b1,a_mant_[i][2]};
    			a[i][0] = (a_exp_in_[i][1:0] == 0) ? {1'b0,a_mant_[i][0]}:{1'b1,a_mant_[i][0]};

    			a_exp[i][3] = '0;
    			a_exp[i][2] = '0;
    			a_exp[i][1] = (a_exp_in_[i][3:2] == 0) ? 2'd1:a_exp_in_[i][3:2];
    			a_exp[i][0] = (a_exp_in_[i][1:0] == 0) ? 2'd1:a_exp_in_[i][1:0];

			a_sign[i][3] = a_sign_in_[i][3];//'0;
			a_sign[i][2] = a_sign_in_[i][2];//'0;
			a_sign[i][1] = a_sign_in_[i][1];
			a_sign[i][0] = a_sign_in_[i][0];

    			a[i+2][3] = (a_exp_in_[i+2][7:6] == 0) ? {1'b0,a_mant_[i+2][6]}:{1'b1,a_mant_[i+2][6]};
    			a[i+2][2] = (a_exp_in_[i+2][5:4] == 0) ? {1'b0,a_mant_[i+2][4]}:{1'b1,a_mant_[i+2][4]};
    			a[i+2][1] = '0;
    			a[i+2][0] = '0;

    			a_exp[i+2][3] = (a_exp_in_[i+2][7:6] == 0) ? 2'd1:a_exp_in_[i+2][7:6];
    			a_exp[i+2][2] = (a_exp_in_[i+2][5:4] == 0) ? 2'd1:a_exp_in_[i+2][5:4];
    			a_exp[i+2][1] = '0;
    			a_exp[i+2][0] = '0;

			a_sign[i+2][3] = a_sign_in_[i+2][3];
			a_sign[i+2][2] = a_sign_in_[i+2][2];
			a_sign[i+2][1] = a_sign_in_[i+2][1];//'0;
			a_sign[i+2][0] = a_sign_in_[i+2][0];//'0;

			//b
    			b[i][3] = '0;
    			b[i][2] = '0;
    			b[i][1] = (b_exp_in_[i][3:2] == 0) ? {1'b0,b_mant_[i][2]}:{1'b1,b_mant_[i][2]};
    			b[i][0] = (b_exp_in_[i][1:0] == 0) ? {1'b0,b_mant_[i][0]}:{1'b1,b_mant_[i][0]};

    			b_exp[i][3] = '0;
    			b_exp[i][2] = '0;
    			b_exp[i][1] = (b_exp_in_[i][3:2] == 0) ? 2'd1:b_exp_in_[i][3:2];
    			b_exp[i][0] = (b_exp_in_[i][1:0] == 0) ? 2'd1:b_exp_in_[i][1:0];

			b_sign[i][3] = b_sign_in_[i][3];//'0;
			b_sign[i][2] = b_sign_in_[i][2];//'0;
			b_sign[i][1] = b_sign_in_[i][1];
			b_sign[i][0] = b_sign_in_[i][0];

    			b[i+2][3] = (b_exp_in_[i+2][7:6] == 0) ? {1'b0,b_mant_[i+2][6]}:{1'b1,b_mant_[i+2][6]};
    			b[i+2][2] = (b_exp_in_[i+2][5:4] == 0) ? {1'b0,b_mant_[i+2][4]}:{1'b1,b_mant_[i+2][4]};
    			b[i+2][1] = '0;
    			b[i+2][0] = '0;

    			b_exp[i+2][3] = (b_exp_in_[i+2][7:6] == 0) ? 2'd1:b_exp_in_[i+2][7:6];
    			b_exp[i+2][2] = (b_exp_in_[i+2][5:4] == 0) ? 2'd1:b_exp_in_[i+2][5:4];
    			b_exp[i+2][1] = '0;
    			b_exp[i+2][0] = '0;

			b_sign[i+2][3] = b_sign_in_[i+2][3];
			b_sign[i+2][2] = b_sign_in_[i+2][2];
			b_sign[i+2][1] = b_sign_in_[i+2][1];//'0;
			b_sign[i+2][0] = b_sign_in_[i+2][0];//'0;
		end
	end else begin //default
		for (i=0;i<4;i=i+1) begin
		for (j=0;j<4;j=j+1) begin
			a[i][j] = '0;
			b[i][j] = '0;
			a_exp[i][j] = '0;
			b_exp[i][j] = '0;
			a_sign[i][j] = '0;
			b_sign[i][j] = '0;
		end
		end
	end
end

endmodule



module multiplication (
	input wire [1:0] a [0:3][0:3],
	input wire [1:0] b [0:3][0:3],

	output logic [3:0] m00_o,
	output logic [3:0] m01_o,
	output logic [3:0] m02_o,
	output logic [3:0] m03_o,

	output logic [3:0] m10_o,
	output logic [3:0] m11_o,
	output logic [3:0] m12_o,
	output logic [3:0] m13_o,

	output logic [3:0] m20_o,
	output logic [3:0] m21_o,
	output logic [3:0] m22_o,
	output logic [3:0] m23_o,

	output logic [3:0] m30_o,
	output logic [3:0] m31_o,
	output logic [3:0] m32_o,
	output logic [3:0] m33_o,

	input  wire [4:0] a_exp [0:3][0:3],
	input  wire [4:0] b_exp [0:3][0:3],
	input  wire       a_sign [0:3][0:3],
	input  wire       b_sign [0:3][0:3],
	output logic [5:0] exp_interm [0:3][0:3],
	output logic       sign_interm [0:3][0:3]
);

//Multipliers:
mul_2bit m00 (.in1(a[0][0]), .in2(b[0][0]), .out(m00_o));
mul_2bit m01 (.in1(a[1][0]), .in2(b[0][1]), .out(m01_o));
mul_2bit m02 (.in1(a[2][0]), .in2(b[0][2]), .out(m02_o));
mul_2bit m03 (.in1(a[3][0]), .in2(b[0][3]), .out(m03_o));

mul_2bit m10 (.in1(a[0][1]), .in2(b[1][0]), .out(m10_o));
mul_2bit m11 (.in1(a[1][1]), .in2(b[1][1]), .out(m11_o));
mul_2bit m12 (.in1(a[2][1]), .in2(b[1][2]), .out(m12_o));
mul_2bit m13 (.in1(a[3][1]), .in2(b[1][3]), .out(m13_o));

mul_2bit m20 (.in1(a[0][2]), .in2(b[2][0]), .out(m20_o));
mul_2bit m21 (.in1(a[1][2]), .in2(b[2][1]), .out(m21_o));
mul_2bit m22 (.in1(a[2][2]), .in2(b[2][2]), .out(m22_o));
mul_2bit m23 (.in1(a[3][2]), .in2(b[2][3]), .out(m23_o));

mul_2bit m30 (.in1(a[0][3]), .in2(b[3][0]), .out(m30_o));
mul_2bit m31 (.in1(a[1][3]), .in2(b[3][1]), .out(m31_o));
mul_2bit m32 (.in1(a[2][3]), .in2(b[3][2]), .out(m32_o));
mul_2bit m33 (.in1(a[3][3]), .in2(b[3][3]), .out(m33_o));

//Exponents of mij_o
integer i1,j1;
always_comb begin
	for (i1=0;i1<4;i1=i1+1) begin
	for (j1=0;j1<4;j1=j1+1) begin
		exp_interm[i1][j1] = a_exp[j1][i1]+b_exp[i1][j1];
		sign_interm[i1][j1] = a_sign[j1][i1]+b_sign[i1][j1];
	end
	end
end
endmodule



module lvl1_adders (
	input logic [3:0] m00_o, 
	input logic [3:0] m01_o, 
	input logic [3:0] m02_o, 
	input logic [3:0] m03_o, 
	input logic [3:0] m10_o, 
	input logic [3:0] m11_o, 
	input logic [3:0] m12_o, 
	input logic [3:0] m13_o, 
	input logic [3:0] m20_o, 
	input logic [3:0] m21_o, 
	input logic [3:0] m22_o, 
	input logic [3:0] m23_o, 
	input logic [3:0] m30_o, 
	input logic [3:0] m31_o, 
	input logic [3:0] m32_o, 
	input logic [3:0] m33_o,
	input wire [5:0] exp_interm [0:3][0:3],
	input wire       sign_interm [0:3][0:3],
	input logic [1:0] prec_mode,

	output logic [9:0] added_mant0,
	output logic [9:0] added_mant1,
	output logic [9:0] added_mant2,
	output logic [9:0] added_mant3,
	output logic [5:0] added_exp0,
	output logic [5:0] added_exp1,
	output logic [5:0] added_exp2,
	output logic [5:0] added_exp3,
	output logic       added_sign0,
	output logic       added_sign1,
	output logic       added_sign2,
	output logic       added_sign3
);




//Need 4 exact additions for small exponents, and 1 FP addition
ST_add_lvl1 ST_add_lvl1_0 (.mant0(m00_o), .exp0(exp_interm[0][0]), .sign0(sign_interm[0][0]), .mant1(m01_o), .exp1(exp_interm[0][1]), .sign1(sign_interm[0][1]), 
		      .mant2(m10_o), .exp2(exp_interm[1][0]), .sign2(sign_interm[1][0]), .mant3(m11_o), .exp3(exp_interm[1][1]), .sign3(sign_interm[1][1]), 
		      .prec_mode(prec_mode), .added_mant(added_mant0), .added_exp(added_exp0), .added_sign(added_sign0));

ST_add_lvl1 ST_add_lvl1_1 (.mant0(m20_o), .exp0(exp_interm[2][0]), .sign0(sign_interm[2][0]), .mant1(m21_o), .exp1(exp_interm[2][1]), .sign1(sign_interm[2][1]), 
		      .mant2(m30_o), .exp2(exp_interm[3][0]), .sign2(sign_interm[3][0]), .mant3(m31_o), .exp3(exp_interm[3][1]), .sign3(sign_interm[3][1]), 
		      .prec_mode(prec_mode), .added_mant(added_mant1), .added_exp(added_exp1), .added_sign(added_sign1));

ST_add_lvl1 ST_add_lvl1_2 (.mant0(m02_o), .exp0(exp_interm[0][2]), .sign0(sign_interm[0][2]), .mant1(m03_o), .exp1(exp_interm[0][3]), .sign1(sign_interm[0][3]), 
		      .mant2(m12_o), .exp2(exp_interm[1][2]), .sign2(sign_interm[1][2]), .mant3(m13_o), .exp3(exp_interm[1][3]), .sign3(sign_interm[1][3]), 
		      .prec_mode(prec_mode), .added_mant(added_mant2), .added_exp(added_exp2), .added_sign(added_sign2));

ST_add_lvl1 ST_add_lvl1_3 (.mant0(m22_o), .exp0(exp_interm[2][2]), .sign0(sign_interm[2][2]), .mant1(m23_o), .exp1(exp_interm[2][3]), .sign1(sign_interm[2][3]), 
		      .mant2(m32_o), .exp2(exp_interm[3][2]), .sign2(sign_interm[3][2]), .mant3(m33_o), .exp3(exp_interm[3][3]), .sign3(sign_interm[3][3]), 
		      .prec_mode(prec_mode), .added_mant(added_mant3), .added_exp(added_exp3), .added_sign(added_sign3));

endmodule
