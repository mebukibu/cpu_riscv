`include "consts.vh"

module top (
  input wire clk,
  input wire rst_n,
  output wire exit,
  output wire uart_out
);

  // For core
  wire intr;
  wire [`WORD_LEN-1:0] addr_i;
  wire [`WORD_LEN-1:0] inst;
  wire [`WORD_LEN-1:0] rdata;
  wire [`WORD_LEN-1:0] addr_d_core;
  wire wen_core;
  wire [`WORD_LEN-1:0] wdata_core;

  // For memory
  wire [`WORD_LEN-1:0] addr_d_mem;
  wire wen_mem;
  wire [`WORD_LEN-1:0] wdata_mem;

  // For uart
  wire [`WORD_LEN-1:0] addr_d_uart;
  wire wen_uart;
  wire [`WORD_LEN-1:0] wdata_uart;


  //**********************************
  // assign

  assign wen_mem    = intr ? 1'b1        : wen_core;
  assign addr_d_mem = intr ? addr_d_uart : addr_d_core;
  assign wdata_mem  = intr ? wdata_uart  : wdata_core;

  //**********************************
  // core

  core core0 (
    .clk(clk),
    .rst_n(rst_n),
    .intr(intr),
    .exit(exit),
    // ImemPort
    .inst(inst),
    .addr_i(addr_i),
    // DmemPort
    .rdata(rdata),
    .addr_d(addr_d_core),
    .wen(wen_core),
    .wdata(wdata_core)
  );


  //**********************************
  // memory

  memory memory0 (
    .clk(clk),
    // ImemPort
    .addr_i(addr_i),
    .inst(inst),
    // DmemPort
    .addr_d(addr_d_mem),
    .rdata(rdata),
    .wen(wen_mem),
    .wdata(wdata_mem)
  );


  //**********************************
  // uart

  uart uart0 (
    .clk(clk),
    .rst_n(rst_n),
    .intr(intr),
    .wen_mem(wen_mem),
    .addr_d_mem(addr_d_mem),
    .wdata_mem(wdata_mem),
    .addr_d_uart(addr_d_uart),
    .wdata_uart(wdata_uart),
    .uart_out(uart_out)
  );
  
endmodule