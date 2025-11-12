module FP_Add #(
  parameter M_out_width = {M_out_width}
)
(
  input  logic [M_out_width-1:0] accum_mant, 
  input  logic [7:0]  accum_exp,
  input  logic        accum_sign,
  input  logic [M_out_width-1:0] input_mant,
  input  logic [7:0]  input_exp,
  input  logic        input_sign,
  output logic [M_out_width-1:0] output_mant,
  output logic [7:0]  output_exp,
  output logic        output_sign
);



  logic signed [8:0] exp_diff, exp_diff_;
  logic [8:0] shift_left;
  assign exp_diff = accum_exp-input_exp;



//Preprocessing
  logic [M_out_width:0] accum_mant_shifted;
  logic [M_out_width:0] input_mant_shifted;
  logic [7:0] pre_exp;
  logic [3:0] len_input;
  logic [8:0] temp;
  logic [8:0] temp2;
  always_comb begin
      if (exp_diff >= 0) begin //shift input_mant
          accum_mant_shifted = (accum_exp == '0) ? {1'b0,accum_mant}:{1'b1,accum_mant}; //accumulator does not store implicit 1, added back here
          input_mant_shifted = (input_exp == '0) ? ({1'b0,input_mant} >> ($unsigned(exp_diff))):({1'b1,input_mant} >> ($unsigned(exp_diff)));
	  pre_exp = accum_exp;
      end 
      else begin
	  accum_mant_shifted = (accum_exp == '0) ? ({1'b0,accum_mant} >> ($unsigned(exp_diff))):({1'b1,accum_mant} >> ($unsigned(exp_diff)));
	  input_mant_shifted = (input_exp == '0) ? {1'b0,input_mant}:{1'b1,input_mant};
	  pre_exp = input_exp;
      end
  end

//Add or substract
  logic [$clog2(M_out_width+2)-1:0] leading_zeros;
  logic signed [M_out_width+1:0] added_mants;
  logic [M_out_width+1:0] mant_to_normalize;
  always_comb begin
    if (~(accum_sign ^ input_sign)) begin //if signs the same
	leading_zeros = 0;
        added_mants = accum_mant_shifted + input_mant_shifted;
        output_sign = accum_sign;
	mant_to_normalize = '0;
        if (added_mants[M_out_width+1]) begin //if addition, check if "overflow", shift accordingly
            output_mant = signed'(added_mants[M_out_width:1]);
            output_exp = pre_exp+1;
        end
        else begin
	  output_mant = added_mants[M_out_width-1:0];
	  output_exp = pre_exp;
        end
    end
    else begin //if substraction
        added_mants = accum_mant_shifted - input_mant_shifted;
        output_sign = (added_mants[M_out_width+1]) ? input_sign:accum_sign; //the bigger value in abs is checked and this one's sign is taken.
        mant_to_normalize = (added_mants[M_out_width+1]) ? (~added_mants)+1:added_mants; //make mantissa positive again
	

	leading_zeros = 0;
	for (int i=(M_out_width+2-1); i>=0; i--) begin
		if (mant_to_normalize[i]==1'b1) begin
			leading_zeros = (M_out_width+2-1)-i;
			break;
		end
	end
	
	casez(leading_zeros)
		0: begin
			output_mant = (mant_to_normalize >> 1);
			output_exp = pre_exp+1;
		end
		1: begin
			output_mant = mant_to_normalize;
			output_exp = pre_exp;
		end
		default: begin
			if (pre_exp < (leading_zeros-1)) begin
		  		output_mant = (mant_to_normalize << pre_exp);
		  		output_exp = '0;
			end
			else begin
				output_mant = (mant_to_normalize << (leading_zeros-1));
		  		output_exp = pre_exp-(leading_zeros-1);
			end
		end
	endcase


/*
	//Normalize
        casez(mant_to_normalize) 
	    25'b1????????????????????????: begin 
		output_mant = (mant_to_normalize >> 1);
		output_exp = pre_exp+1;
	    end
	    25'b01???????????????????????: begin 
		output_mant = mant_to_normalize;
		output_exp = pre_exp;
	    end
	    25'b001??????????????????????: begin 
		if (pre_exp < 1) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end
		else begin
		  output_mant = (mant_to_normalize << 1);
		  output_exp = pre_exp-1;
		end
	    end
	    25'b0001?????????????????????: begin 
		if (pre_exp < 2) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 2);
		  output_exp = pre_exp-2;
		end
	    end
	    25'b00001????????????????????: begin 
		if (pre_exp < 3) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 3);
		  output_exp = pre_exp-3;
		end
	    end
	    25'b000001???????????????????: begin 
		if (pre_exp < 4) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 4);
		  output_exp = pre_exp-4;
		end
	    end
	    25'b0000001??????????????????: begin 
		if (pre_exp < 5) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 5);
		  output_exp = pre_exp-5;
		end
	    end
	    25'b00000001?????????????????: begin 
		if (pre_exp < 6) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 6);
		  output_exp = pre_exp-6;
		end
	    end
	    25'b000000001????????????????: begin 
		if (pre_exp < 7) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 7);
		  output_exp = pre_exp-7;
		end
	    end
	    25'b0000000001???????????????: begin 
		if (pre_exp < 8) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 8);
		  output_exp = pre_exp-8;
		end
	    end
	    25'b00000000001??????????????: begin 
		if (pre_exp < 9) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 9);
		  output_exp = pre_exp-9;
		end
	    end
	    25'b000000000001?????????????: begin 
		if (pre_exp < 10) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 10);
		  output_exp = pre_exp-10;
		end
	    end
	    25'b0000000000001????????????: begin 
		if (pre_exp < 11) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 11);
		  output_exp = pre_exp-11;
		end
	    end
	    25'b00000000000001???????????: begin 
		if (pre_exp < 12) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 12);
		  output_exp = pre_exp-12;
		end
	    end
	    25'b000000000000001??????????: begin 
		if (pre_exp < 13) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 13);
		  output_exp = pre_exp-13;
		end
	    end
	    25'b0000000000000001?????????: begin 
		if (pre_exp < 14) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 14);
		  output_exp = pre_exp-14;
		end
	    end
	    25'b00000000000000001????????: begin 
		if (pre_exp < 15) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 15);
		  output_exp = pre_exp-15;
		end
	    end
	    25'b000000000000000001???????: begin 
		if (pre_exp < 16) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 16);
		  output_exp = pre_exp-16;
		end
	    end
	    25'b0000000000000000001??????: begin 
		if (pre_exp < 17) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 17);
		  output_exp = pre_exp-17;
		end
	    end
	    25'b00000000000000000001?????: begin 
		if (pre_exp < 18) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 18);
		  output_exp = pre_exp-18;
		end
	    end
	    25'b000000000000000000001????: begin 
		if (pre_exp < 19) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 19);
		  output_exp = pre_exp-19;
		end
	    end
	    25'b0000000000000000000001???: begin 
		if (pre_exp < 20) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 20);
		  output_exp = pre_exp-20;
		end
	    end
	    25'b00000000000000000000001??: begin 
		if (pre_exp < 21) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 21);
		  output_exp = pre_exp-21;
		end
	    end
	    25'b000000000000000000000001?: begin 
		if (pre_exp < 22) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = (mant_to_normalize << 22);
		  output_exp = pre_exp-22;
		end
	    end
	    25'b0000000000000000000000001: begin 
		if (pre_exp < 22) begin
		  output_mant = (mant_to_normalize << pre_exp);
		  output_exp = '0;
		end else begin
		  output_mant = '0;
		  output_exp = pre_exp-22;
		end
	    end
            default: begin
		output_mant = '0;
		output_exp = '0;
            end
        endcase*/
    end
  end

endmodule
