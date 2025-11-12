module Add_tree_full_INT_FP4_impr #(
  // One-hot config string: | FP32 | FP64 | FP16 | FP8 | FP16ALT | FP8ALT |
  parameter fpnew_pkg::fmt_logic_t   SrcDotpFpFmtConfig = 6'b000101, // Supported source formats (FP8, FP8ALT)
  parameter fpnew_pkg::fmt_logic_t   DstDotpFpFmtConfig = 6'b100000, // Supported destination formats (FP32)
  parameter int unsigned             VectorSize  = 4,

  // Do not change
  localparam int unsigned SRC_WIDTH = fpnew_pkg::max_fp_width(SrcDotpFpFmtConfig),
  localparam int unsigned DST_WIDTH = fpnew_pkg::max_fp_width(DstDotpFpFmtConfig),
  localparam int unsigned SCALE_WIDTH = 8,
  localparam int unsigned NUM_OPERANDS = 2*VectorSize+1, // scale is not included
  localparam int unsigned NUM_FORMATS = fpnew_pkg::NUM_FP_FORMATS
) (
  input  logic                        clk_i,
  input  logic                        rst_ni,
  // Input signals
  // input  logic [VectorSize-1:0][SRC_WIDTH-1:0] operands_a_i,
  // input  logic [VectorSize-1:0][SRC_WIDTH-1:0] operands_b_i,
  input  logic [9:0] mant0,
  input  logic [5:0] exp0,
  input  logic       sign0,
  input  logic [9:0] mant1,
  input  logic [5:0] exp1,
  input  logic       sign1,
  input  logic [9:0] mant2,
  input  logic [5:0] exp2,
  input  logic       sign2,
  input  logic [9:0] mant3,
  input  logic [5:0] exp3,
  input  logic       sign3,
  input  logic [1:0][SCALE_WIDTH-1:0] operands_c_i, // 2 operands
  input  logic [DST_WIDTH-1:0]        operand_d_i, // 1 operand, accumulator
  input  logic [1:0] prec_mode,
  input  logic [1:0] FP_mode,
  // input  logic [NUM_FORMATS-1:0][NUM_OPERANDS-1:0] is_boxed_i,
  input  fpnew_pkg::roundmode_e       rnd_mode_i,
  // input  fpnew_pkg::operation_e       op_i,
  // input  logic                        op_mod_i,
  // input  logic                        FP_src_mode,
  //input  fpnew_pkg::fp_format_e       src_fmt_i, // format of the multiplicands
  input  fpnew_pkg::fp_format_e       dst_fmt_i, // format of the addend and result
  // input  TagType                      tag_i,
  // input  logic                        mask_i,
  // input  AuxType                      aux_i,
  // Input Handshake
  input  logic                        in_valid_i,
  // output logic                        in_ready_o,
  // input  logic                        flush_i,
  // Output signals
  output logic [DST_WIDTH-1:0]        result_o,
  output fpnew_pkg::status_t          status_o,
  // output logic                        extension_bit_o,
  // output TagType                      tag_o,
  // output logic                        mask_o,
  // output AuxType                      aux_o,
  // Output handshake
  output logic                        out_valid_o,
  // input  logic                        out_ready_i,
  // Indication of valid data in flight
  output logic                        busy_o
);
/*
logic FP_src_mode;
assign FP_src_mode = (src_fmt_i=='d3); //'d3 is E5M2, 'd5 is E4M3
*/


  // ----------
  // Constants
  // ----------
  // The super-format that can hold all formats
  localparam fpnew_pkg::fp_encoding_t SUPER_FORMAT = fpnew_pkg::super_format(SrcDotpFpFmtConfig);
  localparam fpnew_pkg::fp_encoding_t SUPER_DST_FORMAT = fpnew_pkg::super_format(DstDotpFpFmtConfig);

  localparam int unsigned SUPER_EXP_BITS = SUPER_FORMAT.exp_bits;
  localparam int unsigned SUPER_MAN_BITS = SUPER_FORMAT.man_bits;
  localparam int unsigned SUPER_DST_EXP_BITS = SUPER_DST_FORMAT.exp_bits;
  localparam int unsigned SUPER_DST_MAN_BITS = SUPER_DST_FORMAT.man_bits;

  // Precision bits 'p' include the implicit bit
  localparam int unsigned PRECISION_BITS = SUPER_MAN_BITS + 1;
  // Destination precision bits 'p_dst' include the implicit bit
  localparam int unsigned DST_PRECISION_BITS = SUPER_DST_MAN_BITS + 1;

  // Algorithm constants
  localparam int unsigned ANCHOR = 34; // Fractional point position
  localparam int unsigned INT_BITS = 32;
  localparam int unsigned VECTOR_BITS = $clog2(VectorSize);
  localparam int unsigned SOP_FIXED_WIDTH = 1 + VECTOR_BITS + INT_BITS + ANCHOR;
  localparam int unsigned FIXED_SUM_WIDTH  = 1 + DST_PRECISION_BITS + 1 + (SOP_FIXED_WIDTH - 1); // |s|-Acc:24b-|R|-unsigned SoP:64+log2k-|
  localparam int unsigned LZC_SUM_WIDTH    = FIXED_SUM_WIDTH + DST_PRECISION_BITS;
  localparam int unsigned LZC_RESULT_WIDTH = $clog2(LZC_SUM_WIDTH);
  localparam int signed MAX_ACC_SHIFT_AMOUNT = FIXED_SUM_WIDTH - DST_PRECISION_BITS - 1; // Maximum allowable shift, -1 for the sign bit
  localparam int unsigned SOP_SHIFT = ANCHOR - 2*SUPER_MAN_BITS; // Constant left shift amount for the SOP to align the fractional point

  localparam int unsigned EXP_WIDTH = SUPER_EXP_BITS + 1;
  localparam int unsigned DST_EXP_WIDTH = SUPER_DST_EXP_BITS + 2; // +2 for overflow handling
  // Shift amount width: $clog2(DST_BIAS - ANCHOR + (scale_a+scale_b) + FIXED_SUM_WIDTH - 1)
  localparam int unsigned SHIFT_AMOUNT_WIDTH = $clog2(fpnew_pkg::bias(fpnew_pkg::FP32) - ANCHOR + 2**(SCALE_WIDTH) - 1 + FIXED_SUM_WIDTH - 1);


  // ----------------
  // Type definition
  // ----------------
  typedef struct packed {
    logic                      sign;
    logic [SUPER_EXP_BITS-1:0] exponent;
    logic [PRECISION_BITS-1:0] mantissa;
  } fp_src_t;
  typedef struct packed {
    logic                          sign;
    logic [SUPER_DST_EXP_BITS-1:0] exponent;
    logic [DST_PRECISION_BITS-1:0] mantissa;
  } fp_dst_t;






