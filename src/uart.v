`include "consts.vh"

module uart (
  input wire clk,
  input wire rst_n,
  output reg intr,
  input wire wen_mem,
  input wire [`WORD_LEN-1:0] addr_d_mem,
  input wire [`WORD_LEN-1:0] wdata_mem,
  output reg [`WORD_LEN-1:0] addr_d_uart,
  output reg [`WORD_LEN-1:0] wdata_uart,
  output wire uart_out
);

  // register
  reg [`UART_LEN-1:0] uart_regfile [0:`UART_LEN-1];
  integer i;

  // For transmitter
  reg [`UART_LEN-1:0] data_in;
  reg wen_trans;
  wire busy;

  //**********************************
  // transmitter

  transmitter transmitter0 (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .we(wen_trans),
    .data_out(uart_out),
    .busy(busy)
  );


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
                uart_regfile[i]   <= wdata_mem[i*`UART_LEN +: `UART_LEN];
               end
        1'b1 : for (i = 0; i < `WORD_LEN / `UART_LEN; i = i + 1) begin
                uart_regfile[i+4] <= wdata_mem[i*`UART_LEN +: `UART_LEN];
               end
      endcase
    end
  end


  //**********************************
  // Controller

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      intr <= 1'b0;
      addr_d_uart <= `WORD_LEN'b0;
      wdata_uart <= `WORD_LEN'b0;
      wen_trans <= 1'b0;
      data_in <= `UART_LEN'b0;
    end
    else if (uart_regfile[`UART_LSR] & `LSR_TX_IDLE) begin
      if (wen_mem & (addr_d_mem == `UART_ADDR)) begin
        intr <= 1'b1;
        addr_d_uart <= `UART_ADDR + `UART_LSR;
        wdata_uart <= {uart_regfile[7], uart_regfile[6], (uart_regfile[`UART_LSR] & ~`LSR_TX_IDLE), uart_regfile[4]};
        wen_trans <= 1'b1;
        data_in <= wdata_mem[`UART_LEN-1:0];
      end
      else begin
        intr <= 1'b0;
      end
    end
    else begin
      wen_trans <= 1'b0;
      if (!busy) begin
        intr <= 1'b1;
        addr_d_uart <= `UART_ADDR + `UART_LSR;
        wdata_uart <= {uart_regfile[7], uart_regfile[6], (uart_regfile[`UART_LSR] | `LSR_TX_IDLE), uart_regfile[4]};
      end
    end
  end
  
endmodule