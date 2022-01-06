// Code your testbench here
// or browse Examples

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
  rand opcode_t opcode;   // Opcode
  
  rand regflield_t rega;   // Register A field
  rand regflield_t regb;   // Register B field
  rand regflield_t regc;   // Register C field

  rand int imm;           // Immediate value field

  // What format is an instruction?
  static const opcode_format_t format_lookup[opcode_t] = '{
    ADD		: RRR,
    ADDI  : RRI,
    NAND  : RRR,
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
    
    return $sformatf("%-4s %s", opcode.name, regs);                          
  endfunction : to_string
  
  // Return the binary form of the instruction
  function logic[15:0] get_bin();
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
  endfunction : get_bin

  function set_from_bin(logic[15:0] bin_code);
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
        regb = bin_code[9:7];
        imm  = bin_code[6:0];
      end
    endcase
  endfunction : set_from_bin
endclass : instruction

event next_instr;

class simulator #(int INSTRUCTION_COUNT=100, int DATA_COUNT=100);
  instruction inst_mem[INSTRUCTION_COUNT];  // Instruction memory

  logic[15:0] data_mem[DATA_COUNT];         // Data memory

  logic[15:0] registers[7:0];               // Registers

  int program_counter;                      // Program counter

  instruction prev_inst;                    // Previous instruction

  // Constructor
  function new(instruction inst_stream[]);
    for(int i = 0; i < INSTRUCTION_COUNT; i = i + 1)
      if(i < inst_stream.size())
        inst_mem[i] = inst_stream[i];
      else
        inst_mem[i] = new();

    program_counter = 0;

    prev_inst = new();

    for(int i = 0; i < DATA_COUNT; i = i + 1)
      data_mem[i] = 0;
    
    for(int i = 0; i < 8; i = i + 1)
      registers[i] = 0;
  endfunction : new

  // Show state of the simulator (program_count : prev_inst : register values)
  function string to_string();
    string temp = $sformatf("%3d : %-16s : ", program_counter, prev_inst.to_string());
    for(int i = 0; i < 8; i = i + 1)
      temp = $sformatf("%s r%1d-%h", temp, i, registers[i]);
    return temp;
  endfunction : to_string

  function string exec_inst();
    prev_inst = inst_mem[program_counter];
    case (prev_inst.opcode)
        ADD : begin
            write_reg(prev_inst.rega, read_reg(prev_inst.regb) + read_reg(prev_inst.regc));
            program_counter = program_counter + 1;
        end
        ADDI : begin
            write_reg(prev_inst.rega, read_reg(prev_inst.regb) + prev_inst.imm);
            program_counter = program_counter + 1;
        end
        NAND : begin
            write_reg(prev_inst.rega, ~(read_reg(prev_inst.regb) & read_reg(prev_inst.regc)));
            program_counter = program_counter + 1;
        end
        LUI : begin
            write_reg(prev_inst.rega, {prev_inst.imm, 6'b0});
            program_counter = program_counter + 1;
        end
        SW : begin
            data_mem[read_reg(prev_inst.regb) + prev_inst.imm] = read_reg(registers[prev_inst.rega]);
            program_counter = program_counter + 1;
        end
        LW : begin
          	write_reg(prev_inst.rega, data_mem[read_reg(prev_inst.regb) + prev_inst.imm]);
            program_counter = program_counter + 1;
        end
        BEQ : begin
            if(read_reg(prev_inst.rega) == read_reg(prev_inst.regb))
              program_counter = program_counter + prev_inst.imm;
            else
              program_counter = program_counter + 1;
        end
        JALR : begin
            write_reg(prev_inst.rega, program_counter + 1);
            program_counter = registers[prev_inst.regb];
        end
        default: 
            program_counter = program_counter + 1;
    endcase
  endfunction : exec_inst

  function logic[15:0] read_reg(regflield_t reg_idx);
    if(reg_idx == 0)
      return 0;
    else
      return registers[reg_idx];
  endfunction

  function void write_reg(regflield_t reg_idx, logic[15:0] inp);
    if(reg_idx != 0)
      registers[reg_idx] = inp;
  endfunction
endclass

module test;
  localparam max_instr = 12;

  instruction inst_stream[max_instr];

  bit[15:0] inst_mem[max_instr];

  simulator sim;
  
  initial begin
	instruction inst;
    $readmemb("rand.data", inst_mem);
      
    for(int i = 0; i < max_instr; i = i + 1) begin
      inst = new();
      inst.set_from_bin(inst_mem[i]);

      inst_stream[i] = inst;

      $display("%s", inst.to_string());
    end
    
    sim = new(inst_stream);
    
    for(int i = 0; i < 200; i = i + 1) begin
      	sim.exec_inst();
      	$display("%s", sim.to_string());
    end
  end
endmodule
