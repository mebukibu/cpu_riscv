module receiver (
  input wire clk,
  input wire rst_n,
  input wire data_in,
  output wire [7:0] data_out,
  output reg ren,
  output reg busy
);

  parameter WAIT_DIV = 868;  // 100 MHz / 115.2 kbs
  localparam WAIT_LEN = 10;  // 2^10 = 1024 > 868

  localparam STATE_IDLE = 1'b0;
  localparam STATE_RECV = 1'b1;

  reg state, n_state;
  reg [9:0] data_reg, n_data_reg;
  reg [WAIT_LEN-1:0] wait_cnt, n_wait_cnt;
  reg [3:0] bit_cnt, n_bit_cnt;

  assign data_out = data_reg[8:1];

  always @(*) begin
    busy = 1'b0;
    ren = 1'b0;
    n_state = state;
    n_wait_cnt = wait_cnt;
    n_bit_cnt = bit_cnt;
    n_data_reg = data_reg;
    if (state == STATE_IDLE) begin
      if (!data_in)
        n_state = STATE_RECV;
    end
    else if (state == STATE_RECV) begin
      busy = 1'b1;
      if (bit_cnt == 4'd9) begin
        ren = 1'b1;
        n_state = STATE_IDLE;
        n_wait_cnt = 0;
        n_bit_cnt = 4'd0;
      end
      else if (wait_cnt == WAIT_DIV - 1) begin
        n_wait_cnt = 0;
        n_bit_cnt = n_bit_cnt + 1'b1;
      end
      else begin
        n_wait_cnt = wait_cnt + 1'b1;
        n_data_reg[bit_cnt] = data_in;
      end      
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      state <= STATE_IDLE;
      wait_cnt <= 0;
      bit_cnt <= 4'b0;
      data_reg <= 10'h0;
    end
    else begin
      state <= n_state;
      wait_cnt <= n_wait_cnt;
      bit_cnt <= n_bit_cnt;
      data_reg <= n_data_reg;
    end
  end
  
endmodule