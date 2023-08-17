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
  input wire intr,
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
  reg [`WORD_LEN-1:0] csr_regfile [0:4];

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
  wire [19:0] imm_u;
  wire [`WORD_LEN-1:0] imm_u_shifted;
  wire [4:0] imm_z;
  wire [`WORD_LEN-1:0] imm_z_uext;

  wire [`WORD_LEN-1:0] inst_masked_isb;
  wire [`WORD_LEN-1:0] inst_masked_r;
  wire [`WORD_LEN-1:0] inst_masked_uj;

  reg [`EXE_FUN_LEN-1:0] exe_fun;
  reg [`OP1_LEN-1:0] op1_sel;
  reg [`OP2_LEN-1:0] op2_sel;
  reg [`MEM_LEN-1:0] mem_wen;
  reg [`REN_LEN-1:0] rf_wen;
  reg [`WB_SEL_LEN-1:0] wb_sel;
  reg [`CSR_LEN-1:0] csr_cmd;

  wire [`WORD_LEN-1:0] op1_data;
  wire [`WORD_LEN-1:0] op2_data;

  // For EX
  reg [`WORD_LEN-1:0] alu_out;

  // For MEM
  wire [`CSR_ADDR_LEN-1:0] csr_addr;
  wire [`WORD_LEN-1:0] csr_rdata;
  wire [`WORD_LEN-1:0] csr_wdata;

  // For WB
  integer i;
  wire [`WORD_LEN-1:0] wb_data;

  //**********************************
  // State Machine

  reg [2:0] state;
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) state <= `IDLE;
    else if (!intr) begin
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
  assign jmp_flg = (inst_masked_uj == `JAL | inst_masked_isb == `JALR);

  assign pc_next = br_flg  ? br_target : `WORD_LEN'bZ;
  assign pc_next = jmp_flg ? alu_out : `WORD_LEN'bZ;
  assign pc_next = (inst == `ECALL) ? csr_regfile[`CSR_ADDR_MTVBS] : `WORD_LEN'bZ;
  assign pc_next = !(br_flg | jmp_flg | inst == `ECALL) ? pc_plus4 : `WORD_LEN'bZ;

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
  assign imm_u = inst[31:12];
  assign imm_u_shifted = {imm_u, 12'b0};
  assign imm_z = inst[19:15];
  assign imm_z_uext = {27'b0, imm_z};

  assign inst_masked_isb = inst & `TYPE_ISB;
  assign inst_masked_r = inst & `TYPE_R;
  assign inst_masked_uj = inst & `TYPE_UJ;

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
        `LW     : begin exe_fun <= `ALU_ADD;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_MEM; csr_cmd <= `CSR_X; end
        `LBU    : begin exe_fun <= `ALU_ADD;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_M1U; csr_cmd <= `CSR_X; end
        `SB     : begin exe_fun <= `ALU_ADD;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMS; mem_wen <= `MEM_U; rf_wen <= `REN_X; wb_sel <= `WB_X  ; csr_cmd <= `CSR_X; end
        `SW     : begin exe_fun <= `ALU_ADD;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMS; mem_wen <= `MEM_S; rf_wen <= `REN_X; wb_sel <= `WB_X  ; csr_cmd <= `CSR_X; end
        `ADDI   : begin exe_fun <= `ALU_ADD;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
        `ANDI   : begin exe_fun <= `ALU_AND;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
        `ORI    : begin exe_fun <= `ALU_OR;    op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
        `XORI   : begin exe_fun <= `ALU_XOR;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
        `SLTI   : begin exe_fun <= `ALU_SLT;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
        `SLTIU  : begin exe_fun <= `ALU_SLTU;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
        `BEQ    : begin exe_fun <= `BR_BEQ;    op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   csr_cmd <= `CSR_X; end
        `BNE    : begin exe_fun <= `BR_BNE;    op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   csr_cmd <= `CSR_X; end
        `BLT    : begin exe_fun <= `BR_BLT;    op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   csr_cmd <= `CSR_X; end
        `BGE    : begin exe_fun <= `BR_BGE;    op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   csr_cmd <= `CSR_X; end
        `BLTU   : begin exe_fun <= `BR_BLTU;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   csr_cmd <= `CSR_X; end
        `BGEU   : begin exe_fun <= `BR_BGEU;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   csr_cmd <= `CSR_X; end
        `JALR   : begin exe_fun <= `ALU_JALR;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_PC;  csr_cmd <= `CSR_X; end
        `CSRRW  : begin exe_fun <= `ALU_COPY1; op1_sel <= `OP1_RS1; op2_sel <= `OP2_X;   mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_CSR; csr_cmd <= `CSR_W; end
        `CSRRWI : begin exe_fun <= `ALU_COPY1; op1_sel <= `OP1_IMZ; op2_sel <= `OP2_X;   mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_CSR; csr_cmd <= `CSR_W; end
        `CSRRS  : begin exe_fun <= `ALU_COPY1; op1_sel <= `OP1_RS1; op2_sel <= `OP2_X;   mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_CSR; csr_cmd <= `CSR_S; end
        `CSRRSI : begin exe_fun <= `ALU_COPY1; op1_sel <= `OP1_IMZ; op2_sel <= `OP2_X;   mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_CSR; csr_cmd <= `CSR_S; end
        `CSRRC  : begin exe_fun <= `ALU_COPY1; op1_sel <= `OP1_RS1; op2_sel <= `OP2_X;   mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_CSR; csr_cmd <= `CSR_C; end
        `CSRRCI : begin exe_fun <= `ALU_COPY1; op1_sel <= `OP1_IMZ; op2_sel <= `OP2_X;   mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_CSR; csr_cmd <= `CSR_C; end
        `ECALL  : begin exe_fun <= `ALU_X;     op1_sel <= `OP1_X;   op2_sel <= `OP2_X;   mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   csr_cmd <= `CSR_E; end
        default:
        case (inst_masked_r)
          `ADD  : begin exe_fun <= `ALU_ADD;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SUB  : begin exe_fun <= `ALU_SUB;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `AND  : begin exe_fun <= `ALU_AND;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `OR   : begin exe_fun <= `ALU_OR;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `XOR  : begin exe_fun <= `ALU_XOR;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SLL  : begin exe_fun <= `ALU_SLL;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SRL  : begin exe_fun <= `ALU_SRL;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SRA  : begin exe_fun <= `ALU_SRA;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SLLI : begin exe_fun <= `ALU_SLL;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SRLI : begin exe_fun <= `ALU_SRL;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SRAI : begin exe_fun <= `ALU_SRA;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_IMI; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SLT  : begin exe_fun <= `ALU_SLT;  op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          `SLTU : begin exe_fun <= `ALU_SLTU; op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
          default:
          case (inst_masked_uj)
            `JAL   : begin exe_fun <= `ALU_ADD; op1_sel <= `OP1_PC;  op2_sel <= `OP2_IMJ; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_PC;  csr_cmd <= `CSR_X; end
            `LUI   : begin exe_fun <= `ALU_ADD; op1_sel <= `OP1_X;   op2_sel <= `OP2_IMU; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
            `AUIPC : begin exe_fun <= `ALU_ADD; op1_sel <= `OP1_PC;  op2_sel <= `OP2_IMU; mem_wen <= `MEM_X; rf_wen <= `REN_S; wb_sel <= `WB_ALU; csr_cmd <= `CSR_X; end
            default: begin exe_fun <= `ALU_X;   op1_sel <= `OP1_RS1; op2_sel <= `OP2_RS2; mem_wen <= `MEM_X; rf_wen <= `REN_X; wb_sel <= `WB_X;   csr_cmd <= `CSR_X; end
          endcase
        endcase
      endcase
    end
  end

  assign op1_data = (op1_sel == `OP1_RS1) ? rs1_data : `WORD_LEN'bZ;
  assign op1_data = (op1_sel == `OP1_PC)  ? pc_reg : `WORD_LEN'bZ;
  assign op1_data = (op1_sel == `OP1_IMZ) ? imm_z_uext : `WORD_LEN'bZ;
  assign op1_data = (op1_sel == `OP1_X)   ? `WORD_LEN'b0 : `WORD_LEN'bZ;

  assign op2_data = (op2_sel == `OP2_RS2) ? rs2_data : `WORD_LEN'bZ;
  assign op2_data = (op2_sel == `OP2_IMI) ? imm_i_sext : `WORD_LEN'bZ;
  assign op2_data = (op2_sel == `OP2_IMS) ? imm_s_sext : `WORD_LEN'bZ;
  assign op2_data = (op2_sel == `OP2_IMJ) ? imm_j_sext : `WORD_LEN'bZ;
  assign op2_data = (op2_sel == `OP2_IMU) ? imm_u_shifted : `WORD_LEN'bZ;


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
        `ALU_ADD   : alu_out <= op1_data + op2_data;
        `ALU_SUB   : alu_out <= op1_data - op2_data;
        `ALU_AND   : alu_out <= op1_data & op2_data;
        `ALU_OR    : alu_out <= op1_data | op2_data;
        `ALU_XOR   : alu_out <= op1_data ^ op2_data;
        `ALU_SLL   : alu_out <= op1_data << op2_data[4:0];
        `ALU_SRL   : alu_out <= op1_data >> op2_data[4:0];
        `ALU_SRA   : alu_out <= $signed(op1_data) >>> op2_data[4:0];
        `ALU_SLT   : alu_out <= $signed(op1_data) < $signed(op2_data);
        `ALU_SLTU  : alu_out <= op1_data < op2_data;
        `ALU_JALR  : alu_out <= (op1_data + op2_data) & ~(`WORD_LEN'b1);
        `ALU_COPY1 : alu_out <= op1_data;
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

  assign wen = (state == `MEM | state == `WB) & (|mem_wen);
  assign wdata = (mem_wen == `MEM_S) ? rs2_data : `WORD_LEN'bZ;

  assign wdata = (mem_wen == `MEM_U & addr_d[1:0] == 2'b00) ? {rdata[31:8], rs2_data[7:0]} : `WORD_LEN'bZ;
  assign wdata = (mem_wen == `MEM_U & addr_d[1:0] == 2'b01) ? {rdata[31:16], rs2_data[7:0], rdata[ 7:0]} : `WORD_LEN'bZ;
  assign wdata = (mem_wen == `MEM_U & addr_d[1:0] == 2'b10) ? {rdata[31:24], rs2_data[7:0], rdata[15:0]} : `WORD_LEN'bZ;
  assign wdata = (mem_wen == `MEM_U & addr_d[1:0] == 2'b11) ? {rs2_data[7:0], rdata[23:0]} : `WORD_LEN'bZ;

  assign csr_addr =  (inst[31:20] == `CSR_ADDR_LEN'h300) ? `CSR_ADDR_MS    : `CSR_ADDR_LEN'bZ;
  assign csr_addr =  (inst[31:20] == `CSR_ADDR_LEN'h305) ? `CSR_ADDR_MTVBS : `CSR_ADDR_LEN'bZ;
  assign csr_addr =  (inst[31:20] == `CSR_ADDR_LEN'h341) ? `CSR_ADDR_MEPC  : `CSR_ADDR_LEN'bZ;
  assign csr_addr =  (inst[31:20] == `CSR_ADDR_LEN'h342 | csr_cmd == `CSR_E) ? `CSR_ADDR_MC : `CSR_ADDR_LEN'bZ;
  assign csr_addr = !(inst[31:20] == `CSR_ADDR_LEN'h300 | inst[31:20] == `CSR_ADDR_LEN'h305 |
                      inst[31:20] == `CSR_ADDR_LEN'h341 | inst[31:20] == `CSR_ADDR_LEN'h342 | csr_cmd == `CSR_E) ? `CSR_ADDR_X : `CSR_ADDR_LEN'bZ;

  assign csr_rdata = csr_regfile[csr_addr];

  assign csr_wdata = (csr_cmd == `CSR_W) ?  op1_data : `WORD_LEN'bZ;
  assign csr_wdata = (csr_cmd == `CSR_S) ? (csr_rdata | op1_data) : `WORD_LEN'bZ;
  assign csr_wdata = (csr_cmd == `CSR_C) ? (csr_rdata & ~op1_data) : `WORD_LEN'bZ;
  assign csr_wdata = (csr_cmd == `CSR_E) ? `WORD_LEN'd11 : `WORD_LEN'bZ;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 4096; i = i + 1) begin
        csr_regfile[i] <= `WORD_LEN'b0;
      end
    end
    else if (state == `MEM) begin
      if (csr_cmd > `CSR_LEN'b0)
        csr_regfile[csr_addr] <= csr_wdata;
    end
  end


  //**********************************
  // Writeback (WB) Stage

  assign wb_data =  (wb_sel == `WB_MEM) ? rdata : `WORD_LEN'bZ;
  assign wb_data =  (wb_sel == `WB_PC ) ? pc_plus4 : `WORD_LEN'bZ;
  assign wb_data =  (wb_sel == `WB_CSR) ? csr_rdata : `WORD_LEN'bZ;
  assign wb_data = !(wb_sel == `WB_MEM | wb_sel == `WB_PC | wb_sel == `WB_CSR | wb_sel == `WB_M1U) ? alu_out : `WORD_LEN'bZ;

  assign wb_data =  (wb_sel == `WB_M1U & addr_d[1:0] == 2'b00) ? {24'b0, rdata[ 7: 0]} : `WORD_LEN'bZ;
  assign wb_data =  (wb_sel == `WB_M1U & addr_d[1:0] == 2'b01) ? {24'b0, rdata[15: 8]} : `WORD_LEN'bZ;
  assign wb_data =  (wb_sel == `WB_M1U & addr_d[1:0] == 2'b10) ? {24'b0, rdata[23:16]} : `WORD_LEN'bZ;
  assign wb_data =  (wb_sel == `WB_M1U & addr_d[1:0] == 2'b11) ? {24'b0, rdata[31:24]} : `WORD_LEN'bZ;

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
  assign exit = (inst == `UNIMP);

endmodule