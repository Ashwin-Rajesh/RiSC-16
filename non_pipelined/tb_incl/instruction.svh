/*
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
*/

`ifndef INSTRUCTION_SVH
`define INSTRUCTION_SVH

// Opcode type enum
typedef enum logic[2:0] {
    ADD     = 0,
    ADDI,
    NAND,
    LUI,
    SW,
    LW,
    BEQ,
    JALR        
} opcode_t;

// Instruction format enum
typedef enum logic[1:0] {
    RRR     = 0,
    RRI,
    RI
} opcode_format_t;

typedef logic[2:0] regflield_t;

// Class for instruction
class instruction;
  rand opcode_t opcode;   	// Opcode
  
  rand regflield_t rega;   	// Register A field
  rand regflield_t regb;   	// Register B field
  rand regflield_t regc;   	// Register C field

  rand int imm;           	// Immediate value field

  // What format is an instruction?
  static const opcode_format_t format_lookup[opcode_t] = '{
    ADD		: RRR,
    ADDI  	: RRI,
    NAND  	: RRR,
    LUI		: RI,
    SW		: RRI,
    LW		: RRI,
    BEQ		: RRI,
    JALR 	: RRI
  };

  // Immediate value must be valid
  constraint imm_limit {
    // If in RRI format, -64 <= imm <= 63. If opcode is JALR, imm = 0
    if(format_lookup[opcode] == RRI)
      if(opcode == JALR)
        imm == 0;
      else
        imm dist {0:=10, [-63:-1]:/40, [1:62]:/40, -64:=5, 63:=5};
    // If in RI format, 0 <= imm <= 1023
    else if(format_lookup[opcode] == RI)
        imm dist {0:=10, 1023:=10, [1:1022]:/80};
    
    solve opcode before imm;
  }
  
  covergroup cg;
    opcode_cover:		coverpoint opcode;
  	
    rega_cover:		coverpoint rega;
    
    regb_cover:		coverpoint regb;
    
    regc_cover:		coverpoint regc;
    
    sig_imm : 		coverpoint imm  iff(format_lookup[opcode] == RRI){
      bins zero = {0};
      bins min  = {-64};
      bins pos  = {[1:63]};
      bins neg  = {[-63:-1]};
      bins max  = {63};
    }
    
    long_imm:	coverpoint imm iff(format_lookup[opcode] == RI){
      bins zero = {0};
      bins vals[5] = {[1:1023]};
    }
    
    RRR_cover : cross opcode_cover, rega_cover, regb_cover, regc_cover 	iff(format_lookup[opcode] == RRR);
    RRI_cover : cross opcode_cover, rega_cover, regb_cover, sig_imm	    iff(format_lookup[opcode] == RRI);
    RI_cover  : cross opcode_cover, rega_cover, long_imm		            iff(format_lookup[opcode] == RI);
  endgroup

  // Constructor
  function new(
    opcode_t op_in      = opcode_t'(3'bx), 
    regflield_t rega_in = regflield_t'(3'bx), 
    regflield_t regb_in = regflield_t'(3'bx), 
    regflield_t regc_in = regflield_t'(3'bx), 
    int imm_in  = int'(64'bx));
    opcode = op_in;
    rega = rega_in;
    regb = regb_in;
    regc = regc_in;
    imm  = imm_in;
    
    cg = new();
  endfunction

  // Return the string representation of the instruction
  function string to_string();
    string regs = "";
    
    case(opcode)
      ADD, NAND : begin
        regs = $sformatf("r%d, r%d, r%d", rega, regb, regc);
      end
      ADDI, SW, LW, BEQ : begin
        regs = $sformatf("r%d, r%d, %-3d", rega, regb, imm);
      end
      JALR: begin
        regs = $sformatf("r%d, r%d", rega, regb);
      end
      LUI: begin
        regs = $sformatf("r%d, %-3d", rega, imm);
      end
      default: begin
        return "x";
      end
    endcase
    
    return $sformatf("%-4s %-11s", opcode.name, regs);                          
  endfunction : to_string
  
  // Return the binary form of the instruction
  function logic[15:0] to_bin();
    logic[15:0] temp;
    
    temp[15:13] = opcode;
    
    case(format_lookup[opcode])
    	RRR:
        temp[12:0] = {rega, regb, 4'b0, regc};
      RRI:
        temp[12:0] = {rega, regb, imm[6:0]};
      RI:  
        temp[12:0] = {rega, imm[9:0]};
    endcase
    
    return temp;
  endfunction : to_bin

  // Get values from binary
  function from_bin(logic[15:0] bin_code);
    opcode = opcode_t'(bin_code[15:13]);
    rega = bin_code[12:10];    

    case(format_lookup[opcode])
      RRR: begin
        regb = bin_code[9:7];
        regc = bin_code[2:0];
      end
      RRI: begin
        regb = bin_code[9:7];
        imm  = {{25{bin_code[6]}}, bin_code[6:0]};
      end
      RI: begin
        imm  = bin_code[9:0];
      end
    endcase
  endfunction : from_bin
endclass : instruction

`endif