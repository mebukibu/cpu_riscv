module fifo #(
    parameter WIDTH    = 8,
    parameter SIZE     = 32,
    parameter LOG_SIZE = 5
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] wdata,
    output wire [WIDTH-1:0] rdata,
    input  wire wen,
    input  wire ren,
    output reg  empty,
    output reg  full
  );

  reg  [WIDTH-1:0] fifo_ram [0:SIZE-1];
  reg  [WIDTH-1:0] ram_out, d_wdata;
  reg  ram_select;
  wire write_valid, read_valid;
  reg  [LOG_SIZE-1:0] head, tail;
  wire [LOG_SIZE-1:0] n_head, n_tail;
  wire n_empty, n_near_empty;
  reg  near_empty;
  wire n_full, n_near_full;
  reg  near_full;

  // when read and write access same address, process here
  assign rdata = ram_select ? ram_out : d_wdata;
  
  always @ (posedge clk) begin
    if (write_valid) begin
      ram_select <= (n_head != tail);
      d_wdata   <= wdata;
    end else begin
      ram_select <= 1'b1;
    end
  end

  always @ (posedge clk) begin
    ram_out <= fifo_ram[n_head];
    if (write_valid) begin
      fifo_ram[tail] <= wdata;
    end
  end

  // controll read and write
  assign read_valid   = ren & ~empty;
  assign write_valid  = wen & ~full;
  assign n_head       = read_valid  ? head + 1'b1 : head;
  assign n_tail       = write_valid ? tail + 1'b1 : tail;
  assign n_empty      = ~write_valid & (empty | (read_valid & near_empty));
  assign n_full       = ~read_valid  & (full  | (write_valid & near_full));
  assign n_near_empty = (n_head + 1'b1 == n_tail);
  assign n_near_full  = (n_head == n_tail + 1'b1);

  always @ (posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      head  <= 0;
      tail  <= 0;
      empty <= 1'b1;
      full  <= 1'b0;
      near_empty <= 1'b0;
      near_full  <= 1'b0;
    end else begin
      head  <= n_head;
      tail  <= n_tail;
      empty <= n_empty;
      full  <= n_full;
      near_empty <= n_near_empty;
      near_full  <= n_near_full;
    end
  end
endmodule