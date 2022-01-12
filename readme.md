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
![](docs/RiSC-16_formats.png)

- 8 instructions
![](docs/RiSC-16_instructions.png)

- Function of instructions :
    ![Instructions](docs/RiSC16_instructions.png)

- Above 3 images are from the RiSC-16 ISA reference (in [references](#references))

---

## Non-pipelined implementation

- Implementation of a simple non-pipelined version
- RTL code written in **verilog**
- Constrained random verification using **system verilog**
  - **Reference models** of sub-components
  - Testing by comparing results of reference model and RTL design using **constrained random stimulus**
- Documentation : [non_pipelined](non_pipelined/readme.md)

- Register file was **formally verified**

---

## Tools

- Tools for RiSC-16 written in python

1) Assembler
2) Random instruction generator

---

## References
1) [RiSC-16 homepage](https://user.eng.umd.edu/~blj/RiSC/)
 