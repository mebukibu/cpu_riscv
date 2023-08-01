`include "consts.vh"

module top (
  input wire clk,
  input wire rst_n,
  output wire exit
);

  wire [`WORD_LEN-1:0] addr;
  wire [`WORD_LEN-1:0] inst;

  core core0 (
    .clk(clk),
    .rst_n(rst_n),
    .inst(inst),
    .addr(addr),
    .exit(exit)
  );

  memory memory0 (
    .clk(clk),
    .addr(addr),
    .inst(inst)
  );
  
endmodule