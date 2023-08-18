module top_tb ();

  reg clk;
  reg rst_n;
  wire exit;
  wire uart_out;

  integer i;

  top top0 (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n = 0; #20;
    rst_n = 1; #5;

    for (i = 0; exit != 1'b1; i = i + 1) begin
      wait (top_tb.top0.core0.state == 3'b101);
      if (top_tb.top0.core0.wen == 1'b1 & top_tb.top0.core0.addr_d == 32'h1000 & !top_tb.top0.intr) begin
        $write("%s", top_tb.top0.core0.wdata[7:0]);
      end
      #10;
    end
    $display("");
    $finish;
  end

endmodule