////////////////////////////////////////////////////////////////////////////////////////////////
//What actually needs to be done:
//-merge two FP8 formats into FP9
//-put normal bit at mantissa
//-operands_c[i] = signed'(operands_c_q[i]) - signed'(2**(SCALE_WIDTH-1)-1); // signed scale
//-operands in exp,mant,sign package zetten

/*
  // ------------------------
  // Preprocessing A and B
  // ------------------------
  logic [VectorSize-1:0] a_is_normal, b_is_normal;
  always_comb begin
    for (int i = 0; i < VectorSize; i++) begin
      a_is_normal[i] = (FP_src_mode) ? (operands_a_i[i][6:2] != '0):(operands_a_i[i][6:3] != '0);
      b_is_normal[i] = (FP_src_mode) ? (operands_b_i[i][6:2] != '0):(operands_b_i[i][6:3] != '0);
    end
  end

  fp_src_t [VectorSize-1:0] operands_a, operands_b; //turn into FP10 (E5M(3+1))
  always_comb begin
    for (int i = 0; i < VectorSize; i++) begin : ab_preprocess //sign, (0b exp extension), exp, (0b mant extension), normal?, mant 
      operands_a[i] = (FP_src_mode) ? {operands_a_i[i][7], operands_a_i[i][6:2], 1'b0, a_is_normal[i], operands_a_i[i][1:0]}: //FP_src_mode 1 -> E5M2
                                      {operands_a_i[i][7], 1'b0, operands_a_i[i][6:3], a_is_normal[i], operands_a_i[i][2:0]}; //FP_src_mode 0 -> E4M3
      operands_b[i] = (FP_src_mode) ? {operands_b_i[i][7], operands_b_i[i][6:2], 1'b0, b_is_normal[i], operands_b_i[i][1:0]}: //FP_src_mode 1 -> E5M2
                                      {operands_b_i[i][7], 1'b0, operands_b_i[i][6:3], b_is_normal[i], operands_b_i[i][2:0]}; //FP_src_mode 0 -> E4M3
    end
  end
*/

  // ------------------------
  // Preprocessing Exponents
  // ------------------------
  //This code requires the exponents to be centered around 0 for correct shifting and anchor placement
  //Because exponents are normally stored as unbiased form (as operands_c), we also supply unbiased exponents
  logic signed [VectorSize-1:0][5:0] exp_signed;
  logic [5:0] bias;
  assign exp_signed[0] = signed'(exp0-bias);
  assign exp_signed[1] = signed'(exp1-bias);
  assign exp_signed[2] = signed'(exp2-bias);
  assign exp_signed[3] = signed'(exp3-bias);

  always_comb begin
    casez({prec_mode,FP_mode})
	4'b00??: begin //INT8xINT8
		bias = 8'd0;
	end
	4'b0110: begin //E4M3xE4M3
		bias = 8'd7;
	end
	4'b0101: begin //E3M2xE3M2
		bias = 8'd3;
	end
	4'b0111: begin //E5M2xE5M2
		bias = 8'd15;
	end
	4'b0100: begin //E2M3xE2M3
		bias = 8'd1;
	end
	4'b11??: begin //E2M1xE2M1
		bias = 8'd1;
	end
	default: begin
		bias = 0;
	end
      endcase
    end


  // -----------------
  // Preprocessing D
  // -----------------
  logic d_is_normal;
  assign d_is_normal = (operand_d_i[30:23] != '0);

  fp_dst_t operand_d;
  always_comb begin
    operand_d = {operand_d_i[31], operand_d_i[30:23], d_is_normal, operand_d_i[22:0]}; //FP32
  end

  // -----------------
  // Preprocessing C
  // ----------------- 
  logic signed [1:0][SCALE_WIDTH-1:0] operands_c;
  always_comb begin
    for (int i = 0; i < 2; i++) begin : c_preprocess
      operands_c[i] = signed'(operands_c_i[i]) - signed'(2**(SCALE_WIDTH-1)-1); // signed scale
    end
  end


///////////////////////////////////////////////////////////////////////////////////////////////

  // ------------------
  // Scale data path
  // ------------------
  logic signed [SCALE_WIDTH:0] scale; // +1 for addition

  assign scale = signed'(operands_c[0]) + signed'(operands_c[1]);
/*
  // ------------------
  // Product data path
  // ------------------
  logic [VectorSize-1:0][9:0] product;  // the p*p product is 2p-bit wide
  logic signed [VectorSize-1:0][10:0] product_signed;  // two's complement product

  // Add implicit bits to mantissae
  for (genvar i = 0; i < VectorSize; i++) begin : gen_products
    assign product[i] = operands_a[i].mantissa * operands_b[i].mantissa;
    assign product_signed[i] = (operands_a[i].sign ^ operands_b[i].sign) ? -product[i] : product[i];
  end
*/

  logic signed [VectorSize-1:0][12:0] product_signed;  // two's complement product
  always_comb begin
    if (prec_mode == 2'b00) begin
      product_signed[0] = mant0 << 4; //INT8 mode wait for sign after first addition
      product_signed[1] = mant1 << 2;
      product_signed[2] = mant2 << 2;
      product_signed[3] = mant3;
    end
    else if (prec_mode == 2'b11) begin
      product_signed[0] = {sign0,sign0,sign0,mant0}; //FP4 mode is already in 2-complement
      product_signed[1] = {sign1,sign1,sign1,mant1};
      product_signed[2] = {sign2,sign2,sign2,mant2};
      product_signed[3] = {sign3,sign3,sign3,mant3};
    end
    else begin
      product_signed[0] = (sign0) ? -mant0:mant0; //FP8 to 2-complement
      product_signed[1] = (sign1) ? -mant1:mant1;
      product_signed[2] = (sign2) ? -mant2:mant2;
      product_signed[3] = (sign3) ? -mant3:mant3;
    end
  end


/*
  // ------------------
  // Shift data path
  // ------------------
  logic signed [VectorSize-1:0][EXP_WIDTH-1:0] exponent_product;
  logic signed [VectorSize-1:0][SOP_FIXED_WIDTH-1:0] shifted_product;
  logic [VectorSize-1:0][5:0] shift_amount; // max shift can be 58 (28 + exp-max(30)), min shift is 0 (28 + exp-min(-28))

  // Calculate the non-biased exponent of the product
  for (genvar i = 0; i < VectorSize; i++) begin : gen_exponent_adjustment
    assign exponent_product[i] = operands_a[i].exponent + (~a_is_normal[i])
                                + operands_b[i].exponent + (~b_is_normal[i])
                                - 2*signed'(fpnew_pkg::bias(src_fmt_i));
*/
  
  
  logic signed [VectorSize-1:0][5:0] exponent_product;
  logic signed [VectorSize-1:0][SOP_FIXED_WIDTH-1:0] shifted_product;
  logic [VectorSize-1:0][5:0] shift_amount;
  
  for (genvar i = 0; i < VectorSize; i++) begin
    assign exponent_product[i] = exp_signed[i];
  end


  logic [7:0] mode_shift;
  always_comb begin
    casez({prec_mode,FP_mode})
	4'b00??: begin //INT8xINT8
		mode_shift = -8'd12;
	end
	4'b0110: begin //E4M3xE4M3
		mode_shift = -8'd9;
	end
	4'b0101: begin //E3M2xE3M2
		mode_shift = -8'd3;
	end
	4'b0111: begin //E5M2xE5M2
		mode_shift = -8'd15;
	end
	4'b0100: begin //E2M3xE2M3
		mode_shift = -8'd7;
	end
	4'b11??: begin //E2M1xE2M1
		mode_shift = 8'd3;
	end
	default: begin
		mode_shift = 0;
	end
      endcase
    end

/////////////////////////////////////All above needs to change///////////////////////////////////////////////////////////////////
//Put exponents and mantissas of products at right spots, sign products in FP8 and FP4 mode, add shifts and sign after addition for INT8.
//(sign after addition is very bad as 70b long, distinct add path for INT8 better? -> try both!)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Right shift the significand by anchor point - exponent
    // sum of four 9-bit numbers can be at most 11 bits, for 69 bits output we need to shift by 69 - 11 = 58
    // 58-30=28 plus inherit 6 fractional bits from the multiplication -> point moves to 28+6=34
  for (genvar i = 0; i < VectorSize; i++) begin : gen_exponent_adjustment
    assign shift_amount[i] = signed'(SOP_SHIFT) + signed'(exponent_product[i]) + signed'(mode_shift);
    assign shifted_product[i] = signed'(product_signed[i]) << shift_amount[i];
  end

  // ------------------
  // Adder data path
  // ------------------
  logic signed [FIXED_SUM_WIDTH-1:0] sum_product;

  // Sum the products
  always_comb begin : sum_products
    sum_product = '0;
    for (int i = 0; i < VectorSize; i++) begin : gen_sum_products
      sum_product += signed'(shifted_product[i]);
    end
  end

  // -----------------------------
  // Put INT8 in 2-complement
  // -----------------------------
  logic signed [FIXED_SUM_WIDTH-1:0] sum_product_signed;
  
  always_comb begin
    if (prec_mode == 2'b00) begin
      sum_product_signed = (sign0) ? -sum_product:sum_product; //INT8 mode to 2-complement
    end
    else begin
      sum_product_signed = sum_product; //FP8 and FP4 mode already in 2-complement
    end
  end

  // -----------------------------
  // Accumulator shift data path
  // -----------------------------
  logic result_is_accumulator;
  logic accumulator_is_right_shifted;

  logic signed [9:0] accumulator_shift_amount, accumulator_right_shift_amount;
  logic signed [DST_EXP_WIDTH-1:0] exponent_d;
  logic [DST_PRECISION_BITS-1:0] mantissa_d;
  logic signed [DST_PRECISION_BITS :0] signed_mantissa_d;
  logic signed [DST_PRECISION_BITS-1:0] accumulator_remaining;
  logic signed [FIXED_SUM_WIDTH-1:0] accumulator_shifted, sum_product_accumulator;
  logic accumulator_sticky;
  logic signed [LZC_SUM_WIDTH-1:0] sum_product_accumulator_extended;

  // Zero-extend exponents into signed container - implicit width extension
  assign exponent_d = {1'b0, operand_d.exponent};
  assign mantissa_d = operand_d.mantissa;
  assign signed_mantissa_d = operand_d.sign ? -mantissa_d : mantissa_d;

  // Calculate the shift amount for the accumulator, range=[-370,394-9b -> signed 10b]
  assign accumulator_shift_amount = signed'(ANCHOR - SUPER_DST_MAN_BITS) - signed'(scale)
                                     + signed'(exponent_d + (~d_is_normal))
                                     - signed'(fpnew_pkg::bias(dst_fmt_i));

  always_comb begin : accumulator_shift
    result_is_accumulator = 1'b0;
    accumulator_is_right_shifted = 1'b0;
    accumulator_right_shift_amount = '0;
    accumulator_remaining = '0;
    accumulator_sticky = 1'b0;
    if (accumulator_shift_amount > MAX_ACC_SHIFT_AMOUNT) begin
      // SoP is too small to change the accumulator, result is the accumulator
      accumulator_shifted = '0;
      result_is_accumulator = 1'b1;
    end else if (accumulator_shift_amount >= 0) begin
      accumulator_shifted = signed'(signed_mantissa_d) <<< accumulator_shift_amount;
    end else begin
      accumulator_is_right_shifted = 1'b1;
      accumulator_right_shift_amount = -accumulator_shift_amount;
      accumulator_shifted = signed'(signed_mantissa_d) >>> accumulator_right_shift_amount;
      if (accumulator_right_shift_amount > DST_PRECISION_BITS) begin
        result_is_accumulator = (sum_product_signed == '0) ? 1'b1 : 1'b0;
        accumulator_remaining = signed'(signed_mantissa_d) >>> (accumulator_right_shift_amount - DST_PRECISION_BITS);
        accumulator_sticky = |(signed'(signed_mantissa_d) & ((1 << (accumulator_right_shift_amount - DST_PRECISION_BITS)) - 1));
      end else begin
        accumulator_remaining = signed'(signed_mantissa_d) << (DST_PRECISION_BITS - accumulator_right_shift_amount);
        accumulator_sticky = 1'b0;
      end
    end
  end

  assign sum_product_accumulator = sum_product_signed + accumulator_shifted;
  assign sum_product_accumulator_extended = {sum_product_accumulator, accumulator_remaining};

  // --------------
  // Normalization
  // --------------
  logic        [LZC_SUM_WIDTH-1:0]    sum_magnitude, sum_shifted;
  logic        [LZC_RESULT_WIDTH-1:0] leading_zero_count;     // the number of leading zeroes
  logic signed [LZC_RESULT_WIDTH:0]   leading_zero_count_sgn; // signed leading-zero count
  logic                               lzc_zeroes;             // in case only zeroes found

  logic signed [DST_EXP_WIDTH-1:0]      final_tentative_exponent;

  logic        [SHIFT_AMOUNT_WIDTH-1:0] norm_shamt; // Normalization shift amount
  logic signed [DST_EXP_WIDTH-1:0]      normalized_exponent;

  logic                                 final_sign;
  logic        [DST_PRECISION_BITS-1:0] final_mantissa;
  logic        [LZC_SUM_WIDTH-DST_PRECISION_BITS-1:0] sum_sticky_bits;
  logic                                 sticky_after_norm;
  logic signed [DST_EXP_WIDTH-1:0]      final_exponent;

  // Leading sign counter
  // If sum is negative, complement to feed into leading zero counter
  assign final_sign    = sum_product_accumulator_extended[LZC_SUM_WIDTH-1];

  always_comb begin : get_twos_complement
    if (final_sign) begin
      sum_magnitude = ~sum_product_accumulator_extended + 1;
      if (accumulator_is_right_shifted && accumulator_right_shift_amount > DST_PRECISION_BITS && signed_mantissa_d != 0) begin
        sum_magnitude = ~sum_product_accumulator_extended;
      end
    end else begin
      sum_magnitude = sum_product_accumulator_extended;
    end
  end

  // Leading sign counter
  lzc #(
    .WIDTH ( LZC_SUM_WIDTH ),
    .MODE  ( 1             ) // MODE = 1 counts leading zeroes
  ) i_lzc (
    .in_i    ( sum_magnitude      ),
    .cnt_o   ( leading_zero_count ),
    .empty_o ( lzc_zeroes         )
  );

  assign leading_zero_count_sgn = signed'({1'b0, leading_zero_count});

  // Calculate the biased exponent (excess-127 form)
  // The exponent-major is -scaled_anchor
  // exponent = 127 - scaled_anchor + (94-count-1) + increment_exponent [-195, 315 9b -> 10b signed]
  assign final_tentative_exponent = signed'(fpnew_pkg::bias(dst_fmt_i)) - (signed'(ANCHOR)-signed'(scale)) + (signed'(FIXED_SUM_WIDTH) - leading_zero_count_sgn - 1);

  // Normalization shift amount based on exponents and LZC (unsigned as only left shifts)
  always_comb begin : norm_shift_amount
    // Subnormals
    if (final_tentative_exponent > 0 && !lzc_zeroes) begin
      norm_shamt          = leading_zero_count_sgn + 1;
      normalized_exponent = final_tentative_exponent;
    end else begin // Subnormals and zero
      norm_shamt          = leading_zero_count_sgn + final_tentative_exponent;
      normalized_exponent = '0; // subnormals encoded as 0
    end
  end

  // Shift the sum to normalize it
  assign sum_shifted = sum_magnitude << norm_shamt;

  // LSB of final mantissa is the rounding bit


  assign {final_mantissa, sum_sticky_bits} = sum_shifted;
  assign final_exponent                    = normalized_exponent+2;//s: result is 2 off in exponent, why?
  assign sticky_after_norm                 = (|sum_sticky_bits) | accumulator_sticky;



  // ----------------------------
  // Rounding and classification
  // ----------------------------
  logic                                             pre_round_sign;
  logic [SUPER_DST_EXP_BITS+SUPER_DST_MAN_BITS-1:0] pre_round_abs; // absolute value of result before rounding
  logic [1:0]                                       round_sticky_bits;

  logic of_before_round, of_after_round; // overflow
  logic uf_before_round, uf_after_round; // underflow

  logic [NUM_FORMATS-1:0][SUPER_DST_EXP_BITS+SUPER_DST_MAN_BITS-1:0] fmt_pre_round_abs; // per format
  logic [NUM_FORMATS-1:0][1:0]                                       fmt_round_sticky_bits;

  logic [NUM_FORMATS-1:0]                           fmt_of_after_round;
  logic [NUM_FORMATS-1:0]                           fmt_uf_after_round;

  logic                                             rounded_sign;
  logic [SUPER_DST_EXP_BITS+SUPER_DST_MAN_BITS-1:0] rounded_abs; // absolute value of result after rounding
  logic                                             result_zero;

  // Classification before round. RISC-V mandates checking underflow AFTER rounding
  assign of_before_round = final_exponent >= 2**(fpnew_pkg::exp_bits(dst_fmt_i))-1; // infinity exponent is all ones
  assign uf_before_round = final_exponent == 0;               // exponent for subnormals capped to 0

  // Pack exponent and mantissa into proper rounding form
  for (genvar fmt = 0; fmt < int'(NUM_FORMATS); fmt++) begin : gen_res_assemble
    // Set up some constants
    localparam int unsigned EXP_BITS = fpnew_pkg::exp_bits(fpnew_pkg::fp_format_e'(fmt));
    localparam int unsigned MAN_BITS = fpnew_pkg::man_bits(fpnew_pkg::fp_format_e'(fmt));
    localparam int unsigned ALL_EXTRA_BITS = fpnew_pkg::maximum(SUPER_DST_MAN_BITS-MAN_BITS+1+DST_PRECISION_BITS+PRECISION_BITS+2+1, 1);

    logic [EXP_BITS-1:0] pre_round_exponent;
    logic [MAN_BITS-1:0] pre_round_mantissa;

    if (DstDotpFpFmtConfig[fmt]) begin : active_dst_format

      assign pre_round_exponent = (of_before_round) ? 2**EXP_BITS-2 : final_exponent[EXP_BITS-1:0];
      assign pre_round_mantissa = (of_before_round) ? '1 : final_mantissa[SUPER_DST_MAN_BITS-:MAN_BITS];
      // Assemble result before rounding. In case of overflow, the largest normal value is set.
      assign fmt_pre_round_abs[fmt] = {pre_round_exponent, pre_round_mantissa}; // 0-extend

      // Round bit is after mantissa (1 in case of overflow for rounding)
      assign fmt_round_sticky_bits[fmt][1] = final_mantissa[SUPER_DST_MAN_BITS-MAN_BITS] |
                                             of_before_round;

      // remaining bits in mantissa to sticky (1 in case of overflow for rounding)
      if (MAN_BITS < SUPER_DST_MAN_BITS) begin : narrow_sticky
        assign fmt_round_sticky_bits[fmt][0] = (| final_mantissa[SUPER_DST_MAN_BITS-MAN_BITS-1:0]) |
                                               sticky_after_norm | of_before_round;
      end else begin : normal_sticky
        assign fmt_round_sticky_bits[fmt][0] = sticky_after_norm | of_before_round;
      end
    end else begin : inactive_format
      assign fmt_pre_round_abs[fmt] = '{default: fpnew_pkg::DONT_CARE};
      assign fmt_round_sticky_bits[fmt] = '{default: fpnew_pkg::DONT_CARE};
    end
  end

  // Assemble result before rounding. In case of overflow, the largest normal value is set.
  assign pre_round_abs      = fmt_pre_round_abs[dst_fmt_i];

  // In case of overflow, the round and sticky bits are set for proper rounding
  assign round_sticky_bits  = fmt_round_sticky_bits[dst_fmt_i];
  assign pre_round_sign     = final_sign;

  // Perform the rounding
  fpnew_rounding #(
    .AbsWidth     ( SUPER_DST_EXP_BITS + SUPER_DST_MAN_BITS )
  ) i_fpnew_rounding (
    .clk_i                      ( clk_i                    ),
    .rst_ni                     ( rst_ni                   ),
    .id_i                       ( '0                       ),
    .abs_value_i                ( pre_round_abs            ),
    .en_rsr_i                   ( 1'b0                     ),
    .sign_i                     ( pre_round_sign           ),
    .round_sticky_bits_i        ( round_sticky_bits        ),
    .stochastic_rounding_bits_i ( '0                       ),
    .rnd_mode_i                 ( rnd_mode_i               ),
    .effective_subtraction_i    ( 1'b0 ), // Effective subtraction is not implemented as RNE is used
    .abs_rounded_o              ( rounded_abs              ),
    .sign_o                     ( rounded_sign             ),
    .exact_zero_o               ( result_zero              )
  );

  logic [NUM_FORMATS-1:0][DST_WIDTH-1:0] fmt_result;

  for (genvar fmt = 0; fmt < int'(NUM_FORMATS); fmt++) begin : gen_sign_inject
    // Set up some constants
    localparam int unsigned FP_WIDTH = fpnew_pkg::fp_width(fpnew_pkg::fp_format_e'(fmt));
    localparam int unsigned EXP_BITS = fpnew_pkg::exp_bits(fpnew_pkg::fp_format_e'(fmt));
    localparam int unsigned MAN_BITS = fpnew_pkg::man_bits(fpnew_pkg::fp_format_e'(fmt));

    if (DstDotpFpFmtConfig[fmt]) begin : active_dst_format
      always_comb begin : post_process
        // detect of / uf
        fmt_uf_after_round[fmt] = rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '0; // denormal
        fmt_of_after_round[fmt] = rounded_abs[EXP_BITS+MAN_BITS-1:MAN_BITS] == '1; // inf exp.

        // Assemble regular result, nan box short ones.
        fmt_result[fmt]               = '1;
        fmt_result[fmt][FP_WIDTH-1:0] = {rounded_sign, rounded_abs[EXP_BITS+MAN_BITS-1:0]};
      end
    end else begin : inactive_format
      assign fmt_uf_after_round[fmt] = fpnew_pkg::DONT_CARE;
      assign fmt_of_after_round[fmt] = fpnew_pkg::DONT_CARE;
      assign fmt_result[fmt]         = '{default: fpnew_pkg::DONT_CARE};
    end
  end

  // Classification after rounding select by destination format
  assign uf_after_round = fmt_uf_after_round[dst_fmt_i];
  assign of_after_round = fmt_of_after_round[dst_fmt_i];

  // -----------------
  // Result selection
  // -----------------
  logic [DST_WIDTH-1:0] regular_result;
  fpnew_pkg::status_t   regular_status;

  // Assemble regular result
  assign regular_result    = fmt_result[dst_fmt_i];
  assign regular_status.NV = 1'b0; // only valid cases are handled in regular path
  assign regular_status.DZ = 1'b0; // no divisions
  assign regular_status.OF = of_before_round | of_after_round;   // rounding can introduce overflow
  assign regular_status.UF = uf_after_round & regular_status.NX; // only inexact results raise UF
  assign regular_status.NX = (| round_sticky_bits) | of_before_round | of_after_round;

  // Final results for output pipeline
  logic [DST_WIDTH-1:0] result_d;
  fpnew_pkg::status_t   status_d;

  // Select output depending on special case detection
  assign result_d = result_is_accumulator ? operand_d_i : regular_result;
  assign status_d = result_is_accumulator ? fpnew_pkg::status_t'(0) : regular_status;

  // ----------------
  // Output Pipeline
  // ----------------

  // Output stage: Ready travels backwards from output side, driven by downstream circuitry
  // assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
  // Output stage: assign module outputs
  assign result_o        = result_d;
  assign status_o        = status_d;
  assign out_valid_o     = in_valid_i;
  assign busy_o          = ~in_valid_i;
endmodule
