#!/usr/bin/env python3

from io import RawIOBase
import sys

class data_mem:
    def __init__(self):
        self.mem_dict = {}

    def write(self, addr, data):
        self.mem_dict[addr] = data
    
    def read(self, addr):
        if(addr in self.mem_dict):
            return self.mem_dict[addr]
    pass

class instruction:
    inst_names      = ["add", "addi", "nand", "lui", "sw", "lw", "beq", "jalr"]

    inst_id         = {
        "add"   : 0, 
        "addi"  : 1, 
        "nand"  : 2, 
        "lui"   : 3, 
        "sw"    : 4, 
        "lw"    : 5, 
        "beq"   : 6, 
        "jalr"  : 7
    }

    format_names    = ["rrr", "rri", "ri"]

    format_id       = {
        "rrr"   : 0,
        "rri"   : 1,
        "rl"    : 2
    }

    inst_format     = {
        0   : "rrr",
        1   : "rri",
        2   : "rrr",
        3   : "rl",
        4   : "rri",
        5   : "rri",
        6   : "rri",
        7   : "rri"
    }

    def __init__(self, machine_code=None):
        self.opcode = None
        self.rega   = None
        self.regb   = None
        self.regc   = None
        self.imm    = None

        if(machine_code != None):
            self.decode(machine_code)            
        
    # RRR : 0, RRI : 1, RI : 2
    def get_type(self):
        if(
            self.opcode == 0 or
            self.opcode == 2 or
            self.opcode == 7
        ):
            return 0
        elif(
            self.opcode == 1 or
            self.opcode == 4 or
            self.opcode == 5 or
            self.opcode == 6
        ):
            return 1
        elif(
            self.opcode == 3
        ):
            return 2

    def decode(self, machine_code):
        self.opcode = int(machine_code[:3], 2)

        opcode_format = self.inst_format[self.opcode]

        if(opcode_format == "rrr"):
            self.rega   = int(machine_code[3:6], 2)
            self.regb   = int(machine_code[6:9], 2)
            self.regc   = int(machine_code[13:], 2)
        elif(opcode_format == "rri"):
            self.rega   = int(machine_code[3:6], 2)
            self.regb   = int(machine_code[6:9], 2)
            if(machine_code[9] == '0'):
                self.imm = int(machine_code[10:], 2) 
            else:
                self.imm = int(machine_code[10:], 2) - 64
        elif(opcode_format == "rl"):
            self.rega   = int(machine_code[3:6], 2)
            self.imm    = int(machine_code[6:], 2)
    
    def __str__(self):
        if(self.opcode == None):
            return ""
        else:
            temp = ""
            temp += self.inst_names[self.opcode] + " " + self.rega + ", "
            
            opcode_format = self.inst_format[self.opcode]

            if(opcode_format == "rrr"):
                temp += self.regb + ", " + self.regc

            elif(opcode_format == "rri"):
                temp += self.regb
                if(self.opcode != self.inst_id["jalr"]):
                    temp += ", " + self.imm

            elif(opcode_format == "ri"):
                temp += self.imm

            return temp


class prog_mem:
    def __init__(self):
        self.mem = []

    def read_file(self, file_name):
        with open(file_name) as f:
            while True:
                word = f.readline().rstrip()
            
                if(word==""):
                    return

                word += f.readline().rstrip()
            
                print(word)

def main():
    if(len(sys.argv) == 1):
        print("No input file name detected. Plesae pass input file name as argument.")
        return

    source_file = sys.argv[1]

    progmem = prog_mem()
    progmem.read_file(source_file)

if(__name__ == "__main__"):
    main()
