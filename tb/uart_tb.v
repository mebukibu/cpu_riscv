`include "consts.vh"

module uart_tb ();

  reg clk;
  reg rst_n;
  wire intr;
  wire wen_mem;
  wire [`WORD_LEN-1:0] addr_d_mem;
  wire [`WORD_LEN-1:0] wdata_mem;
  wire [`WORD_LEN-1:0] addr_d_uart;
  wire [`WORD_LEN-1:0] wdata_uart;
  wire uart_out;

  reg wen_core;
  reg [`WORD_LEN-1:0] addr_d_core;
  reg [`WORD_LEN-1:0] wdata_core;

  uart uart0 (.*);

  assign wen_mem    = intr ? intr        : wen_core;
  assign addr_d_mem = intr ? addr_d_uart : addr_d_core;
  assign wdata_mem  = intr ? wdata_uart  : wdata_core;

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n = 0; wen_core = 0; addr_d_core = `WORD_LEN'h8000; wdata_core = `WORD_LEN'h0; #20;
    rst_n = 1; #5;
    #11;
    addr_d_core = `WORD_LEN'h1000; wdata_core = `WORD_LEN'h0041; #9;
    wen_core = 1; #10
    $display("uart_regfile[0] = 0x%h", uart0.uart_regfile[0]);
    $display("uart_regfile[5] = 0x%h", uart0.uart_regfile[5]);
    #10;
    $display("uart_regfile[0] = 0x%h", uart0.uart_regfile[0]);
    $display("uart_regfile[5] = 0x%h", uart0.uart_regfile[5]);
    #10;
    wait (uart0.busy == 1'b0);
    #30;
    $display("uart_regfile[0] = 0x%h", uart0.uart_regfile[0]);
    $display("uart_regfile[5] = 0x%h", uart0.uart_regfile[5]);
    #10;
    $finish;
  end

endmodule