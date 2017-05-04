OPC1 Definition
---------------

OPC1 is a minimal implementation of a [One Page Computer](.) which fits into a single Xilinx XC9572 CPLD.

The OPC1 is an accumulator based computer with an 8 bit datapath and a 11 bit address space.
The computer supports 3 addressing modes:

   * immediate/implied - where the operand byte holds an 8 immediate data value or is ignored
   * direct - where a combination of opcode and operand byte provides a 11 bit data address
   * indirect (pointer) - loads and stores only, where the 11 bit operand is used to get an
     8 bit value from memory which is subsequently used as the address to/from which
     to store/read data.

The OPC has just one flag register: the carry (C) flag. Branching instructions dependent on the
state of this flag and the state of the accumulator are available.

All instructions are encoded in a fixed two byte format consisting of an opcode and an operand ::

    bbbbb  ooo : oooooooo
     \       \        \_______   8 bit operand for Immediate/Implied Instructions, or
      \       \________\______  11 bit operand for Direct/Indirect Instructions
       \______________________   5 bit opcode

On reset the CPU starts execution at address 0x100 to leave page zero free for variables which can
be accessed by the 8 bit pointers.

Instructions

| Mnemonic | Opcode  | Function (Imm. Mode)          | Opcode | Function (Direct or Ind.Mode)| Carry |
|----------|---------|-------------------------------|--------|------------------------------|-------|
| AND[.i]  | 1.0000  | A <- A & n                    | 0.0000 | A <- A & (n)                 | 0     |
| LDA[.i]  | 1.0001  | A <- n                        | 0.0001 | A <- (n)                     | -     |
| NOT[.i]  | 1.0010  | A <- ~n                       | 0.0010 | A <- ~(n)                    | -     |
| ADD[.i]  | 1.0011  | A <- A+n+C                    | 0.0011 | A <- A+(n)+C                 | arith |
| LDA.p    | -       | -                             | 0.1001 | A <- ((n))                   | -     |
| STA[.p]  | 1.1000  | (n) <- A                      | 0.1000 | ((n)) <- A                   | -     |
| JPC      | 1.1001  | PC <-n if C else PC+2         | -      | -                            | -     |
| JPZ      | 1.1010  | PC <-n if (ACC==0) else PC+2  | -      | -                            | -     |
| JP       | 1.1011  | PC <- n                       | -      | -                            | -     |
| JSR      | 1.1100  | LINK<-PC;PC<- n               | -      | -                            | X     |
| RTS      | 1.1101  | PC<-LINK                      | -      | -                            | X     |
| LXA      | 1.1110  | Swap Acc with Link            | -      | -                            | X     |
| HALT     | 1.1111  | Halt simulation               | -      | -                            | -     |

Notes

  * (n) indicates contents of memory at address 'n'
  * ((n)) indicates contents of memory addressed by contents of memory at address 'n'
  * Flag operations shown as '-' preserve flag contents, 'X' invalidate flag contents
  * Mnemonics qualified with '.i' indicate immediate addressing mode in the assembler
  * Mnemonics qualified with '.p' indicate pointer (indirect) addressing mode in the assembler

Subroutine call and returns are handled by the LXA, JSR and RTS instructions. When a JSR
instruction is issued the upper 3 bits of the PC are placed into a link register and the
lower 8 bits are stored in the accumulator. On entering the subroutine the accumulator
value should be saved and then using the LXA instruction the link register bits can be
moved to the accumulator and saved also. On leaving a subroutine the return address needs
to be retrieved by the reverse of this process. First get the upper return address bits
into the accumulator, then transfer them to the link register using LXA and finally get
the lower return address bits into the accumulator. Executing the RTS will now set the PC
to the 11 bit value made by concatenating link register with accumulator.

NB In order to fit in the 9572, the bottom bit of the link register doubles up as the
carry flag, so any instruction altering the link will invalidate the carry and vice versa.
