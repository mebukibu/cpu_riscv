`include "consts.vh"

module uart (
  input wire clk,
  input wire rst_n,
  input wire [`WORD_LEN-1:0] addr,
  output reg [`WORD_LEN-1:0] rdata,
  input wire wen,
  input wire [`WORD_LEN-1:0] wdata,
  input wire uart_in,
  output wire uart_out
);

  parameter WAIT_DIV = 868;  // 100 MHz / 115.2 kbs

  localparam STATE_IDLE = 1'b0;
  localparam STATE_RECV = 1'b1;

  // registers
  genvar i;
  integer j;
  reg [`UART_LEN-1:0]   regfile [0:`UART_LEN-1];
  reg [`UART_LEN-1:0] n_regfile [0:`UART_LEN-1];

  // For transmitter/receiver
  wire busy_trans, busy_recv;

  // For fifo_trans
  wire [`UART_LEN-1:0] wdata_fifo_trans, rdata_fifo_trans;
  reg wen_fifo_trans;
  wire ren_fifo_trans;
  wire empty_fifo_trans, full_fifo_trans;

  // For fifo_recv
  wire [`UART_LEN-1:0] wdata_fifo_recv, rdata_fifo_recv;
  wire wen_fifo_recv;
  reg ren_fifo_recv;
  wire empty_fifo_recv, full_fifo_recv;

  // For Controller
  reg state_recv, n_state_recv;
  wire writeTHR, readRHR;
  wire [`WORD_LEN-1:0] n_rdata;
  reg n_wen_fifo_trans, n_ren_fifo_recv;


  //**********************************
  // assign

  assign wdata_fifo_trans = regfile[`UART_THR];
  assign ren_fifo_trans   = !busy_trans & !empty_fifo_trans;

  assign writeTHR =  wen & (addr == `UART_ADDR + `UART_THR) & regfile[`UART_LSR][`LSR_TX_IDLE];
  assign readRHR  = !wen & (addr == `UART_ADDR + `UART_RHR) & regfile[`UART_LSR][`LSR_RX_READY];
  assign n_rdata  = (addr[2]) ? {regfile[7], regfile[6], regfile[5], regfile[4]}
                              : {regfile[3], regfile[2], regfile[1], regfile[0]};


  //**********************************
  // Controller

  generate
    for (i = 0; i < `UART_LEN; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
          regfile[i] <= `UART_LEN'b0;
        else
          regfile[i] <= n_regfile[i];
      end
    end
  endgenerate

  always @(*) begin
    n_state_recv = state_recv;
    n_wen_fifo_trans = 1'b0;
    n_ren_fifo_recv = 1'b0;
    for (j = 0; j < `UART_LEN; j = j + 1) begin
      n_regfile[j] = regfile[j];
    end

    if (wen) begin
      case (addr[2])
        1'b0 : for (j = 0; j < `WORD_LEN / `UART_LEN; j = j + 1) begin
                 n_regfile[j]   = wdata[j*`UART_LEN +: `UART_LEN];
               end
        1'b1 : for (j = 0; j < `WORD_LEN / `UART_LEN; j = j + 1) begin
                 n_regfile[j+4] = wdata[j*`UART_LEN +: `UART_LEN];
               end
      endcase
      if (writeTHR) begin
        n_wen_fifo_trans = 1'b1;
      end
    end
    else begin
      if (full_fifo_trans)
        n_regfile[`UART_LSR] = regfile[`UART_LSR] & ~(1'b1 << `LSR_TX_IDLE);
      else
        n_regfile[`UART_LSR] = regfile[`UART_LSR] | (1'b1 << `LSR_TX_IDLE);
      
      if (state_recv == STATE_IDLE) begin
        if (!empty_fifo_recv) begin
          n_state_recv = STATE_RECV;
          n_ren_fifo_recv = 1'b1;
          n_regfile[`UART_RHR] = rdata_fifo_recv;
          n_regfile[`UART_LSR] = regfile[`UART_LSR] | (1'b1 << `LSR_RX_READY);
        end
      end
      else if (state_recv == STATE_RECV) begin
        if (readRHR) begin
          n_state_recv = STATE_IDLE;
          n_regfile[`UART_LSR] = regfile[`UART_LSR] & ~(1'b1 << `LSR_RX_READY);
        end
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      state_recv <= STATE_IDLE;
      wen_fifo_trans <= 1'b0;
      ren_fifo_recv <= 1'b0;
      rdata <= `WORD_LEN'b0;
    end
    else begin
      state_recv <= n_state_recv;
      wen_fifo_trans <= n_wen_fifo_trans;
      ren_fifo_recv <= n_ren_fifo_recv;
      rdata <= n_rdata;
    end
  end


  //**********************************
  // Instance

  // transmitter
  transmitter #(
    .WAIT_DIV(WAIT_DIV)
  ) transmitter0 (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(rdata_fifo_trans),
    .wen(ren_fifo_trans),
    .data_out(uart_out),
    .busy(busy_trans)
  );

  // receiver
  receiver #(
    .WAIT_DIV(WAIT_DIV)
  ) receiver0 (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(uart_in),
    .data_out(wdata_fifo_recv),
    .ren(wen_fifo_recv),
    .busy(busy_recv)
  );

  // fifo_trans
  fifo #(
    .WIDTH(`UART_LEN),
    .SIZE(32),
    .LOG_SIZE(5)
  ) fifo_trans (
    .clk(clk),
    .rst_n(rst_n),
    .wdata(wdata_fifo_trans),
    .rdata(rdata_fifo_trans),
    .wen(wen_fifo_trans),
    .ren(ren_fifo_trans),
    .empty(empty_fifo_trans),
    .full(full_fifo_trans)
  );

  // fifo_recv
  fifo #(
    .WIDTH(`UART_LEN),
    .SIZE(32),
    .LOG_SIZE(5)
  ) fifo_recv (
    .clk(clk),
    .rst_n(rst_n),
    .wdata(wdata_fifo_recv),
    .rdata(rdata_fifo_recv),
    .wen(wen_fifo_recv),
    .ren(ren_fifo_recv),
    .empty(empty_fifo_recv),
    .full(full_fifo_recv)
  );

endmodule