`include "consts.vh"

module memory #(
  parameter integer depth = 12      // 2^12 = 4096
) (
  input wire clk,
  // ImemPort
  input wire [`WORD_LEN-1:0] addr_i,
  output reg [`WORD_LEN-1:0] inst,
  // DmemPort
  input wire [`WORD_LEN-1:0] addr_d,
  output reg [`WORD_LEN-1:0] rdata
);

  (* ram_style = "block" *)
  reg [`WORD_LEN-1:0] mem [0:depth-1];

  always @(posedge clk) begin
    inst <= mem[addr_i[`WORD_LEN-1:2]];
    rdata <= mem[addr_d[`WORD_LEN-1:2]];
  end

  initial begin
    $readmemh("C:/Users/masato/src/cpu_riscv/hex/lw.hex", mem);
  end
  
endmodule