OPC2 Definition
---------------

OPC2 is a second minimal implementation of a [One Page Computer](.) which fits into a single Xilinx XC9572 CPLD.

OPC2 is a load/store based machine with an 8 bit datapath and an 11 bit address space. Like the OPC1 it
supports 3 addressing modes:

   * immediate - where the operand byte holds an 8 immediate data value or is ignored
   * direct - where a combination of opcode and operand byte provides an 11 bit data address
   * indirect (pointer) - loads and stores only, where the 11 bit operand is used to get an
     8 bit value from memory which is subsequently used as the address to/from which
     to store/read data.

The OPC2 datapath has two 8 bit registers which are used in all logical and arithmetic operations:

   * A - the accumulator, used as both an operand source and the only available desination
   * B - a secondary operand source

On using the JAL instruction the PC is swapped with the values in A and B, with B providing and
receiving the high PC byte (actually just a nybble) and A the low byte. This provides a base for
indirect jumps, computed jumps, calling subroutines and returning from them.

The OPC has just one flag register: the carry (C) flag. Branching instructions dependent on the
state of this flag and the state of the accumulator are available.

On reset the CPU starts execution at address 0x100 to leave page zero free for variables which can
be accessed by the 8 bit pointers.

OPC2 Instructions
-----------------

| Instr | Function                  | #bytes |  Opcode/Operand   |
|-------|---------------------------|--------|-------------------|
| lda.i | a <- n                    |  2     | 1000xxxx nnnnnnnn |
| lda   | a <- (n)                  |  2     | 1001xnnn nnnnnnnn |
| sta.p | ((n)) <- a                |  2     | 1010xnnn nnnnnnnn |
| lda.p | a <- ((n))                |  2     | 1100xnnn nnnnnnnn |
| sta   | (n) <- a                  |  2     | 0110xnnn nnnnnnnn |
| halt  | simulation only           |  2     | 11111111 xxxxxxxx |
|-------|---------------------------|--------|-------------------|
| jpc   | pc <- n if c else pc      |  2     | 0100nnnn nnnnnnnn |
| jpz   | pc <- n if (a==0) else pc |  2     | 0101nnnn nnnnnnnn |
| jal   | pc <- {b,a}; {b,a} <- pc  |  2     | 0111xxxx xxxxxxxx |
|-------|---------------------------|--------|-------------------|
| adc   | {c,a} <- a + b + c        |  1     | 0000xxxx	 	 |
| not   | a <- ~a                   |  1     | 0001xxxx    	 |
| and   | a <- a & b ; c <- 0       |  1     | 0010xxxx     	 |
| axb   | a <- b ; b <- a           |  1     | 0011xxxx    	 |

Notes
-----

JAL is a two byte instruction although the operand is not needed and is ignored. Lack of
space in the XC9572 means that decoding has had to be simplified here.
    
