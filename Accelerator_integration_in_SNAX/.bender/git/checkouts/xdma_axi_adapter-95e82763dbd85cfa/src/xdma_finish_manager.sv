// Authors:
// - Fanchen Kong <fanchen.kong@kuleuven.be>
// - Yunhao Deng <yunhao.deng@kuleuven.be>

/// This module tracks the handshake signal of the
/// from_remote_data 
//  to_remote_data

module xdma_finish_manager #(
    parameter type         id_t                                  = logic,
    parameter type         len_t                                 = logic,
    parameter type         addr_t                                = logic,
    parameter type         data_t                                = logic,
    parameter type         xdma_to_remote_data_accompany_cfg_t   = logic,
    parameter type         xdma_from_remote_data_accompany_cfg_t = logic,
    parameter type         xdma_req_desc_t                       = logic,
    parameter type         xdma_to_remote_finish_t               = logic,
    parameter type         xdma_from_remote_finish_t             = logic,
    //Dependent parameter
    parameter int unsigned LenWidth                              = $bits(len_t)
) (
    /// Clock
    input  logic                                 clk_i,
    /// Asynchronous reset, active low
    input  logic                                 rst_ni,
    /// Status Signal
    // The XDMA finish indicator, connect to XDMA Frontend. Only becomes high at first XDMA (Write / ChainWrite)
    output logic                                 xdma_finish_o,
    // The XDMA remote write finish indicator, connect to grant_manager. Becomes high for the whole chain
    output logic                                 xdma_write_finish_o,
    /// to remote
    input  xdma_to_remote_data_accompany_cfg_t   to_remote_data_accompany_cfg_i,
    /// from remote accompany cfg
    input  xdma_from_remote_data_accompany_cfg_t from_remote_data_accompany_cfg_i,
    // input  logic                                 from_remote_data_happening_i,
    /// from remote finish
    input  data_t                                from_remote_finish_i,
    input  logic                                 from_remote_finish_valid_i,
    output logic                                 from_remote_finish_ready_o,

    output addr_t remote_addr_o,
    output id_t   from_remote_dma_id_o,
    output logic  to_remote_finish_valid_o,
    input  logic  to_remote_finish_ready_i
);

  // Convert data_t to xdma_to_remote_grant_t
  xdma_pkg::xdma_to_remote_finish_t from_remote_finish;
  assign from_remote_finish = from_remote_finish_i;


  // Status that need the pull up xdma_finish_o: Read task, The first hop of a write task
  typedef enum logic [1:0] {
    ReadIdle,
    ReadBusy,
    ReadFinish
  } xdma_read_status_t;

  typedef enum logic [1:0] {
    WriteFirstIdle,
    WriteFirstBusy,
    WriteFirstFinish
  } xdma_first_write_status_t;

  typedef enum logic [2:0] {
    WriteMiddleLastIdle,
    WriteMiddleBusy,
    WriteLastBusy,
    WriteLastFinish,
    SendToPreviousHop
  } xdma_last_write_status_t;

  // The temporal saver for to_remote_id, from_remote_id, and from_remote_addr
  id_t   to_remote_dma_id_q;
  id_t   from_remote_dma_id_q;
  addr_t from_remote_addr_q;
  logic to_remote_dma_id_en, from_remote_dma_id_en, from_remote_addr_en;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      to_remote_dma_id_q   <= '0;
      from_remote_dma_id_q <= '0;
      from_remote_addr_q   <= '0;
    end else begin
      if (to_remote_dma_id_en) to_remote_dma_id_q <= to_remote_data_accompany_cfg_i.dma_id;
      if (from_remote_dma_id_en) from_remote_dma_id_q <= from_remote_data_accompany_cfg_i.dma_id;
      if (from_remote_addr_en) from_remote_addr_q <= from_remote_data_accompany_cfg_i.src_addr;
    end
  end

  // The declaration for the FSM
  xdma_read_status_t read_current_state, read_next_state;
  xdma_first_write_status_t first_write_current_state, first_write_next_state;
  xdma_last_write_status_t last_write_current_state, last_write_next_state;

  // First FSM: Read
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      read_current_state <= ReadIdle;
    end else begin
      read_current_state <= read_next_state;
    end
  end

  // Two signals to send the read finish to XDMACtrl
  logic read_finish_valid, read_finish_ready;
  always_comb begin
    read_next_state   = read_current_state;
    read_finish_valid = 1'b0;
    case (read_current_state)
      ReadIdle: begin
        if ((~from_remote_data_accompany_cfg_i.dma_type) && from_remote_data_accompany_cfg_i.ready_to_transfer) begin
          read_next_state = ReadBusy;
        end
      end
      ReadBusy: begin
        if (~from_remote_data_accompany_cfg_i.ready_to_transfer) begin
          read_finish_valid = 1'b1;
          if (read_finish_ready) begin
            read_next_state = ReadIdle;
          end else begin
            read_next_state = ReadFinish;
          end
        end
      end
      ReadFinish: begin
        read_finish_valid = 1'b1;
        if (read_finish_ready) begin
          read_next_state = ReadIdle;
        end
      end
      default: begin
        read_next_state = ReadIdle;
      end
    endcase
  end

  // Second FSM: First Write
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      first_write_current_state <= WriteFirstIdle;
    end else begin
      first_write_current_state <= first_write_next_state;
    end
  end

  // Two signals to send the write finish to XDMACtrl
  logic first_write_finish_valid, first_write_finish_ready;
  always_comb begin
    first_write_next_state = first_write_current_state;
    first_write_finish_valid = 1'b0;
    to_remote_dma_id_en = 1'b0;
    case (first_write_current_state)
      WriteFirstIdle: begin
        if (to_remote_data_accompany_cfg_i.dma_type && 
        to_remote_data_accompany_cfg_i.ready_to_transfer && 
        to_remote_data_accompany_cfg_i.is_first_cw && 
        (~to_remote_data_accompany_cfg_i.is_last_cw)) begin
          to_remote_dma_id_en = 1'b1;
          first_write_next_state = WriteFirstBusy;
        end
      end
      WriteFirstBusy: begin
        if (from_remote_finish_valid_i && from_remote_finish.dma_id == to_remote_dma_id_q) begin
          first_write_finish_valid = 1'b1;
          if (first_write_finish_ready) begin
            first_write_next_state = WriteFirstIdle;
          end else begin
            first_write_next_state = WriteFirstFinish;
          end
        end
      end
      WriteFirstFinish: begin
        first_write_finish_valid = 1'b1;
        if (first_write_finish_ready) begin
          first_write_next_state = WriteFirstIdle;
        end
      end
      default: begin
        first_write_next_state = WriteFirstIdle;
      end
    endcase
  end

  // The simple arbitration signal for read_finish, write_finish to xdma_finish_o (finish arbitration)
  assign xdma_finish_o = read_finish_valid | first_write_finish_valid;
  always_comb begin
    read_finish_ready = '0;
    first_write_finish_ready = '0;
    if (read_finish_valid) read_finish_ready = '1;
    else if (first_write_finish_valid) first_write_finish_ready = '1;
  end

  // Third FSM: Middle / Last Write
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      last_write_current_state <= WriteMiddleLastIdle;
    end else begin
      last_write_current_state <= last_write_next_state;
    end
  end

  logic middle_last_write_finish_valid;

  assign remote_addr_o = from_remote_addr_q;
  assign from_remote_dma_id_o = from_remote_dma_id_q;

  always_comb begin
    last_write_next_state = last_write_current_state;
    from_remote_dma_id_en = 1'b0;
    from_remote_addr_en = 1'b0;
    to_remote_finish_valid_o = 1'b0;
    middle_last_write_finish_valid = 1'b0;

    case (last_write_current_state)
      WriteMiddleLastIdle: begin
        if (from_remote_data_accompany_cfg_i.dma_type && 
            from_remote_data_accompany_cfg_i.ready_to_transfer && 
            (~from_remote_data_accompany_cfg_i.is_first_cw) && 
            (~from_remote_data_accompany_cfg_i.is_last_cw)) begin
          from_remote_dma_id_en = 1'b1;
          from_remote_addr_en   = 1'b1;
          last_write_next_state = WriteMiddleBusy;
        end else if (from_remote_data_accompany_cfg_i.dma_type && 
                     from_remote_data_accompany_cfg_i.ready_to_transfer && 
                     (~from_remote_data_accompany_cfg_i.is_first_cw) && 
                     from_remote_data_accompany_cfg_i.is_last_cw) begin
          from_remote_dma_id_en = 1'b1;
          from_remote_addr_en   = 1'b1;
          last_write_next_state = WriteLastBusy;
        end
      end
      WriteMiddleBusy: begin
        if (from_remote_finish_valid_i && from_remote_finish.dma_id == from_remote_dma_id_q) begin
          last_write_next_state = SendToPreviousHop;
        end
      end
      WriteLastBusy: begin
        if (~from_remote_data_accompany_cfg_i.ready_to_transfer) begin
          last_write_next_state = WriteLastFinish;
        end
      end
      WriteLastFinish: begin
        to_remote_finish_valid_o = 1'b1;
        if (to_remote_finish_ready_i) begin
          last_write_next_state = WriteMiddleLastIdle;
        end
      end
      SendToPreviousHop: begin
        to_remote_finish_valid_o = 1'b1;
        if (to_remote_finish_ready_i) begin
          middle_last_write_finish_valid = 1'b1;
          last_write_next_state = WriteMiddleLastIdle;
        end
      end
      default: begin
        last_write_next_state = WriteMiddleLastIdle;
      end
    endcase
  end

  // Assign from_remote_finish_ready_o signal
  assign from_remote_finish_ready_o = last_write_current_state == WriteMiddleBusy | first_write_current_state == WriteFirstBusy;
  // Assign xdma_write_finish_o signal
  // This signal is used to the grant_manager to release the reserved entry
  // There are two conditions to release the entry:
  // 1. The first write node (the first CW of a write task)
  // 2. The intermediate node in CW
  assign xdma_write_finish_o = middle_last_write_finish_valid | first_write_finish_valid;

endmodule
