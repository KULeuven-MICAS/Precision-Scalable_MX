// Authors:
// - Fanchen Kong <fanchen.kong@kuleuven.be>
// - Yunhao Deng <yunhao.deng@kuleuven.be>

module dw_up_converter #(
    parameter int unsigned INPUT_DW = 64,
    parameter int unsigned OUTPUT_DW = 512,
    /// Dependent parameters, DO NOT OVERRIDE!
    parameter int unsigned UP_RATIO = OUTPUT_DW / INPUT_DW
) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic [INPUT_DW-1:0]  data_i,
    input  logic                 valid_i,
    output logic                 ready_o,
    output logic [OUTPUT_DW-1:0] data_o,
    output logic                 valid_o,
    input  logic                 ready_i
);
    // Counter width must be at least $clog2(UP_RATIO)
    localparam int unsigned CNT_WIDTH = $clog2(UP_RATIO);

    logic [CNT_WIDTH-1:0] count_q;
    logic                 counter_en, counter_clr, counter_load, counter_down;
    logic [CNT_WIDTH-1:0] counter_d;
    logic                 counter_overflow;

    logic [OUTPUT_DW-1:0] buffer_q;
    logic [OUTPUT_DW-1:0] buffer_d;
    logic                 buffer_we;

    // Counter instantiation
    counter #(
        .WIDTH(CNT_WIDTH),
        .STICKY_OVERFLOW(1'b0)
    ) u_counter (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .clear_i     (counter_clr),
        .en_i        (counter_en),
        .load_i      (counter_load),
        .down_i      (counter_down),
        .d_i         (counter_d),
        .q_o         (count_q),
        .overflow_o  (counter_overflow)
    );

    // Internal signals
    logic [$clog2(UP_RATIO):0] word_idx;
    assign word_idx = count_q;

    // Shift buffer input data into the right position
    always_comb begin
        buffer_d  = buffer_q;
        buffer_we = 1'b0;
        if (valid_i && ready_o) begin
            buffer_d[INPUT_DW * word_idx +: INPUT_DW] = data_i;
            buffer_we = 1'b1;
        end
    end

    // Output valid when all input words have been collected
    assign valid_o = (count_q == (UP_RATIO - 1)) && valid_i;

    // Handshake control
    assign ready_o = (!valid_o || ready_i); // Only take data if downstream can accept it

    // Buffer register update
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            buffer_q <= '0;
        end else if (buffer_we) begin
            buffer_q <= buffer_d;
        end
    end

    assign data_o = buffer_q;

    // Counter control logic
    always_comb begin
        counter_en   = valid_i && ready_o;
        counter_clr  = valid_o && ready_i; // reset counter when data_o is accepted
        counter_load = 1'b0;
        counter_d    = '0;
        counter_down = 1'b0;
    end
    
    initial begin
        assert (OUTPUT_DW % INPUT_DW == 0)
            else $fatal("OUTPUT_DW must be an integer multiple of INPUT_DW.");
    end
endmodule
