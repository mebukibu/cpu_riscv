`include "consts.vh"

module memory #(
  parameter integer depth = 4096
) (
  input wire clk,
  // ImemPort
  input wire [`WORD_LEN-1:0] addr_i,
  output reg [`WORD_LEN-1:0] inst,
  // DmemPort
  input wire [`WORD_LEN-1:0] addr_d,
  output reg [`WORD_LEN-1:0] rdata,
  input wire wen,
  input wire [`WORD_LEN-1:0] wdata
);

  (* ram_style = "block" *)
  reg [`WORD_LEN-1:0] mem [0:depth-1];

  always @(posedge clk) begin
    inst <= mem[addr_i[11:2]];
    rdata <= mem[addr_d[11:2]];
    if (wen) mem[addr_d[11:2]] <= wdata;
  end

  initial begin
    $readmemh("/home/masato/src/cpu_riscv/hex/minitests/ctest.hex", mem);
  end
  
endmodule