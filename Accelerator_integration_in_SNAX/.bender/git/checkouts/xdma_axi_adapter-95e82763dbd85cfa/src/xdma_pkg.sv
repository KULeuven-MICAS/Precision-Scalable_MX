// Authors:
// Fanchen Kong <fanchen.kong@kuleuven.be>


//! XDMA Package
/// Contains all necessary type definitions, constants, and generally useful functions.
package xdma_pkg;
  localparam int unsigned ChipIdWidth = 32'd8;
  localparam int unsigned DMAIdWidth = 32'd4;
  localparam int unsigned AxiWideDataWidth = 32'd512;
  localparam int unsigned WideStrbWidth = AxiWideDataWidth / 8;
  localparam int unsigned AxiNarrowDataWidth = 32'd64;
  localparam int unsigned NarrowStrbWidth = AxiNarrowDataWidth / 8;
  localparam int unsigned WIDE_NARROW_DW_BITS = $clog2(AxiWideDataWidth / AxiNarrowDataWidth);
  localparam int unsigned AddrWidth = 32'd48;
  localparam int unsigned StrideWidth = 32'd19;
  localparam int unsigned BoundWidth = 32'd19;
  // localparam int unsigned EnableChannelWidth = 32'd8;
  // localparam int unsigned EnableByteWidth = 32'd8;
  localparam int unsigned DMALengthWidth = 32'd19;
  // localparam int unsigned NrBroadcast  = 32'd4;
  // localparam int unsigned NrDimension = 32'd6;
  typedef logic [ChipIdWidth-1:0] chip_id_t;
  typedef logic [DMAIdWidth-1:0] id_t;
  typedef logic [AxiWideDataWidth-1:0] wide_data_t;
  typedef logic [WideStrbWidth-1:0] wide_strb_t;
  typedef logic [AxiNarrowDataWidth-1:0] narrow_data_t;
  typedef logic [NarrowStrbWidth-1:0] narrow_strb_t;  
  typedef logic [AddrWidth-1:0] addr_t;
  // typedef logic [StrideWidth-1:0] stride_t;
  // typedef logic [BoundWidth-1:0] bound_t;
  // typedef logic [EnableChannelWidth-1:0] enable_channel_t;
  // typedef logic [EnableByteWidth-1:0] enable_byte_t;
  typedef logic [DMALengthWidth-1:0] len_t;
  typedef logic [AxiNarrowDataWidth-DMAIdWidth-AddrWidth-1:0] grant_reserved_t;
  typedef logic [AxiNarrowDataWidth-DMAIdWidth-AddrWidth-1:0] finish_reserved_t;

  localparam int unsigned TotalFrameWidth = 32'd4;
  typedef logic [TotalFrameWidth-1:0] frame_length_t;
  localparam int unsigned FirstFrameRemaingPayloadWidth = AxiWideDataWidth - 1 - TotalFrameWidth - DMAIdWidth - AddrWidth - AddrWidth;
  typedef logic [FirstFrameRemaingPayloadWidth-1:0] first_frame_remaining_payload_t;
  localparam int unsigned RemainingPayloadWidth = AxiWideDataWidth - 1 - TotalFrameWidth;
  typedef logic [RemainingPayloadWidth-1:0] remaining_payload_t;

  //--------------------------------------
  // to remote cfg type
  //--------------------------------------

  typedef struct packed {
    first_frame_remaining_payload_t first_frame_remaining_payload;
    addr_t                          writer_addr;
    addr_t                          reader_addr;
    id_t                            dma_id;
    frame_length_t                  frame_length;
    // The dma_type
    // 0: read
    // 1: write
    logic                           dma_type;
  } xdma_inter_cluster_cfg_t;

  // typedef struct packed {
  //   remaining_payload_t remaining_payload;
  //   // The dma_type
  //   // 0: read
  //   // 1: write
  //   logic               dma_type;
  //   id_t                dma_id;
  // } xdma_inter_cluster_cfg_t;

  typedef logic [AxiWideDataWidth-1:0] xdma_to_remote_data_t;
  typedef logic [AxiWideDataWidth-1:0] xdma_from_remote_data_t;


  //--------------------------------------
  // to remote IDX
  //--------------------------------------
  // Here we can tell if the write data is the to_remote_write

  typedef enum int unsigned {
    ToRemoteFinish = 0,
    ToRemoteGrant  = 1,
    ToRemoteCfg    = 2,
    NUM_NARROW_INP = 3
  } xdma_narrow_to_remote_idx_e;

  typedef enum int unsigned {
    ToRemoteData   = 0,
    NUM_WIDE_INP   = 1
  } xdma_wide_to_remote_idx_e;  

  typedef logic [$clog2(NUM_WIDE_INP)-1:0] xdma_wide_req_idx_t;
  typedef logic [$clog2(NUM_NARROW_INP)-1:0] xdma_narrow_req_idx_t;
  //--------------------------------------
  // Accompany CFG
  //--------------------------------------
  typedef struct packed {
    id_t   dma_id;
    logic  dma_type;
    addr_t src_addr;
    addr_t dst_addr;
    len_t  dma_length;
    logic  ready_to_transfer;
    logic  is_first_cw;
    logic  is_last_cw;
  } xdma_accompany_cfg_t;
  //--------------------------------------
  // Req description
  //--------------------------------------    
  typedef struct packed {
    id_t   dma_id;
    logic  dma_type;
    addr_t remote_addr;
    len_t  dma_length;
    logic  ready_to_transfer;
  } xdma_req_desc_t;

  //-------------------------------- ------
  // req meta type
  //--------------------------------------    
  typedef struct packed {
    id_t  dma_id;
    len_t dma_length;
  } xdma_req_meta_t;

  //--------------------------------------
  // to remote grant
  //--------------------------------------
  typedef struct packed {
    id_t             dma_id;
    addr_t           from;
    grant_reserved_t reserved;
  } xdma_to_remote_grant_t;

  //--------------------------------------
  // from remote grant
  //--------------------------------------
  typedef struct packed {
    id_t         dma_id;
    addr_t       from;
  } xdma_from_remote_grant_t;

  //--------------------------------------
  // to remote finish
  //--------------------------------------
  typedef struct packed {
    id_t              dma_id;
    addr_t            from;
    finish_reserved_t reserved;
  } xdma_to_remote_finish_t;

  //--------------------------------------
  // From remote finish
  //--------------------------------------
  typedef struct packed {
    id_t         dma_id;
    addr_t from;
  } xdma_from_remote_finish_t;
  //--------------------------------------
  // AW desc
  //--------------------------------------
  typedef struct packed {
    id_t        id;
    addr_t      addr;
    logic [7:0] len;
    logic [2:0] size;
    logic [1:0] burst;
    logic [3:0] cache;
    logic       is_write_data;
  } xdma_req_aw_desc_t;

  //--------------------------------------
  // W desc
  //--------------------------------------
  typedef struct packed {
    logic [7:0] num_beats;
    logic       is_single;
    logic       is_write_data;
  } xdma_req_w_desc_t;


  //--------------------------------------
  // addr decoder rule
  //--------------------------------------
  typedef struct packed {
    int unsigned idx;
    addr_t       start_addr;
    addr_t       end_addr;
  } rule_t;
  //--------------------------------------
  // addr decoder idx
  //--------------------------------------
  typedef enum int unsigned {
    FinishIdx  = 0,
    GrantIdx   = 1,
    CfgIdx     = 2,
    DataIdx    = 3
  } xdma_addr_offset_idx_e;

  typedef enum int unsigned {
    FromRemoteFinish = 0,
    FromRemoteGrant  = 1,
    FromRemoteCfg    = 2,
    NUM_NARROW_OUP = 3
  } xdma_narrow_from_remote_idx_e;


  //--------------------------------------
  // Reqrsp Type for Standalone Test
  //-------------------------------------- 
  typedef enum logic [3:0] {
    AMONone = 4'h0,
    AMOSwap = 4'h1,
    AMOAdd  = 4'h2,
    AMOAnd  = 4'h3,
    AMOOr   = 4'h4,
    AMOXor  = 4'h5,
    AMOMax  = 4'h6,
    AMOMaxu = 4'h7,
    AMOMin  = 4'h8,
    AMOMinu = 4'h9,
    AMOLR   = 4'hA,
    AMOSC   = 4'hB
  } amo_op_e;

  // Wide reqrsp
  typedef struct packed {
    addr_t        addr;
    logic         write;
    amo_op_e      amo;
    wide_data_t   data;
    wide_strb_t   strb;
    logic [2:0]   size;
    logic         q_valid;
    logic         p_ready;
  } reqrsp_wide_req_t;

  typedef struct packed {
    wide_data_t   data;
    logic         error;
    logic         p_valid;
    logic         q_ready;
  } reqrsp_wide_rsp_t;

  // Narrow reqrsp
  typedef struct packed {
    addr_t        addr;
    logic         write;
    amo_op_e      amo;
    narrow_data_t data;
    narrow_strb_t strb;
    logic [2:0]   size;
    logic         q_valid;
    logic         p_ready;
  } reqrsp_narrow_req_t;

  typedef struct packed {
    narrow_data_t data;
    logic         error;
    logic         p_valid;
    logic         q_ready;
  } reqrsp_narrow_rsp_t;


endpackage
