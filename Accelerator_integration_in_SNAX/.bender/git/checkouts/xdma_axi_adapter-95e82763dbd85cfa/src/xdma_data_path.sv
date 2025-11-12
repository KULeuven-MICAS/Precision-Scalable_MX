// Fanchen Kong <fanchen.kong@kuleuven.be>
// Yunhao Deng <yunhao.deng@kuleuven.be>

module xdma_data_path #(
    parameter type data_t = logic,
    parameter type strb_t = logic,
    // typedef struct packed {
    //     logic [7:0]                         num_beats;
    //     logic                               is_single;
    //     logic                               is_write_data;
    // } xdma_req_w_desc_t;    
    parameter type xdma_req_w_desc_t = logic
) (
    /// Clock
    input  logic             clk_i,
    /// Asynchronous reset, active low
    input  logic             rst_ni,
    //
    input  data_t            write_req_data_i,
    //
    input  logic             write_req_data_valid_i,
    //
    output logic             write_req_data_ready_o,
    //
    input  xdma_req_w_desc_t w_desc_i,
    input  logic             w_dp_valid_i,
    output logic             w_dp_ready_o,
    // w-channel
    /// Write data of the AXI bus
    output data_t            w_data_o,
    /// Write strobe of the AXI bus
    output strb_t            w_strb_o,
    /// Last signal of the AXI w channel
    output logic             w_last_o,
    /// Valid signal of the AXI w channel
    output logic             w_valid_o,
    /// Ready signal of the AXI w channel
    input  logic             w_ready_i,
    // Grant signal
    // When we issue a write request:
    //  1.CFG will first send to the remote
    //  2.The remote will send back a grant signal to permit this send
    //  3.Then the data can send to remote
    //  So we have to monitor the grant signal to back pressure the data_ready_o signal
    // When we issue a read request:
    //  1.CFG will first send to the remote
    //  2.Wait the remote sends the data
    input  logic             write_req_grant_i
);
  logic counter_clear;
  logic counter_en;
  logic counter_load;
  logic [7:0] beats_counter_q;
  counter #(
      .WIDTH(8)
  ) i_lens_counter (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .clear_i   (counter_clear),
      .en_i      (counter_en),
      .load_i    (counter_load),
      .down_i    (1'b0),
      .d_i       ('0),
      .q_o       (beats_counter_q),
      .overflow_o()
  );

  typedef enum logic [0:0] {
    IDLE,
    BUSY
  } state_t;
  state_t cur_state, next_state;

  // State Update
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      cur_state <= IDLE;
    end else begin
      cur_state <= next_state;
    end
  end

  // Output + Next State logic
  always_comb begin : proc_output_logic
    next_state = cur_state;
    w_data_o = 1'b0;
    w_strb_o = 1'b0;
    w_last_o = 1'b0;
    w_valid_o = 1'b0;
    w_dp_ready_o = 1'b0;
    counter_clear = 1'b0;
    write_req_data_ready_o = 1'b0;
    counter_en = 1'b0;
    counter_load = 1'b0;

    case (cur_state)
      IDLE: begin
        // Wait the w desc is valid
        if (w_dp_valid_i) begin
          next_state   = BUSY;
          counter_load = 1'b1;
        end
      end
      BUSY: begin
        w_data_o = write_req_data_i;
        w_strb_o = '1;
        w_valid_o = (w_desc_i.is_write_data)? (write_req_grant_i && write_req_data_valid_i) : write_req_data_valid_i;
        write_req_data_ready_o = (w_desc_i.is_write_data)? (write_req_grant_i && w_ready_i) : w_ready_i;
        counter_en = w_valid_o && w_ready_i;
        counter_load = 1'b0;
        if ((beats_counter_q == w_desc_i.num_beats - 1) && w_valid_o && w_ready_i) begin
          counter_clear = 1'b1;
          w_last_o = 1'b1;
          w_dp_ready_o = 1'b1;
        end
        if (!w_dp_valid_i) next_state = IDLE;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end


  // logic [7:0] w_num_beats_d, w_num_beats_q;
  // logic w_cnt_valid_d, w_cnt_valid_q;
  // logic write_happening;
  // logic is_last_w;
  // logic is_first_w;
  // always_comb begin : proc_write_control
  //   // counter
  //   w_num_beats_d   = w_num_beats_q;
  //   w_cnt_valid_d   = w_cnt_valid_q;
  //   // bus signals
  //   w_valid_o       = write_req_data_valid_i & w_dp_valid_i;
  //   w_data_o        = write_req_data_i;
  //   w_strb_o        = '1;
  //   w_last_o        = 1'b0;
  //   // first/last
  //   is_last_w       = 1'b0;
  //   // data flow
  //   w_dp_ready_o    = 1'b0;
  //   // If the current w is write data request
  //   // it can not be sent unless the grant_i is high
  //   // for other cases it can send only the w_ready_i permits
  //   write_req_data_ready_o    = (w_desc_i.is_write_data)? (write_req_grant_i & w_ready_i) : w_ready_i;
  //   // handshake signal
  //   write_happening = w_valid_o & w_ready_i;


  //   // differentiate between the burst and non-burst case. If a transfer
  //   // consists just of one beat the counters are disabled
  //   if (w_desc_i.is_single) begin
  //     // in the single case the transfer is last.
  //     is_last_w  = 1'b1;

  //     // in the bursted case the counters are needed to keep track of the progress of sending
  //     // beats. The w_last_o depends on the state of the counter
  //   end else begin
  //     // first transfer happens as soon as the counter is currently invalid
  //     is_first_w = ~w_cnt_valid_q;

  //     // last happens as soon as a) the counter is valid and b) the counter is now down to 1
  //     is_last_w  = w_cnt_valid_q & (w_num_beats_q == 8'h01);

  //     // load the counter with data in a first cycle, only modifying state if bus is ready
  //     if (is_first_w && write_happening) begin
  //       w_num_beats_d = w_desc_i.num_beats;
  //       w_cnt_valid_d = 1'b1;
  //     end

  //     // if we hit the last element, invalidate the counter, only modifying state
  //     // if bus is ready
  //     if (is_last_w && write_happening) begin
  //       w_cnt_valid_d = 1'b0;
  //     end

  //     // count down the beats if the counter is valid and valid data is written to the bus
  //     if (w_cnt_valid_q && write_happening) w_num_beats_d = w_num_beats_q - 8'h01;
  //   end
  //   // the w_last_o signal should only be applied to the bus if an actual transfer happens
  //   w_last_o = is_last_w & write_req_data_valid_i;
  //   // we are ready for the next transfer internally, once the w_last_o signal is applied
  //   w_dp_ready_o = is_last_w & write_happening;
  // end


  // //--------------------------------------
  // // Module Control
  // //-------------------------------------    
  // always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ff
  //   if (!rst_ni) begin
  //     w_cnt_valid_q <= 1'b0;
  //     w_num_beats_q <= 8'h0;
  //   end else begin
  //     w_cnt_valid_q <= w_cnt_valid_d;
  //     w_num_beats_q <= w_num_beats_d;
  //   end
  // end    
endmodule
