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
    inst <= mem[addr_i[`WORD_LEN-1:2]];
    rdata <= mem[addr_d[`WORD_LEN-1:2]];
    if (wen) mem[addr_d[`WORD_LEN-1:2]] <= wdata;
  end

  initial begin
    $readmemh("C:/Users/masato/src/cpu_riscv/hex/riscv-tests/rv32ui-p-add.hex", mem);
  end
  
endmodule