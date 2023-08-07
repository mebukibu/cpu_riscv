jal x0, 8
jal x0, 0
lw x6, 4(x0)
lui x7, 8192
sw x6, 0(x7)
csrrw x0, 305, x7
ecall