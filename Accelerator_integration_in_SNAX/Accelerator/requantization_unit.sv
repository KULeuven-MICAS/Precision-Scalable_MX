module requantization_unit #(
	parameter LEN_BLK = 8,
	parameter WD_BLK = 8,
	parameter M_out_width = 23
)
(
	input logic clk_i,
	input logic rstn,
	input logic [0:LEN_BLK-1][0:WD_BLK-1][(1+8+M_out_width-1):0] unq_block,
	input logic [1:0] prec_mode,
	input logic [1:0] FP_mode,
	output logic [0:LEN_BLK-1][0:WD_BLK-1][7:0] quan_block,
	output logic [7:0] shared_exp
);


logic [2:0] E_len;
logic [3:0] M_len;
always_comb begin
	casez ({prec_mode, FP_mode})
		4'b00??: begin //INT8
			E_len = 0;
			M_len = 8;
		end
		4'b11??: begin //FP4
			E_len = 2;
			M_len = 1;
		end
		4'b0111: begin //E5M2
			E_len = 5;
			M_len = 2;
		end
		4'b0110: begin //E4M3
			E_len = 4;
			M_len = 3;
		end
		4'b0101: begin //E3M2
			E_len = 3;
			M_len = 2;
		end
		4'b0100: begin //E2M3
			E_len = 2;
			M_len = 3;
		end
		default: begin
			E_len = 2;
			M_len = 1;
		end
	endcase
end


