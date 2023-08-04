insts = {
    'lw'      : 0b00000000000000000010000000000011,     # type I
    'sw'      : 0b00000000000000000010000000100011,     # type S

    'add'     : 0b00000000000000000000000000110011,     # type R
    'addi'    : 0b00000000000000000000000000010011,     # type I
    'sub'     : 0b01000000000000000000000000110011,     # type R

    'and'     : 0b00000000000000000111000000110011,     # type R
    'or'      : 0b00000000000000000110000000110011,     # type R
    'xor'     : 0b00000000000000000100000000110011,     # type R
    'andi'    : 0b00000000000000000111000000010011,     # type I
    'ori'     : 0b00000000000000000110000000010011,     # type I
    'xori'    : 0b00000000000000000100000000010011,     # type I

    'sll'     : 0b00000000000000000001000000110011,     # type R
    'srl'     : 0b00000000000000000101000000110011,     # type R
    'sra'     : 0b01000000000000000101000000110011,     # type R
    'slli'    : 0b00000000000000000001000000010011,     # type I*
    'srli'    : 0b00000000000000000101000000010011,     # type I*
    'srai'    : 0b01000000000000000101000000010011,     # type I*

    'slt'     : 0b00000000000000000010000000110011,     # type R
    'sltu'    : 0b00000000000000000011000000110011,     # type R
    'slti'    : 0b00000000000000000010000000010011,     # type I
    'sltiu'   : 0b00000000000000000011000000010011,     # type I

    'beq'     : 0b00000000000000000000000001100011,     # type B
    'bne'     : 0b00000000000000000001000001100011,     # type B
    'blt'     : 0b00000000000000000100000001100011,     # type B
    'bge'     : 0b00000000000000000101000001100011,     # type B
    'bltu'    : 0b00000000000000000110000001100011,     # type B
    'bgeu'    : 0b00000000000000000111000001100011,     # type B
}