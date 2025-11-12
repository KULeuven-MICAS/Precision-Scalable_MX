// Authors:
// - Fanchen Kong <fanchen.kong@kuleuven.be>
// - Yunhao Deng <yunhao.deng@kuleuven.be>

/// This module tracks the handshake signal for the w 
// and output the trans_complete once the required data is sent to axi
// here we do not care on the b.valid

module xdma_meta_manager #(
    parameter type         xdma_req_meta_t = logic,
    parameter type         id_t            = logic,
    parameter type         len_t           = logic,
    //Dependent parameter
    parameter int unsigned LenWidth        = $bits(len_t)
) (
    /// Clock
    input  logic           clk_i,
    /// Asynchronous reset, active low
    input  logic           rst_ni,
    /// typedef struct packed {
    ///     id_t                                 dma_id;
    ///     len_t                                dma_length;
    /// } xdma_req_meta_t;     
    input  xdma_req_meta_t write_req_meta_i,
    /// one req is start
    input  logic           write_req_busy_i,
    /// Current transaction is done, valid for 1 CC
    output logic           write_req_done_o,
    /// Current DMA ID
    output id_t            cur_dma_id_o,
    /// AXI Handshake Signal
    input  logic           write_happening_i
);

  // The counter to count the number of data sent
  logic counter_en;
  logic counter_clear;
  len_t lens_counter_q;
  counter #(
      .WIDTH($bits(len_t))
  ) i_lens_counter (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .clear_i   (counter_clear),
      .en_i      (counter_en),
      .load_i    ('0),
      .down_i    (1'b0),
      .d_i       (write_req_meta_i.dma_length),
      .q_o       (lens_counter_q),
      .overflow_o()
  );

  typedef enum logic [1:0] {
    IDLE,
    BUSY,
    FINISH
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

  // Next state logic
  always_comb begin : proc_next_state_logic
    next_state = cur_state;
    case (cur_state)
      IDLE:   if (write_req_busy_i) next_state = BUSY;
      BUSY:   if (write_req_done_o) next_state = FINISH;
      FINISH: next_state = IDLE;
    endcase
  end

  // Counter Holder Register
  len_t lens_holder_q;
  logic lens_holder_en;
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      lens_holder_q <= '0;
    end else if (lens_holder_en) begin
      lens_holder_q <= write_req_meta_i.dma_length;
    end
  end

  // Output logic
  always_comb begin : proc_output_logic
    counter_en = 1'b0;
    counter_clear = 1'b0;
    lens_holder_en = 1'b0;
    write_req_done_o = 1'b0;
    cur_dma_id_o = 1'b0;
    case (cur_state)
      IDLE: begin
        if (write_req_busy_i) begin
          counter_clear = 1'b1;
          lens_holder_en = 1'b1;
        end
      end
      BUSY: begin
        counter_en = write_happening_i;
        write_req_done_o = (lens_counter_q == lens_holder_q - 1) && write_happening_i;
        cur_dma_id_o = write_req_meta_i.dma_id;
      end
      FINISH: begin
        counter_clear = 1'b1;
      end
    endcase
  end
endmodule
