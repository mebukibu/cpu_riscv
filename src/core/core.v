`include "consts.vh"

module core (
  input wire clk,
  input wire rst_n,
  input wire [`WORD_LEN-1:0] inst,
  output wire [`WORD_LEN-1:0] addr,
  output wire exit
);

  // For IF
  reg [`WORD_LEN-1:0] regfile [0:`ADDR_LEN-1];
  reg [`WORD_LEN-1:0] pc_reg;
  reg [`WORD_LEN-1:0] inst_reg;

  // For ID
  reg [`ADDR_LEN-1:0] rs1_addr;
  reg [`ADDR_LEN-1:0] rs2_addr;
  reg [`ADDR_LEN-1:0] wb_addr;
  wire [`WORD_LEN-1:0] rs1_data;
  wire [`WORD_LEN-1:0] rs2_data;

  //**********************************
  // Instruction Fetch (IF) Stage

  initial pc_reg <= `START_ADDR;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) pc_reg <= `START_ADDR;
    else pc_reg <= pc_reg + 1;
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) inst_reg <= 0;
    else inst_reg <= inst;
  end

  assign addr = pc_reg;

  //**********************************
  // Instruction Decode (ID) Stage

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      rs1_addr <= 0;
      rs2_addr <= 0;
      wb_addr <= 0;
    end
    else begin
      rs1_addr <= inst_reg[19:15];
      rs2_addr <= inst_reg[24:20];
      wb_addr <= inst_reg[11:7];
    end
  end

  assign rs1_data = (rs1_addr != `ADDR_LEN'b0) ? regfile[rs1_addr] : `WORD_LEN'b0;
  assign rs2_data = (rs2_addr != `ADDR_LEN'b0) ? regfile[rs2_addr] : `WORD_LEN'b0;

  assign exit = (inst == `WORD_LEN'h34333231);

endmodule