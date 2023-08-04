lw x6, 16(x0)
lw x7, 24(x0)
lw x8, 32(x0)
beq x6, x7, 8
0x1
bne x6, x8, 8
0x1
blt x8, x6, 8
0xffffffff
bge x6, x7, 8
0x0
bltu x6, x8, 8
0x0
bgeu x7, x6, 8
0x0
add x7, x6, x8