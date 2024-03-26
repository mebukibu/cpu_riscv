`include "consts.vh"

module uart_tb ();

  
  reg clk;
  reg rst_n;
  reg [`WORD_LEN-1:0] addr;
  wire [`WORD_LEN-1:0] rdata;
  reg wen;
  reg [`WORD_LEN-1:0] wdata;
  reg uart_in;
  wire uart_out;

  parameter WAIT_DIV = 8;

  uart #(WAIT_DIV) uart0 (.*);


  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars(0, uart0.regfile[`UART_LSR]);
  end

  initial begin
    $dumpvars;
    // test transmitter
    $display("--------------------");
    $display("test transmitter");
    rst_n = 0; uart_in = 1;
    wen = 0; addr = `WORD_LEN'h8000; wdata = `WORD_LEN'h0; #20;
    rst_n = 1;
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    #20;
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    #10;
    addr = `WORD_LEN'h1000; wdata = `WORD_LEN'h0041; #10;
    wen = 1; #10;
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    wen = 0; #10;
    addr = `WORD_LEN'h1000; wdata = `WORD_LEN'h000a; #10;
    wen = 1; #10;
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    wen = 0; #10;
    #50;
    wait (uart0.busy_trans == 1'b0); #50;
    wait (uart0.busy_trans == 1'b0); #5;
    #30;
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    #100;

    // test receiver
    $display("--------------------");
    $display("test receiver");
    addr = `WORD_LEN'h8000;
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    #10;
    uart_tx(8'h42);
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    uart_tx(8'h5a);
    #20;
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    #10;
    $display("regfile[0] = 0x%h", uart0.regfile[0]);
    $display("regfile[5] = 0x%h", uart0.regfile[5]);
    #10;
    addr = `WORD_LEN'h1000;
    #50;
    $finish;
  end

  task uart_tx;
    input [7:0] data;
    integer i;
    integer BIT_CYC;

    begin
      BIT_CYC = WAIT_DIV * 10;
      uart_in = 1'b0;
      #BIT_CYC;
      for (i = 0; i < 8; i = i + 1) begin
        uart_in = data[i];
        #BIT_CYC;
      end
      uart_in = 1'b1;
      #BIT_CYC;
    end
  endtask

endmodule