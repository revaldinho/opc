OPC6 Definition
-----------------

OPC-6 a pure 16 bit [One Page Computer](.) with a 16 entry register file based very largely on the earlier
OPC-5 and OPC-5LS machines, but with a significantly extended instruction set.

All memory accesses are 16 bits wide and instructions are encoded in either one or two words ::

    ppp l oooo ssss dddd  nnnnnnnnnnnnnnnn
      \  \   \    \   \           \_______ 16b optional operand word
       \  \   \    \___\__________________  4b source and destination registers
        \  \___\__________________________  1b instruction length + 4b opcode
         \________________________________  3b predicate bits                         

On reset the processor will start executing instructions from location 0.

OPC-6 has a 16 entry register file. Each instruction can specify one register as a source and another as both source
and destination using the two 4 bit fields in the encoding. Two of the registers have special purposes:

  * R0 holds 'all-zeros'. It is legal to write R0 but this has no effect on the register contents.
  * R15 is the program counter. This can be written or read like any other register.

Addressing Modes and Effective Address/Data Computation
-------------------------------------------------------

The 16b effective address or data (EAD) for all instructions is created by adding the 16b operand to the source register.
By using combinations of the zero register and zero operands with the LD and STO instructions the following addressing modes are supported:

  |  Mode     | Source Reg | Operand   |  Effective address/Data  |
  |-----------|------------|-----------|--------------------------|
  | Direct    | R0         | \<addr\>  | mem[\<addr\>]            |
  | Indirect  | \<reg\>    | 0         | mem[\<reg\>]             |
  | Indexed   | \<reg\>    | \<index\> | mem[\<reg\> + \<index\>] |
  | Immediate | R0         | \<immed\> | \<immed\>                |

Processor Status Register
-------------------------

The processor has an 8 bit processor status register. Included in this arethree processor status flags which 
are set by ALU operations - calculation of the EAD values has no effect on these - and 5 bits related to interrupt
handling. 

  * SWI   - 4 bits used to identify a software interrupt. Writing a non-zero value here triggers a SWI.
  * EI    - used to enable or disable hardware interrupts
  * Carry - set or cleared only on arithmetic operations
  * Zero  - set on every instruction based on the state of the destination register
  * Sign  - set when the MSB of the result is a '1'

Predication
-----------

Many instructions can have predicated execution and this is determined by the three instruction MSBs and indicated by
a prefix on the instruction mnemonic in the assembler.

  | P0 | P1 | P2 | Asm Prefix | Function                                           |
  |----|----|----|------------|----------------------------------------------------|
  |  0 |  0 |  0 | 1. or none | Always execute                                     |
  |  0 |  0 |  1 | 0.         | Used as a 5th opcode bit for extended instructions |
  |  0 |  1 |  0 | z.         | Execute if Zero flag is set                        |
  |  0 |  1 |  1 | nz.        | Execute if Zero flag is clear                      |
  |  1 |  0 |  0 | c.         | Execute if Carry flag is set                       |
  |  1 |  0 |  1 | nc.        | Execute if Carry flag is clear                     |
  |  1 |  1 |  0 | mi.        | Execute if Sign flag is set                        |
  |  1 |  1 |  1 | pl.        | Execute if Sign flag is clear                      |

Instruction Set
---------------

