OPC5 Definition
----------------

OPC-5 is a pure 16 bit [One Page Computer](.) with a 16 entry register file and predicated instruction
execution. All memory accesses are 16 bits wide and instructions are encoded in either one or two words ::

    pp l o_ooox ssss dddd  nnnnnnnnnnnnnnnn
     \  \   \      \    \           \_______ 16b optional operand word
      \  \   \      \    \__________________  4b source/destination register
       \  \   \      \______________________  4b source register
        \  \   \____________________________  5b opcode (only 4 bits used)
         \  \_______________________________  1b instruction length
         \__________________________________  2b predicate bits                         

On reset the processor will start executing instructions from location 0.

All instructions can have predicated execution and this is determined by the two instruction MSBs:

  |  Carry Pred.  | Non-Zero Pred. |  Function                                           |
  |---------------|----------------|-----------------------------------------------------|
  |      1        |        1       |  Always execute                                     |
  |      1        |        0       |  Execute only if Zero flag is not set               |
  |      0        |        1       |  Execute only if Carry flag is set                  |
  |      0        |        0       |  Execute only if Zero is not set and Carry is set   |

OPC-5 has a 16 entry register file. Each instruction can specify one register as a source and another as both source
and destination using the two 4 bit fields in the encoding. Two of the registers have special purposes:

  * R0 holds 'all-zeros'. It is legal to write R0 but this has no effect on the register contents.

  * R15 is the program counter. This can be written or read like any other register.

The effective address (EA) for all instruction is created by adding the 16b operand to the source register. By using
combinations of the zero register and zero operands the following addressing modes are supported:

  |  Mode     | Source Reg | Operand  |  Effective address/Data   |
  |-----------|------------|----------|---------------------------|
  | Direct    | R0         | <addr>   | mem[<addr>]               |
  | Indirect  | <reg>      | 0        | mem[<reg>]                |
  | Indexed   | <reg>      | <index>  | mem[<reg> + <index>]      |
  | Immediate | R0         | <immed>  | <immed>                   |

There are only two processor status flags:

  * Carry - set or reset only on arithmetic operations
  * Zero  - set on every instruction based on the state of the destination register (and not set on stores)

All instructions support all addressing modes.

Instruction Table
-----------------

| Mnemonic           | Opcode | Function (Imm. Mode)     | Opcode | Function (Direct or Ind.Mode)| Carry |
|--------------------|--------|--------------------------|--------|------------------------------|-------|
| ld[.i] r1, r2, n   | 0000   | r1 <- r2 + n             | 1000   |  r1 <- mem(r2+n)             |   -   |
| sto r1, r2, n      | -      | -                        | 0111   |  mem(r2+n) <- r1             |   -   |
| add[.i] r1, r2, n  | 0001   | r1 <- r1 + r2 + n        | 1001   |  r1 <- r1 + mem(r2+n)        | arith |
| and[.i] r1, r2, n  | 0010   | r1 <- (r1 & (r2 + n))    | 1010   |  r1 <- (r1 & mem(r2+n))      |   -   |
| or[.i] r1, r2, n   | 0011   | r1 <- (r1 | (r2 + n))    | 1011   |  r1 <- (r1 | mem(r2+n))      |   -   |
| xor[.i] r1, r2, n  | 0100   | r1 <- (r1 ^ (r2 + n))    | 1100   |  r1 <- (r1 ^ mem(r2+n))      |   -   |
| ror[.i] r1, r2, n  | 0101   | r1 <- ROR(r2+n)          | 1101   |  r1 <- ROR(mem(r2+n)         |  LSB  |
| sub[.i] r1, r2, n  | 0110   | r1 <- r1 - (r2 + n)      | 1110   |  r1 <- r1 - mem(r2+n)        | arith |
