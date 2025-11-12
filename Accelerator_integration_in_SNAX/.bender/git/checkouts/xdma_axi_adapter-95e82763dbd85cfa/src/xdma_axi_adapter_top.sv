// Fanchen Kong <fanchen.kong@kuleuven.be>
// Yunhao Deng <yunhao.deng@kuleuven.be>

// The top module of the xdma
// Sender side are
// - to_remote_cfg
// - to_remote_data
// - to_remote_data_accompany_cfg
//   This accompany_cfg points the aw
// Follower side are
// - from_remote_cfg
// - from_remote_data
// - from_remote_data_accompany_cfg
// Only use the aw/w from the axi interface
module xdma_axi_adapter_top
  import xdma_pkg::*;
#(
    // Wide AXI Types
    parameter type axi_wide_id_t         = logic,
    parameter type axi_wide_out_req_t    = logic,
    parameter type axi_wide_out_resp_t   = logic,
    parameter type axi_wide_in_req_t     = logic,
    parameter type axi_wide_in_resp_t    = logic,
    // Narrow AXI Types
    parameter type axi_narrow_id_t       = logic,
    parameter type axi_narrow_out_req_t  = logic,
    parameter type axi_narrow_out_resp_t = logic,
    parameter type axi_narrow_in_req_t   = logic,
    parameter type axi_narrow_in_resp_t  = logic,
    // Reqrsp types
    // Wide
    parameter type reqrsp_wide_req_t     = logic,
    parameter type reqrsp_wide_rsp_t     = logic,
    // Narrow
    parameter type reqrsp_narrow_req_t   = logic,
    parameter type reqrsp_narrow_rsp_t   = logic,
    // Data types
    parameter type wide_data_t           = logic,
    parameter type wide_strb_t           = logic,
    parameter type narrow_data_t         = logic,
    parameter type narrow_strb_t         = logic,
    parameter type addr_t                = logic,
    // XDMA type
    // Total dma length type
    parameter type len_t                 = logic,
    // Sender side
    parameter type xdma_to_remote_cfg_t  = logic,
    // typedef struct packed {
    //   first_frame_remaining_payload_t first_frame_remaining_payload;
    //   addr_t                          writer_addr;
    //   addr_t                          reader_addr;

    //   id_t           dma_id;
    //   frame_length_t frame_length;
    //   // The dma_type
    //   // 0: read
    //   // 1: write
    //   logic          dma_type;
    // } xdma_inter_cluster_first_cfg_t;
    parameter type xdma_to_remote_data_t               = logic,
    /// The data is logic [DataWidth-1:0]
    parameter type xdma_to_remote_data_accompany_cfg_t = logic,
    /// typedef struct packed {
    ///     id_t                                 dma_id;
    ///     logic                                dma_type;
    ///     addr_t                               src_addr;
    ///     addr_t                               dst_addr;
    ///     len_t                                dma_length;
    ///     logic                                ready_to_transfer;
    /// } xdma_accompany_cfg_t;
    parameter type xdma_req_desc_t                     = logic,

    /// typedef struct packed {
    ///     id_t                                 dma_id; 
    ///     logic                                dma_type;
    ///     addr_t                               remote_addr;
    ///     len_t                                dma_length;
    ///     logic                                ready_to_transfer;
    /// } xdma_req_desc_t;
    parameter type xdma_req_meta_t          = logic,
    /// typedef struct packed {
    ///     id_t                                 dma_id;
    ///     len_t                                dma_length;
    /// } xdma_req_meta_t;       
    parameter type xdma_to_remote_grant_t   = logic,
    // typedef struct packed {
    //     id_t                                 dma_id;
    //     addr_t                               from;
    //     grant_reserved_t                     reserved;
    // } xdma_to_remote_grant_t;
    // Receiver side
    parameter type xdma_from_remote_grant_t = logic,
    // typedef struct packed {
    //     id_t                                 dma_id;
    //     addr_t                               from;
    // } xdma_from_remote_grant_t;
    parameter type xdma_from_remote_cfg_t   = logic,
    // typedef struct packed {
    //   first_frame_remaining_payload_t first_frame_remaining_payload;
    //   addr_t                          writer_addr;
    //   addr_t                          reader_addr;

    //   id_t           dma_id;
    //   frame_length_t frame_length;
    //   // The dma_type
    //   // 0: read
    //   // 1: write
    //   logic          dma_type;
    // } xdma_inter_cluster_first_cfg_t;
    parameter type xdma_from_remote_data_t               = logic,
    /// The data is logic [DataWidth-1:0]
    parameter type xdma_from_remote_data_accompany_cfg_t = logic,
    // typedef struct packed {
    //     id_t                                 dma_id; 
    //     logic                                dma_type;
    //     addr_t                               src_addr;
    //     addr_t                               dst_addr;
    //     len_t                                dma_length;
    //     logic                                ready_to_transfer;
    // } xdma_accompany_cfg_t;

    // Cluster Cfgs
    parameter addr_t ClusterBaseAddr     = 'h1000_0000,
    parameter addr_t ClusterAddressSpace = 'h0010_0000,
    parameter addr_t MainMemBaseAddr     = 'h8000_0000,
    parameter addr_t MainMemEndAddr      = 48'b1 << 32,
    // MMIO size in KB
    parameter int    MMIOSize            = 16
) (
    /// Clock
    input logic clk_i,
    /// Asynchronous reset, active low
    input logic rst_ni,

    ///
    input  addr_t                              cluster_base_addr_i,
    // Sender Side
    //// To remote cfg
    input  xdma_to_remote_cfg_t                to_remote_cfg_i,
    input  logic                               to_remote_cfg_valid_i,
    output logic                               to_remote_cfg_ready_o,
    //// To remote data
    input  xdma_to_remote_data_t               to_remote_data_i,
    input  logic                               to_remote_data_valid_i,
    output logic                               to_remote_data_ready_o,
    //// To remote data accompany cfg
    input  xdma_to_remote_data_accompany_cfg_t to_remote_data_accompany_cfg_i,

    // Receiver Side
    //// From remote cfg
    output xdma_from_remote_cfg_t                from_remote_cfg_o,
    output logic                                 from_remote_cfg_valid_o,
    input  logic                                 from_remote_cfg_ready_i,
    //// From remote data
    output xdma_from_remote_data_t               from_remote_data_o,
    output logic                                 from_remote_data_valid_o,
    input  logic                                 from_remote_data_ready_i,
    //// From remote data accompany cfg
    input  xdma_from_remote_data_accompany_cfg_t from_remote_data_accompany_cfg_i,
    /// XDMA finish
    output logic                                 xdma_finish_o,
    // AXI Interface
    // Wide
    output axi_wide_out_req_t                    axi_xdma_wide_out_req_o,
    input  axi_wide_out_resp_t                   axi_xdma_wide_out_resp_i,
    input  axi_wide_in_req_t                     axi_xdma_wide_in_req_i,
    output axi_wide_in_resp_t                    axi_xdma_wide_in_resp_o,
    // Narrow
    output axi_narrow_out_req_t                  axi_xdma_narrow_out_req_o,
    input  axi_narrow_out_resp_t                 axi_xdma_narrow_out_resp_i,
    input  axi_narrow_in_req_t                   axi_xdma_narrow_in_req_i,
    output axi_narrow_in_resp_t                  axi_xdma_narrow_in_resp_o
);
  //--------------------------------------
  // Define Macros
  //--------------------------------------
  localparam int ClusterAddressLength = $clog2(ClusterAddressSpace);
  // Offset is calculated from the cluster_end_addr
  // data   (4kB)
  // cfg    (4kB)
  // grant  (4kB)
  // finish (4kB)
  // cluster end addr (high addr)
  // Data  start addr is cluster_end_addr-16KB
  localparam addr_t MMIODataOffset = (xdma_pkg::DataIdx + 1) * (MMIOSize / 4) * 1024;
  // CFG   start addr is cluster_end_addr-12KB
  localparam addr_t MMIOCFGOffset = (xdma_pkg::CfgIdx + 1) * (MMIOSize / 4) * 1024;
  // Grant start addr is cluster_end_addr-8KB
  localparam addr_t MMIOGrantOffset = (xdma_pkg::GrantIdx + 1) * (MMIOSize / 4) * 1024;
  // Finish start addr is cluster_end_addr-4KB
  localparam addr_t MMIOFinishOffset = (xdma_pkg::FinishIdx + 1) * (MMIOSize / 4) * 1024;

  function automatic addr_t get_cluster_base_addr(addr_t addr);
    return addr & {{($bits(addr_t) - ClusterAddressLength) {1'b1}}, {ClusterAddressLength{1'b0}}};
  endfunction

  function automatic addr_t get_cluster_end_addr(addr_t addr);
    return (addr & {{(AddrWidth - ClusterAddressLength) {1'b1}},
                    {ClusterAddressLength{1'b0}}}) + ClusterAddressSpace;
  endfunction

  function automatic addr_t get_main_mem_base_addr(addr_t addr);
    return {addr[AddrWidth-1:AddrWidth-ChipIdWidth], MainMemBaseAddr[AddrWidth-ChipIdWidth-1:0]};
  endfunction

  function automatic addr_t get_main_mem_end_addr(addr_t addr);
    return {addr[AddrWidth-1:AddrWidth-ChipIdWidth], MainMemEndAddr[AddrWidth-ChipIdWidth-1:0]};
  endfunction

  function automatic logic address_is_main_mem(addr_t addr);
    return addr[AddrWidth-ChipIdWidth-1:0] >= MainMemBaseAddr;
  endfunction
  //--------------------------------------
  // Unpack the req descriptor
  //--------------------------------------
  // To remote cfg
  // Since we are using the narrow to send the cfg
  // we need the 64bit cfg
  // but the xdma requires the 512bit CFG
  // ==> we use the narrow axi to burst 8 times
  narrow_data_t to_remote_cfg_narrow;
  logic         to_remote_cfg_narrow_valid;
  logic         to_remote_cfg_narrow_ready;
  // First we need the dw converter for the cfg from 512->64
  dw_converter #(
      .INPUT_DW (xdma_pkg::AxiWideDataWidth),
      .OUTPUT_DW(xdma_pkg::AxiNarrowDataWidth)
  ) i_cfg_dw_down_converter (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .data_i (to_remote_cfg_i),
      .valid_i(to_remote_cfg_valid_i),
      .ready_o(to_remote_cfg_ready_o),
      .data_o (to_remote_cfg_narrow),
      .valid_o(to_remote_cfg_narrow_valid),
      .ready_i(to_remote_cfg_narrow_ready)
  );
  // To remote grant
  xdma_to_remote_grant_t  to_remote_grant;
  logic                   to_remote_grant_valid;
  logic                   to_remote_grant_ready;
  // To remote finish
  xdma_to_remote_finish_t to_remote_finish;
  logic                   to_remote_finish_valid;
  logic                   to_remote_finish_ready;
  // Descriptions
  xdma_req_desc_t
      to_remote_cfg_desc, to_remote_data_desc, to_remote_grant_desc, to_remote_finish_desc;
  // CFG ready to transfer signal
  logic cfg_ready_to_transfer;
  always_comb begin : proc_unpack_desc
    //--------------------------------------
    // to remote cfg desc
    //--------------------------------------
    // We still need the original 512bit to remote cfg to compose the desc
    // DMA ID
    to_remote_cfg_desc.dma_id = to_remote_cfg_i.dma_id;
    // DMA type
    // read = 0, write=1
    to_remote_cfg_desc.dma_type = to_remote_cfg_i.dma_type;
    // if the task is a read (task_type=0)
    // local is writer addr, remote is reader addr
    // If the task is a write (task_type=1)
    // local is read addr, remote is writer addr
    to_remote_cfg_desc.remote_addr = (to_remote_cfg_desc.dma_type == 1'b0) ? address_is_main_mem(
        to_remote_cfg_i.reader_addr) ? get_main_mem_end_addr(to_remote_cfg_i.reader_addr) -
        MMIOCFGOffset : get_cluster_end_addr(to_remote_cfg_i.reader_addr) - MMIOCFGOffset :
        address_is_main_mem(to_remote_cfg_i.writer_addr) ?
        get_main_mem_end_addr(to_remote_cfg_i.writer_addr) - MMIOCFGOffset :
        get_cluster_end_addr(to_remote_cfg_i.writer_addr) - MMIOCFGOffset;
    // The cfg length is stored in the first frame.
    // Since now we are using the narrow instead of the wide to send the cfg
    // we need to multiple the 512/64 = 8 to the dma length
    to_remote_cfg_desc.dma_length = to_remote_cfg_i.frame_length << xdma_pkg::WIDE_NARROW_DW_BITS;
    // Ready to transfer logic: Is a FSM that counts the frames to determine the frame header
    // FSM will control cfg_ready_to_transfer signal when the first frame is there
    to_remote_cfg_desc.ready_to_transfer = cfg_ready_to_transfer;

    //--------------------------------------
    // to remote data desc
    //--------------------------------------
    // to_remote_data_desc needs the to_remote_data_accompany_cfg
    to_remote_data_desc.dma_id = to_remote_data_accompany_cfg_i.dma_id;
    to_remote_data_desc.dma_length = to_remote_data_accompany_cfg_i.dma_length;
    to_remote_data_desc.dma_type = to_remote_data_accompany_cfg_i.dma_type;
    // the to_remote_data has two scnerios:
    // 1. 0 reads 1
    //    remote cluster 1 needs the to_remote_data to send back back to 0
    //    in this way the task_type = read, the cluster 1 can send the data rightaway
    //    now the accompany_cfg.src_addr = cluster 1 addr
    //            accompany_cfg.dst_addr = cluster 0 addr
    //    the to_remote_data_desc.remote_addr = dst_addr
    // 2. 0 writes 1
    //    local cluster 0 needs to handshake with the cluster 1
    //    in this way the task_type = write
    //    now the accompany_cfg.src_addr = cluster 0 addr
    //            accompany_cfg.dst_addr = cluster 1 addr
    //    the to_remote_data_desc.remote_addr = dst_addr
    to_remote_data_desc.remote_addr = address_is_main_mem(to_remote_data_accompany_cfg_i.dst_addr) ?
        get_main_mem_end_addr(to_remote_data_accompany_cfg_i.dst_addr) - MMIODataOffset :
        get_cluster_end_addr(to_remote_data_accompany_cfg_i.dst_addr) - MMIODataOffset;
    to_remote_data_desc.ready_to_transfer = to_remote_data_accompany_cfg_i.ready_to_transfer;

    //--------------------------------------
    // to remote grant desc
    //--------------------------------------
    to_remote_grant_desc.dma_id = from_remote_data_accompany_cfg_i.dma_id;
    to_remote_grant_desc.dma_length = 1;
    to_remote_grant_desc.dma_type = from_remote_data_accompany_cfg_i.dma_type;
    to_remote_grant_desc.remote_addr =
        address_is_main_mem(from_remote_data_accompany_cfg_i.src_addr) ?
        get_main_mem_end_addr(from_remote_data_accompany_cfg_i.src_addr) - MMIOGrantOffset :
        get_cluster_end_addr(from_remote_data_accompany_cfg_i.src_addr) - MMIOGrantOffset;
    to_remote_grant_desc.ready_to_transfer = from_remote_data_accompany_cfg_i.ready_to_transfer;

  end

  // FSM to control the cfg_ready_to_transfer signal
  typedef enum int unsigned {
    sIDLE = 0,
    sSendFrameBody = 1
  } state_cfg_ready_to_transfer_t;

  // Declaration of the FSM's current and next state
  state_cfg_ready_to_transfer_t cur_state_cfg_ready_to_transfer, next_state_ready_to_transfer;

  // Declaration of the counter reg that count the current cfg frame number
  frame_length_t frame_length_counter;
  logic frame_length_counter_enable, frame_length_counter_clear;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      frame_length_counter <= '0;
    end else if (frame_length_counter_clear) begin
      frame_length_counter <= '0;
    end else if (frame_length_counter_enable) begin
      frame_length_counter <= frame_length_counter + 1;
    end
  end

  // Declaration of the holder reg that hold the cfg total length
  frame_length_t frame_length_holder;
  logic frame_length_holder_enable;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      frame_length_holder <= '0;
    end else if (frame_length_holder_enable) begin
      frame_length_holder <= to_remote_cfg_i.frame_length;
    end
  end

  // Current State Logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      cur_state_cfg_ready_to_transfer <= sIDLE;
    end else begin
      cur_state_cfg_ready_to_transfer <= next_state_ready_to_transfer;
    end
  end

  // Next State Logic
  always_comb begin : proc_next_state_logic
    cfg_ready_to_transfer = 1'b0;
    frame_length_counter_clear = 1'b0;
    frame_length_counter_enable = to_remote_cfg_valid_i && to_remote_cfg_ready_o;
    frame_length_holder_enable = 1'b0;
    next_state_ready_to_transfer = cur_state_cfg_ready_to_transfer;
    case (cur_state_cfg_ready_to_transfer)
      sIDLE: begin
        cfg_ready_to_transfer = to_remote_cfg_valid_i;
        frame_length_counter_clear = 1'b1;
        if (to_remote_cfg_valid_i && to_remote_cfg_ready_o && to_remote_cfg_i.frame_length > 1) begin
          // When the first frame is acknowledged, and the length is larger than 1, then the remaining several frames are not the header, so should not commit the new transfer
          frame_length_counter_clear   = 1'b0;
          frame_length_holder_enable   = 1'b1;
          next_state_ready_to_transfer = sSendFrameBody;
        end
      end
      sSendFrameBody: begin
        if (frame_length_counter == frame_length_holder - 1) begin
          next_state_ready_to_transfer = sIDLE;
        end
      end
      default: begin
        next_state_ready_to_transfer = sIDLE;
      end
    endcase
  end

  //--------------------------------------
  // Req Manager
  //--------------------------------------
  // We need wide/narrow managers
  // Wide manager only sends the data
  // Wide Data
  wide_data_t wide_write_req_data;
  logic wide_write_req_valid;
  logic wide_write_req_ready;
  // Wide Description
  xdma_req_desc_t wide_write_req_desc;
  xdma_pkg::xdma_wide_req_idx_t wide_write_req_idx;
  // Wide Status
  logic wide_write_req_start;
  logic wide_write_req_busy;
  logic wide_write_req_done;
  xdma_req_manager #(
      .data_t         (wide_data_t),
      .xdma_req_desc_t(xdma_req_desc_t),
      .N_INP          (xdma_pkg::NUM_WIDE_INP)
  ) i_xdma_wide_req_manager (
      .clk_i      (clk_i),
      .rst_ni     (rst_ni),
      .inp_data_i (wide_data_t'(to_remote_data_i)),
      .inp_valid_i(to_remote_data_valid_i),
      .inp_ready_o(to_remote_data_ready_o),
      .inp_desc_i (to_remote_data_desc),
      .oup_data_o (wide_write_req_data),
      .oup_valid_o(wide_write_req_valid),
      .oup_ready_i(wide_write_req_ready),
      .oup_desc_o (wide_write_req_desc),
      .idx_o      (wide_write_req_idx),
      .start_o    (wide_write_req_start),
      .busy_o     (wide_write_req_busy),
      .done_i     (wide_write_req_done)
  );


  // Narrow manager sends the ctrl (cfg, grant, finish)
  // Narrow Data
  narrow_data_t narrow_write_req_data;
  logic narrow_write_req_valid;
  logic narrow_write_req_ready;
  // Narrow Description
  xdma_req_desc_t narrow_write_req_desc;
  xdma_pkg::xdma_narrow_req_idx_t narrow_write_req_idx;
  // Narrow Status
  logic narrow_write_req_start;
  logic narrow_write_req_busy;
  logic narrow_write_req_done;

  xdma_req_manager #(
      .data_t         (narrow_data_t),
      .xdma_req_desc_t(xdma_req_desc_t),
      .N_INP          (xdma_pkg::NUM_NARROW_INP)
  ) i_xdma_narrow_req_manager (
      .clk_i(clk_i),
      .rst_ni(rst_ni),
      .inp_data_i({
        narrow_data_t'(to_remote_cfg_narrow),
        narrow_data_t'(to_remote_grant),
        narrow_data_t'(to_remote_finish)
      }),
      .inp_valid_i({to_remote_cfg_narrow_valid, to_remote_grant_valid, to_remote_finish_valid}),
      .inp_ready_o({to_remote_cfg_narrow_ready, to_remote_grant_ready, to_remote_finish_ready}),
      .inp_desc_i({to_remote_cfg_desc, to_remote_grant_desc, to_remote_finish_desc}),
      .oup_data_o(narrow_write_req_data),
      .oup_valid_o(narrow_write_req_valid),
      .oup_ready_i(narrow_write_req_ready),
      .oup_desc_o(narrow_write_req_desc),
      .idx_o(narrow_write_req_idx),
      .start_o(narrow_write_req_start),
      .busy_o(narrow_write_req_busy),
      .done_i(narrow_write_req_done)
  );
  ////--------------------------------------
  // Req Backend
  ////-------------------------------------
  logic grant;
  // Narrow Req Backend
  logic narrow_write_req_data_valid;
  logic narrow_write_req_data_ready;
  logic narrow_write_req_desc_valid;
  xdma_req_backend #(
      .ReqFifoDepth      (3),
      .addr_t            (addr_t),
      .data_t            (narrow_data_t),
      .strb_t            (narrow_strb_t),
      .len_t             (len_t),
      .xdma_req_idx_t    (xdma_pkg::xdma_narrow_req_idx_t),
      .xdma_req_desc_t   (xdma_req_desc_t),
      .xdma_req_aw_desc_t(xdma_pkg::xdma_req_aw_desc_t),
      .xdma_req_w_desc_t (xdma_pkg::xdma_req_w_desc_t),
      .axi_out_req_t     (axi_narrow_out_req_t),
      .axi_out_resp_t    (axi_narrow_out_resp_t)
  ) i_xdma_narrow_req_backend (
      .clk_i                 (clk_i),
      .rst_ni                (rst_ni),
      // Data Path
      .write_req_data_i      (narrow_write_req_data),
      .write_req_data_valid_i(narrow_write_req_data_valid),
      .write_req_data_ready_o(narrow_write_req_data_ready),
      // Grant
      // The control signal do not needs the grant signal
      .write_req_grant_i     (1'b1),
      // Req Done
      .write_req_done_i      (narrow_write_req_done),
      // Control Path
      .write_req_idx_i       (narrow_write_req_idx),
      .write_req_desc_i      (narrow_write_req_desc),
      .write_req_desc_valid_i(narrow_write_req_desc_valid),
      // AXI interface
      .axi_dma_req_o         (axi_xdma_narrow_out_req_o),
      .axi_dma_resp_i        (axi_xdma_narrow_out_resp_i)
  );
  assign narrow_write_req_data_valid = narrow_write_req_valid;
  assign narrow_write_req_desc_valid = narrow_write_req_desc.ready_to_transfer;
  assign narrow_write_req_ready = narrow_write_req_data_ready;

  // Wide Req Backend
  logic wide_write_req_data_valid;
  logic wide_write_req_data_ready;
  logic wide_write_req_desc_valid;

  xdma_req_backend #(
      .ReqFifoDepth      (3),
      .addr_t            (addr_t),
      .data_t            (wide_data_t),
      .strb_t            (wide_strb_t),
      .len_t             (len_t),
      .xdma_req_idx_t    (xdma_pkg::xdma_wide_req_idx_t),
      .xdma_req_desc_t   (xdma_req_desc_t),
      .xdma_req_aw_desc_t(xdma_pkg::xdma_req_aw_desc_t),
      .xdma_req_w_desc_t (xdma_pkg::xdma_req_w_desc_t),
      .axi_out_req_t     (axi_wide_out_req_t),
      .axi_out_resp_t    (axi_wide_out_resp_t)
  ) i_xdma_wide_req_backend (
      .clk_i                 (clk_i),
      .rst_ni                (rst_ni),
      // Data Path
      .write_req_data_i      (wide_write_req_data),
      .write_req_data_valid_i(wide_write_req_data_valid),
      .write_req_data_ready_o(wide_write_req_data_ready),
      // Grant
      .write_req_grant_i     (grant),
      // Req Done
      .write_req_done_i      (wide_write_req_done),
      // Control Path
      .write_req_idx_i       (wide_write_req_idx),
      .write_req_desc_i      (wide_write_req_desc),
      .write_req_desc_valid_i(wide_write_req_desc_valid),
      // AXI interface
      .axi_dma_req_o         (axi_xdma_wide_out_req_o),
      .axi_dma_resp_i        (axi_xdma_wide_out_resp_i)
  );
  assign wide_write_req_data_valid = wide_write_req_valid;
  assign wide_write_req_desc_valid = wide_write_req_desc.ready_to_transfer;
  assign wide_write_req_ready = wide_write_req_data_ready;
  ////--------------------------------------
  // Req Meta Manager
  ////-------------------------------------
  // Here we record the meta data of the current req
  // meta = dma_id + length
  // Again we need the narrow and wide req meta manager
  // since the cfg and the data can be sent at the same time
  //
  // Narrow Req Meta Manager
  xdma_req_meta_t narrow_write_req_meta;
  always_comb begin : proc_pack_narrow_req_meta
    narrow_write_req_meta.dma_id     = narrow_write_req_desc.dma_id;
    narrow_write_req_meta.dma_length = narrow_write_req_desc.dma_length;
  end
  id_t  narrow_cur_dma_id;
  logic narrow_write_happening;
  assign narrow_write_happening = axi_xdma_narrow_out_req_o.w_valid & axi_xdma_narrow_out_resp_i.w_ready;
  xdma_meta_manager #(
      .xdma_req_meta_t(xdma_req_meta_t),
      .len_t          (len_t),
      .id_t           (id_t)
  ) i_xdma_narrow_meta_manager (
      .clk_i            (clk_i),
      .rst_ni           (rst_ni),
      .write_req_meta_i (narrow_write_req_meta),
      .write_req_busy_i (narrow_write_req_busy),
      .write_req_done_o (narrow_write_req_done),
      .cur_dma_id_o     (narrow_cur_dma_id),
      // From AXI handshake
      .write_happening_i(narrow_write_happening)
  );

  // Wide Req Meta Manager
  xdma_req_meta_t wide_write_req_meta;
  always_comb begin : proc_pack_wide_req_meta
    wide_write_req_meta.dma_id     = wide_write_req_desc.dma_id;
    wide_write_req_meta.dma_length = wide_write_req_desc.dma_length;
  end
  id_t  wide_cur_dma_id;
  logic wide_write_happening;
  assign wide_write_happening = axi_xdma_wide_out_req_o.w_valid & axi_xdma_wide_out_resp_i.w_ready;
  xdma_meta_manager #(
      .xdma_req_meta_t(xdma_req_meta_t),
      .len_t          (len_t),
      .id_t           (id_t)
  ) i_xdma_wide_meta_manager (
      .clk_i            (clk_i),
      .rst_ni           (rst_ni),
      .write_req_meta_i (wide_write_req_meta),
      .write_req_busy_i (wide_write_req_busy),
      .write_req_done_o (wide_write_req_done),
      .cur_dma_id_o     (wide_cur_dma_id),
      // From AXI handshake
      .write_happening_i(wide_write_happening)
  );

  //--------------------------------------
  // Grant Manager
  //--------------------------------------
  always_comb begin
    to_remote_grant.dma_id = from_remote_data_accompany_cfg_i.dma_id;
    to_remote_grant.from = from_remote_data_accompany_cfg_i.src_addr;
    to_remote_grant.reserved = '0;
  end
  xdma_grant_manager #(
      .xdma_from_remote_data_accompany_cfg_t(xdma_from_remote_data_accompany_cfg_t)
  ) i_xdma_grant_manager (
      .clk_i                           (clk_i),
      .rst_ni                          (rst_ni),
      .from_remote_grant_i             (grant),
      .from_remote_data_accompany_cfg_i(from_remote_data_accompany_cfg_i),
      .to_remote_grant_valid_o         (to_remote_grant_valid),
      .to_remote_grant_ready_i         (to_remote_grant_ready)
  );
  //--------------------------------------
  // Receiver front end
  //-------------------------------------
  // Wide receiver front end
  reqrsp_wide_req_t wide_receive_write_req;
  reqrsp_wide_rsp_t wide_receive_write_rsp;
  logic wide_receiver_busy;
  xdma_axi_to_write #(
      .data_t       (wide_data_t),
      .addr_t       (addr_t),
      .axi_id_t     (axi_wide_id_t),
      .strb_t       (wide_strb_t),
      .reqrsp_req_t (reqrsp_wide_req_t),
      .reqrsp_rsp_t (reqrsp_wide_rsp_t),
      .axi_in_req_t (axi_wide_in_req_t),
      .axi_in_resp_t(axi_wide_in_resp_t)
  ) i_xdma_wide_receiver_axi_to_write (
      .clk_i       (clk_i),
      .rst_ni      (rst_ni),
      // AXI interface
      .axi_req_i   (axi_xdma_wide_in_req_i),
      .axi_rsp_o   (axi_xdma_wide_in_resp_o),
      // ReqRsp
      .reqrsp_req_o(wide_receive_write_req),
      .reqrsp_rsp_i(wide_receive_write_rsp),
      // Status
      .busy_o      (wide_receiver_busy)
  );
  // We only care on the aw/w, hence no read is back from the rsp
  always_comb begin : proc_write_wide_rsp_compose
    wide_receive_write_rsp.data = '0;
    wide_receive_write_rsp.error = '0;
    wide_receive_write_rsp.p_valid = '0;
  end
  // Narrow receiver front end
  reqrsp_narrow_req_t narrow_receive_write_req;
  reqrsp_narrow_rsp_t narrow_receive_write_rsp;
  logic narrow_receiver_busy;
  xdma_axi_to_write #(
      .data_t       (narrow_data_t),
      .addr_t       (addr_t),
      .axi_id_t     (axi_narrow_id_t),
      .strb_t       (narrow_strb_t),
      .reqrsp_req_t (reqrsp_narrow_req_t),
      .reqrsp_rsp_t (reqrsp_narrow_rsp_t),
      .axi_in_req_t (axi_narrow_in_req_t),
      .axi_in_resp_t(axi_narrow_in_resp_t)
  ) i_xdma_narrow_receiver_axi_to_write (
      .clk_i       (clk_i),
      .rst_ni      (rst_ni),
      // AXI interface
      .axi_req_i   (axi_xdma_narrow_in_req_i),
      .axi_rsp_o   (axi_xdma_narrow_in_resp_o),
      // ReqRsp
      .reqrsp_req_o(narrow_receive_write_req),
      .reqrsp_rsp_i(narrow_receive_write_rsp),
      // Status
      .busy_o      (narrow_receiver_busy)
  );
  // We only care on the aw/w, hence no read is back from the rsp
  always_comb begin : proc_write_narrow_rsp_compose
    narrow_receive_write_rsp.data = '0;
    narrow_receive_write_rsp.error = '0;
    narrow_receive_write_rsp.p_valid = '0;
  end

  //-------------------------------------
  // Receiver demux
  //-------------------------------------
  // For data, we do not need the demux
  // since the data is from the wide axi
  always_comb begin : proc_compose_wide_data
    from_remote_data_o = wide_receive_write_req.data;
    from_remote_data_valid_o = wide_receive_write_req.q_valid;
    wide_receive_write_rsp.q_ready = from_remote_data_ready_i;
  end

  // For control (cfg, grant, finish), we need the demux
  // since the control signals are all from the narrow axi

  xdma_pkg::rule_t [xdma_pkg::NUM_NARROW_OUP-1:0] xdma_narrow_rules;
  addr_t local_end_addr;
  assign local_end_addr = address_is_main_mem(
      cluster_base_addr_i
  ) ? get_main_mem_end_addr(
      cluster_base_addr_i
  ) : get_cluster_end_addr(
      cluster_base_addr_i
  );
  assign xdma_narrow_rules = {
    xdma_pkg::rule_t
'{
        idx: xdma_pkg::FromRemoteCfg,
        start_addr: local_end_addr - MMIOCFGOffset,
        end_addr: local_end_addr - MMIOCFGOffset + (MMIOSize / 4) * 1024
    },
    xdma_pkg::rule_t
