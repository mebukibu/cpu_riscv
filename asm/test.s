lw x6, 12(x0)
lw x7, -4(x6)
bne x6, x7, 12
0x14
0xf
add x8, x6, x7
sw x8, -4(x6)
lw x7, -4(x6)
addi x8, x7, -3
slti x8, x7, -1
bne x6, x7, -20