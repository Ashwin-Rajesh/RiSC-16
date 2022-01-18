#!/usr/bin/env python3

"""
MIT License

Copyright (c) 2022 Ashwin Rajesh

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import sys
import os

class report_error:
    typ = "Unknown error"

    def __init__(self, msg) -> None:
        self.msg        = msg

    def __str__(self) -> str:
        return str(self.typ) + " : " + self.msg

class decode_error(report_error):
    typ = "Decode error"

    def __init__(self, msg, line_no = None) -> None:
        super().__init__(msg)
        self.line_no = line_no

    def __str__(self) -> str:
        return self.typ + " at line number : " + ("??" if self.line_no == None else str(self.line_no)) + "\n" + super().__str__()

class op_decode_error(decode_error):
    typ = "Opcode decode error"

class reg_decode_error(decode_error):
    typ = "Register decode error"

class imm_decode_error(decode_error):
    typ = "Immediate decode error"

class pre_processor_error(decode_error):
    typ = "Pre processor error"

class internal_error(report_error):
    typ = "Internal error"

    def __str__(self) -> str:
        return "(internal error) " + super().__str__()

class inp_internal_error(internal_error):
    typ = "Input error"

def check_error(error, line):
    if(error == None):
        return False
    
    if(not isinstance(error, report_error)):
        raise TypeError(f"Argument was not None or report_error type. Received type {type(error)}")

    print(str(error))

    if(isinstance(error, decode_error)):
        if(error.line_no != None):
            print(f"     {line}")

    return True

def parse_imm(inp : str):
    base        = 10        # Base of the number
    neg         = False     # Is the number given as negative?
    start_idx   = 0         # What is the start index of the actual numeric value?

    if(inp[0:2] == "0x"):
        base        = 16
        start_idx   = 2
    elif(inp[0:2] == "0b"):
        base        = 2
        start_idx   = 2
    elif(inp[0:2] == "0o"):
        base        = 8
        start_idx   = 2
    elif(inp[0] == "-"):
        neg         = True
        start_idx   = 1

    abs = int(inp[start_idx:], base)

    out = ""

    if(neg):
        out = "".join(['1' if x == '0' else '0' for x in bin(abs-1)[2:]])
    else:
        out = bin(abs)[2:]

    return out, neg, None
    
# Decode from assembly and encode to machine language
class Coder:
    def __init__(self) -> None:
        self.line_no   = None
        self.line      = ""

    def check_error(self, err):
        return check_error(err, self.line)

    def get_opcode(self, inp):
        if(inp == "add"):
            return "000", 0, None
        if(inp == "addi"):
            return "001", 1, None
        if(inp == "nand"):
            return "010", 2, None
        if(inp == "lui"):
            return "011", 3, None
        if(inp == "sw"):
            return "100", 4, None
        if(inp == "lw"):
            return "101", 5, None
        if(inp == "beq"):
            return "110", 6, None
        if(inp == "jalr"):
            return "111", 7, None
        
        return "___", 0, op_decode_error(f" Unknown opcode \"{inp}\"", self.line_no)

    def get_reg(self, inp : str):
        start = 0
        if(inp[0] == "r"):
            start = 1

        try:
            val = int(inp[start])
        except ValueError:
            return "", reg_decode_error(f"Register id not an integer : {inp}", self.line_no)

        if(val < 8):
            out = bin(int(inp[start]))[2:]

            if(len(out) < 3):
                out = "0"*(3-len(out)) + out

            return out, None
        else:
            return "", reg_decode_error(f"Register id must be < 8", self.line_no)

    def get_sigimm(self, inp : str):        
        val, neg, parse_err = parse_imm(inp)

        if(parse_err != None):
            return "", parse_err

        val = ("1"*(7-len(val)) if neg else "0"*(7-len(val))) + val

        if(len(val) > 7):
            return "", imm_decode_error(f" Value is outside signed immediate field limit (-64 to 63). (Decoded to {val} : length {len(val)}, maximum 6))", self.line_no)

        return val, None

    def get_imm(self, inp : str):
        val, neg, parse_err = parse_imm(inp)

        if(parse_err != None):
            return "", parse_err

        if(len(val) > 10):
            return "", imm_decode_error(f" Value is outside large immediate field limit (0 to -x3FF). (Decoded to {val} : length {len(val)}, maximum 10))", self.line_no)

        return "0"*(10-len(val)) + val, None

    def decode_asm(self, parts, line_no, line):
        self.line_no = line_no
        self.line    = line

        if(len(parts) != 0):
            opcode_str, opcode, opcode_err = self.get_opcode(parts[0])

            if(self.check_error(opcode_err)):
                sys.exit()
            
            # RRR - type
            if(opcode == 0 or opcode == 2):
                regA, regA_err = self.get_reg(parts[1])
                regB, regB_err = self.get_reg(parts[2])
                regC, regC_err = self.get_reg(parts[3])

                if(self.check_error(regA_err) or self.check_error(regB_err) or self.check_error(regC_err)):
                    sys.exit()
                
                return opcode_str + regA + regB + "0000" + regC

            # RRI - type
            elif(opcode == 1 or opcode == 4 or opcode == 5 or opcode == 6 or opcode == 7):
                regA, regA_err = self.get_reg(parts[1])
                regB, regB_err = self.get_reg(parts[2])
                if(opcode == 7):
                    imm = "0000000"
                    imm_err = None
                else:
                    imm, imm_err   = self.get_sigimm(parts[3])

                if(self.check_error(regA_err) or self.check_error(regB_err) or self.check_error(imm_err)):
                    sys.exi()
                
                return opcode_str + regA + regB + imm

            # RI type
            else:
                regA, regA_err = self.get_reg(parts[1])
                imm, imm_err = self.get_imm(parts[2])
                
                if(self.check_error(regA_err) or self.check_error(imm_err)):
                    return
                
                return opcode_str + regA + imm

def write_code(file_name, bitstream):
    with open(file_name, "w") as f:
        for i in range(len(bitstream) // 16):
            f.write(bitstream[16 * i : 16*(i+1)]+"\n")
            print(bitstream[16*i : 16*(i+1)])
    f.close()

class asm_line:
    res_words = ["r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7"]

    def __init__(self, line_no, line) -> None:
        self.line_no = line_no
        self.line    = line

        self.label, self.parts, err = self.pre_process()

        if(self.parts == None or self.parts[0] == ""):
            self.valid = False
        else:
            self.valid = True

        if(check_error(err, line)):
            sys.exit()

    def pre_process(self):
        pure_asm = ""

        line = self.line.split('#')[0]

        if(line.find(':') != -1):
            parts = line.split(':')
            label = parts[0].lstrip().rstrip()

            if(label.find(' ') != -1 or label.find(',') != -1):
                return None, None, pre_processor_error("Label must not contain delimters", self.line_no)
            if(label == ""):
                return None, None, pre_processor_error("Label must not be empty", self.line_no)
            if(len(parts) >2):
                return None, None, pre_processor_error("Multiple ':' detected!", self.line_no)

            pure_asm = parts[1].lstrip().rstrip()

            if(label[0] == '-' or label[0].isdigit()):
                return None, None, pre_processor_error("Illegal label name! (starts with - or digit)", self.line_no)

            if(label in self.res_words):
                return None, None, pre_processor_error(f"label name, {label} is a reserved keyword!", self.line_no)
        else:
            label = None
            pure_asm = line.lstrip().rstrip()

        pure_asm = pure_asm.replace(',', ' ')

        parts = [i for i in pure_asm.split(' ') if i != '']

        if(len(parts) == 0):
            parts = None

        return label, parts, None

def main():
    if(len(sys.argv) == 1):
        print("No input file name detected. Please pass input file name as argument.")
        return

    source_file = sys.argv[1]
    
    if(len(sys.argv) == 2):
        dest_file = os.path.splitext(source_file)[0] + ".data"
    else:
        dest_file   = sys.argv[2]

    print(f"Source      : {source_file}")
    print(f"Destination : {dest_file}")
    
    output = ""

    coder   = Coder()
    lines   = []
    processed_lines = []
    symbols = {}

    with open(source_file, "r") as f:
        line_num = 0

        # Pre-processing
        while True:
            line_num = line_num + 1
            line = f.readline()
            if(line == ""):
                break
            
            lines.append(asm_line(line_num, line))

        line_num = 0

        # Parse symbols
        for l in lines:
            if l.label != None:
                if(not l.valid):
                    symbols[l.label] = line_num
                elif(l.parts[0] == ".fill"):
                    if(l.parts[1] in symbols.keys()):
                        symbols[l.label] = symbols[l.parts[1]]
                    symbols[l.label] = l.parts[1]
                elif(l.parts[0] == ".space"):
                    symbols[l.label] = "0"
                else:
                    symbols[l.label] = line_num

            if(l.parts != None):
                if(l.parts[0][0] == '.'):
                    l.valid = False

            if(l.valid):
                line_num = line_num + 1

        print("Symbols detected : " + str(symbols))

        line_num = 0
        # Replace symbols and pseudo instructions in the stream
        for l in lines:
            if(l.valid):
                if(l.parts != None):
                    # First, replace the keys
                    for i, p in enumerate(l.parts):
                        if(i == 0):
                            continue
                        if(p in symbols.keys()):
                            if(isinstance(symbols[p], int)):
                                if(l.parts[0] == "beq"):
                                    l.parts[i] = str(symbols[p] - line_num - 1)
                                else:
                                    print("Warning : using label address as immediate value in non-branch instruction")
                                    l.parts[i] = str(symbols[p])
                            else:
                                l.parts[i] = symbols[p]

                    # If pseudo-instruction, substitute
                    if(l.parts[0] == "nop"):
                        processed_lines.append(["add", "r0", "r0", "r0"])
                        line_num = line_num + 1
                    elif(l.parts[0] == "halt"):
                        processed_lines.append(["jalr", "0", "0"])
                        line_num = line_num + 1
                    elif(l.parts[0] == "lli"):
                        imm = parse_imm(l.parts[2])[0]
                        if(len(imm) > 6):
                            imm = imm[-6:0]
                        processed_lines.append(["addi", l.parts[1], l.parts[1], "0b" + imm])
                        line_num = line_num + 1
                    elif(l.parts[0] == "movi"):
                        # movi rega, imm 
                        #   lui rega, (imm & 0xffc0) >> 6 
                        #   addi rega, rega, imm & ox3f
                        imm = parse_imm(l.parts[2])[0]
                        imm = "0" * (16 - len(imm)) + imm
                        processed_lines.append(["lui", l.parts[1], "0b" + imm[:-6]])
                        processed_lines.append(["addi", l.parts[1], l.parts[1], "0b" + imm[-6:]])
                        line_num = line_num + 2
                    else:
                        processed_lines.append(l.parts)
                        line_num = line_num + 1



        # for l in lines:
        #     print(str(l.line_no) + " : " + str(l.parts) + ("" if l.valid else "(invalid)"))

        for l in processed_lines:
            print(str(l))
            output = output + coder.decode_asm(l, 0, " ")

        # for l in lines:
        #     if l.valid:
        #         output = output + coder.decode_asm(l.parts, l.line_no, l.line)

    write_code(dest_file, output)

if __name__ == "__main__":
    main()
