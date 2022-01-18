# Single-cycle implementation

The single-cycle implementation of the RiSC-16 ISA

---

## RTL code structure

#### ```mem_data.v```
- Data memory
  ```verilog
  module mem_data #(
      parameter p_WORD_LEN = 16,                  // Number of bits in a word
      parameter p_ADDR_LEN = 10,                  // Number of addressing lines
      localparam p_MEM_SIZE = 2 ** p_ADDR_LEN     // Number of words
  ) (
      input i_clk,                                // Clock signal
      input i_wr_en,                              // High to write on positive edge

      input[p_ADDR_LEN-1:0]        i_addr,        // Address of data
      output[p_WORD_LEN-1:0]       o_rd_data,     // Data for reading (asynchronous)
      input[p_WORD_LEN-1:0]        i_wr_data      // Data for writing (on posedge)
  );
  ```

#### ```mem_reg.v```
- Register file
```verilog
module mem_reg #(
    parameter p_WORD_LEN        = 16,
    parameter p_REG_ADDR_LEN    = 3,
    parameter p_REG_FILE_SIZE   = 8
) (
    input i_clk,                                // Clock signal

    input[p_REG_ADDR_LEN-1:0]     i_src1,      // Read address 1
    input[p_REG_ADDR_LEN-1:0]     i_src2,      // Read address 2
  	input[p_REG_ADDR_LEN-1:0]     i_tgt,       // Write register address

    output[p_WORD_LEN-1:0]        o_src1_data, // Read output 1 (asynchronous)
    output[p_WORD_LEN-1:0]        o_src2_data, // Read output 2 (asynchronous)
    input[p_WORD_LEN-1:0]         i_tgt_data,  // Input to write to the target (on posedge)

    input i_wr_en                              // High to write on posedge
);
```

#### ```core.v```
- Control and ALU
- Uses ```mem_reg``` and ```mem_data``` modules
```verilog
module core #(
	parameter p_DATA_MEM_SIZE=1024              // Length of data memory
) (
    input               i_clk,                  // Main clock signal
    input               i_rst,                  // Global reset

    input[15:0]         i_inst,                 // Instruction input from instruction memory
    output reg[15:0]    o_pc                    // Program counter output to instruction memory
);
```
- Has 2 combinational always blocks. Functions :
  - Decide which register fields to give to which port of the register file
  - Set register and memory control and data input signals
- One sequential always block
  - Update the program counter

#### ```design.v```
- Toplevel module
- Integrates core and instruction memory
```verilog
module toplevel (
  input clk,                  // Global clock
  output[15:0] pc
);
```
- Reads from the file, ```code.data``` to initialize instruction memory

---

## Reference models

- In folder [tb_incl](./tb_incl)
- System verilog classes to be used to compare results with the DUT(design under test) in constrained random verification

#### ```instruction.svh```

- Datatype ```regfield_t``` 
  - ```logic[2:0]``` type
  - For register address fields in instructions

- Enumeration ```opcode_t```
  - ```logic[2:0]``` type
  - For all 8 instructions with their actual opcodes

- Enumeration ```opcode_format_t```
  - ```logic[2:0]``` type
  - For the 3 instruction formats
  - ```RRR``` : 0
  - ```RRI``` : 1
  - ```RI```  : 2

- A class, ```instruction``` to model the instructions for other reference models

- constraint ```imm_limit```
  - Set limits for immediate values (0 to 1023 for long immediate, -64 to 63 for signed immediate)
  - Higher probability to get 0, and extremum values (-64, 63 for signed immediate, 1023 for long immediate)

- coverpoint ```cg```
  - opcode
  - register fields
  - immediate value

- ```verilog
  function new(
    opcode_t op_in      = opcode_t'(3'b0), 
    regflield_t rega_in = regflield_t'(3'b0), 
    regflield_t regb_in = regflield_t'(3'b0), 
    regflield_t regc_in = regflield_t'(3'b0), 
    int imm_in  = int'(64'b0)
  );
  ```
  - Constructor
  - By default, all values are 0 (```nop``` instruction, ```add r0, r0, r0```)

- ```function string to_string();```
  - Convert the instruction representation to string

- ```function logic[15:0] to_bin();```
  - Convert the instruction representation to binary

- ```function void from_bin(logic[15:0] bin_code);```
  - Get the values from binary representation

- ```function string get_coverage();```
  - Get instruction format wise coverage information as a string

#### ```mem_data_ref.svh```
- Data memory reference
- Parameters
  - ```size``` : Size of data memory
- ```function new;```
  - Constructor
- ```function void write_mem(input bit[15:0] addr, bit[15:0] data);```
  - Write ```data``` to ```addr```
- ```function bit[15:0] read_mem(bit[15:0] addr);```
  - Read from ```addr```
- ```function void reset;```
  - Reset memory

#### ```mem_reg_ref.svh```
- Register class for the register file

- ```function new;```
  - Constructor

- ```function void write_reg(bit[2:0] addr, bit[15:0] data);```
  - Write data to register at addr

