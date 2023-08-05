addi x6, x0, 1
jal x1, 8
addi x7, x0, 1
beq x6, x7, 8
jalr x0, 0(x1)
jal x1, -20