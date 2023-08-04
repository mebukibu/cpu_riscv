`include "consts.vh"

// load, store
`define LW      `WORD_LEN'b00000000000000000010000000000011     // type I
`define SW      `WORD_LEN'b00000000000000000010000000100011     // type S

// add
`define ADD     `WORD_LEN'b00000000000000000000000000110011     // type R
`define ADDI    `WORD_LEN'b00000000000000000000000000010011     // type I

// sub
`define SUB     `WORD_LEN'b01000000000000000000000000110011     // type R

// logic
`define AND     `WORD_LEN'b00000000000000000111000000110011     // type R
`define OR      `WORD_LEN'b00000000000000000110000000110011     // type R
`define XOR     `WORD_LEN'b00000000000000000100000000110011     // type R
`define ANDI    `WORD_LEN'b00000000000000000111000000010011     // type I
`define ORI     `WORD_LEN'b00000000000000000110000000010011     // type I
`define XORI    `WORD_LEN'b00000000000000000100000000010011     // type I

// shift
`define SLL     `WORD_LEN'b00000000000000000001000000110011     // type R
`define SRL     `WORD_LEN'b00000000000000000101000000110011     // type R
`define SRA     `WORD_LEN'b01000000000000000101000000110011     // type R
`define SLLI    `WORD_LEN'b00000000000000000001000000010011     // type I*
`define SRLI    `WORD_LEN'b00000000000000000101000000010011     // type I*
`define SRAI    `WORD_LEN'b01000000000000000101000000010011     // type I*

// comparison
`define SLT     `WORD_LEN'b00000000000000000010000000110011     // type R
`define SLTU    `WORD_LEN'b00000000000000000011000000110011     // type R
`define SLTI    `WORD_LEN'b00000000000000000010000000010011     // type I
`define SLTIU   `WORD_LEN'b00000000000000000011000000010011     // type I

// conditional branch
`define BEQ     `WORD_LEN'b00000000000000000000000001100011     // type B
`define BNE     `WORD_LEN'b00000000000000000001000001100011     // type B
`define BLT     `WORD_LEN'b00000000000000000100000001100011     // type B
`define BGE     `WORD_LEN'b00000000000000000101000001100011     // type B
`define BLTU    `WORD_LEN'b00000000000000000110000001100011     // type B
`define BGEU    `WORD_LEN'b00000000000000000111000001100011

// jump
`define JAL     `WORD_LEN'bXXXXXXXXXXXXXXXXXXXXXXXXX1101111
`define JALR    `WORD_LEN'bXXXXXXXXXXXXXXXXX000XXXXX1100111

// im load
`define LUI     `WORD_LEN'bXXXXXXXXXXXXXXXXXXXXXXXXX0110111
`define AUIPC   `WORD_LEN'bXXXXXXXXXXXXXXXXXXXXXXXXX0010111

// CSR
`define CSRRW   `WORD_LEN'bXXXXXXXXXXXXXXXXX001XXXXX1110011
`define CSRRWI  `WORD_LEN'bXXXXXXXXXXXXXXXXX101XXXXX1110011
`define CSRRS   `WORD_LEN'bXXXXXXXXXXXXXXXXX010XXXXX1110011
`define CSRRSI  `WORD_LEN'bXXXXXXXXXXXXXXXXX110XXXXX1110011
`define CSRRC   `WORD_LEN'bXXXXXXXXXXXXXXXXX011XXXXX1110011
`define CSRRCI  `WORD_LEN'bXXXXXXXXXXXXXXXXX111XXXXX1110011

// except
`define ECALL   `WORD_LEN'b00000000000000000000000001110011

// vector
`define VSETVLI `WORD_LEN'bXXXXXXXXXXXXXXXXX111XXXXX1010111
`define VLE     `WORD_LEN'b000000100000XXXXXXXXXXXXX0000111
`define VSE     `WORD_LEN'b000000100000XXXXXXXXXXXXX0100111
`define VADDVV  `WORD_LEN'b0000001XXXXXXXXXX000XXXXX1010111

// custom
`define PCNT    `WORD_LEN'b000000000000XXXXX110XXXXX0001011


// instruction type mask
`define TYPE_R  `WORD_LEN'b11111110000000000111000001111111
`define TYPE_ISB`WORD_LEN'b00000000000000000111000001111111
`define TYPE_U  `WORD_LEN'b00000000000000000000000001111111