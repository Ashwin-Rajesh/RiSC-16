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

`ifndef SIMULATOR_SVH
`define SIMULATOR_SVH

`include "instruction.svh"
`include "mem_data_ref.svh"
`include "mem_reg_ref.svh"

class simulator #(int INSTRUCTION_COUNT=100, int DATA_COUNT=100);
  // logic[15:0] data_mem[DATA_COUNT];         // Data memory

  // logic[15:0] registers[7:0];               // Registers

  datamem #(DATA_COUNT) data_mem;

  regfile registers;

  int program_counter;                      // Program counter
  int temp;

  instruction inst;                         // Previous instruction

  // Constructor
  function new();
    program_counter = 0;

    data_mem = new();

    registers = new();

    inst = new();
  endfunction : new

  // Show state of the simulator (program_count : next_inst : register values)
  function string to_string();
    string temp = $sformatf("%3d : %-16s : ", program_counter, inst.to_string());
    for(int i = 0; i < 8; i = i + 1)
      temp = $sformatf("%s r%1d-%h", temp, i, registers.read_reg(i));
    return temp;
  endfunction : to_string

  // Set the instruction to execute next
  function void set_inst(instruction inp);
  	inst = inp;
  endfunction

  // Execute the instruction  
  function void exec_inst();
    // Define behaviour of each instruction here
    case (inst.opcode)
        ADD : begin
            registers.write_reg(inst.rega, registers.read_reg(inst.regb) + registers.read_reg(inst.regc));
            program_counter = program_counter + 1;
        end
        ADDI : begin
            registers.write_reg(inst.rega, registers.read_reg(inst.regb) + inst.imm);
            program_counter = program_counter + 1;
        end
        NAND : begin
            registers.write_reg(inst.rega, ~(registers.read_reg(inst.regb) & registers.read_reg(inst.regc)));
            program_counter = program_counter + 1;
        end
        LUI : begin
            registers.write_reg(inst.rega, {inst.imm, 6'b0});
            program_counter = program_counter + 1;
        end
        SW : begin
            data_mem.write_mem(registers.read_reg(inst.regb) + inst.imm, registers.read_reg(inst.rega));
            program_counter = program_counter + 1;
        end
        LW : begin
          	registers.write_reg(inst.rega, data_mem.read_mem(registers.read_reg(inst.regb) + inst.imm));
            program_counter = program_counter + 1;
        end
        BEQ : begin
            if(registers.read_reg(inst.rega) == registers.read_reg(inst.regb))
              program_counter = program_counter + 1 + inst.imm;
            else
              program_counter = program_counter + 1;
        end
        JALR : begin
          	temp = registers.read_reg(inst.regb);
          	if(inst.rega != 0)
              registers.write_reg(inst.rega, program_counter + 1);
            program_counter <= temp;			
        end
        default: 
            program_counter = program_counter + 1;
    endcase
    
    // Ensure that program counter value is valid
    while(program_counter < 0)
      program_counter = 65536 + program_counter;
    
    program_counter = program_counter % 65536;

  endfunction : exec_inst

  // Assertions to verify that current state is valid
  function void verify_state;
    assert(program_counter >= 0 && program_counter < 65536);

    assert(inst.randomize(null));
  endfunction

endclass

`endif