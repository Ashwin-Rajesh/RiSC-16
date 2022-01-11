from random_asm_gen import reg_src

class instruction:
    # opcode id to name
    inst_names      = ["add", "addi", "nand", "lui", "sw", "lw", "beq", "jalr"]
    # instruction name to id
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

    # format id to name
    format_names    = ["rrr", "rri", "ri"]
    # format name to id
    format_id       = {
        "rrr"   : 0,
        "rri"   : 1,
        "rl"    : 2
    }

    # format for each opcode
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

    # Constructor
    def __init__(self, machine_code=None):

        self.opcode     = None
        self.rega       = None
        self.regb       = None
        self.regc       = None
        self.imm        = None
        self.line_num   = -1
        self.asm_line   = ""

        if(machine_code != None):
            self.decode(machine_code)            

    # Checks if inp is an integer in the range [0,max] (incl of both)
    def is_inrange(self, inp, max):
        if(not isinstance(inp, int)):
            return False

        if(inp < 0 or inp > max):
            return False
        
        return True

    # Checks if the details in the fields are valid
    def is_valid(self):
        if(not self.is_inrange(self.opcode, 7)):
            return False
        
        opcode_format = self.inst_format[self.opcode]

        if(opcode_format == "rrr"):
            if(not self.is_inrange(self.rega, 7)):
                return False

            if(not self.is_inrange(self.regb, 7)):
                return False

            if(not self.is_inrange(self.regc, 7)):
                return False

            return True
        elif(opcode_format == "rri"):
            if(not self.is_inrange(self.rega, 7)):
                return False

            if(not self.is_inrange(self.regb, 7)):
                return False

            if(self.opcode != self.inst_id["jalr"]):
                if(not isinstance(self.imm, int)):
                    return False

                if(self.imm > 63 or self.imm < -64):
                    return False

            return True

        elif(opcode_format == "rl"):
            if(not self.is_inrange(self.rega, 7)):
                return False

            if(not isinstance(self.imm, int)):
                return False
            
            if(self.imm < 0 or self.imm > 1023):
                return False

            return True

    # Returns the type as an integer
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

    # Decodes from machine code (and sets internal values)
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

    # Prepend 0s or 1s to get a constant size
    @staticmethod
    def extend(bin_str, size=3, signed=False):
        if(signed):
            if(bin_str[0]):
                return "1" * (size - len(bin_str)) + bin_str
            else:
                return "0" * (size - len(bin_str)) + bin_str
        else:
            return "0" * (size - len(bin_str)) + bin_str

    # Encode to machine code (from internal values)
    def encode(self):
        temp = ""

        opcode_str = bin(self.inst_names[self.opcode])[2:]

        opcode_str = self.extend(opcode_str, size=3)

        temp += opcode_str

        opcode_format = self.inst_format[self.opcode]

        if(opcode_format == "rrr"):
            rega_str = self.extend(bin(self.rega)[2:], size=3)
            regb_str = self.extend(bin(self.regb)[2:], size=3)
            regc_str = self.extend(bin(self.regc)[2:], size=3)
            
            temp += rega_str + regb_str + "0000" + regc_str

        elif(opcode_format == "rri"):
            rega_str = self.extend(bin(self.rega)[2:], size=3)
            regb_str = self.extend(bin(self.regb)[2:], size=3)

            if(self.imm < 0):
                imm_str = "1".join(['1' if x == '0' else '0' for x in bin(abs(self.imm)-1)[2:]])
            else:
                imm_str = bin(self.imm)[2:]

            imm_str = self.extend(imm_str, size=7, signed=True)

            temp += rega_str + regb_str + imm_str

        elif(opcode_format == "rl"):
            rega_str = self.extend(bin(self.rega)[2:], size=3)

            imm_str = bin(abs(self.imm))[2:]

            imm_str = self.extend(imm_str, size=10)

            temp += rega_str + imm_str

        return temp

    # Output string representation of the instruction
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
