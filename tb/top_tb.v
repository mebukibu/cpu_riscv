module top_tb ();

  reg clk;
  reg rst_n;
  wire exit;
  wire uart_in;
  wire uart_out;

  integer i;

  top top0 (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n = 0; #20;
    rst_n = 1; #5;

    for (i = 0; i < 13 * 1024; i = i + 1) begin
      #45;
      $display("pc_reg    : 0x%h", top_tb.top0.core0.pc_reg);
      $display("inst      : 0x%h", top_tb.top0.core0.inst);
      $display("rs1_addr  : %d", top_tb.top0.core0.rs1_addr);
      $display("rs2_addr  : %d", top_tb.top0.core0.rs2_addr);
      $display("wb_addr   : %d", top_tb.top0.core0.wb_addr);
      $display("rs1_data  : 0x%h", top_tb.top0.core0.rs1_data);
      $display("rs2_data  : 0x%h", top_tb.top0.core0.rs2_data);
      $display("wb_data   : 0x%h", top_tb.top0.core0.wb_data);
      // $display("addr_d    : %d", top_tb.top0.core0.addr_d);
      // $display("wen       :  %d", top_tb.top0.core0.wen);
      // $display("wdata     : 0x%h", top_tb.top0.core0.wdata);
      // $display("gp        : 0x%h", top_tb.top0.core0.gp);
      $display("exit      : %d", exit);
      $display("---------");
      #5;
    end
    #50;
    $finish;
  end

endmodule