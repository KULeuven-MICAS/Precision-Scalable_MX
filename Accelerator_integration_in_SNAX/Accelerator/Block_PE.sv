module Block_PE #(
	parameter M_out_width = 16
)
(
	input  logic        clk_i,
	input  logic        rstn,


input logic [0:7][7:0] a_mant0,
input logic [0:7][7:0] a_mant1,
input logic [0:7][7:0] a_mant2,
input logic [0:7][7:0] a_mant3,
input logic [0:7][7:0] b_mant0,
input logic [0:7][7:0] b_mant1,
input logic [0:7][7:0] b_mant2,
input logic [0:7][7:0] b_mant3,
input logic [0:7][9:0] a_exp_in0,
input logic [0:7][9:0] a_exp_in1,
input logic [0:7][9:0] a_exp_in2,
input logic [0:7][9:0] a_exp_in3,
input logic [0:7][9:0] b_exp_in0,
input logic [0:7][9:0] b_exp_in1,
input logic [0:7][9:0] b_exp_in2,
input logic [0:7][9:0] b_exp_in3,
input logic [0:7][3:0] a_sign_in0,
input logic [0:7][3:0] a_sign_in1,
input logic [0:7][3:0] a_sign_in2,
input logic [0:7][3:0] a_sign_in3,
input logic [0:7][3:0] b_sign_in0,
input logic [0:7][3:0] b_sign_in1,
input logic [0:7][3:0] b_sign_in2,
input logic [0:7][3:0] b_sign_in3,



	input  logic [1:0]  prec_mode,
	input  logic [1:0]  FP_mode,
	input  logic [1:0]  prec_mode_quan,
	input  logic [1:0]  FP_mode_quan,

	input  logic        send_output,

	input  logic        A_valid,
	input  logic        B_valid,

input  logic [7:0]  shared_exp0,
input  logic [7:0]  shared_exp1,
/*
output logic [M_out_width-1:0] MAC_mant_out [0:7][0:7],
output logic [7:0] MAC_exp_out [0:7][0:7],
output logic MAC_sign_out [0:7][0:7]*/

output logic [0:7][0:7][7:0] quantized_outputs,
output logic [7:0]           shared_exp_out
);


logic [M_out_width-1:0] MAC_mant_out [0:7][0:7];
logic [7:0] MAC_exp_out [0:7][0:7];
logic MAC_sign_out [0:7][0:7];




////////////
logic [7:0] shared_exp_added;
assign shared_exp_added = shared_exp0 + shared_exp1 - 127;




////////


////////

//Generate 64 MX_MACs
genvar i,j;
generate 
for (i=0;i<8;i=i+1) begin
for (j=0;j<8;j=j+1) begin
MX_MAC_hybrid_BPE #(.M_out_width(M_out_width)) MX_MAC0 (.clk_i(clk_i), .rstn(rstn), .a_mant0(a_mant0[i]), .a_mant1(a_mant1[i]), .a_mant2(a_mant2[i]), .a_mant3(a_mant3[i]), 
.b_mant0(b_mant0[j]), .b_mant1(b_mant1[j]), .b_mant2(b_mant2[j]), .b_mant3(b_mant3[j]), .a_exp_in0(a_exp_in0[i]), .a_exp_in1(a_exp_in1[i]), 
.a_exp_in2(a_exp_in2[i]), .a_exp_in3(a_exp_in3[i]), .b_exp_in0(b_exp_in0[j]), .b_exp_in1(b_exp_in1[j]), .b_exp_in2(b_exp_in2[j]), .b_exp_in3(b_exp_in3[j]), 
.a_sign_in0(a_sign_in0[i]), .a_sign_in1(a_sign_in1[i]), .a_sign_in2(a_sign_in2[i]), .a_sign_in3(a_sign_in3[i]), .b_sign_in0(b_sign_in0[j]), 
.b_sign_in1(b_sign_in1[j]), .b_sign_in2(b_sign_in2[j]), .b_sign_in3(b_sign_in3[j]), .prec_mode(prec_mode), .FP_mode(FP_mode), .shared_exp_added(shared_exp_added), .MAC_mant_out(MAC_mant_out[i][j]), .MAC_exp_out(MAC_exp_out[i][j]), .MAC_sign_out(MAC_sign_out[i][j]),
.A_valid(A_valid), .B_valid(B_valid));
end
end
endgenerate


////////////
//Requantization
logic [0:7][0:7][(1+8+M_out_width-1):0] unq_block;
logic [0:7][0:7][7:0] quan_block;
always_comb begin
for (int i=0; i<8; i++) begin
for (int j=0; j<8; j++) begin
	unq_block[i][j] = (send_output) ? {MAC_sign_out[i][j], MAC_exp_out[i][j], MAC_mant_out[i][j]}:'d0;
	quantized_outputs[i][j] = quan_block[i][j];
end	
end
end

requantization_unit #(.LEN_BLK(8), .WD_BLK(8), .M_out_width(M_out_width)) requantization_unit0 (.clk_i(clk_i), .rstn(rstn), .unq_block(unq_block), .prec_mode(prec_mode_quan), .FP_mode(FP_mode_quan), .quan_block(quan_block), .shared_exp(shared_exp_out));



endmodule
