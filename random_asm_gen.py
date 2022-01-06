#!/usr/bin/env python3

import random
import sys
import os

# Random assembly generator for RiSC-16

inst_max = 100
inst_num = 0

target_regs = ["r" + str(i) for i in range(1, 8)]
source_regs = ["r" + str(i) for i in range(8)]

def reg_tgt():
    return random.choice(target_regs)

def reg_src():
    return random.choice(source_regs)

def sig_imm():
    return str(random.randint(-64, 64))

def branch_imm():
    return str(random.randint(max(-64, -1 * inst_num), min(63, inst_max - inst_num - 1)))

def imm():
    return str(random.randint(0, 1023))

instructions = [
    ["add", reg_tgt, reg_src, reg_src],
    ["nand", reg_tgt, reg_src, reg_src],
    ["addi", reg_tgt, reg_src, sig_imm],
    ["sw", reg_tgt, reg_src, sig_imm],
    ["lw", reg_tgt, reg_src, sig_imm],
    ["beq", reg_tgt, reg_src, branch_imm],
    ["jalr", reg_tgt, reg_src],
    ["lui", reg_tgt, imm]
]

def write_code(file_name, asm):
    with open(file_name, "w") as f:
        f.write(asm)
    f.close()

def main():
    global inst_max
    global inst_num

    out_file = None

    if(len(sys.argv) == 1):
        print("No CLI input detected.")
    else:
        inst_max = int(sys.argv[1])
        if(len(sys.argv) == 3):
            out_file = sys.argv[2]

    print(f"Taking {inst_max} as size for random generation.")
    
    if(inst_max > 200):
        print(f"Number of instructions is high. Are you sure?")
        if(input() != "y"):
            return

    out = ""

    for inst_num in range(inst_max):
        rand_op = random.choice(instructions)

        instr_str = ""

        instr_str += rand_op[0] + " "

        for f in rand_op[1:-1]:
            instr_str += f()+", "
        
        instr_str += rand_op[-1]()

        if(inst_max <= 200):
            print(instr_str)

        out += instr_str + "\n"

    if(out_file != None):
        write_code(out_file, out)

if __name__ == "__main__":
    main()
