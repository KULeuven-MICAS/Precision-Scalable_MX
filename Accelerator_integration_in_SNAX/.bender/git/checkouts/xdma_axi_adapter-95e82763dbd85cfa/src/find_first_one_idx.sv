// Authors:
// - Fanchen Kong <fanchen.kong@kuleuven.be>
// - Yunhao Deng <yunhao.deng@kuleuven.be>
module find_first_one_idx #(
    parameter int unsigned N = 4,
    /// Dependent parameters, DO NOT OVERRIDE!
    parameter integer LOG_N_INP = $clog2(N)
) (
    input  logic [        N-1:0] in_i,
    output logic [LOG_N_INP-1:0] idx_o,
    output logic                 valid_o
);
  if (N==32'd1) begin : gen_direct
    // if the input is only 1
    // make direct connection
    assign valid_o = in_i;
    assign idx_o = '0;
  end else begin : gen_find_idx
    // else the input is more than 1
    // generate the find_idx circuit 
    logic found;
    always_comb begin : find_idx
      idx_o   = '0;
      valid_o = |in_i;
      found   = 1'b0;
      for (int i = 0; i < N; i++) begin
        // We search from the MSB to LSB
        // In our xdma case the narrow inputs are (cfg,grant,finish)
        // The cfg has the highest priority
        if (!found && in_i[N-i]) begin
          idx_o = LOG_N_INP'(N-i);
          found = 1'b1;
        end
      end
    end    
  end

endmodule
