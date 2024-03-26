module top_shell_tb ();

  reg clk;
  reg rst_n;
  wire exit;
  reg uart_in;
  wire uart_out;

  parameter WAIT_DIV = 8;  // 100 MHz / 115.2 kbs

  integer i;

  top #(WAIT_DIV) top0 (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n = 0; uart_in = 1; #20;
    rst_n = 1; #10;

    // Set up
    wait_1024(32);

    // Send "A\r"
    uart_tx(8'h41);
    wait_1024(1);
    uart_tx(8'h0d);
    wait_1024(32);

    // Send "hello\r"
    uart_tx(8'h68);
    wait_1024(1);
    uart_tx(8'h65);
    wait_1024(1);
    uart_tx(8'h6c);
    wait_1024(1);
    uart_tx(8'h6c);
    wait_1024(1);
    uart_tx(8'h6f);
    wait_1024(1);
    uart_tx(8'h0d);
    wait_1024(32);

    // Send "exit\r"
    uart_tx(8'h65);
    wait_1024(1);
    uart_tx(8'h78);
    wait_1024(1);
    uart_tx(8'h69);
    wait_1024(1);
    uart_tx(8'h74);
    wait_1024(1);
    uart_tx(8'h0d);
    wait_1024(32);

    $display("");
    $finish;
  end

  task wait_1024;
    input [7:0] num;
    integer i;

    for (i = 0; i < num * 1024; i = i + 1) begin
      wait (top0.core0.state == 3'b100);
      if (top0.core0.wen & top0.core0.addr_d == 32'h1000) begin
        $write("%s", top0.core0.wdata[7:0]);
      end
      #10;
    end
  endtask

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