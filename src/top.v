`include "consts.vh"

module top (
  input wire clk,
  input wire rst_n,
  output wire exit
);

  wire [`WORD_LEN-1:0] addr_i;
  wire [`WORD_LEN-1:0] inst;
  wire [`WORD_LEN-1:0] addr_d;
  wire [`WORD_LEN-1:0] rdata;
  wire wen;
  wire [`WORD_LEN-1:0] wdata;

  core core0 (
    .clk(clk),
    .rst_n(rst_n),
    .exit(exit),
    // ImemPort
    .inst(inst),
    .addr_i(addr_i),
    // DmemPort
    .rdata(rdata),
    .addr_d(addr_d),
    .wen(wen),
    .wdata(wdata)
  );

  memory memory0 (
    .clk(clk),
    // ImemPort
    .addr_i(addr_i),
    .inst(inst),
    // DmemPort
    .addr_d(addr_d),
    .rdata(rdata),
    .wen(wen),
    .wdata(wdata)
  );
  
endmodule