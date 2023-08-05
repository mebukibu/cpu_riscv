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

  // register
  reg [`WORD_LEN-1:0] regfile [0:`WORD_LEN-1];

  // For IF
  reg [`WORD_LEN-1:0] pc_reg;
  wire [`WORD_LEN-1:0] pc_plus4;
  wire [`WORD_LEN-1:0] pc_next;
  reg br_flg;
  reg [`WORD_LEN-1:0] br_target;
  wire jmp_flg;

  // For ID
  wire [`ADDR_LEN-1:0] rs1_addr;
  wire [`ADDR_LEN-1:0] rs2_addr;
  wire [`ADDR_LEN-1:0] wb_addr;
  wire [`WORD_LEN-1:0] rs1_data;
  wire [`WORD_LEN-1:0] rs2_data;

  wire [11:0] imm_i;
  wire [`WORD_LEN-1:0] imm_i_sext;
  wire [11:0] imm_s;
  wire [`WORD_LEN-1:0] imm_s_sext;
  wire [11:0] imm_b;
  wire [`WORD_LEN-1:0] imm_b_sext;
  wire [19:0] imm_j;
  wire [`WORD_LEN-1:0] imm_j_sext;

  wire [`WORD_LEN-1:0] inst_masked_isb;
  wire [`WORD_LEN-1:0] inst_masked_r;
  wire [`WORD_LEN-1:0] inst_masked_j;

  reg [`EXE_FUN_LEN-1:0] exe_fun;
  reg [`OP1_LEN-1:0] op1_sel;
  reg [`OP2_LEN-1:0] op2_sel;
  reg [`MEM_LEN-1:0] mem_wen;
  reg [`REN_LEN-1:0] rf_wen;
  reg [`WB_SEL_LEN-1:0] wb_sel;

  wire [`WORD_LEN-1:0] op1_data;
  wire [`WORD_LEN-1:0] op2_data;

  // For EX
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

  assign addr_i = pc_reg;
  assign pc_plus4 = pc_reg + `WORD_LEN'h4;
  assign jmp_flg = (inst_masked_j == `JAL | inst_masked_isb == `JALR);

  assign pc_next = br_flg  ? br_target : `WORD_LEN'bZ;
  assign pc_next = jmp_flg ? alu_out : `WORD_LEN'bZ;
  assign pc_next = !(br_flg | jmp_flg) ? pc_plus4 : `WORD_LEN'bZ;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) pc_reg <= `START_ADDR;
    else if (state == `WB) pc_reg <= pc_next;
  end  


  //**********************************
  // Instruction Decode (ID) Stage

  assign rs1_addr = inst[19:15];
  assign rs2_addr = inst[24:20];
  assign wb_addr = inst[11:7];
  assign rs1_data = (rs1_addr != `ADDR_LEN'b0) ? regfile[rs1_addr] : `WORD_LEN'b0;
  assign rs2_data = (rs2_addr != `ADDR_LEN'b0) ? regfile[rs2_addr] : `WORD_LEN'b0;

  assign imm_i = inst[31:20];
  assign imm_i_sext = {{20{imm_i[11]}}, imm_i};
  assign imm_s = {inst[31:25], inst[11:7]};
  assign imm_s_sext = {{20{imm_s[11]}}, imm_s};
  assign imm_b = {inst[31], inst[7], inst[30:25], inst[11:8]};
  assign imm_b_sext = {{19{imm_b[11]}}, imm_b, 1'b0};
  assign imm_j = {inst[31], inst[19:12], inst[20], inst[30:21]};
  assign imm_j_sext = {{11{imm_j[19]}}, imm_j, 1'b0};

  assign inst_masked_isb = inst & `TYPE_ISB;
  assign inst_masked_r = inst & `TYPE_R;
  assign inst_masked_j = inst & `TYPE_UJ;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      exe_fun <= `EXE_FUN_LEN'b0;
      op1_sel <= `OP1_LEN'b0;
      op2_sel <= `OP2_LEN'b0;
      mem_wen <= `MEM_LEN'b0;
      rf_wen <= `REN_LEN'b0;
      wb_sel <= `WB_SEL_LEN'b0;
    end
    else if (state == `ID) begin
      case (inst_masked_isb)
        `LW    : begin exe_fun <= `ALU_ADD;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_MEM; end
        `SW    : begin exe_fun <= `ALU_ADD;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMS; mem_wen <= `MEM_S; rf_wen <= `REN_X; wb_sel <= `WB_X  ; end
        `ADDI  : begin exe_fun <= `ALU_ADD;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
        `ANDI  : begin exe_fun <= `ALU_AND;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
        `ORI   : begin exe_fun <= `ALU_OR;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
        `XORI  : begin exe_fun <= `ALU_XOR;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
        `SLTI  : begin exe_fun <= `ALU_SLT;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
        `SLTIU : begin exe_fun <= `ALU_SLTU; op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
        `BEQ   : begin exe_fun <= `BR_BEQ;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   end
        `BNE   : begin exe_fun <= `BR_BNE;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   end
        `BLT   : begin exe_fun <= `BR_BLT;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   end
        `BGE   : begin exe_fun <= `BR_BGE;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   end
        `BLTU  : begin exe_fun <= `BR_BLTU;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   end
        `BGEU  : begin exe_fun <= `BR_BGEU;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   end
        `JALR  : begin exe_fun <= `ALU_JALR; op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_PC ; end
        default:
        case (inst_masked_r)
          `ADD  : begin exe_fun <= `ALU_ADD;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SUB  : begin exe_fun <= `ALU_SUB;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `AND  : begin exe_fun <= `ALU_AND;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `OR   : begin exe_fun <= `ALU_OR;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `XOR  : begin exe_fun <= `ALU_XOR;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SLL  : begin exe_fun <= `ALU_SLL;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SRL  : begin exe_fun <= `ALU_SRL;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SRA  : begin exe_fun <= `ALU_SRA;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SLLI : begin exe_fun <= `ALU_SLL;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SRLI : begin exe_fun <= `ALU_SRL;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SRAI : begin exe_fun <= `ALU_SRA;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SLT  : begin exe_fun <= `ALU_SLT;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          `SLTU : begin exe_fun <= `ALU_SLTU; op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; end
          default:
          case (inst_masked_j)
            `JAL   : begin exe_fun <= `ALU_ADD; op1_sel <= `OP1_PC;  op2_sel <= `OP2_IMJ; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_PC; end
            default: begin exe_fun <= `ALU_X;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X ; end
          endcase
        endcase
      endcase
    end
  end

  assign op1_data = (op1_sel == `OP1_RS1) ? rs1_data : `WORD_LEN'bZ;
  assign op1_data = (op1_sel == `OP1_PC)  ? pc_reg : `WORD_LEN'bZ;

  assign op2_data = (op2_sel == `OP2_RS2) ? rs2_data : `WORD_LEN'bZ;
  assign op2_data = (op2_sel == `OP2_IMI) ? imm_i_sext : `WORD_LEN'bZ;
  assign op2_data = (op2_sel == `OP2_IMS) ? imm_s_sext : `WORD_LEN'bZ;
  assign op2_data = (op2_sel == `OP2_IMJ) ? imm_j_sext : `WORD_LEN'bZ;


  //**********************************
  // Execute (EX) Stage

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      alu_out <= `WORD_LEN'b0;
      br_flg <= 1'b0;
      br_target <= `WORD_LEN'b0;
    end
    else if (state == `EX) begin
      case (exe_fun)
        `ALU_ADD  : alu_out <= op1_data + op2_data;
        `ALU_SUB  : alu_out <= op1_data - op2_data;
        `ALU_AND  : alu_out <= op1_data & op2_data;
        `ALU_OR   : alu_out <= op1_data | op2_data;
        `ALU_XOR  : alu_out <= op1_data ^ op2_data;
        `ALU_SLL  : alu_out <= op1_data << op2_data[4:0];
        `ALU_SRL  : alu_out <= op1_data >> op2_data[4:0];
        `ALU_SRA  : alu_out <= $signed(op1_data) >>> op2_data[4:0];
        `ALU_SLT  : alu_out <= $signed(op1_data) < $signed(op2_data);
        `ALU_SLTU : alu_out <= op1_data < op2_data;
        `ALU_JALR : alu_out <= (op1_data + op2_data) & ~(`WORD_LEN'b1);
        default  : alu_out <= `WORD_LEN'b0;
      endcase
      case (exe_fun)
        `BR_BEQ  : br_flg <=  (op1_data == op2_data);
        `BR_BNE  : br_flg <= !(op1_data == op2_data);
        `BR_BLT  : br_flg <=  ($signed(op1_data) < $signed(op2_data));
        `BR_BGE  : br_flg <= !($signed(op1_data) < $signed(op2_data));
        `BR_BLTU : br_flg <=  (op1_data < op2_data);
        `BR_BGEU : br_flg <= !(op1_data < op2_data);
        default  : br_flg <= 1'b0; 
      endcase
      br_target <= pc_reg + imm_b_sext;
    end
  end  


  //**********************************
  // Memory Access Stage

  assign addr_d = alu_out;

  assign wen = (state == `MEM) & (|mem_wen);
  assign wdata = rs2_data;


  //**********************************
  // Writeback (WB) Stage

  assign wb_data =  (wb_sel == `WB_MEM) ? rdata : `WORD_LEN'bZ;
  assign wb_data =  (wb_sel == `WB_PC ) ? pc_plus4 : `WORD_LEN'bZ;
  assign wb_data = !(wb_sel == `WB_MEM | wb_sel == `WB_PC) ? alu_out : `WORD_LEN'bZ;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < `WORD_LEN; i = i + 1) begin
        regfile[i] <= `WORD_LEN'b0;
      end
    end
    else if (state == `WB) begin
      if (rf_wen == `REN_S)
        regfile[wb_addr] <= wb_data;
    end
  end


  //**********************************
  // Debug
  assign exit = (inst == `WORD_LEN'h00000000);

endmodule