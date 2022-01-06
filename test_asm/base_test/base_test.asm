addi    r3  r0  10      # r3 = Counter
addi    r4  r0  5       # r4 = Jump target 4
addi    r1  r0  15      # r1 = Constant value 15
addi    r2  r3  0       # r2 = -r3
nand    r2  r2  r2
addi    r2  r2  1
add     r2  r2  r1      # r2 = r2 - r1
addi    r3  r3  -1
beq     r3  r0  2
jalr    r5  r4
