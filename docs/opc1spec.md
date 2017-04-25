OPC1 Definition
---------------

OPC1 is a minimal implementation of a One Page Computer designed to fit inside a single Xilinx XC9572 CPLD.

The OPC1 is an accumulator based computer with an 8 bit datapath and a 12 bit address space.
The computer supports 2 addressing modes:

   * immediate/implied - where the operand byte holds an 8 immediate data value or is ignored
   * direct - where a combination of opcode and operand byte provides a 12 bit data address

The OPC has just one flag register: the carry (C) flag. Branching instructions dependent
on the state of this flag and the state of the accumulator are available.

All instructions are encoded in a fixed two byte format consisting of an opcode byte and an operand byte.

The state of the MSB determines which addressing mode will be used for each instruction::

    byte 0       byte 1
    ____________   ________
    0  bbb  oooo   oooooooo
     \   \    \________\______  12 bit Operand
      \   \___________________   3 bit opcode
       \______________________   1 bit 0

    1  bbb  xxxx   oooooooo
     \   \     \     \_____   8 bit Operand
      \   \     \__________   4 bit unused
       \   \_______________   3 bit opcode
        \__________________   1 bit 1


Instruction Set Definition
--------------------------

+----------+--------+------------------+--------+------------------------------------+-------+
|          |    Immediate Mode         |     Direct Mode                             | Flag  |
+----------+--------+------------------+--------+------------------------------------+-------+
| Mnemonic | Opcode | Function         | Opcode | Function                           | C     |
+----------+--------+------------------+--------+------------------------------------+-------+
| AND[.i]  | 1.000  | A <- A & operand | 0.000  | A <- A & (operand)                 | 0     |
+----------+--------+------------------+--------+------------------------------------+-------+
| LDA[.i]  | 1.001  | A <- operand     | 0.001  | A <- (operand)                     | -     |
+----------+--------+------------------+--------+------------------------------------+-------+
| NOT[.I]  | 1.010  | A <- ~operand    | 0.010  | A <- ~(operand)                    | -     |
+----------+--------+------------------+--------+------------------------------------+-------+
| ADD[.i]  | 1.011  | A <- A+operand+C | 0.011  | A <- A+(operand)+C                 | arith |
+----------+--------+------------------+--------+------------------------------------+-------+
| STA      |  -     |     -            | 1.100  | (operand) <- A                     | -     |
+----------+--------+------------------+--------+------------------------------------+-------+
| JPC      |  -     |     -            | 1.101  | PC <-operand if C==1 else PC+2     | -     |
+----------+--------+------------------+--------+------------------------------------+-------+
| JPZ      |  -     |     -            | 1.110  | PC <-operand if (ACC==0) else PC+2 | -     |
+----------+--------+------------------+--------+------------------------------------+-------+
| JP       |  -     |     -            | 1.111  | PC <- operand                      | -     |
+----------+--------+------------------+--------+------------------------------------+-------+
| HALT     | 0.111  | Halt simulation  |  -     | -                                  | -     |
+----------+--------+------------------+--------+------------------------------------+-------+

Notes

  * (operand) indicates contents of memory at address 'operand'
  * PC is incremented by 2 bytes after each instruction unless explicitly indicated
  * Flag operations shown as '-' preserve flag contents
  * Mnemonics qualified with '.i' indicate immediate addressing mode in the assembler
  * Carry is set if a carry is generated in arithmetic operations
