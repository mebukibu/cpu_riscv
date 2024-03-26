`include "consts.vh"

module top (
  input wire clk,
  input wire rst_n,
  output wire exit,
  input wire uart_in,
  output wire uart_out
);

  parameter WAIT_DIV = 868;  // 100 MHz / 115.2 kbs

  // For core
  wire [`WORD_LEN-1:0] addr_i;
  wire [`WORD_LEN-1:0] inst;
  wire [`WORD_LEN-1:0] rdata_core;
  wire [`WORD_LEN-1:0] addr_d;
  wire wen_core;
  wire [`WORD_LEN-1:0] wdata;

  // For memory
  wire [`WORD_LEN-1:0] rdata_mem;
  wire wen_mem;

  // For uart
  wire [`WORD_LEN-1:0] rdata_uart;
  wire wen_uart;

  // For Controller
  wire is_uart;
  reg wen_core_delay, is_uart_delay;


  //**********************************
  // assign

  assign is_uart = ((addr_d & ~`WORD_LEN'b111) == `UART_ADDR);

  assign rdata_core = is_uart_delay ? rdata_uart : rdata_mem;
  assign wen_mem = wen_core;
  assign wen_uart = wen_core & wen_core_delay & is_uart;


  //**********************************
  // Controller
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      wen_core_delay <= 1'b0;
      is_uart_delay <= 1'b0;
    end
    else begin
      wen_core_delay <= wen_core;
      is_uart_delay <= is_uart;
    end
  end


  //**********************************
  // Instance

  // core
  core core0 (
    .clk(clk),
    .rst_n(rst_n),
    .exit(exit),
    // ImemPort
    .inst(inst),
    .addr_i(addr_i),
    // DmemPort
    .rdata(rdata_core),
    .addr_d(addr_d),
    .wen(wen_core),
    .wdata(wdata)
  );

  // memory
  memory memory0 (
    .clk(clk),
    // ImemPort
    .addr_i(addr_i),
    .inst(inst),
    // DmemPort
    .addr_d(addr_d),
    .rdata(rdata_mem),
    .wen(wen_mem),
    .wdata(wdata)
  );

  // uart
  uart #(
    .WAIT_DIV(WAIT_DIV)
  ) uart0 (
    .clk(clk),
    .rst_n(rst_n),
    .addr(addr_d),
    .rdata(rdata_uart),
    .wen(wen_uart),
    .wdata(wdata),
    .uart_in(uart_in),
    .uart_out(uart_out)
  );
  
endmodule