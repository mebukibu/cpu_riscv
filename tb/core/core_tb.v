`include "consts.vh"

module core_tb ();

  reg clk;
  reg rst_n;
  reg [`WORD_LEN-1:0] inst;
  wire [`WORD_LEN-1:0] addr;
  wire exit;

  core core0 (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n = 0; inst = 0; #5
    rst_n = 1; #5
    #100
    $finish;
  end

endmodule