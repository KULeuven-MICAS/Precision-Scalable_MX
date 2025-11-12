// Authors:
// - Fanchen Kong <fanchen.kong@kuleuven.be>
// - Yunhao Deng <yunhao.deng@kuleuven.be>
module dw_down_converter #(
    parameter int unsigned INPUT_DW  = 512,
    parameter int unsigned OUTPUT_DW = 64,
    // Dependent parameters, DO NOT OVERRIDE!
    parameter int unsigned DOWN_RATIO = INPUT_DW / OUTPUT_DW
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

    // Counter width must be at least $clog2(DOWN_RATIO)
    localparam int unsigned CNT_WIDTH = $clog2(DOWN_RATIO);

    logic [CNT_WIDTH-1:0] counter_q;
    logic                 counter_en, counter_clr;

    // Counter instantiation
    counter #(
        .WIDTH(CNT_WIDTH),
        .STICKY_OVERFLOW(1'b0)
    ) u_counter (
        .clk_i       (clk_i),
        .rst_ni      (rst_ni),
        .clear_i     (counter_clr),
        .en_i        (counter_en),
        .load_i      (1'b0),
        .down_i      (1'b0),
        .d_i         ('0),
        .q_o         (counter_q),
        .overflow_o  (/* Not connect*/)
    );


    typedef enum logic [1:0] {
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

    // Next state logic
    always_comb begin
        next_state = cur_state;
        case (cur_state)
        // Any of the valid is high, the next state is busy
        IDLE: if (valid_i) next_state = BUSY;
        BUSY: if ((counter_q == DOWN_RATIO - 1)) next_state = IDLE;
        endcase
    end

    // Output logic
    always_comb begin
        // Default values
        ready_o = 1'b0;
        valid_o = 1'b0;
        data_o = '0;
        counter_en = 1'b0;
        counter_clr = 1'b0;
        case (cur_state)
        IDLE: begin
            data_o = '0;
            valid_o = 1'b0;
            ready_o = 1'b0;
            counter_en = 1'b0;
            counter_clr = 1'b1;
        end
        BUSY: begin
            data_o = data_i[OUTPUT_DW * counter_q +: OUTPUT_DW];
            valid_o = 1'b1;
            ready_o = ready_i && (counter_q == DOWN_RATIO - 1);
            counter_en = ready_i;
            counter_clr = ready_i && (counter_q == DOWN_RATIO - 1);
        end
        endcase
    end

    initial begin
        assert (INPUT_DW % OUTPUT_DW == 0)
            else $fatal("INPUT_DW must be an integer multiple of OUTPUT_DW.");
    end
endmodule
