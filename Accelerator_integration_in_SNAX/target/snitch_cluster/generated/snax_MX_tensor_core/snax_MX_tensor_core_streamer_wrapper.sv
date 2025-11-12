// Copyright 2024 KU Leuven.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51


//-----------------------------
// Streamer wrapper
//-----------------------------
module snax_MX_tensor_core_streamer_wrapper #(
  // TCDM typedefs
  parameter type         tcdm_req_t    = logic,
  parameter type         tcdm_rsp_t    = logic,
  // Parameters related to TCDM
  parameter int unsigned TCDMDataWidth = 64,
  parameter int unsigned TCDMNumPorts  = 18,
  parameter int unsigned TCDMAddrWidth = 17
)(
  //-----------------------------
  // Clocks and reset
  //-----------------------------
  // clock from accelerator domain
  input  logic clk_i,
  input  logic rst_ni,
  //-----------------------------
  // Accelerator ports
  //-----------------------------
  // Ports from accelerator to streamer by writer data movers
  input  logic [575:0] acc2stream_0_data_i,
  input  logic acc2stream_0_valid_i,
  output logic acc2stream_0_ready_o,

  // Ports from streamer to accelerator by reader data movers
  output logic [255:0] stream2acc_0_data_o,
  output logic stream2acc_0_valid_o,
  input  logic stream2acc_0_ready_i,

  output logic [255:0] stream2acc_1_data_o,
  output logic stream2acc_1_valid_o,
  input  logic stream2acc_1_ready_i,

  output logic [63:0] stream2acc_2_data_o,
  output logic stream2acc_2_valid_o,
  input  logic stream2acc_2_ready_i,

  //-----------------------------
  // TCDM ports
  //-----------------------------
  output tcdm_req_t [TCDMNumPorts-1:0] tcdm_req_o,
  input  tcdm_rsp_t [TCDMNumPorts-1:0] tcdm_rsp_i,
  //-----------------------------
  // CSR control ports
  //-----------------------------
  // Request
  input  logic [31:0] csr_req_bits_data_i,
  input  logic [31:0] csr_req_bits_addr_i,
  input  logic        csr_req_bits_write_i,
  input  logic        csr_req_valid_i,
  output logic        csr_req_ready_o,
  // Response
  output logic [31:0] csr_rsp_bits_data_o,
  output logic        csr_rsp_valid_o,
  input  logic        csr_rsp_ready_i
);

  //-----------------------------
  // Wiring and combinational logic
  //-----------------------------

  // TCDM signals
  // Request
  logic [TCDMNumPorts-1:0][  TCDMAddrWidth-1:0] tcdm_req_addr;
  logic [TCDMNumPorts-1:0]                      tcdm_req_write;
  //Note that tcdm_req_amo_i is 4 bits based on reqrsp definition
  logic [TCDMNumPorts-1:0][                3:0] tcdm_req_amo;
  logic [TCDMNumPorts-1:0][  TCDMDataWidth-1:0] tcdm_req_data;
  logic [TCDMNumPorts-1:0][TCDMDataWidth/8-1:0] tcdm_req_strb;
  //Note that tcdm_req_user_core_id_i is 5 bits based on Snitch definition
  logic [TCDMNumPorts-1:0][                4:0] tcdm_req_user_core_id;
  logic [TCDMNumPorts-1:0]                      tcdm_req_user_is_core;
  logic [TCDMNumPorts-1:0]                      tcdm_req_q_valid;

  // Response
  logic [TCDMNumPorts-1:0]                      tcdm_rsp_q_ready;
  logic [TCDMNumPorts-1:0]                      tcdm_rsp_p_valid;
  logic [TCDMNumPorts-1:0][  TCDMDataWidth-1:0] tcdm_rsp_data;

  // Fixed ports that are defaulted to tie-low
  // towards the TCDM from the streamer
  always_comb begin
    for(int i = 0; i < TCDMNumPorts; i++ ) begin
      tcdm_req_amo          [i] = '0;
      tcdm_req_user_core_id [i] = '0;
      tcdm_req_user_is_core [i] = '0;
    end
  end

  // Re-mapping wires for TCDM IO ports
  always_comb begin
    for ( int i = 0; i < TCDMNumPorts; i++) begin
      tcdm_req_o[i].q.addr         = tcdm_req_addr   [i];
      tcdm_req_o[i].q.write        = tcdm_req_write  [i];
      tcdm_req_o[i].q.amo          = reqrsp_pkg::AMONone;
      tcdm_req_o[i].q.data         = tcdm_req_data   [i];
      tcdm_req_o[i].q.strb         = tcdm_req_strb   [i];
      tcdm_req_o[i].q.user.core_id = '0;
      tcdm_req_o[i].q.user.is_core = '0;
      tcdm_req_o[i].q_valid        = tcdm_req_q_valid[i];

      tcdm_rsp_q_ready[i] = tcdm_rsp_i[i].q_ready;
      tcdm_rsp_p_valid[i] = tcdm_rsp_i[i].p_valid;
      tcdm_rsp_data   [i] = tcdm_rsp_i[i].p.data ;
    end
  end
  

  // Streamer module that is generated
  // with template mechanics
  snax_MX_tensor_core_Streamer i_snax_MX_tensor_core_streamer_top (	
    //-----------------------------
    // Clocks and reset
    //-----------------------------
    // clock from accelerator domain
    .clock ( clk_i   ),
    .reset ( ~rst_ni ),

    //-----------------------------
    // Accelerator ports
    //-----------------------------
    // Ports from accelerator to streamer by writer data movers
    .io_data_accelerator2streamer_data_0_bits  (  acc2stream_0_data_i ),
    .io_data_accelerator2streamer_data_0_valid ( acc2stream_0_valid_i ),
    .io_data_accelerator2streamer_data_0_ready ( acc2stream_0_ready_o ),

    // Ports from streamer to accelerator by reader data movers
    .io_data_streamer2accelerator_data_0_bits  (  stream2acc_0_data_o ),
    .io_data_streamer2accelerator_data_0_valid ( stream2acc_0_valid_o ),
    .io_data_streamer2accelerator_data_0_ready ( stream2acc_0_ready_i ),

    .io_data_streamer2accelerator_data_1_bits  (  stream2acc_1_data_o ),
    .io_data_streamer2accelerator_data_1_valid ( stream2acc_1_valid_o ),
    .io_data_streamer2accelerator_data_1_ready ( stream2acc_1_ready_i ),

    .io_data_streamer2accelerator_data_2_bits  (  stream2acc_2_data_o ),
    .io_data_streamer2accelerator_data_2_valid ( stream2acc_2_valid_o ),
    .io_data_streamer2accelerator_data_2_ready ( stream2acc_2_ready_i ),

    //-----------------------------
    // TCDM Ports
    //-----------------------------
    // Request
    .io_data_tcdm_rsp_0_bits_data  ( tcdm_rsp_data   [0] ),
    .io_data_tcdm_rsp_0_valid      ( tcdm_rsp_p_valid[0] ),
    .io_data_tcdm_req_0_ready      ( tcdm_rsp_q_ready[0] ),

    .io_data_tcdm_rsp_1_bits_data  ( tcdm_rsp_data   [1] ),
    .io_data_tcdm_rsp_1_valid      ( tcdm_rsp_p_valid[1] ),
    .io_data_tcdm_req_1_ready      ( tcdm_rsp_q_ready[1] ),

    .io_data_tcdm_rsp_2_bits_data  ( tcdm_rsp_data   [2] ),
    .io_data_tcdm_rsp_2_valid      ( tcdm_rsp_p_valid[2] ),
    .io_data_tcdm_req_2_ready      ( tcdm_rsp_q_ready[2] ),

    .io_data_tcdm_rsp_3_bits_data  ( tcdm_rsp_data   [3] ),
    .io_data_tcdm_rsp_3_valid      ( tcdm_rsp_p_valid[3] ),
    .io_data_tcdm_req_3_ready      ( tcdm_rsp_q_ready[3] ),

    .io_data_tcdm_rsp_4_bits_data  ( tcdm_rsp_data   [4] ),
    .io_data_tcdm_rsp_4_valid      ( tcdm_rsp_p_valid[4] ),
    .io_data_tcdm_req_4_ready      ( tcdm_rsp_q_ready[4] ),

    .io_data_tcdm_rsp_5_bits_data  ( tcdm_rsp_data   [5] ),
    .io_data_tcdm_rsp_5_valid      ( tcdm_rsp_p_valid[5] ),
    .io_data_tcdm_req_5_ready      ( tcdm_rsp_q_ready[5] ),

    .io_data_tcdm_rsp_6_bits_data  ( tcdm_rsp_data   [6] ),
    .io_data_tcdm_rsp_6_valid      ( tcdm_rsp_p_valid[6] ),
    .io_data_tcdm_req_6_ready      ( tcdm_rsp_q_ready[6] ),

    .io_data_tcdm_rsp_7_bits_data  ( tcdm_rsp_data   [7] ),
    .io_data_tcdm_rsp_7_valid      ( tcdm_rsp_p_valid[7] ),
    .io_data_tcdm_req_7_ready      ( tcdm_rsp_q_ready[7] ),

    .io_data_tcdm_rsp_8_bits_data  ( tcdm_rsp_data   [8] ),
    .io_data_tcdm_rsp_8_valid      ( tcdm_rsp_p_valid[8] ),
    .io_data_tcdm_req_8_ready      ( tcdm_rsp_q_ready[8] ),

    .io_data_tcdm_rsp_9_bits_data  ( tcdm_rsp_data   [9] ),
    .io_data_tcdm_rsp_9_valid      ( tcdm_rsp_p_valid[9] ),
    .io_data_tcdm_req_9_ready      ( tcdm_rsp_q_ready[9] ),

    .io_data_tcdm_rsp_10_bits_data  ( tcdm_rsp_data   [10] ),
    .io_data_tcdm_rsp_10_valid      ( tcdm_rsp_p_valid[10] ),
    .io_data_tcdm_req_10_ready      ( tcdm_rsp_q_ready[10] ),

    .io_data_tcdm_rsp_11_bits_data  ( tcdm_rsp_data   [11] ),
    .io_data_tcdm_rsp_11_valid      ( tcdm_rsp_p_valid[11] ),
    .io_data_tcdm_req_11_ready      ( tcdm_rsp_q_ready[11] ),

    .io_data_tcdm_rsp_12_bits_data  ( tcdm_rsp_data   [12] ),
    .io_data_tcdm_rsp_12_valid      ( tcdm_rsp_p_valid[12] ),
    .io_data_tcdm_req_12_ready      ( tcdm_rsp_q_ready[12] ),

    .io_data_tcdm_rsp_13_bits_data  ( tcdm_rsp_data   [13] ),
    .io_data_tcdm_rsp_13_valid      ( tcdm_rsp_p_valid[13] ),
    .io_data_tcdm_req_13_ready      ( tcdm_rsp_q_ready[13] ),

    .io_data_tcdm_rsp_14_bits_data  ( tcdm_rsp_data   [14] ),
    .io_data_tcdm_rsp_14_valid      ( tcdm_rsp_p_valid[14] ),
    .io_data_tcdm_req_14_ready      ( tcdm_rsp_q_ready[14] ),

    .io_data_tcdm_rsp_15_bits_data  ( tcdm_rsp_data   [15] ),
    .io_data_tcdm_rsp_15_valid      ( tcdm_rsp_p_valid[15] ),
    .io_data_tcdm_req_15_ready      ( tcdm_rsp_q_ready[15] ),

    .io_data_tcdm_rsp_16_bits_data  ( tcdm_rsp_data   [16] ),
    .io_data_tcdm_rsp_16_valid      ( tcdm_rsp_p_valid[16] ),
    .io_data_tcdm_req_16_ready      ( tcdm_rsp_q_ready[16] ),

    .io_data_tcdm_rsp_17_bits_data  ( tcdm_rsp_data   [17] ),
    .io_data_tcdm_rsp_17_valid      ( tcdm_rsp_p_valid[17] ),
    .io_data_tcdm_req_17_ready      ( tcdm_rsp_q_ready[17] ),

    // Response
    .io_data_tcdm_req_0_valid      ( tcdm_req_q_valid[0] ),
    .io_data_tcdm_req_0_bits_addr  ( tcdm_req_addr   [0] ),
    .io_data_tcdm_req_0_bits_write ( tcdm_req_write  [0] ),
    .io_data_tcdm_req_0_bits_data  ( tcdm_req_data   [0] ),
    .io_data_tcdm_req_0_bits_strb  ( tcdm_req_strb   [0] ),

    .io_data_tcdm_req_1_valid      ( tcdm_req_q_valid[1] ),
    .io_data_tcdm_req_1_bits_addr  ( tcdm_req_addr   [1] ),
    .io_data_tcdm_req_1_bits_write ( tcdm_req_write  [1] ),
    .io_data_tcdm_req_1_bits_data  ( tcdm_req_data   [1] ),
    .io_data_tcdm_req_1_bits_strb  ( tcdm_req_strb   [1] ),

    .io_data_tcdm_req_2_valid      ( tcdm_req_q_valid[2] ),
    .io_data_tcdm_req_2_bits_addr  ( tcdm_req_addr   [2] ),
    .io_data_tcdm_req_2_bits_write ( tcdm_req_write  [2] ),
    .io_data_tcdm_req_2_bits_data  ( tcdm_req_data   [2] ),
    .io_data_tcdm_req_2_bits_strb  ( tcdm_req_strb   [2] ),

    .io_data_tcdm_req_3_valid      ( tcdm_req_q_valid[3] ),
    .io_data_tcdm_req_3_bits_addr  ( tcdm_req_addr   [3] ),
    .io_data_tcdm_req_3_bits_write ( tcdm_req_write  [3] ),
    .io_data_tcdm_req_3_bits_data  ( tcdm_req_data   [3] ),
    .io_data_tcdm_req_3_bits_strb  ( tcdm_req_strb   [3] ),

    .io_data_tcdm_req_4_valid      ( tcdm_req_q_valid[4] ),
    .io_data_tcdm_req_4_bits_addr  ( tcdm_req_addr   [4] ),
    .io_data_tcdm_req_4_bits_write ( tcdm_req_write  [4] ),
    .io_data_tcdm_req_4_bits_data  ( tcdm_req_data   [4] ),
    .io_data_tcdm_req_4_bits_strb  ( tcdm_req_strb   [4] ),

    .io_data_tcdm_req_5_valid      ( tcdm_req_q_valid[5] ),
    .io_data_tcdm_req_5_bits_addr  ( tcdm_req_addr   [5] ),
    .io_data_tcdm_req_5_bits_write ( tcdm_req_write  [5] ),
    .io_data_tcdm_req_5_bits_data  ( tcdm_req_data   [5] ),
    .io_data_tcdm_req_5_bits_strb  ( tcdm_req_strb   [5] ),

    .io_data_tcdm_req_6_valid      ( tcdm_req_q_valid[6] ),
    .io_data_tcdm_req_6_bits_addr  ( tcdm_req_addr   [6] ),
    .io_data_tcdm_req_6_bits_write ( tcdm_req_write  [6] ),
    .io_data_tcdm_req_6_bits_data  ( tcdm_req_data   [6] ),
    .io_data_tcdm_req_6_bits_strb  ( tcdm_req_strb   [6] ),

    .io_data_tcdm_req_7_valid      ( tcdm_req_q_valid[7] ),
    .io_data_tcdm_req_7_bits_addr  ( tcdm_req_addr   [7] ),
    .io_data_tcdm_req_7_bits_write ( tcdm_req_write  [7] ),
    .io_data_tcdm_req_7_bits_data  ( tcdm_req_data   [7] ),
    .io_data_tcdm_req_7_bits_strb  ( tcdm_req_strb   [7] ),

    .io_data_tcdm_req_8_valid      ( tcdm_req_q_valid[8] ),
    .io_data_tcdm_req_8_bits_addr  ( tcdm_req_addr   [8] ),
    .io_data_tcdm_req_8_bits_write ( tcdm_req_write  [8] ),
    .io_data_tcdm_req_8_bits_data  ( tcdm_req_data   [8] ),
    .io_data_tcdm_req_8_bits_strb  ( tcdm_req_strb   [8] ),

    .io_data_tcdm_req_9_valid      ( tcdm_req_q_valid[9] ),
    .io_data_tcdm_req_9_bits_addr  ( tcdm_req_addr   [9] ),
    .io_data_tcdm_req_9_bits_write ( tcdm_req_write  [9] ),
    .io_data_tcdm_req_9_bits_data  ( tcdm_req_data   [9] ),
    .io_data_tcdm_req_9_bits_strb  ( tcdm_req_strb   [9] ),

    .io_data_tcdm_req_10_valid      ( tcdm_req_q_valid[10] ),
    .io_data_tcdm_req_10_bits_addr  ( tcdm_req_addr   [10] ),
    .io_data_tcdm_req_10_bits_write ( tcdm_req_write  [10] ),
    .io_data_tcdm_req_10_bits_data  ( tcdm_req_data   [10] ),
    .io_data_tcdm_req_10_bits_strb  ( tcdm_req_strb   [10] ),

    .io_data_tcdm_req_11_valid      ( tcdm_req_q_valid[11] ),
    .io_data_tcdm_req_11_bits_addr  ( tcdm_req_addr   [11] ),
    .io_data_tcdm_req_11_bits_write ( tcdm_req_write  [11] ),
    .io_data_tcdm_req_11_bits_data  ( tcdm_req_data   [11] ),
    .io_data_tcdm_req_11_bits_strb  ( tcdm_req_strb   [11] ),

    .io_data_tcdm_req_12_valid      ( tcdm_req_q_valid[12] ),
    .io_data_tcdm_req_12_bits_addr  ( tcdm_req_addr   [12] ),
    .io_data_tcdm_req_12_bits_write ( tcdm_req_write  [12] ),
    .io_data_tcdm_req_12_bits_data  ( tcdm_req_data   [12] ),
    .io_data_tcdm_req_12_bits_strb  ( tcdm_req_strb   [12] ),

    .io_data_tcdm_req_13_valid      ( tcdm_req_q_valid[13] ),
    .io_data_tcdm_req_13_bits_addr  ( tcdm_req_addr   [13] ),
    .io_data_tcdm_req_13_bits_write ( tcdm_req_write  [13] ),
    .io_data_tcdm_req_13_bits_data  ( tcdm_req_data   [13] ),
    .io_data_tcdm_req_13_bits_strb  ( tcdm_req_strb   [13] ),

    .io_data_tcdm_req_14_valid      ( tcdm_req_q_valid[14] ),
    .io_data_tcdm_req_14_bits_addr  ( tcdm_req_addr   [14] ),
    .io_data_tcdm_req_14_bits_write ( tcdm_req_write  [14] ),
    .io_data_tcdm_req_14_bits_data  ( tcdm_req_data   [14] ),
    .io_data_tcdm_req_14_bits_strb  ( tcdm_req_strb   [14] ),

    .io_data_tcdm_req_15_valid      ( tcdm_req_q_valid[15] ),
    .io_data_tcdm_req_15_bits_addr  ( tcdm_req_addr   [15] ),
    .io_data_tcdm_req_15_bits_write ( tcdm_req_write  [15] ),
    .io_data_tcdm_req_15_bits_data  ( tcdm_req_data   [15] ),
    .io_data_tcdm_req_15_bits_strb  ( tcdm_req_strb   [15] ),

    .io_data_tcdm_req_16_valid      ( tcdm_req_q_valid[16] ),
    .io_data_tcdm_req_16_bits_addr  ( tcdm_req_addr   [16] ),
    .io_data_tcdm_req_16_bits_write ( tcdm_req_write  [16] ),
    .io_data_tcdm_req_16_bits_data  ( tcdm_req_data   [16] ),
    .io_data_tcdm_req_16_bits_strb  ( tcdm_req_strb   [16] ),

    .io_data_tcdm_req_17_valid      ( tcdm_req_q_valid[17] ),
    .io_data_tcdm_req_17_bits_addr  ( tcdm_req_addr   [17] ),
    .io_data_tcdm_req_17_bits_write ( tcdm_req_write  [17] ),
    .io_data_tcdm_req_17_bits_data  ( tcdm_req_data   [17] ),
    .io_data_tcdm_req_17_bits_strb  ( tcdm_req_strb   [17] ),

    //-----------------------------
    // CSR control ports
    //-----------------------------
    // Request
    .io_csr_req_bits_data  ( csr_req_bits_data_i  ),
    .io_csr_req_bits_addr  ( csr_req_bits_addr_i  ),
    .io_csr_req_bits_write ( csr_req_bits_write_i ),
    .io_csr_req_bits_strb  ( '1                   ),
    .io_csr_req_valid      ( csr_req_valid_i      ),
    .io_csr_req_ready      ( csr_req_ready_o      ),

    // Response
    .io_csr_rsp_bits_data  ( csr_rsp_bits_data_o  ),	
    .io_csr_rsp_valid      ( csr_rsp_valid_o      ),
    .io_csr_rsp_ready      ( csr_rsp_ready_i      )
  );

endmodule