'{
        idx: xdma_pkg::FromRemoteGrant,
        start_addr: local_end_addr - MMIOGrantOffset,
        end_addr: local_end_addr - MMIOGrantOffset + (MMIOSize / 4) * 1024
    },
    xdma_pkg::rule_t
'{
        idx: xdma_pkg::FromRemoteFinish,
        start_addr: local_end_addr - MMIOFinishOffset,
        end_addr: local_end_addr - MMIOFinishOffset + (MMIOSize / 4) * 1024
    }
  };

  narrow_data_t from_remote_cfg;
  logic         from_remote_cfg_valid;
  logic         from_remote_cfg_ready;

  narrow_data_t from_remote_grant;
  logic         from_remote_grant_valid;
  logic         from_remote_grant_ready;

  narrow_data_t from_remote_finish;
  logic         from_remote_finish_valid;
  logic         from_remote_finish_ready;

  xdma_write_demux #(
      .N_OUP (xdma_pkg::NUM_NARROW_OUP),
      .data_t(narrow_data_t),
      .addr_t(addr_t),
      .rule_t(rule_t)
  ) i_xdma_receiver_write_demux_narrow (
      // Input side
      .inp_addr_i (narrow_receive_write_req.addr),
      .addr_map_i (xdma_narrow_rules),
      .inp_data_i (narrow_receive_write_req.data),
      .inp_valid_i(narrow_receive_write_req.q_valid),
      .inp_ready_o(narrow_receive_write_rsp.q_ready),
      // Outpu side
      .oup_data_o ({from_remote_cfg, from_remote_grant, from_remote_finish}),
      .oup_valid_o({from_remote_cfg_valid, from_remote_grant_valid, from_remote_finish_valid}),
      .oup_ready_i({from_remote_cfg_ready, from_remote_grant_ready, from_remote_finish_ready})
  );

  //-------------------------------------
  // Receive CFG DW Converter
  //-------------------------------------
  dw_converter #(
      .INPUT_DW (xdma_pkg::AxiNarrowDataWidth),
      .OUTPUT_DW(xdma_pkg::AxiWideDataWidth)
  ) i_cfg_dw_up_converter (
      .clk_i  (clk_i),
      .rst_ni (rst_ni),
      .data_i (from_remote_cfg),
      .valid_i(from_remote_cfg_valid),
      .ready_o(from_remote_cfg_ready),
      .data_o (from_remote_cfg_o),
      .valid_o(from_remote_cfg_valid_o),
      .ready_i(from_remote_cfg_ready_i)
  );
  //-------------------------------------
  // Receive Grant FIFO
  //-------------------------------------
  // This temp is the structure converter from data_t to xdma_to_remote_grant_t
  xdma_pkg::xdma_to_remote_grant_t from_remote_grant_tmp;
  assign from_remote_grant_tmp = from_remote_grant;

  xdma_from_remote_grant_t receive_grant;
  always_comb begin : proc_unpack_received_grant
    receive_grant.dma_id = from_remote_grant_tmp.dma_id;
    receive_grant.from   = from_remote_grant_tmp.from;
  end
  logic grant_fifo_full;
  logic grant_fifo_empty;
  logic grant_fifo_push;
  logic grant_fifo_pop;
  xdma_from_remote_grant_t receive_grant_cur;

  fifo_v3 #(
      .dtype(xdma_from_remote_grant_t),
      .DEPTH(3)
  ) i_xdma_receive_grant_fifo (
      .clk_i     (clk_i),
      .rst_ni    (rst_ni),
      .flush_i   (1'b0),
      .testmode_i(1'b0),
      .full_o    (grant_fifo_full),
      .empty_o   (grant_fifo_empty),
      .usage_o   (),
      .data_i    (receive_grant),
      .push_i    (grant_fifo_push),
      .data_o    (receive_grant_cur),
      .pop_i     (grant_fifo_pop)
  );
  // xdma_write_finish from xdma_finish_manager to pop out grant signals
  logic xdma_write_finish;

  assign grant = !grant_fifo_empty;
  assign grant_fifo_pop = !grant_fifo_empty & xdma_write_finish;
  assign from_remote_grant_ready = !grant_fifo_full;
  assign grant_fifo_push = from_remote_grant_valid & !grant_fifo_full;

  //-------------------------------------
  // Finish Manager
  //-------------------------------------
  addr_t remote_addr;
  id_t   from_remote_dma_id;
  xdma_finish_manager #(
      .id_t                                 (id_t),
      .len_t                                (len_t),
      .addr_t                               (addr_t),
      .data_t                               (narrow_data_t),
      .xdma_to_remote_data_accompany_cfg_t  (xdma_to_remote_data_accompany_cfg_t),
      .xdma_from_remote_data_accompany_cfg_t(xdma_from_remote_data_accompany_cfg_t),
      .xdma_req_desc_t                      (xdma_req_desc_t),
      .xdma_to_remote_finish_t              (xdma_to_remote_finish_t),
      .xdma_from_remote_finish_t            (xdma_from_remote_finish_t)
  ) i_xdma_finish_manager (
      .clk_i                           (clk_i),
      .rst_ni                          (rst_ni),
      .xdma_finish_o                   (xdma_finish_o),
      .xdma_write_finish_o             (xdma_write_finish),
      .to_remote_data_accompany_cfg_i  (to_remote_data_accompany_cfg_i),
      .from_remote_data_accompany_cfg_i(from_remote_data_accompany_cfg_i),
      .from_remote_finish_i            (from_remote_finish),
      .from_remote_finish_valid_i      (from_remote_finish_valid),
      .from_remote_finish_ready_o      (from_remote_finish_ready),
      .remote_addr_o                   (remote_addr),
      .from_remote_dma_id_o            (from_remote_dma_id),
      .to_remote_finish_valid_o        (to_remote_finish_valid),
      .to_remote_finish_ready_i        (to_remote_finish_ready)
  );
  always_comb begin : proc_unpack_finish_desc
    //--------------------------------------
    // to remote finish desc
    //--------------------------------------
    to_remote_finish_desc.dma_id = from_remote_dma_id;
    to_remote_finish_desc.dma_type = 1'b1;  // write
    to_remote_finish_desc.remote_addr = address_is_main_mem(remote_addr) ? get_main_mem_end_addr(
        remote_addr) - MMIOFinishOffset : get_cluster_end_addr(remote_addr) - MMIOFinishOffset;
    to_remote_finish_desc.dma_length = 1;
    to_remote_finish_desc.ready_to_transfer = to_remote_finish_valid;
  end

  always_comb begin : proc_unpack_finish
    to_remote_finish = '0;
    to_remote_finish.dma_id = from_remote_dma_id;
    to_remote_finish.from = cluster_base_addr_i;
  end

endmodule : xdma_axi_adapter_top
