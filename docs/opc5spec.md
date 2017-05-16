OPC5 Definition
----------------

OPC-5 is a pure 16 bit [One Page Computer](.) with a 16 entry register file and predicated instruction
execution. All memory accesses are 16 bits wide and instructions are encoded in a fixed two word format ::

    pp 1o_xxoo ssss dddd  nnnnnnnnnnnnnnnn
     \    \      \    \           \_______ 16b operand word
      \    \      \    \__________________  4b source/destination register
       \    \      \______________________  4b source register
        \    \____________________________  6b opcode (only 3 bits used but field compatible with NOPC5)
         \________________________________  2b predicate bits                         

On reset the processor will start executing instructions from location 0.

All instructions can have predicated execution and this is determined by the two instruction MSBs:

  |  Carry Pred.  |    Zero Pred. |    Function                                            |
  |---------------|---------------|--------------------------------------------------------|
  |      1        |        1      |    Always execute                                      |
  |      1        |        0      |    Execute only if Zero flag is set                    |
  |      0        |        1      |    Execute only if Carry flag is set                   |
  |      0        |        0      |    Execute only if both Zero and Carry flags are set   |

OPC-5 has a 16 entry register file. Each instruction can specify one register as a source and another
as both source and destination using the two 4 bit fields in the encoding. Two of the registers have
special purposes: 

  * R0 holds 'all-zeros'. It is legal to write R0 but this has no effect on the register contents.

  * R15 is the program counter. This can be written or read like any other register.
  Absolute and relative jumps and branches can be made by modifying the program counter, with
  the option of predicated execution as with all other instructions.

The following addressing modes are supported. In all cases the effective address (EA) is initially created
by adding the 16b operand (or zero if none supplied) to the source register. 

  * Direct    - R0 is used as the source register, so the EA specifies a memory location directly
  * Indirect  - A zero operand is used so the EA is effectively the memory location pointed to by the
              contents of the chosen source register
  * Indexed   - the EA created by adding source register and non-zero operand  specifies a memory 
              location from which to read or to which to store data 
  * Immediate - the EA is treated as immediate data for a load (move) or arithmetic/logical operation

There are only two processor status flags:

  * Carry - set or reset only on arithmetic operations 
  * Zero  - set on every instruction based on the state of the destination register (and not set on stores)

All instructions support all addressing modes.

Instruction Table
-----------------

  |Assembler Code          |Function                       |#Words   |#States   |Opcode  |
  |------------------------|-------------------------------|---------|----------|--------|
  |ld.i    r1, r2, n       |r1 <- r2 + n                   |2        |4         |10_00xx |
  |ld      r1, r2, n       |r1 <- mem(r2 + n)              |2        |5         |11_00xx |
  |sto     r1, r2, n       |mem(r2+n) <- r1                |2        |4         |10_11xx |
  |add.i   r1, r2, n       |r1 <- r1 + r2 + n              |2        |4         |10_01xx |
  |add     r1, r2, n       |r1 <- r1 + mem(r2 + n)         |2        |5         |11_01xx |
  |nand.i  r1, r2, n       |r1 <- !(r1 &(r2 + n))          |2        |4         |10_10xx |
  |nand    r1, r2, n       |r1 <- !(r1 &(mem(r2 + n)))     |2        |5         |11_10xx |

Note: the assembler will always use 0's in place of x (don't care) for compatibility with NOPC-5.
