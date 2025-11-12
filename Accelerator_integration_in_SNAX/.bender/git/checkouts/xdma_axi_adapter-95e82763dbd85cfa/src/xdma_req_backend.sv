// Authors:
// - Fanchen Kong <fanchen.kong@kuleuven.be>
// - Yunhao Deng <yunhao.deng@kuleuven.be>

module xdma_req_backend #(
    /// Number of AX beats that can be in-flight
    parameter int unsigned ReqFifoDepth = -1,

    /// Data
    parameter type addr_t = logic,
    parameter type data_t = logic,
    parameter type strb_t = logic,
    parameter type len_t  = logic,

    parameter type xdma_req_idx_t     = logic,
    // typedef struct packed {
    //     id_t                                 dma_id; 
    //     logic                                dma_type;
    //     addr_t                               remote_addr;
    //     len_t                                dma_length;
    //     logic                                ready_to_transfer;
    // } xdma_req_desc_t;   
    parameter type xdma_req_desc_t    = logic,
    // typedef struct packed {
    //     id_t                                 id;
    //     addr_t                               addr;
    //     logic [7:0]                          len;
    //     logic [2:0]                          size;
    //     logic [1:0]                          burst;
    //     logic [3:0]                          cache;
    // } xdma_req_aw_desc_t;    
    parameter type xdma_req_aw_desc_t = logic,
    // typedef struct packed {
    //     logic [7:0]                         num_beats;
    //     logic                               is_single;
    //     logic                               is_write_data;
    // } xdma_req_w_desc_t;
    parameter type xdma_req_w_desc_t  = logic,

    /// Enable or disable tracing
    parameter bit  DmaTracing     = 0,
    /// AXI4+ATOP request struct definition.
    parameter type axi_out_req_t  = logic,
    /// AXI4+ATOP response struct definition.
    parameter type axi_out_resp_t = logic
) (
    /// Clock
    input  logic           clk_i,
    /// Asynchronous reset, active low
    input  logic           rst_ni,
    /// Inpt Data 
    input  data_t          write_req_data_i,
    /// Handshake
    input  logic           write_req_data_valid_i,
    /// Handshake
    output logic           write_req_data_ready_o,
    /// Grant
    input  logic           write_req_grant_i,
    /// Req Done
    input  logic           write_req_done_i,
    ///
    input  xdma_req_idx_t  write_req_idx_i,
    /// Req Description
    input  xdma_req_desc_t write_req_desc_i,
    /// Handshake
    input  logic           write_req_desc_valid_i,
    /// AXI Interface
    /// AXI4+ATOP master request
    output axi_out_req_t   axi_dma_req_o,
    /// AXI4+ATOP master response
    input  axi_out_resp_t  axi_dma_resp_i
);
  //--------------------------------------
  // XDMA Burst Reshaper
  //--------------------------------------
  xdma_req_aw_desc_t xdma_req_aw_desc;
  xdma_req_w_desc_t xdma_req_w_desc;
  logic write_req_desc_valid;
  logic write_req_desc_ready;
  xdma_burst_reshaper #(
      .data_t            (data_t),
      .len_t             (len_t),
      .addr_t            (addr_t),
      .xdma_req_idx_t    (xdma_req_idx_t),
      .xdma_req_desc_t   (xdma_req_desc_t),
      .xdma_req_aw_desc_t(xdma_req_aw_desc_t),
      .xdma_req_w_desc_t (xdma_req_w_desc_t)
  ) i_xdma_burst_reshaper (
      .clk_i                 (clk_i),
      .rst_ni                (rst_ni),
      .write_req_done_i      (write_req_done_i),
      // Input data
      .write_req_desc_i      (write_req_desc_i),
      .write_req_idx_i       (write_req_idx_i),
      .write_req_desc_valid_i(write_req_desc_valid_i),
      // Output data
      .write_req_aw_desc_o   (xdma_req_aw_desc),
      .write_req_w_desc_o    (xdma_req_w_desc),
      .write_req_desc_valid_o(write_req_desc_valid),
      .write_req_desc_ready_i(write_req_desc_ready)
  );

  //--------------------------------------
  // AW emitter
  //--------------------------------------
  // object currently at the tail of the fifo
  xdma_req_aw_desc_t current_req_aw_desc;
  // control signals
  logic aw_emitter_full;
  logic aw_emitter_empty;
  logic aw_emitter_push;
  logic aw_emitter_pop;

  // instantiate a fifo to buffer the address write requests
  fifo_v3 #(
      .FALL_THROUGH(1'b0),
      .dtype       (xdma_req_aw_desc_t),
      .DEPTH       (ReqFifoDepth)
  ) i_fifo_aw_emitter (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .flush_i   (1'b0),
      .testmode_i(1'b0),
      .full_o    (aw_emitter_full),
      .empty_o   (aw_emitter_empty),
      .usage_o   (),
      .data_i    (xdma_req_aw_desc),
      .push_i    (aw_emitter_push),
      .data_o    (current_req_aw_desc),
      .pop_i     (aw_emitter_pop)
  );

  //--------------------------------------
  // W emitter
  //--------------------------------------
  // object currently at the tail of the fifo
  xdma_req_w_desc_t current_req_w_desc;
  // control signals
  logic w_emitter_full;
  logic w_emitter_empty;
  logic w_emitter_push;
  logic w_emitter_pop;

  // instanciate a fifo to buffer the write requests
  fifo_v3 #(
      .FALL_THROUGH(1'b0),
      .dtype       (xdma_req_w_desc_t),
      .DEPTH       (ReqFifoDepth)
  ) i_fifo_w_emitter (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .flush_i   (1'b0),
      .testmode_i(1'b0),
      .full_o    (w_emitter_full),
      .empty_o   (w_emitter_empty),
      .usage_o   (),
      .data_i    (xdma_req_w_desc),
      .push_i    (w_emitter_push),
      .data_o    (current_req_w_desc),
      .pop_i     (w_emitter_pop)
  );

  //--------------------------------------
  // XDMA Data Path
  //--------------------------------------
  logic  w_dp_valid;
  logic  w_dp_ready;
  data_t w_data;
  strb_t w_strb;
  logic  w_last;
  logic  w_valid;
  logic  w_ready;
  xdma_data_path #(
      .data_t           (data_t),
      .strb_t           (strb_t),
      .xdma_req_w_desc_t(xdma_req_w_desc_t)
  ) i_xdma_data_path (
      .clk_i                 (clk_i),
      .rst_ni                (rst_ni),
      // Data 
      .write_req_data_i      (write_req_data_i),
      .write_req_data_valid_i(write_req_data_valid_i),
      .write_req_data_ready_o(write_req_data_ready_o),
      // Grant
      .write_req_grant_i     (write_req_grant_i),
      // From W emitter
      .w_desc_i              (current_req_w_desc),
      .w_dp_valid_i          (w_dp_valid),
      .w_dp_ready_o          (w_dp_ready),
      // AXI Interface
      .w_data_o              (w_data),
      .w_strb_o              (w_strb),
      .w_last_o              (w_last),
      .w_valid_o             (w_valid),
      .w_ready_i             (w_ready)
  );
  assign w_dp_valid = !w_emitter_empty;
  assign w_emitter_pop = w_dp_ready & !w_emitter_empty;
  //--------------------------------------
  // Refill control
  //--------------------------------------
  // the aw and w fifos of both channels are filled
  // together, as request come bundled.
  always_comb begin : proc_refill

    // Write related channels
    write_req_desc_ready = ~aw_emitter_full & ~w_emitter_full;
    w_emitter_push       = write_req_desc_valid & write_req_desc_ready;
    aw_emitter_push      = write_req_desc_valid & write_req_desc_ready;
  end
  //--------------------------------------
  // Bus control
  //--------------------------------------
  // here the AXI bus is unpacked/packed.
  always_comb begin : proc_axi_packer
    // We do not need the ar/r right now
    // We tie them to zero
    axi_dma_req_o          = '0;
    // assign W signals
    axi_dma_req_o.w.data   = w_data;
    axi_dma_req_o.w.strb   = w_strb;
    axi_dma_req_o.w.last   = w_last;
    axi_dma_req_o.w_valid  = w_valid;
    w_ready                = axi_dma_resp_i.w_ready;
    // AW signals
    axi_dma_req_o.aw.id    = current_req_aw_desc.id;
    axi_dma_req_o.aw.addr  = current_req_aw_desc.addr;
    axi_dma_req_o.aw.len   = current_req_aw_desc.len;
    axi_dma_req_o.aw.size  = current_req_aw_desc.size;
    axi_dma_req_o.aw.burst = current_req_aw_desc.burst;
    axi_dma_req_o.aw.cache = current_req_aw_desc.cache;
    axi_dma_req_o.aw_valid = (current_req_aw_desc.is_write_data)? ~aw_emitter_empty && write_req_grant_i : ~aw_emitter_empty;
    aw_emitter_pop         = axi_dma_resp_i.aw_ready & axi_dma_req_o.aw_valid;
    // B signals
    // we are always ready to accept b signals, as we do not need them
    // inside the DMA (we don't care if write failed)
    axi_dma_req_o.b_ready  = 1'b1;
  end
endmodule : xdma_req_backend
