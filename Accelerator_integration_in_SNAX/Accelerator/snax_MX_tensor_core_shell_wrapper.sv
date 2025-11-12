// Copyright 2025 KU Leuven.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// Author: Xiaoling Yi <xiaoling.yi@kuleuven.be>

// Accelerator wrapper

module snax_MX_tensor_core_shell_wrapper #(
    // CSR parameters
    parameter int unsigned RegRWCount = 4,
    parameter int unsigned RegROCount = 2,
    parameter int unsigned RegDataWidth = 32,
    parameter int unsigned RegAddrWidth = 32,
    // Accelerator parameters
    // 4 A port
    parameter int unsigned StreamADataWidth = 256,
    // 4 B port
    parameter int unsigned StreamBDataWidth = 256,
    // 1 Shared exponent port
    parameter int unsigned StreamSharedExpDataWidth = 64,
    // 8 + 1 = 9
    // 8 output port, 1 output shared exponent port
    parameter int unsigned StreamCDataWidth = 576
) (
    //-------------------------------
    // Clocks and reset
    //-------------------------------
    input logic clk_i,
    input logic rst_ni,

    //-------------------------------
    // Accelerator ports
    //-------------------------------
    // Note, we maintained the form of these signals
    // just to comply with the top-level wrapper

    // Ports from streamer to accelerator
    input logic [(StreamADataWidth)-1:0] stream2acc_0_data_i,
    input logic stream2acc_0_valid_i,
    output logic stream2acc_0_ready_o,

    input logic [(StreamBDataWidth)-1:0] stream2acc_1_data_i,
    input logic stream2acc_1_valid_i,
    output logic stream2acc_1_ready_o,

    input logic [(StreamSharedExpDataWidth)-1:0] stream2acc_2_data_i,
    input logic stream2acc_2_valid_i,
    output logic stream2acc_2_ready_o,

    // Ports from accelerator to streamer
    output logic [(StreamCDataWidth)-1:0] acc2stream_0_data_o,
    output logic acc2stream_0_valid_o,
    input logic acc2stream_0_ready_i,

    //-------------------------------
    // CSR manager ports
    //-------------------------------
    input  logic [RegRWCount-1:0][RegDataWidth-1:0] csr_reg_set_i,
    input  logic                                    csr_reg_set_valid_i,
    output logic                                    csr_reg_set_ready_o,
    output logic [RegROCount-1:0][RegDataWidth-1:0] csr_reg_ro_set_o
);

  // -----------------------------------------------------------
  // -----------------------------------------------------------
  // simple finite current_state machine to control the accelerator
  // -----------------------------------------------------------
  // -----------------------------------------------------------

  typedef enum logic {
    IDLE,
    BUSY
  } state_t;
  state_t current_state, next_state;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  logic config_fire;
  assign config_fire = (current_state == IDLE) && (csr_reg_set_valid_i && csr_reg_set_ready_o);

  // store the CSR configuration
  logic [RegRWCount-1:0][RegDataWidth-1:0] csr_reg_set_buffer;
  // CSR 0: precision mode
  // CSR 1: accumulation count
  // CSR 2: output count
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      csr_reg_set_buffer <= '0;
    end else begin
      if (config_fire) begin
        csr_reg_set_buffer <= csr_reg_set_i;
      end
    end
  end

  logic acc_busy;
  assign acc_busy = (current_state == BUSY);

  logic output_fire;
  assign output_fire = acc2stream_0_valid_o && acc2stream_0_ready_i && (acc_busy);
  logic [31:0] output_fire_counter;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      output_fire_counter <= 32'b0;  // Reset counter
    end else begin
      if (output_fire) begin
        output_fire_counter <= output_fire_counter + 1;
      end else if (current_state == IDLE) begin
        output_fire_counter <= 32'b0;  // Reset counter on current_state change
      end
    end
  end

  logic compute_finish;
  assign compute_finish = output_fire_counter == csr_reg_set_buffer[2];

  always_comb begin
    next_state = current_state;
    case (current_state)
      IDLE: begin
        if (config_fire) begin
          next_state = BUSY;
        end
      end
      BUSY: begin
        if (compute_finish) begin
          next_state = IDLE;
        end
      end
      default: begin
      end
    endcase
  end

  // -----------------------------------------------------------
  // -----------------------------------------------------------
  // sMX tensor core instantiation
  // -----------------------------------------------------------
  // -----------------------------------------------------------

  // Inputs
  logic [0:7][7:0] A_INT8;
  logic [0:7][7:0] B_INT8;

  logic [0:7][0:3][7:0] A_FP8;
  logic [0:7][0:3][7:0] B_FP8;

  logic [0:7][0:3][5:0] A_FP6;
  logic [0:7][0:3][5:0] B_FP6;

  logic [0:7][0:7][3:0] A_FP4;
  logic [0:7][0:7][3:0] B_FP4;

  logic [7:0] shared_exp_A;
  logic [7:0] shared_exp_B;

  // Outputs
  logic [0:7][0:7][7:0] Out;
  logic [7:0] shared_exp_out;

  // // Data distribution
  // always_comb begin
  //   for (int i = 0; i < 8; i++) begin
  //     // INT8 inputs
  //     // Take care of the order
  //     // A_INT8[7-0] = stream2acc_0_data_i[7:0]
  //     // A_INT8[7-1] = stream2acc_1_data_i[15:8]
  //     A_INT8[8-1-i] = stream2acc_0_data_i[i*8+:8];
  //     B_INT8[8-1-i] = stream2acc_1_data_i[i*8+:8];

  //     // FP8 inputs
  //     for (int j = 0; j < 4; j++) begin
  //       A_FP8[8-1-i][4-1-j] = stream2acc_0_data_i[(i*32)+(j*8)+:8];
  //       B_FP8[8-1-i][4-1-j] = stream2acc_1_data_i[(i*32)+(j*8)+:8];
  //     end

  //     // FP6 inputs
  //     for (int j = 0; j < 4; j++) begin
  //       A_FP6[8-1-i][4-1-j] = stream2acc_0_data_i[(i*24)+(j*6)+:6];
  //       B_FP6[8-1-i][4-1-j] = stream2acc_1_data_i[(i*24)+(j*6)+:6];
  //     end

  //     // FP4 inputs
  //     for (int j = 0; j < 8; j++) begin
  //       A_FP4[8-1-i][8-1-j] = stream2acc_0_data_i[(i*32)+(j*4)+:4];
  //       B_FP4[8-1-i][8-1-j] = stream2acc_1_data_i[(i*32)+(j*4)+:4];
  //     end
  //   end

  //   shared_exp_A = stream2acc_2_data_i[7 : 0];  // Default shared exponent of A
  //   shared_exp_B = stream2acc_2_data_i[15 : 8];  // Default shared exponent of B
  // end

  //--------------------------------------------------------------
  // Data distribution – generate-for version
  //--------------------------------------------------------------

  generate
    // ----------------------------------------------------------
    // Top-level loop over the 8 vector lanes
    // ----------------------------------------------------------
    for (genvar i = 0; i < 8; i = i + 1) begin : gen_i_loop
      //--------------------------------------------------------
      // INT8 inputs (1 byte per element)
      //--------------------------------------------------------
      // A_INT8[7-0]  <= stream2acc_0_data_i[7:0]
      // A_INT8[7-1] <= stream2acc_1_data_i[15:8]
      assign A_INT8[8-1-i] = stream2acc_0_data_i[i*8+:8];
      assign B_INT8[8-1-i] = stream2acc_1_data_i[i*8+:8];

      //--------------------------------------------------------
      // FP8 inputs (4 elements × 8 bits inside the 32-bit lane)
      //--------------------------------------------------------
      for (genvar j = 0; j < 4; j = j + 1) begin : gen_j_fp8_loop
        assign A_FP8[8-1-i][4-1-j] = stream2acc_0_data_i[(i*32)+(j*8)+:8];
        assign B_FP8[8-1-i][4-1-j] = stream2acc_1_data_i[(i*32)+(j*8)+:8];
      end

      //--------------------------------------------------------
      // FP6 inputs (4 elements × 6 bits inside a 24-bit slice)
      //--------------------------------------------------------
      for (genvar j = 0; j < 4; j = j + 1) begin : gen_j_fp6_loop
        assign A_FP6[8-1-i][4-1-j] = stream2acc_0_data_i[(i*24)+(j*6)+:6];
        assign B_FP6[8-1-i][4-1-j] = stream2acc_1_data_i[(i*24)+(j*6)+:6];
      end

      //--------------------------------------------------------
      // FP4 inputs (8 elements × 4 bits inside a 32-bit slice)
      //--------------------------------------------------------
      for (genvar  j = 0; j < 8; j = j + 1) begin : gen_j_fp4_loop
        assign A_FP4[8-1-i][8-1-j] = stream2acc_0_data_i[(i*32)+(j*4)+:4];
        assign B_FP4[8-1-i][8-1-j] = stream2acc_1_data_i[(i*32)+(j*4)+:4];
      end
    end
  endgenerate

  //--------------------------------------------------------------
  // Shared default exponents
  //--------------------------------------------------------------
  assign shared_exp_A = stream2acc_2_data_i[7 : 0];
  assign shared_exp_B = stream2acc_2_data_i[15 : 8];

  // Output data gathering
  always_comb begin
    acc2stream_0_data_o = '0;
    for (int i = 0; i < 8; i++) begin
      for (int j = 0; j < 8; j++) begin
        acc2stream_0_data_o[(i*64)+(j*8)+:8] = Out[8-1-i][8-1-j];
      end
    end
    acc2stream_0_data_o[StreamCDataWidth-1-64+:8] = shared_exp_out;
  end

  logic A_valid;
  logic B_valid;
  logic A_ready;
  logic B_ready;
  logic send_output;
  // logic O_valid_delay1;
  // logic O_valid_delay2;

  // always_ff @(posedge clk_i or negedge rst_ni) begin
  //   if (rst_ni == 1'b0) begin
  //     O_valid_delay1 <= 1'b0;
  //     O_valid_delay2 <= 1'b0;
  //   end else begin
  //     O_valid_delay1 <= send_output;
  //     O_valid_delay2 <= O_valid_delay1;
  //   end
  // end

  // M_out_width is ony Mantissa width of output, so for FP32 should be 23 not 32
  Block_PE_wrapper #(
  // .M_out_width(23) // Use the one default in the block PE
  ) Block_PE_wrapper_i (
      .clk_i(clk_i),
      .rstn (rst_ni),

      // Control Signals for inputs
      .prec_mode(csr_reg_set_buffer[0][1:0]),  // Precision mode for MACs
      .FP_mode  (csr_reg_set_buffer[0][3:2]),  // FP mode for MACs

      .prec_mode_quan(csr_reg_set_buffer[0][5:4]),  // Precision mode for quantization
      .FP_mode_quan  (csr_reg_set_buffer[0][7:6]),  // FP mode for quantization

      .A_valid(A_valid),  //Stef: if both 1 then accumulate
      .B_valid(B_valid),  //Stef: if both 1 then accumulate
      .A_ready(A_ready),               // Ready signal for A input
      .B_ready(B_ready),               // Ready signal for B input

      // Data Inputs
      .A_INT8(A_INT8),  // [0:7][7:0] 64-bit INT8 input A
      .B_INT8(B_INT8),  // [0:7][7:0] 64-bit INT8 input B

      .A_FP8(A_FP8),  // [0:7][0:3][7:0] 256-bit FP8 input A
      .B_FP8(B_FP8),  // [0:7][0:3][7:0] 256-bit FP8 input B

      .A_FP6(A_FP6),  // [0:7][0:3][5:0] 192-bit FP6 input A
      .B_FP6(B_FP6),  // [0:7][0:3][5:0] 192-bit FP6 input B

      .A_FP4(A_FP4),  // [0:7][0:7][3:0] 256-bit FP4 input A
      .B_FP4(B_FP4),  // [0:7][0:7][3:0] 256-bit FP4 input B

      .shared_exp_A(shared_exp_A),  // 8-bit shared exponent A
      .shared_exp_B(shared_exp_B),  // 8-bit shared exponent B

      // Control signal for output
      // Stef: when high the quantization happens and we get an output
      // So if assert this signal, make sure to take the data once the output valid is high (highest priority, no backpressure)
      .send_output(send_output),  // Control signal for output

      // Data Outputs
      .Out           (Out),            // [0:7][0:7][7:0] Output data
      .shared_exp_out(shared_exp_out)  // 8-bit shared exponent output

      // !!!missing port!!!
      // .O_valid(O_valid),
      // .O_ready           (O_ready),

  );

  // -----------------------------------------------------------
  // -----------------------------------------------------------
  // handshake logic
  // -----------------------------------------------------------
  // -----------------------------------------------------------

  // considering the back pressure signal from the streamer
  logic keep_output;
  logic next_cycle_keep_output;
  // Keep output valid in the next cycle if streamer is ready
  assign next_cycle_keep_output = acc2stream_0_valid_o && !acc2stream_0_ready_i;
  always_ff @(posedge clk_i or negedge rst_ni) begin : blockName
    if (rst_ni == 1'b0) begin
      keep_output <= 1'b0;  // Reset current_state
    end else begin
      keep_output <= next_cycle_keep_output;
    end
  end

  // computation_fire if all the input fires
  logic computation_fire;
  logic all_input_valid;
  assign all_input_valid = stream2acc_0_valid_i && stream2acc_1_valid_i && stream2acc_2_valid_i;
  logic all_input_ready;
  assign all_input_ready = stream2acc_0_ready_o && stream2acc_1_ready_o && stream2acc_2_ready_o;
  assign computation_fire = all_input_valid && all_input_ready && acc_busy;

  assign stream2acc_0_ready_o = all_input_valid && A_ready && acc_busy && !next_cycle_keep_output;
  assign stream2acc_1_ready_o = all_input_valid && B_ready && acc_busy && !next_cycle_keep_output;
  assign stream2acc_2_ready_o = stream2acc_0_ready_o && stream2acc_1_ready_o;

  logic [31:0] computation_fire_counter;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      computation_fire_counter <= 32'b0;  // Reset counter
    end else begin
      if (computation_fire && (computation_fire_counter <= csr_reg_set_buffer[1] - 1)) begin
        computation_fire_counter <= computation_fire_counter + 1;
      end else if (send_output) begin
        computation_fire_counter <= 32'b0;  // Reset counter on output fire once give the send_out signal
      end else if (current_state == IDLE) begin
        computation_fire_counter <= 32'b0;  // Reset counter on current_state change
      end
    end
  end

  assign A_valid = computation_fire;
  assign B_valid = computation_fire;

  // after programmed time of success computation, set the send_output signal to 1 only when there is on stall on the output
  assign send_output = (computation_fire_counter == csr_reg_set_buffer[1]) && acc2stream_0_ready_i && acc_busy;

  assign acc2stream_0_valid_o = send_output && acc_busy;

  assign csr_reg_set_ready_o = ~acc_busy;  // Always ready to accept CSR writes

  assign csr_reg_ro_set_o[0] = {31'b0, acc_busy};  // read-only CSR value

  logic [31:0] performance_counter;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      performance_counter <= 32'b0;  // Reset counter
    end else begin
      if (current_state == BUSY) begin
        performance_counter <= performance_counter + 1;
      end else if (config_fire) begin
        performance_counter <= 32'b0;  // Reset counter on config fire
      end
    end
  end

  assign csr_reg_ro_set_o[1] = performance_counter;

endmodule
