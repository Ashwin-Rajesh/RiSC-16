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

class op_decode_error(decode_error):
    typ = "Opcode decode error"

class reg_decode_error(decode_error):
    typ = "Register decode error"

class imm_decode_error(decode_error):
    typ = "Immediate decode error"

class internal_error(report_error):
    typ = "Internal error"

    def __str__(self) -> str:
        return "(internal error) " + super().__str__()

class inp_internal_error(internal_error):
    typ = "Input error"

def check_error(error, line_no, line):
    if(error == None):
        return False
    
    if(not isinstance(error, report_error)):
        raise TypeError(f"Argument was not None or report_error type. Received type {type(error)}")

    print()
    print(f"{error.typ} at line no {line_no}")
    print(f"    {line}")
    print(str(error))

    return True

def get_opcode(inp):
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
    
    return "___", 0, op_decode_error(f" Unknown opcode \"{inp}\"")

def get_reg(inp : str):
    start = 0
    if(inp[0] == "r"):
        start = 1

    try:
        val = int(inp[start])
    except ValueError:
        return "", reg_decode_error(f"Register id not an integer : {inp}")

    if(val < 8):
        out = bin(int(inp[start]))[2:]

        if(len(out) < 3):
            out = "0"*(3-len(out)) + out

        return out, None
    else:
        return "", reg_decode_error(f"Register id must be < 8")

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

def get_sigimm(inp : str):
    val, neg, parse_err = parse_imm(inp)

    if(parse_err != None):
        return "", parse_err

    val = ("1"*(7-len(val)) if neg else "0"*(7-len(val))) + val

    if(len(val) > 7):
        return "", imm_decode_error(f" Value is outside signed immediate field limit (-64 to 63). (Decoded to {val} : length {len(val)}, maximum 6))")

    return val, None

def get_imm(inp : str):
    val, neg, parse_err = parse_imm(inp)

    if(parse_err != None):
        return "", parse_err

    if(len(val) > 10):
        return "", imm_decode_error(f" Value is outside large immediate field limit (0 to -x3FF). (Decoded to {val} : length {len(val)}, maximum 10))")

    return "0"*(10-len(val)) + val, None

def write_code(file_name, bitstream):
    with open(file_name, "w") as f:
        for i in range(len(bitstream) // 16):
            f.write(bitstream[16 * i : 16*(i+1)]+"\n")
            print(bitstream[16*i : 16*(i+1)])
    f.close()

def main():
    if(len(sys.argv) == 1):
        print("No input file name detected. Plesae pass input file name as argument.")
        return

    source_file = sys.argv[1]
    
    if(len(sys.argv) == 2):
        dest_file = os.path.splitext(source_file)[0] + ".data"
    else:
        dest_file   = sys.argv[2]

    print(f"Source      : {source_file}")
    print(f"Destination : {dest_file}")
    
    output = ""

    with open(source_file, "r") as f:
        line_num = 0
        while True:
            line_num = line_num + 1
            line = f.readline()
            if(line == ""):
                break
            line = line.split('#')[0].rstrip()
    
            parts = [x.lower() for x in line.split(' ') if x != '']

            if(len(parts) != 0):
                opcode_str, opcode, opcode_err = get_opcode(parts[0])

                if(check_error(opcode_err, line_num, line)):
                    return
                
                # RRR - type
                if(opcode == 0 or opcode == 2):
                    regA, regA_err = get_reg(parts[1])
                    regB, regB_err = get_reg(parts[2])
                    regC, regC_err = get_reg(parts[3])

                    if(check_error(regA_err, line_num, line) or check_error(regB_err, line_num, line) or check_error(regC_err, line_num, line)):
                        return
                    
                    output = output + opcode_str + regA + regB + "0000" + regC

                # RRI - type
                elif(opcode == 1 or opcode == 4 or opcode == 5 or opcode == 6 or opcode == 7):
                    regA, regA_err = get_reg(parts[1])
                    regB, regB_err = get_reg(parts[2])
                    if(opcode == 7):
                        imm = "0000000"
                        imm_err = None
                    else:
                        imm, imm_err   = get_sigimm(parts[3])

                    if(check_error(regA_err, line_num, line) or check_error(regB_err, line_num, line) or check_error(imm_err, line_num, line)):
                        return
                    
                    output = output + opcode_str + regA + regB + imm

                # RI type
                else:
                    regA, regA_err = get_reg(parts[1])
                    imm, imm_err = get_imm(parts[2])
                    
                    if(check_error(regA_err, line_num, line) or check_error(imm_err, line_num, line)):
                        return
                    
                    output = output + opcode_str + regA + imm

    write_code(dest_file, output)


if __name__ == "__main__":
    main()