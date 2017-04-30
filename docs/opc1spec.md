OPC1 Definition
---------------

OPC1 is a minimal implementation of a One Page Computer designed to fit inside a single Xilinx
XC9572 CPLD.

The OPC1 is an accumulator based computer with an 8 bit datapath and a 11 bit address space.
The computer supports 2 addressing modes:

   * immediate/implied - where the operand byte holds an 8 immediate data value or is ignored
   * direct - where a combination of opcode and operand byte provides a 11 bit data address

The OPC has just one flag register: the carry (C) flag. Branching instructions dependent on the
state of this flag and the state of the accumulator are available.

All instructions are encoded in a fixed two byte format consisting of an opcode byte and an
operand byte::

    bbbb  xooo   oooooooo
     \       \________\______  11 bit operand       Direct Instructions
      \______________________   4 bit opcode

    bbbb  xxxx   oooooooo
      \      \        \______  8 bit operand        Immediate/Implied Instructions
       \      \______________  4 bit unused
        \____________________  4 bit opcode

Instruction Set Definition
--------------------------

| Mnemonic | Opcode | Function (Imm. Mode) | Opcode | Function (Direct Mode)       | C     |
|----------|--------|----------------------|--------|------------------------------|-------|
| AND[.i]  | 1.000  | A <- A & n           | 0.000  | A <- A & (n)                 | 0     |
| LDA[.i]  | 1.001  | A <- n               | 0.001  | A <- (n)                     | -     |
| NOT[.I]  | 1.010  | A <- ~n              | 0.010  | A <- ~(n)                    | -     |
| ADD[.i]  | 1.011  | A <- A+n+C           | 0.011  | A <- A+(n)+C                 | arith |
| RTS      | 1.100  | PC<-LINK             |  -     | -                            | -     |
| LXA      | 1.101  | Swap Acc with Link   |  -     | -                            | -     |
| HALT     | 1.110  | Halt simulation      |  -     | -                            | -     |
| STA      |  -     |     -                | 0.100  | (n) <- A                     | -     |
| JPC      |  -     |     -                | 0.101  | PC <-n if C==1 else PC+2     | -     |
| JPZ      |  -     |     -                | 0.110  | PC <-n if (ACC==0) else PC+2 | -     |
| JP       |  -     |     -                | 0.111  | PC <- n                      | -     |
| JSR      | 1.111  | LINK<-PC;PC<- n      | -      | -                            | -     |

Notes

  * (n) indicates contents of memory at address 'n'
  * PC is incremented by 2 bytes after each instruction unless explicitly indicated
  * Flag operations shown as '-' preserve flag contents
  * Mnemonics qualified with '.i' indicate immediate addressing mode in the assembler
  * Carry is set if a carry is generated in arithmetic operations

Subroutine call and returns are handled by the LXA, JSR and RTS instructions. When a JSR
instruction is issued the upper 3 bits of the PC are placed into a link register and the
lower 8 bits are stored in the accumulator. On entering the subroutine the accumulator
value should be saved and then using the LXA instruction the link register bits can be
moved to the accumulator and saved also. On leaving a subroutine the return address needs
to be retrieved by the reverse of this process. First get the upper return address bits
into the accumulator, then transfer them to the link register using LXA and finally get
the lower return address bits into the accumulator. Executing the RTS will now set the PC
to the 11 bit value made by concatenating link register with accumulator.
