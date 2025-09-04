module Mux10x1
(
  input [9:0] in,
  input [3:0] sel,
  output  Tx
);
assign Tx=in[sel];
endmodule
