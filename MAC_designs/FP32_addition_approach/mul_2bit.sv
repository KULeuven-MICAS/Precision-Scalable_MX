module mul_2bit
(
  input  logic [1:0] in1,
  input  logic [1:0] in2,
  output logic [3:0] out
);

assign out = in1*in2;

endmodule
