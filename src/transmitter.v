module transmitter (
  input wire clk,
  input wire rst_n,
  input wire [7:0] data_in,
  input wire we,
  output wire data_out,
  output reg busy
);

  parameter WAIT_DIV = 868;  // 100 MHz / 115.2 kbs
  localparam WAIT_LEN = 10;  // 2^10 = 1024 > 868

  localparam STATE_IDLE = 1'b0;
  localparam STATE_SEND = 1'b1;

  reg state, n_state;
  reg [9:0] data_reg, n_data_reg;
  reg [WAIT_LEN-1:0] wait_cnt, n_wait_cnt;
  reg [3:0] bit_cnt, n_bit_cnt;

  assign data_out = data_reg[0];

  always @(*) begin
    busy = 1'b0;
    n_state = state;
    n_wait_cnt = wait_cnt;
    n_bit_cnt = bit_cnt;
    n_data_reg = data_reg;
    if (state == STATE_IDLE) begin
      if (we) begin
        n_state = STATE_SEND;
        n_data_reg = {1'b1, data_in, 1'b0};
      end
    end
    else if (state == STATE_SEND) begin
      busy = 1'b1;
      if (wait_cnt == WAIT_DIV - 1) begin
        if (bit_cnt == 4'd9) begin
          n_state = STATE_IDLE;
          n_wait_cnt = 0;
          n_bit_cnt = 4'd0;
        end
        else begin
          n_data_reg = {1'b1, data_reg[9:1]};
          n_wait_cnt = 0;
          n_bit_cnt = n_bit_cnt + 1'b1;
        end
      end
      else begin
        n_wait_cnt = wait_cnt + 1'b1;
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      state <= STATE_IDLE;
      wait_cnt <= 0;
      bit_cnt <= 4'b0;
      data_reg <= 10'h3ff;
    end
    else begin
      state <= n_state;
      wait_cnt <= n_wait_cnt;
      bit_cnt <= n_bit_cnt;
      data_reg <= n_data_reg;
    end
  end

endmodule