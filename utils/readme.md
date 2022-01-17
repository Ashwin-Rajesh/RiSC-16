# RiSC-16 utils

Some tools for RiSC-16 development written in python.

- Written using ```python3```
- Uses only base python utilities. No dependencies

Tools include
- Assembler
- Random instruction generator

---

## Assembler

- A very simple assembler
- Can input immediate values in
  - Decimal
  - Hexadecimal (```0xff```)
  - Octal (```0o377```)
  - Binary (```0b11111111```)
- Comments start with ```#```

- To use the assembler, type the command
```
python3 assembler.py <assembly file> <output file>
```
or, if the file is made an executable using ```chmod```,
```
./assembler.py <assembly file> <output file>
```
- The paths are relative to your current directory, not the assembler file, if you are launching from somewhere else
- The output file name is optional. If not given, it will change the suffix of the source file to ```.data``` and save it.

- End aim is to be compliant with [this](https://user.eng.umd.edu/~blj/RiSC/RiSC-isa.pdf). This requires the following additional features to be added
  - Labels for jumps
  - Named constants
  - Psuedo instructions
    - ```nop```
    - ```halt```
    - ```lli```
    - ```movi```
    - ```.fill```
    - ```.space```

---

## Random instruction generator

- Completely random generation
- Does not check for valid jump addresses. This needs to be worked on
- Does not check for valid load/word addresses.
