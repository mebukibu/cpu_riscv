`include "consts.vh"

module core (
  input wire clk,
  input wire rst_n,
  input wire [`WORD_LEN-1:0] inst,
  output wire [`WORD_LEN-1:0] addr,
  output wire exit
);

  reg [`WORD_LEN-1:0] regfile [0:`ADDR_LEN-1];
  reg [`WORD_LEN-1:0] pc_reg;

  //**********************************
  // Instruction Fetch (IF) Stage

  initial pc_reg <= `START_ADDR;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) pc_reg <= `START_ADDR;
    else pc_reg <= pc_reg + 1;
  end

  assign addr = pc_reg;

  assign exit = (inst == `WORD_LEN'h34333231);

  initial begin
    pc_reg <= `START_ADDR;
  end
  
endmodule