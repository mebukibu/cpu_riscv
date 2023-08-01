`include "consts.vh"

module memory #(
  parameter integer depth = 12      // 2^12 = 4096
) (
  input wire clk,
  input wire [`WORD_LEN-1:0] addr,
  output reg [`WORD_LEN-1:0] inst
);

  (* ram_style = "block" *)
  reg [`WORD_LEN-1:0] mem [0:depth-1];

  always @(posedge clk) begin
    inst <= mem[addr];
  end

  initial begin
    $readmemh("C:/Users/masato/src/cpu_riscv/hex/fetch.hex", mem);
  end
  
endmodule