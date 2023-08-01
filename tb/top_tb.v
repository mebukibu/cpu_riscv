module top_tb ();

  reg clk;
  reg rst_n;
  wire exit;

  top top0 (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n = 0; #20
    rst_n = 1; #5
    #200
    $finish;
  end

endmodule