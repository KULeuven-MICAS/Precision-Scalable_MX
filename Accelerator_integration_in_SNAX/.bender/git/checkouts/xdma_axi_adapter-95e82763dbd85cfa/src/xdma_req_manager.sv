// Authors:
// - Fanchen Kong <fanchen.kong@kuleuven.be>
// - Yunhao Deng <yunhao.deng@kuleuven.be>

/// When an input is holding the valid, it will only release after the done is high
module xdma_req_manager #(
    /// The data type
    /// Now we support the 512bit wide signal
    parameter type data_t = logic,
    /// typedef struct packed {
    ///     id_t                                 dma_id; 
    ///     logic                                dma_type;
    ///     addr_t                               remote_addr;
    ///     len_t                                dma_length;
    ///     logic                                ready_to_transfer;
    /// } xdma_req_desc_t;
    /// - dma_id:
    /// - dma_type:
    /// - remote_addr:
    /// - dma_length:
    /// - ready_to_transfer:
    parameter type xdma_req_desc_t = logic,
    parameter integer N_INP = 1,
    /// Dependent parameters, DO NOT OVERRIDE!
    parameter integer LOG_N_INP = $clog2(N_INP)
) (
    /// Clock
    input  logic                           clk_i,
    /// Asynchronous reset, active low
    input  logic                           rst_ni,
    /// input data
    input  data_t          [    N_INP-1:0] inp_data_i,
    input  logic           [    N_INP-1:0] inp_valid_i,
    output logic           [    N_INP-1:0] inp_ready_o,
    output data_t                          oup_data_o,
    output logic                           oup_valid_o,
    input  logic                           oup_ready_i,
    /// input req 
    input  xdma_req_desc_t [    N_INP-1:0] inp_desc_i,
    output xdma_req_desc_t                 oup_desc_o,
    //  Status signal
    output logic           [LOG_N_INP-1:0] idx_o,
    output logic                           start_o,
    output logic                           busy_o,
    // From the counter
    input  logic                           done_i
);

  logic [LOG_N_INP-1:0] grant_idx, grant_idx_d, grant_idx_q;
  logic grant_valid;
  // The state enum
  typedef enum logic [1:0] {
    IDLE,
    BUSY
  } state_t;
  state_t cur_state, next_state;
  find_first_one_idx #(
      .N(N_INP)
  ) i_find_idx (
      .in_i(inp_valid_i),
      .idx_o(grant_idx),
      .valid_o(grant_valid)
  );
  // State Update
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      grant_idx_q <= '0;
    end else begin
      grant_idx_q <= grant_idx_d;
    end
  end
  always_comb begin
    grant_idx_d = grant_idx_q;
    start_o = 1'b0;
    if (cur_state == IDLE && grant_valid) begin
      grant_idx_d = grant_idx;
      start_o = 1'b1;
    end
  end

  // State Update
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      cur_state <= IDLE;
    end else begin
      cur_state <= next_state;
    end
  end

  // Next state logic
  always_comb begin
    next_state = cur_state;
    case (cur_state)
      // Any of the valid is high, the next state is busy
      IDLE: if (grant_valid) next_state = BUSY;
      BUSY: if (done_i) next_state = IDLE;
    endcase
  end

  // Output logic
  always_comb begin
    // Default values
    inp_ready_o = 1'b0;
    oup_valid_o = 1'b0;
    oup_data_o = '0;
    oup_desc_o = '0;
    busy_o = 1'b0;
    case (cur_state)
      IDLE: begin
        inp_ready_o = 1'b0;
        oup_valid_o = 1'b0;
        oup_data_o = '0;
        oup_desc_o = '0;
        busy_o = 1'b0;
      end
      BUSY: begin
        inp_ready_o[grant_idx_q] = oup_ready_i;
        oup_valid_o = inp_valid_i[grant_idx_q];
        oup_data_o = inp_data_i[grant_idx_q];
        oup_desc_o = inp_desc_i[grant_idx_q];
        busy_o = 1'b1;
      end
    endcase
  end

  assign idx_o = grant_idx_q;

endmodule
