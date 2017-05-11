OPC3 Definition
---------------

OPC3 is a [One Page Computer](.) which fits into a single Xilinx XC95144 CPLD. This is a direct
and decidedly non-optimal conversion of the original OPC1 into a 16b word based computer.

The OPC3 is an accumulator based computer with both a 16 bit datapath and a 16b address space.

All instructions are encoded in a fixed two word format consisting of an opcode and an operand ::

    bbbbb xxxxxxxxxxx : oooooooo_oooooooo    
     \        \               \________\_ 16 bit operand
      \        \_________________________ 11 bit unused field in opcode word
       \_________________________________  5 bit opcode
       

The computer supports 3 addressing modes:

   * immediate/implied - where the operand word holds an 16 immediate data value or is ignored
   * direct - where the operand word provides a 16 bit data address
   * indirect (pointer) - loads and stores only, where the 16 bit operand is used to get another
     16 bit value from memory which is then used as the effective address.

The OPC has just one flag register: the carry (C) flag. There is a branch on carry and also a
branch on zero.

On reset the CPU starts execution at address 0x0000.

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
| JSR      | 1.1100  | ACC<-PC;PC<- n                | -      | -                            | -     |
| RTS      | 1.1101  | PC<-ACC                       | -      | -                            | -     |
| BSW      | 1.1110  | Swap Acc hi and lo bytes      | -      | -                            | -     |
| HALT     | 1.1111  | Halt simulation               | -      | -                            | -     |

Notes

  * (n) indicates contents of memory at address 'n'
  * ((n)) indicates contents of memory addressed by contents of memory at address 'n'
  * Flag operations shown as '-' preserve flag contents, 'X' invalidate flag contents
  * Mnemonics qualified with '.i' indicate immediate addressing mode in the assembler
  * Mnemonics qualified with '.p' indicate pointer (indirect) addressing mode in the assembler

Subroutine call and returns are handled by the JSR and RTS instructions. When a JSR
instruction is issued the PC current value (address of next instruction) is saved in
the accumulator. On entering the subroutine the accumulator value should be saved. On
leaving a subroutine the return address needs to be retrieved by the reverse of this process.
Executing the RTS will now set the PC to return execution to the instruction following the
original subroutine call.

Unlike the original OPC1 there is no longer a requirement for a partial LINK register. The LXA instruction
has therefore been deleted and replaced with BSW, which swaps over upper and lower bytes in the accumulator,
to make a small attempt at handling byte oriented data without significant alteration of the machine.
