`include "consts.vh"

module uart (
  input wire clk,
  input wire rst_n,
  output wire intr,
  input wire [`WORD_LEN-1:0] rdata,
  input wire wen_mem,
  input wire [`WORD_LEN-1:0] addr_d_mem,
  input wire [`WORD_LEN-1:0] wdata_mem,
  output wire wen_uart,
  output wire [`WORD_LEN-1:0] addr_d_uart,
  output wire [`WORD_LEN-1:0] wdata_uart
);

  // Debug
  assign intr = 0;

  // register
  reg [`UART_LEN-1:0] uart_regfile [0:`UART_LEN-1];
  integer i;


  //**********************************
  // Memory Mapped

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < `UART_LEN; i = i + 1) begin
        uart_regfile[i] <= `UART_LEN'b0;
      end
      uart_regfile[`UART_LSR] <= `LSR_TX_IDLE;
    end
    else if (wen_mem & ((addr_d_mem & ~`WORD_LEN'b111) == `UART_ADDR)) begin
      case (addr_d_mem[2])
        1'b0 : for (i = 0; i < `WORD_LEN / `UART_LEN; i = i + 1) begin
                uart_regfile[i]   <= rdata[i*`UART_LEN +: `UART_LEN];
               end
        1'b1 : for (i = 0; i < `WORD_LEN / `UART_LEN; i = i + 1) begin
                uart_regfile[i+4] <= rdata[i*`UART_LEN +: `UART_LEN];
               end
      endcase
    end
  end
  
endmodule