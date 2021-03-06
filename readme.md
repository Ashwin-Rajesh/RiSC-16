# RiSC16

RiSC stands for Ridiculously Simple Computer. It is an ISA used for teaching purposes, based on the Little Computer (LC-896) ISA developed by Peter Chen at the University of Michigan.

---

## The RiSC-16 ISA

- 16-bit architecture
  - 16 bit registers
  - 16 bit ALU
  - 16 bit Data bus
  - 16 bit Address bus

- 8 registers
  - ```r0``` is always 0
  - All other registers ```r1```-```r7``` are general purpose

- 3 instruction formats 
![Instruction formats](docs/RiSC16_inst_formats.png)

- 8 instructions
![Instructions](docs/RiSC16_instructions.png)

- Function of instructions :
![Instruction information](docs/RiSC16_instructions.png)

- Above 3 images are from the RiSC-16 ISA reference (in [references](#references))

---

## Conventions

The following naming convention is followed in the verilog code :

| Prefix | Meaning
| -----|-------
| ```i_```| Input port
| ```o_```| Output port
| ```p_```| Parameter (or localparam)
| ```r_```| Register
| ```w_```| Wire
| ```s_```| State definitions (as localparam)

The following legend is followed for all diagrams in the documents. (all diagrams were made using drawio)

![](docs/legend.drawio.svg)

---

## Singe cycle implementation

- Implementation of a simple non-pipelined version
- RTL code written in **verilog**
- Constrained random verification using **system verilog**
  - **Reference models** of sub-components
  - Testing by comparing results of reference model and RTL design using **constrained random stimulus**

- Formal verification using symbiyosys
  - Proved register file and data memory using k-induction and bmc

- Documentation : [./single_cycle/readme.md](single_cycle/readme.md)

![Block diagram](single_cycle/docs/block_diagram.drawio.svg)

---

## Pipelined implementation

![](pipelined/docs/block_diagram.drawio.svg) 

---

## Utilities

- Tools for RiSC-16 written in python

1) Assembler
2) Random instruction generator

- For documentation and usage, go to [./utils/readme.md](./utils/readme.md)

---

## References
1) [RiSC-16 homepage](https://user.eng.umd.edu/~blj/RiSC/)
 