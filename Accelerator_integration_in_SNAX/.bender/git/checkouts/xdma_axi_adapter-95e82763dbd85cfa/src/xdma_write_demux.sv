// Fanchen Kong <fanchen.kong@kuleuven.be>
// Yunhao Deng <yunhao.deng@kuleuven.be>


// Pure combinatorial ckt

module xdma_write_demux #(
    parameter int unsigned N_OUP = 32'd1,
    parameter type data_t = logic,
    parameter type addr_t = logic,
    /// Rule packed struct type.
    /// The address decoder expects three fields in `rule_t`:
    ///
    /// typedef struct packed {
    ///   int unsigned idx;
    ///   addr_t       start_addr;
    ///   addr_t       end_addr;
    /// } rule_t;
    ///
    ///  - `idx`:        index of the rule, has to be < `NoIndices`
    ///  - `start_addr`: start address of the range the rule describes, value is included in range
    ///  - `end_addr`:   end address of the range the rule describes, value is NOT included in range
    ///                  if `end_addr == '0` end of address space is assumed
    ///
    /// If `Napot` is 1, The field names remain the same, but the rule describes a naturally-aligned
    /// power of two (NAPOT) region instead of an address range: `start_addr` becomes the base address
    /// and `end_addr` the mask. See the wrapping module `addr_decode_napot` for details.    
    parameter type rule_t = logic,
    /// DEPENDENT PARAMETER! DO NOT OVERRIDE
    parameter int unsigned LOG_N_OUP = (N_OUP > 32'd1) ? unsigned'($clog2(N_OUP)) : 1'b1,
    parameter type sel_t = logic [LOG_N_OUP-1:0]
) (
    // Input side
    input addr_t inp_addr_i,
    input rule_t [N_OUP-1:0] addr_map_i,
    input data_t inp_data_i,
    input logic inp_valid_i,
    output logic inp_ready_o,
    // Output side
    output data_t [N_OUP-1:0] oup_data_o,
    output logic [N_OUP-1:0] oup_valid_o,
    input logic [N_OUP-1:0] oup_ready_i
);
  sel_t oup_sel;
  logic addr_decode_valid;
  logic addr_decode_error;
  addr_decode #(
      .NoIndices(N_OUP),
      .NoRules  (N_OUP),
      .addr_t   (addr_t),
      .rule_t   (rule_t),
      .Napot    (0)
  ) i_addr_decode_write (
      .addr_i          (inp_addr_i),
      .addr_map_i      (addr_map_i),
      .idx_o           (oup_sel),
      .dec_valid_o     (addr_decode_valid),
      .dec_error_o     (addr_decode_error),
      .en_default_idx_i('0),
      .default_idx_i   ('0)
  );

  always_comb begin : proc_compose_output
    oup_data_o = '0;
    oup_valid_o = '0;
    oup_data_o[oup_sel] = inp_data_i;
    oup_valid_o[oup_sel] = inp_valid_i && (addr_decode_valid && !addr_decode_error);
    inp_ready_o = oup_ready_i[oup_sel] && (addr_decode_valid && !addr_decode_error);
  end
endmodule