logic [7:0] B;
logic [7:0] e_max_elem;
assign B = (prec_mode == 2'b00) ? 'd0:2**(E_len-1)-1;
assign e_max_elem = (prec_mode == 2'b00) ? 'd0:2**(E_len)-1-B;


//Find max_exp in block:
logic [7:0] max_exp;
logic [0:LEN_BLK-1][0:WD_BLK-1][7:0] Exps;
logic [0:LEN_BLK-1][0:WD_BLK-1][M_out_width+1:0] Mants;
logic [0:LEN_BLK-1][0:WD_BLK-1] Signs;
always_comb begin
	for (int i=0; i < LEN_BLK; i++) begin
		for (int j=0; j < WD_BLK; j++) begin
			Exps[i][j] = unq_block[i][j][M_out_width+7:M_out_width];
			Mants[i][j] = (Exps[i][j] == 8'd0) ? {1'b0, unq_block[i][j][M_out_width-1:0]}:{1'b1, unq_block[i][j][M_out_width-1:0]};
			Signs[i][j] = unq_block[i][j][M_out_width+8];
		end
	end
end

always_comb begin
	max_exp = Exps[0][0];
	for (int k=0; k < LEN_BLK; k++) begin
		for (int l=0; l < WD_BLK; l++) begin
			if (Exps[k][l] > max_exp)
				max_exp = Exps[k][l];
		end
	end
end

assign shared_exp = max_exp - e_max_elem;

//E_out processing:
logic [0:LEN_BLK-1][0:WD_BLK-1][7:0] del_E;
logic signed [0:LEN_BLK-1][0:WD_BLK-1][7:0] E_temp;
logic signed [0:LEN_BLK-1][0:WD_BLK-1][7:0] to_shift;
logic [0:LEN_BLK-1][0:WD_BLK-1][7:0] E_out;
logic [0:LEN_BLK-1][0:WD_BLK-1][M_out_width+1:0] Mants_;
always_comb begin
	for (int k=0; k < LEN_BLK; k++) begin
		for (int l=0; l < WD_BLK; l++) begin
			del_E[k][l] = max_exp - Exps[k][l];
			E_temp[k][l] = e_max_elem - del_E[k][l];
			to_shift[k][l] = signed'(E_temp[k][l] + B);
			//if (to_shift[k][l] < 0) begin
			if (to_shift[k][l][7] == 1'b1) begin
				E_out[k][l] = 'd0;
				Mants_[k][l] = Mants[k][l] >> (-(to_shift[k][l]));
			end
			else begin
				E_out[k][l] = unsigned'(to_shift[k][l]);
				Mants_[k][l] = Mants[k][l];
			end
		end
	end
end


//M_out processing:
//Rounding to nearest
logic [0:LEN_BLK-1][0:WD_BLK-1] round_bit;
logic [0:LEN_BLK-1][0:WD_BLK-1][8:0] M_out; //Max is 8b for INT8, rest will use highest n bits and put zeros after
logic [0:LEN_BLK-1][0:WD_BLK-1][8:0] M_temp;
logic [0:LEN_BLK-1][0:WD_BLK-1][8:0] M_temp_;
logic [0:LEN_BLK-1][0:WD_BLK-1][7:0] E_out_;
always_comb begin
	for (int k=0; k < LEN_BLK; k++) begin
		for (int l=0; l < WD_BLK; l++) begin
			round_bit[k][l] = Mants_[k][l][(M_out_width+1)-(1+M_len)];
			if (round_bit[k][l] == 1'b0) begin
				M_out[k][l] = Mants_[k][l][M_out_width+1:M_out_width-6];
				M_temp[k][l] = '0;
				M_temp_[k][l] = '0;
				E_out_[k][l] = E_out[k][l];
			end
			else begin
				M_temp[k][l] = {1'd0, Mants_[k][l][M_out_width+1:M_out_width-6]};
				casez ({prec_mode, FP_mode}) 
					4'b00??: M_temp_[k][l] = M_temp[k][l]+1;  //INT8
					4'b11??: M_temp_[k][l] = M_temp[k][l]+16; //E2M1
					4'b0111: M_temp_[k][l] = M_temp[k][l]+8; //E5M2
					4'b0110: M_temp_[k][l] = M_temp[k][l]+4; //E4M3
					4'b0101: M_temp_[k][l] = M_temp[k][l]+8; //E3M2
					4'b0100: M_temp_[k][l] = M_temp[k][l]+4; //E2M3
					default: M_temp_[k][l] = M_temp[k][l]+16;
				endcase
				if (M_temp_[k][l][8] == 1'b1) begin
					if (prec_mode == 2'b00) begin
						M_out[k][l] = M_temp[k][l]; //clamping to max for INT8
						E_out_[k][l] = E_out[k][l];
					end
					else begin
						M_out[k][l] = M_temp_[k][l] >> 1;
						E_out_[k][l] = E_out[k][l]+1;
					end
				end
				else begin
					M_out[k][l] = M_temp_[k][l];
					E_out_[k][l] = E_out[k][l];

				end
			end
		end
	end
end


//Assign outputs
logic [0:LEN_BLK-1][0:WD_BLK-1][7:0] quan_block_;
always_comb begin
	for (int k=0; k < LEN_BLK; k++) begin
		for (int l=0; l < WD_BLK; l++) begin
			casez ({prec_mode, FP_mode}) 
				4'b00??: quan_block_[k][l] = (Signs[k][l]) ? -M_out[k][l][8:1]:M_out[k][l][8:1];      //INT8
				4'b11??: quan_block_[k][l] = {Signs[k][l], E_out_[k][l][1:0], M_out[k][l][5], 4'd0};  //E2M1
				4'b0111: quan_block_[k][l] = {Signs[k][l], E_out_[k][l][4:0], M_out[k][l][5:4]};      //E5M2
				4'b0110: quan_block_[k][l] = {Signs[k][l], E_out_[k][l][3:0], M_out[k][l][5:3]};      //E4M3
				4'b0101: quan_block_[k][l] = {Signs[k][l], E_out_[k][l][2:0], M_out[k][l][5:4], 2'd0};//E3M2
				4'b0100: quan_block_[k][l] = {Signs[k][l], E_out_[k][l][1:0], M_out[k][l][5:3], 2'd0};//E2M3
				default: quan_block_[k][l] = {Signs[k][l], E_out_[k][l][1:0], M_out[k][l][5], 4'd0};
			endcase
		end
	end
end

genvar i_var,j_var;
generate
	for (i_var = 0; i_var < LEN_BLK; i_var++) begin
		for (j_var = 0; j_var < WD_BLK; j_var++) begin
			assign quan_block[i_var][j_var] = quan_block_[i_var][j_var];
		end
	end
endgenerate

endmodule














