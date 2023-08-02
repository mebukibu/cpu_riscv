`include "consts.vh"
`include "instructions.vh"

`define IDLE  3'b000
`define IF    3'b001
`define ID    3'b010
`define EX    3'b011
`define MEM   3'b100
`define WB    3'b101

module core (
  input wire clk,
  input wire rst_n,
  output wire exit,
  // ImemPort
  input wire [`WORD_LEN-1:0] inst,
  output wire [`WORD_LEN-1:0] addr_i,
  // DmemPort
  input wire [`WORD_LEN-1:0] rdata,
  output wire [`WORD_LEN-1:0] addr_d,
  output wire wen,
  output wire [`WORD_LEN-1:0] wdata
);

  // For IF
  reg [`WORD_LEN-1:0] regfile [0:`WORD_LEN-1];
  reg [`WORD_LEN-1:0] pc_reg;
  reg [`WORD_LEN-1:0] inst_reg;

  // For ID
  reg [`ADDR_LEN-1:0] rs1_addr;
  reg [`ADDR_LEN-1:0] rs2_addr;
  reg [`ADDR_LEN-1:0] wb_addr;
  wire [`WORD_LEN-1:0] rs1_data;
  wire [`WORD_LEN-1:0] rs2_data;

  reg [11:0] imm_i;
  wire [`WORD_LEN-1:0] imm_i_sext;
  reg [11:0] imm_s;
  wire [`WORD_LEN-1:0] imm_s_sext;

  // For EX
  wire [`WORD_LEN-1:0] inst_masked_is;
  reg [`WORD_LEN-1:0] alu_out;

  // For WB
  integer i;
  wire [`WORD_LEN-1:0] wb_data;

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
    else if (state == `WB) pc_reg <= pc_reg + `WORD_LEN'h4;
  end

  assign addr_i = pc_reg;


  //**********************************
  // Instruction Decode (ID) Stage

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      rs1_addr <= 0;
      rs2_addr <= 0;
      wb_addr <= 0;
      imm_i <= 0;
      imm_s <= 0;
    end
    else if (state == `ID) begin
      rs1_addr <= inst[19:15];
      rs2_addr <= inst[24:20];
      wb_addr <= inst[11:7];
      imm_i <= inst[31:20];
      imm_s <= {inst[31:25], inst[11:7]};
    end
  end

  assign rs1_data = (rs1_addr != `ADDR_LEN'b0) ? regfile[rs1_addr] : `WORD_LEN'b0;
  assign rs2_data = (rs2_addr != `ADDR_LEN'b0) ? regfile[rs2_addr] : `WORD_LEN'b0;

  assign imm_i_sext = {{20{imm_i[11]}}, imm_i};
  assign imm_s_sext = {{20{imm_s[11]}}, imm_s};


  //**********************************
  // Execute (EX) Stage

  assign inst_masked_is = inst & `TYPE_IS;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) alu_out <= 0;
    else if (state == `EX) begin
      case (inst_masked_is)
        `LW : alu_out <= rs1_data + imm_i_sext;
        `SW : alu_out <= rs1_data + imm_s_sext;
        default: alu_out <= `WORD_LEN'b0;
      endcase
    end
  end  


  //**********************************
  // Memory Access Stage

  assign addr_d = alu_out;

  assign wen = (state == `MEM) & (inst_masked_is == `SW);
  assign wdata = rs2_data;


  //**********************************
  // Writeback (WB) Stage

  assign wb_data = rdata;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < `WORD_LEN; i = i + 1) begin
        regfile[i] <= `WORD_LEN'b0;
      end
    end
    else if (state == `WB) begin
      case (inst_masked_is)
        `LW : regfile[wb_addr] <= wb_data;
        default: ;
      endcase
    end
  end


  //**********************************
  // Debug
  assign exit = (inst == `WORD_LEN'h00602823);

endmodule