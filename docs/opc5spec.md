OPC5 Definition
----------------

OPC-5 is a pure 16 bit [One Page Computer](.) with a 16 entry register file and predicated instruction
execution. All memory accesses are 16 bits wide and instructions are encoded in either one or two words ::

    ppp l oooo ssss dddd  nnnnnnnnnnnnnnnn
      \  \   \    \   \           \_______ 16b optional operand word
       \  \   \    \   \__________________  4b source/destination register
        \  \   \    \_____________________  4b source register
         \  \   \_________________________  4b opcode
          \  \____________________________  1b instruction length
           \______________________________  3b predicate bits                         

On reset the processor will start executing instructions from location 0.

All instructions can have predicated execution and this is determined by the three instruction MSBs:

  |  Carry Pred.  | Zero Pred. |  Predicate Invert  |   Function                       |
  |---------------|------------|--------------------|----------------------------------|
  |      1        |      1     |        0           |   Always execute                 |
  |      1        |      0     |        0           |   Execute if Zero flag is set    |
  |      0        |      1     |        0           |   Execute if Carry flag is set   |
  |      0        |      0     |        0           |   Execute if both Zero and Carry flags are set   |
  |      1        |      1     |        1           |   never execute - NOP            |
  |      1        |      0     |        1           |   Execute if Zero flag is clear  |
  |      0        |      1     |        1           |   Execute if Carry flag is clear |
  |      0        |      0     |        1           |   Execute if both Zero and Carry flags are clear |

OPC-5 has a 16 entry register file. Each instruction can specify one register as a source and another as both source
and destination using the two 4 bit fields in the encoding. Two of the registers have special purposes:

  * R0 holds 'all-zeros'. It is legal to write R0 but this has no effect on the register contents.

  * R15 is the program counter. This can be written or read like any other register.

The 16b effective address or data (EAD) for all instructions is created by adding the 16b operand to the source register.
By using combinations of the zero register and zero operands the following addressing modes are supported:

  |  Mode     | Source Reg | Operand  |  Effective address/Data   |
  |-----------|------------|----------|---------------------------|
  | Direct    | R0         | \<addr\>  | mem[\<addr\>]            |
  | Indirect  | \<reg\>    | 0         | mem[\<reg\>]             |
  | Indexed   | \<reg\>    | \<index\> | mem[\<reg\> + \<index\>] |
  | Immediate | R0         | \<immed\> | \<immed\>                |

There are only two processor status flags and these are set only by ALU operations - calculation of the EAD values
has no effect on these:

  * Carry - set or cleared only on arithmetic operations
  * Zero  - set on every instruction based on the state of the destination register (not set on stores)

All instructions support all addressing modes.

| Mnemonic           | Opcode | Function (Imm. Mode)     | Opcode | Function (Direct or Ind.Mode)| Carry |
|--------------------|--------|--------------------------|--------|------------------------------|-------|
| ld[.i] r1, r2, n   | 0000   | r1 <- EAD                | 1000   |  r1 <- mem(EAD)              |   -   |
| sto r1, r2, n      | -      | -                        | 0111   |  mem(EAD) <- r1              |   -   |
| add[.i] r1, r2, n  | 0001   | r1 <- r1 + EAD           | 1001   |  r1 <- r1 + mem(EAD)         | arith |
| and[.i] r1, r2, n  | 0010   | r1 <- r1 & (EAD)         | 1010   |  r1 <- r1 & mem(EAD)         |   -   |
| or[.i] r1, r2, n   | 0011   | r1 <- r1 \| (EAD)        | 1011   |  r1 <- r1 \| mem(EAD)        |   -   |
| xor[.i] r1, r2, n  | 0100   | r1 <- r1 ^ (EAD)         | 1100   |  r1 <- r1 ^ mem(EAD)         |   -   |
| ror[.i] r1, r2, n  | 0101   | r1 <- ROR(EAD, cin)      | 1101   |  r1 <- ROR(mem(EAD, cin)     |  LSB  |
| adc[.i] r1, r2, n  | 0110   | r1 <- r1 + (EAD) + c     | 1110   |  r1 <- r1 + mem(EAD) +c      | arith |

  * where EAD = (r2 + n) modulo 64K
