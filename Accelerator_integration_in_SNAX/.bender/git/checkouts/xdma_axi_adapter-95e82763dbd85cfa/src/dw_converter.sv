// Authors:
// - Fanchen Kong <fanchen.kong@kuleuven.be>
// - Yunhao Deng <yunhao.deng@kuleuven.be>

module dw_converter #(
    parameter int unsigned INPUT_DW  = 512,
    parameter int unsigned OUTPUT_DW = 64
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
    if (INPUT_DW>OUTPUT_DW) begin
        // Down converter
        dw_down_converter #(
            .INPUT_DW          (INPUT_DW),
            .OUTPUT_DW         (OUTPUT_DW)
        ) i_dw_down_converter (
            .clk_i       (clk_i  ),
            .rst_ni      (rst_ni ),
            .data_i      (data_i ),
            .valid_i     (valid_i),
            .ready_o     (ready_o),
            .data_o      (data_o ),
            .valid_o     (valid_o),
            .ready_i     (ready_i)
        );
    end else if (INPUT_DW<OUTPUT_DW) begin
        // Up converter
        dw_up_converter #(
            .INPUT_DW          (INPUT_DW),
            .OUTPUT_DW         (OUTPUT_DW)
        ) i_dw_up_converter (
            .clk_i       (clk_i  ),
            .rst_ni      (rst_ni ),
            .data_i      (data_i ),
            .valid_i     (valid_i),
            .ready_o     (ready_o),
            .data_o      (data_o ),
            .valid_o     (valid_o),
            .ready_i     (ready_i)
        );        
    end else begin
        // Not change, simple assign
        assign data_o  = data_i;
        assign valid_o = valid_i;
        assign ready_o = ready_i;
    end
endmodule
