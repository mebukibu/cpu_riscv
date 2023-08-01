`include "consts.vh"

`define IDLE  3'b000
`define IF    3'b001
`define ID    3'b010
`define EX    3'b011
`define MEM   3'b100
`define WB    3'b101

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
  // State Machine

  reg [2:0] state;
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) state <= `IDLE;
    else begin
      case (state)
        `IDLE   : state <= `IF;
        `IF     : state <= `ID;
        `ID     : state <= `EX;
        `EX     : state <= `MEM;
        `MEM    : state <= `WB;
        `WB     : state <= `IF; 
        default : state <= 3'bXXX; 
      endcase
    end
  end

  //**********************************
  // Instruction Fetch (IF) Stage

  initial pc_reg <= `START_ADDR;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) pc_reg <= `START_ADDR;
    else if (state == `WB) pc_reg <= pc_reg + 1;
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
    else if (state == `ID) begin
      rs1_addr <= inst[19:15];
      rs2_addr <= inst[24:20];
      wb_addr <= inst[11:7];
    end
  end

  assign rs1_data = (rs1_addr != `ADDR_LEN'b0) ? regfile[rs1_addr] : `WORD_LEN'b0;
  assign rs2_data = (rs2_addr != `ADDR_LEN'b0) ? regfile[rs2_addr] : `WORD_LEN'b0;

  assign exit = (inst == `WORD_LEN'h34333231);

endmodule