- ```function bit[15:0] read_reg(bit[2:0] addr);```
  - Read from register at addr

- ```function void reset();```
  - Reset the register file

#### ```simulator.svh```
- Reference for the CPU model

- ```function new();```
  - Constructor

- ```function string to_string();```
  - Output the currest state of the simulator
  - Format : ```program_count : next_inst : register values```

- ```function void set_inst(instruction inp);```
  - Set the instruction to execute next

- ```function void exec_inst();```
  - Execute the stored instruction

---

## Testbenches

- In folder [tb](./tb)
- ```core_test.sv```
  - Testing the entire processor
  - Output :
  ```
  Staring core processor test
          0 instructions completed
      10000 instructions completed
      20000 instructions completed
      30000 instructions completed
      40000 instructions completed
      50000 instructions completed
      60000 instructions completed
      70000 instructions completed
      80000 instructions completed
      90000 instructions completed
  Number of failures :           0
  Instruction coverage : Net - 100.00		RRR - 100.00		RRI ; 100.00		RI : 100.00
  Finished core processor test
  ```
- ```inst_test.sv```
  - Testing if instruction model encode and decode is working
  - Output:
  ```
  Staring instruction test
          0 NAND r7, r4, r4  NAND r7, r4, r4 
        250 ADD  r1, r3, r7  ADD  r1, r3, r7 
        ...
      24750 BEQ  r3, r3, 20  BEQ  r3, r3, 20 
          0 inconsistencies detected!
  Coverage : Net - 99.99		RRR - 99.90		RRI ; 100.00		RI : 100.00
  Finished instruction test
  ```
- ```mem_data_test.sv```
  - Testing data memory
  - Output :
  ```
  Starting data memory test
  Coverage : 100.00
  Data memory test finished
  ... (simuator logs)
  "mem_data_test.sv", 110: mem_data_test.cover_reread, 50083 attempts, 15450 total match, 15450 first match
  ...
  ```
- ```mem_reg_test.sv```
  - Testing register file
  - Output :
  ```
  Starting register test
  Coverage : 100.00
  Finished register test
  ```
- ```testbench.sv```
  - Toplevel testbench which instantiates the other testbenches

---

## Developer notes

- This was my first try with proper, comprehensive verification
- I caught multiple bugs in both the RTL code and the reference designs
  - Assigning 0 to a wire by mistake
  - Inaccuracy in JALR instruction execution by the simulator when both rega and regb are the same
- 100,000 random instructions were generated and used for verification. Since the state was the same throughout, we can be reasonable confident that the reference design and RTL design are equivalent.
- There are no makefiles or scripts to run these because i used EDA playground to run them. Access it [here](https://www.edaplayground.com/x/H8RE)

---

## Synthesis

All synthesis results are for 2kB (1024 word) RAM and 2kB (1024 word) instruction memory (randomly generated instructions).

Initially, I had quite ignoranlty, put a single cycle reset for the data memory and register file. This turned out to be quite expensive. The logic utilization was :

|          Site Type         |  Used | Available | Util% |
|---|---|---|---|
| Slice LUTs*                | 10443 |     63400 | 16.47 |
|   LUT as Logic             | 10419 |     63400 | 16.43 |
|   LUT as Memory            |    24 |     19000 |  0.13 |
|     LUT as Distributed RAM |    24 |           |       |
|     LUT as Shift Register  |     0 |           |       |
| Slice Registers            | 16412 |    126800 | 12.94 |
|   Register as Flip Flop    | 16412 |    126800 | 12.94 |
|   Register as Latch        |     0 |    126800 |  0.00 |
| F7 Muxes                   |  2307 |     31700 |  7.28 |
| F8 Muxes                   |  1140 |     15850 |  7.19 |

However, when the reset was removed from the data memory and register file, the logic utilization became :

|          Site Type         | Used | Available | Util% |
|---|---|---|---|
| Slice LUTs*                |  806 |     63400 |  1.27 |
|   LUT as Logic             |  526 |     63400 |  0.83 |
|   LUT as Memory            |  280 |     19000 |  1.47 |
|     LUT as Distributed RAM |  280 |           |       |
|     LUT as Shift Register  |    0 |           |       |
| Slice Registers            |   26 |    126800 |  0.02 |
|   Register as Flip Flop    |   26 |    126800 |  0.02 |
|   Register as Latch        |    0 |    126800 |  0.00 |
| F7 Muxes                   |  256 |     31700 |  0.81 |
| F8 Muxes                   |  128 |     15850 |  0.81 |

That was a > 10 times improvement!! The previous version used way too many LUTs for logic than the CPU needed.

This is because a single-cycle reset of memory is very expensive to implement. Here, for memory, we use distributed RAM where the LUT SRAM bits are written to using an address input. But, we can only write to one bit at a time. We cannot reset all values in the LUT at once.

Still, distributed RAM (LUTs) are being used instead of block RAMs to implement memory because the read is asynchronous. To use block RAM, the read needs to synchronous, requiring a multi-cycle design. This will be our next challenge!
