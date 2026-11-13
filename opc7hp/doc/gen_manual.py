#!/usr/bin/env python3
'''
gen_manual.py - build the OPC7HP manual, opc7hp_manual.html

  gen_manual.py [out.html]

Chapter 1 (the programmer's summary) comes from manual_ch1.html; chapter 2, one page per instruction
in alphabetical order, in the style of Rodnay Zaks's Programming the Z80, comes from the INSTR table below. Every example is
assembled with ../../opc7/opc7asm.py and its encoded word is put on the page, so the encodings can't
drift from the assembler: the build stops if an example doesn't assemble.
'''
import os, sys, re, subprocess, tempfile, html

HERE = os.path.dirname(os.path.abspath(__file__))
ASM = os.path.join(HERE, '..', '..', 'opc7', 'opc7asm.py')

ALL = 'V SWI EI S C Z'.split()
# timing text by class: (opc7cpu, opc7hpcpu)
EARLY = ('a source register used with a non-zero immediate', )
T = {
 'alu': ('2 (EAD, EXEC); 3 after a store, a jump or a skipped instruction, which need a separate fetch. 1 if the predicate fails.',
         '1. The result reaches the next instruction\'s ALU operands without a wait. An instruction that needs it earlier, as an address, store data, a jump target, a bperm source or a source with a non-zero immediate, waits up to 2 cycles. This instruction\'s own source is needed early in the same way when its immediate is not zero.'),
 'cmp': ('2 (EAD, EXEC); 3 after a store, a jump or a skipped instruction. 1 if the predicate fails.',
         '1. The flags are ready for a predicated instruction straight after it. Its source is needed early when the immediate is not zero.'),
 'load': ('3 (EAD, RDM, EXEC); 4 after a store, a jump or a skipped instruction. 1 if the predicate fails.',
          '1, with memory that answers at once. Its address register is needed early: up to 2 cycles\' wait if one of the two instructions before wrote it. The value read reaches the next instruction\'s ALU operands without a wait, and an address 2 cycles later. Each cycle the port\'s wait input is high adds one.'),
 'store': ('2 (EAD, WRM), and the next instruction then needs a separate fetch. 1 if the predicate fails.',
           '1. Its address and its data register are both needed early: up to 2 cycles\' wait if one of the two instructions before wrote them. It waits while a jump or anything else that could change the flow is ahead of it in the pipeline, so that it never acts and is then cancelled.'),
 'jump': ('2, and the target then needs a separate fetch. 1 if the predicate fails.',
          '2 when unpredicated: it redirects the fetch as it leaves EA, losing one cycle. Its source is needed early. A predicated one with an immediate or pc-relative backward target is predicted taken: 2 if it is, 4 if not. Any other taken jump of this kind costs 4.'),
 'xjump': ('2 or 3, and the target then needs a separate fetch. 1 if the predicate fails.',
           '4 when the jump is taken: it is decided in EX, and the three instructions behind it are cancelled.'),
 'psr': ('2 (EAD, EXEC); 3 after a store, a jump or a skipped instruction. 1 if the predicate fails.',
         '1. Stores, in and out behind it wait until it completes, since it can raise a software interrupt. A software interrupt costs as a taken jump.'),
}

def F(*setflags, note=''):
    return (set(setflags), note)

# Each instruction: mnemonic, name, opcode, format ('std'/'long'), function, description paragraphs,
# data path rows, flags, timing class, examples [(asm, effect)], see also.
INSTR = [
 dict(mn='MOV', name='Move', op=0x00, fmt='std', fn='dst &larr; src + imm16',
  desc=['The source register plus the sign-extended immediate replaces the destination register.',
        'With <code>r0</code> as the source this loads a constant from &minus;32768 to 32767. Use <code>movt</code> after it for the top half of a 32-bit constant, or <code>lmov</code> for 20 bits.',
        'With <code>r15</code> as the destination it is a jump: to an absolute address with <code>r0</code> as the source, relative to the next instruction with <code>r15</code>, or through a register, as in <code>mov pc, r13</code> to return from a subroutine.'],
  dp=[['src', '+ imm16', 'dst']], flags=F('S', 'Z'), t='alu',
  ex=[('mov r1, r0, 100', 'r1 &larr; 100'), ('mov r2, r3', 'r2 &larr; r3'), ('mov r4, r5, -1', 'r4 &larr; r5 &minus; 1'),
      ('mov pc, r13', 'return through the link in r13'), ('nz.mov pc, pc, -3', 'if Z is clear, jump back 2 instructions')]),
 dict(mn='MOVT', name='Move top', op=0x01, fmt='std', fn='dst &larr; {(src + imm16)[15:0], dst[15:0]}',
  desc=['The low 16 bits of the source plus the immediate replace the top half of the destination register. Its bottom half is unchanged.',
        'After a <code>mov</code> of the low half, this completes a 32-bit constant.'],
  dp=[['src', '+ imm16', 'low 16 bits', 'top of dst']], flags=F('S', 'Z'), t='alu',
  ex=[('mov r1, r0, 0x5678', 'r1 &larr; 0x00005678'), ('movt r1, r0, 0x1234', 'r1 &larr; 0x12345678'), ('movt r2, r0', 'clear the top half of r2')]),
 dict(mn='XOR', name='Exclusive or', op=0x02, fmt='std', fn='dst &larr; dst ^ (src + imm16)',
  desc=['The destination register is exclusive-ored with the source plus the immediate.'],
  dp=[['src', '+ imm16', 'dst ^ EAD', 'dst']], flags=F('S', 'Z'), t='alu',
  ex=[('xor r1, r2', 'r1 &larr; r1 ^ r2'), ('xor r3, r0, -1', 'invert every bit of r3'), ('xor r4, r4', 'r4 &larr; 0, Z set')]),
 dict(mn='AND', name='And', op=0x03, fmt='std', fn='dst &larr; dst &amp; (src + imm16)',
  desc=['The destination register is anded with the source plus the immediate.',
        'As the immediate is sign extended, a mask of 0x8000 or more in it also sets the top 16 bits. Masks such as 0xFF and 0x7FFF are fine.'],
  dp=[['src', '+ imm16', 'dst &amp; EAD', 'dst']], flags=F('S', 'Z'), t='alu',
  ex=[('and r1, r0, 0xFF', 'keep the low byte of r1'), ('and r2, r3', 'r2 &larr; r2 &amp; r3'), ('and r4, r0, 1', 'Z set if r4 is even')]),
 dict(mn='OR', name='Or', op=0x04, fmt='std', fn='dst &larr; dst | (src + imm16)',
  desc=['The destination register is ored with the source plus the immediate.'],
  dp=[['src', '+ imm16', 'dst | EAD', 'dst']], flags=F('S', 'Z'), t='alu',
  ex=[('or r1, r2', 'r1 &larr; r1 | r2'), ('or r3, r0, 0x80', 'set bit 7 of r3'), ('or r4, r0', 'test r4: S and Z from its value')]),
 dict(mn='NOT', name='Not', op=0x05, fmt='std', fn='dst &larr; ~(src + imm16)',
  desc=['The ones complement of the source plus the immediate replaces the destination register.',
        'With an immediate of &minus;1 this is negation, since &minus;x = ~(x &minus; 1).'],
  dp=[['src', '+ imm16', '~EAD', 'dst']], flags=F('S', 'Z'), t='alu',
  ex=[('not r1, r2', 'r1 &larr; ~r2'), ('not r3, r3, -1', 'r3 &larr; &minus;r3'), ('not r4, r0', 'r4 &larr; 0xFFFFFFFF')]),
 dict(mn='CMP', name='Compare', op=0x06, fmt='std', fn='dst &minus; (src + imm16), result discarded',
  desc=['The source plus the immediate is subtracted from the destination register, as <code>sub</code> does, but only the flags keep the result.',
        'Z is set if the two are equal. C is set if the destination is greater than or equal to the operand as unsigned numbers, since the subtraction is done as dst + ~operand + 1. For signed comparisons, use <code>scmp</code>.',
        'With <code>r15</code> as the destination it compares the next instruction\'s address and doesn\'t jump.'],
  dp=[['src', '+ imm16', 'dst &minus; EAD', 'flags only']], flags=F('V', 'S', 'C', 'Z'), t='cmp',
  ex=[('cmp r1, r2', 'compare r1 with r2'), ('cmp r1, r0, 10', 'compare r1 with 10'), ('z.mov r3, r0, 1', 'after it: r3 &larr; 1 if they were equal'),
      ('nc.mov pc, r0, 0x200', 'after it: jump if r1 &lt; 10, unsigned')]),
 dict(mn='SUB', name='Subtract', op=0x07, fmt='std', fn='{C, dst} &larr; dst + ~(src + imm16) + 1',
  desc=['The source plus the immediate is subtracted from the destination register.',
        'C is set when there is no borrow, that is when the destination was greater than or equal to the operand as unsigned numbers. V is set on signed overflow.'],
  dp=[['src', '+ imm16', 'dst &minus; EAD', 'dst']], flags=F('V', 'S', 'C', 'Z'), t='alu',
  ex=[('sub r1, r2', 'r1 &larr; r1 &minus; r2'), ('sub r3, r0, 1', 'r3 &larr; r3 &minus; 1, Z set at zero'), ('sub r4, r4', 'r4 &larr; 0, C set')]),
 dict(mn='ADD', name='Add', op=0x08, fmt='std', fn='{C, dst} &larr; dst + (src + imm16)',
  desc=['The source register and the sign-extended immediate are added to form the operand. The operand is then added to the destination register, and the 32-bit sum replaces it.',
        'C is the carry out of bit 31 and V is set on signed overflow. <code>add rd, rd</code> shifts left one place.'],
  dp=[['src', '+ imm16', 'dst + EAD', 'dst']], flags=F('V', 'S', 'C', 'Z'), t='alu',
  ex=[('add r1, r2, 0x10', 'r1 &larr; r1 + r2 + 16'), ('add r4, r4', 'r4 &larr; 2 &times; r4; C holds the bit shifted out'),
      ('nz.add r3, r0, -1', 'if Z is clear, r3 &larr; r3 &minus; 1'), ('add pc, r0, 3', 'skip the next 3 instructions; flags kept')]),
 dict(mn='BPERM', name='Byte permute', op=0x09, fmt='std', fn='dst &larr; bytes of src, chosen by imm16',
  desc=['Each byte of the result comes from the source register as directed by a 4-bit field of the immediate. The fields are in byte order, so the leftmost hex digit controls byte 3, the top byte.',
        'In each field, bits 1 and 0 pick a byte of the source and bit 2 makes the result byte zero instead. Unlike other instructions, the immediate isn\'t added to the source.'],
  dp=[['src', 'permute by imm16', 'dst']], flags=F('S', 'Z'), t='alu',
  ex=[('bperm r1, r2, 0x3210', 'r1 &larr; r2 unchanged'), ('bperm r1, r2, 0x0123', 'reverse the bytes'), ('bperm r1, r2, 0x0321', 'rotate right by a byte'),
      ('bperm r1, r2, 0x4441', 'byte 1 of r2 to byte 0, the rest zero'), ('bperm r1, r2, 0x0000', 'byte 0 copied to all four')]),
 dict(mn='ROR', name='Rotate right through carry', op=0x0A, fmt='std', fn='{dst, C} &larr; {C, src + imm16}',
  desc=['The source plus the immediate is shifted right one place. C goes into bit 31, and bit 0 goes into C.',
        'A chain of <code>ror</code> instructions shifts a multi-word value right.'],
  dp=[['src', '+ imm16', 'C &rarr; ... &rarr; C', 'dst']], flags=F('S', 'C', 'Z'), t='alu',
  ex=[('ror r1, r1', 'rotate r1 right through C'), ('ror r2, r3', 'r2 &larr; r3 rotated right through C')]),
 dict(mn='LSR', name='Logical shift right', op=0x0B, fmt='std', fn='{dst, C} &larr; {0, src + imm16}',
  desc=['The source plus the immediate is shifted right one place. Zero goes into bit 31, and bit 0 goes into C.'],
  dp=[['src', '+ imm16', '0 &rarr; ... &rarr; C', 'dst']], flags=F('S', 'C', 'Z'), t='alu',
  ex=[('lsr r1, r1', 'r1 &larr; r1 / 2, unsigned'), ('lsr r2, r3', 'r2 &larr; r3 / 2, unsigned; C holds the remainder')]),
 dict(mn='JSR', name='Jump to subroutine', op=0x0C, fmt='std', fn='dst &larr; next pc; pc &larr; src + imm16',
  desc=['The address of the next instruction is saved in the destination register, the link, and execution continues at the source plus the immediate.',
        'Return with <code>mov pc, rlink</code>. BCPL code uses r13 as the link. With <code>r0</code> as the destination it is a plain jump.'],
  dp=[['next pc', 'dst (link)'], ['src', '+ imm16', 'pc']], flags=F('S', 'Z', note='of the link'), t='jump',
  ex=[('jsr r13, r0, 0x1234', 'call the routine at 0x1234'), ('jsr r13, r4', 'call through r4'), ('mov pc, r13', 'and return')]),
 dict(mn='ASR', name='Arithmetic shift right', op=0x0D, fmt='std', fn='{dst, C} &larr; {(src + imm16)[31], src + imm16}',
  desc=['The source plus the immediate is shifted right one place. Bit 31 keeps its value, so the sign is kept, and bit 0 goes into C.',
        'This divides a signed number by two, rounding towards minus infinity.'],
  dp=[['src', '+ imm16', 'b31 &rarr; ... &rarr; C', 'dst']], flags=F('S', 'C', 'Z'), t='alu',
  ex=[('asr r1, r1', 'r1 &larr; r1 / 2, signed'), ('asr r2, r3', 'r2 &larr; r3 / 2, signed')]),
 dict(mn='ROL', name='Rotate left through carry', op=0x0E, fmt='std', fn='{C, dst} &larr; {src + imm16, C}',
  desc=['The source plus the immediate is shifted left one place. C goes into bit 0, and bit 31 goes into C.',
        'A chain of <code>rol</code> instructions shifts a multi-word value left.'],
  dp=[['src', '+ imm16', 'C &larr; ... &larr; C', 'dst']], flags=F('S', 'C', 'Z'), t='alu',
  ex=[('rol r1, r1', 'rotate r1 left through C'), ('rol r2, r3', 'r2 &larr; r3 rotated left through C')]),
 dict(mn='MULSTEP', name='Multiply step', op=0x0F, fmt='std', fn='dst &larr; {dst[30:0], 0} + (C ? src + imm16 : 0)',
  desc=['One bit of a shift-and-add multiply. The destination is shifted left one place, and if C is set the source plus the immediate is added to it. C and V are left alone, so the next multiplier bit can come in through C.',
        'A product (the low 32 bits, the same for signed and unsigned operands) is formed from the top of the multiplier down: clear the product, then for each multiplier bit shift it into C with <code>add m, m</code> and do <code>mulstep p, b</code>. Skipping the multiplier\'s leading zero bytes first makes small multipliers quick.'],
  dp=[['src', '+ imm16', 'dst&times;2 + (C ? EAD : 0)', 'dst']], flags=F('S', 'Z'), t='alu',
  ex=[('add r3, r3', 'next multiplier bit (top first) to C'), ('mulstep r1, r2', 'r1 &larr; 2 &times; r1 + (C ? r2 : 0)'),
      ('mulstep r1, r0, 10', 'r1 &larr; 2 &times; r1 + (C ? 10 : 0)')]),
 dict(mn='HALT', name='Halt', op=0x10, fmt='std', fn='stop',
  desc=['Ends a program. The emulators and testbenches stop and report the immediate as the halt number.',
        'On opc7hpcpu the instruction raises the <code>hlt</code> output as it completes, and the system around it stops the CPU there. The CPU itself carries on.'],
  dp=[['halt', 'hlt output']], flags=F(note='n/a'), t='alu', tnote='The CPU is stopped by the system as halt completes.',
  ex=[('halt r0, r0, 0x99', 'stop, halt number 0x99')]),
 dict(mn='RTI', name='Return from interrupt', op=0x11, fmt='std', fn='pc &larr; saved pc; flags &larr; saved flags',
  desc=['Returns from an interrupt handler to the instruction where the interrupt was taken, and restores the flags saved then: V, EI, S, C and Z. The SWI bits are cleared.',
        'Written <code>rti pc, pc</code>. Since EI is restored, interrupts are enabled again if they were enabled before.'],
  dp=[['saved pc', 'pc'], ['saved flags', 'PSR']], flags=F(*ALL, note='restored'), t='xjump',
  ex=[('rti pc, pc', 'return from the handler')]),
 dict(mn='PUTPSR', name='Put processor status register', op=0x12, fmt='std', fn='PSR &larr; src + imm16',
  desc=['The source plus the immediate replaces the PSR: V from bit 31, SWI from bits 7 to 4, then EI, S, C and Z from bits 3 to 0.',
        'A non-zero SWI value raises a software interrupt as the instruction completes. It enters the handler at 0x0002 with the return address of the next instruction. Setting EI enables hardware interrupts.'],
  dp=[['src', '+ imm16', 'PSR']], flags=F(*ALL, note='all from the operand'), t='psr',
  ex=[('putpsr psr, r0, 0x08', 'enable interrupts, clear the flags'), ('putpsr psr, r1', 'PSR &larr; r1'), ('putpsr psr, r0, 0x18', 'software interrupt 1, interrupts enabled')]),
 dict(mn='GETPSR', name='Get processor status register', op=0x13, fmt='std', fn='dst &larr; PSR',
  desc=['The PSR is copied to the destination register. The immediate is ignored.',
        'V is in bit 31 of the copy, so the S flag that the copy sets equals V. That makes <code>getpsr</code> then <code>mi.</code> or <code>pl.</code> a test for overflow.'],
  dp=[['PSR', 'dst']], flags=F('S', 'Z', note='S = V'), t='alu',
  ex=[('getpsr r1, psr', 'r1 &larr; PSR'), ('getpsr r0, psr', 'only set S from V'), ('mi.mov pc, r0, 0x300', 'after it: jump if V was set')]),
 dict(mn='SCMP', name='Signed compare', op=0x16, fmt='std', fn='dst &minus; (src + imm16), with S = signed less-than',
  desc=['Compares as <code>cmp</code> does, but sets S to the sign of the result exclusive-ored with V. S is then set exactly when the destination is less than the operand as signed numbers, even when the subtraction overflows.',
        'So <code>mi.</code> after <code>scmp</code> means signed less-than, and <code>pl.</code> means signed greater-than-or-equal. V, C and Z are set as for <code>cmp</code>.'],
  dp=[['src', '+ imm16', 'dst &minus; EAD', 'flags only']], flags=F('V', 'S', 'C', 'Z', note='S = sign ^ V'), t='cmp',
  ex=[('scmp r1, r2', 'compare r1 with r2, signed'), ('mi.mov pc, r0, 0x400', 'after it: jump if r1 &lt; r2, signed'), ('scmp r1, r0, -5', 'compare r1 with &minus;5, signed')]),
 dict(mn='DIVSTEP', name='Divide step', op=0x17, fmt='std', fn='t = {dst, C}; {C, dst} &larr; t &ge; EAD ? {1, t &minus; EAD} : {0, t[31:0]}',
  desc=['One bit of a shift-and-subtract (restoring) divide. The destination, a partial remainder, is shifted left one place with C coming in at the bottom, giving a 33-bit value. If that is at least the source plus the immediate (unsigned), the operand is subtracted and C is set; otherwise it is kept and C is cleared. C is then the next quotient bit.',
        'An unsigned 32-bit divide: clear the remainder and C, then 32 times <code>rol n, n</code> (the quotient bit from C in at the bottom of n, the next dividend bit out of its top into C) and <code>divstep r, d</code>, and a last <code>rol n, n</code>. n then holds the quotient and r the remainder. The comparison is of 33 bits, so the same steps also continue a division of a longer dividend.'],
  dp=[['src', '+ imm16', '{dst, C} &minus; EAD if &ge;', 'dst']], flags=F('S', 'C', 'Z', note='C = the quotient bit'), t='alu',
  ex=[('rol r1, r1', 'quotient bit in, next dividend bit out to C'), ('divstep r3, r2', 'r3 &larr; 2 &times; r3 + C, less r2 if that is &ge; r2; C &larr; the quotient bit'),
      ('divstep r3, r0, 10', 'one bit of a divide by 10')]),
 dict(mn='OUT', name='Output', op=0x18, fmt='std', fn='io[src + imm16] &larr; dst',
  desc=['The destination register is written to the I/O port at the source plus the immediate. The I/O space is separate from memory: the CPU signals the access with <code>vio</code> rather than <code>vda</code>, and the port address is 16 bits.',
        'Any 16-bit constant is a valid port number here. The flags are unchanged.'],
  dp=[['src', '+ imm16', 'port'], ['dst', 'I/O data']], flags=F(note='unchanged'), t='store',
  ex=[('out r1, r0, 0x01', 'write r1 to port 1 (the system UART\'s data)'), ('out r2, r3, 0x10', 'write r2 to port r3 + 16')]),
 dict(mn='IN', name='Input', op=0x19, fmt='std', fn='dst &larr; io[src + imm16]',
  desc=['The I/O port at the source plus the immediate is read into the destination register, which sets S and Z. The access uses <code>vio</code>, and the port address is 16 bits.',
        'In the emulators, every <code>in</code> reads the next character of standard input, whatever the port.'],
  dp=[['src', '+ imm16', 'port'], ['I/O data', 'dst']], flags=F('S', 'Z'), t='load',
  ex=[('in r1, r0, 0x00', 'read port 0 (the system UART\'s status)'), ('in r2, r0, 0x10', 'read the GPIO input pins')]),
 dict(mn='STO', name='Store', op=0x1A, fmt='std', fn='mem[src + imm16] &larr; dst',
  desc=['The destination register is written to memory at the source plus the immediate, a word address of which the low 20 bits are used. The flags are unchanged.',
        'Note that the register written to memory is the one in the destination field.'],
  dp=[['src', '+ imm16', 'address'], ['dst', 'memory']], flags=F(note='unchanged'), t='store',
  ex=[('sto r1, r2', 'mem[r2] &larr; r1'), ('sto r1, r11, 3', 'mem[r11 + 3] &larr; r1'), ('sto r0, r0, 0x200', 'mem[0x200] &larr; 0')]),
 dict(mn='LD', name='Load', op=0x1B, fmt='std', fn='dst &larr; mem[src + imm16]',
  desc=['The source register and the sign-extended immediate are added to form a word address. Its low 20 bits select one of the 1M words of memory, and that word replaces the destination register.',
        'With <code>r0</code> as the source the immediate is an absolute address in the first 32K words, and <code>lld</code> reaches all 1M. A destination of <code>r15</code> jumps to the loaded address, as through a jump table.'],
  dp=[['src', '+ imm16', 'address'], ['memory', 'dst']], flags=F('S', 'Z'), t='load',
  ex=[('ld r1, r2, 4', 'r1 &larr; the word 4 after r2'), ('ld r5, r11, -2', 'r5 &larr; the word 2 before r11'), ('mi.ld r6, r12, 94', 'if S is set, r6 &larr; mem[r12 + 94]'),
      ('ld pc, r0, 0x200', 'jump to the address held at 0x200')]),
 dict(mn='LJSR', name='Long jump to subroutine', op=0x1C, fmt='long', fn='dst &larr; next pc; pc &larr; imm20',
  desc=['As <code>jsr</code>, with the target a 20-bit address in the instruction, so it reaches the whole address space.'],
  dp=[['next pc', 'dst (link)'], ['imm20', 'pc']], flags=F('S', 'Z', note='of the link'), t='jump',
  ex=[('ljsr r13, 0x1000', 'call the routine at 0x01000')]),
 dict(mn='LMOV', name='Long move', op=0x1D, fmt='long', fn='dst &larr; imm20',
  desc=['The sign-extended 20-bit immediate replaces the destination register, giving constants from &minus;524288 to 524287 in one instruction.',
        'With <code>r15</code> as the destination it is a jump to any address.'],
  dp=[['imm20', 'dst']], flags=F('S', 'Z'), t='alu',
  ex=[('lmov r1, 0x12345', 'r1 &larr; 0x12345'), ('lmov r2, -100000', 'r2 &larr; &minus;100000'), ('lmov pc, 0x1000', 'jump to 0x01000')]),
 dict(mn='LSTO', name='Long store', op=0x1E, fmt='long', fn='mem[imm20] &larr; dst',
  desc=['The destination register is written to the 20-bit address in the instruction. The flags are unchanged.'],
  dp=[['imm20', 'address'], ['dst', 'memory']], flags=F(note='unchanged'), t='store',
  ex=[('lsto r1, 0x12345', 'mem[0x12345] &larr; r1')]),
 dict(mn='LLD', name='Long load', op=0x1F, fmt='long', fn='dst &larr; mem[imm20]',
  desc=['The word at the 20-bit address in the instruction replaces the destination register.'],
  dp=[['imm20', 'address'], ['memory', 'dst']], flags=F('S', 'Z'), t='load',
  ex=[('lld r1, 0x12345', 'r1 &larr; mem[0x12345]'), ('lld pc, 0x00010', 'jump to the address held at 0x10')]),
]

def assemble(lines):
    '''the 32-bit words opc7asm.py gives for these lines, in order'''
    with tempfile.TemporaryDirectory() as d:
        s, h = os.path.join(d, 'x.s'), os.path.join(d, 'x.hex')
        open(s, 'w').write(''.join('        %s\n' % l for l in lines))
        out = subprocess.run([sys.executable, ASM, '-g', 'sparse', s, h], capture_output=True, text=True).stdout
        if ' 0 errors' not in out:
            sys.exit('gen_manual.py: examples do not assemble:\n' + out)
        words = [w for w in open(h).read().split() if not w.startswith('@')]
    return ['%08X' % int(w, 16) for w in words[:len(lines)]]

def word_html(op, fmt):
    bits = format(op, '05b')
    cells = [('31', '29', 'p p p', 'pred', ''), ('28', '24', ' '.join(bits), 'opcode', ' op'), ('23', '20', 'd d d d', 'dst', '')]
    if fmt == 'std':
        cells += [('19', '16', 's s s s', 'src', ''), ('15', '0', 'i ' * 15 + 'i', 'imm16, sign extended', '')]
    else:
        cells += [('19', '0', 'i ' * 19 + 'i', 'imm20, sign extended', '')]
    cols = '3fr 5fr 4fr 4fr 16fr' if fmt == 'std' else '3fr 5fr 4fr 20fr'
    inner = ''.join('<div class="%s"><span class="bits"><span>%s</span><span>%s</span></span><span class="val">%s</span><span class="f">%s</span></div>'
                    % (c[4].strip(), c[0], c[1], c[2], c[3]) for c in cells)
    return '<div class="wordbox"><div class="word" style="grid-template-columns:%s">%s</div></div>' % (cols, inner)

def datapath(rows, flags):
    '''a box-and-arrow chain per row; the flags set, if any, beside the first row'''
    bw, gap, bh, rh = 116, 34, 34, 54
    width = max(len(r) for r in rows) * (bw + gap) - gap + 20
    fl = ' '.join(f for f in ALL if f in flags[0])
    if fl: width += 120
    height = len(rows) * rh + 6
    out = ['<svg class="dp" viewBox="0 0 %d %d" role="img" aria-label="%s">' % (width, height, html.escape('; '.join(' to '.join(re.sub('&[a-z]+;', ' ', b) for b in r) for r in rows)))]
    for ri, row in enumerate(rows):
        y = 6 + ri * rh
        for bi, b in enumerate(row):
            x = 10 + bi * (bw + gap)
            last = bi == len(row) - 1
            out.append('<rect class="%s" x="%d" y="%d" width="%d" height="%d"/>' % ('boxa' if 0 < bi < len(row) - 1 else 'box', x, y, bw, bh))
            out.append('<text x="%d" y="%d" text-anchor="middle">%s</text>' % (x + bw // 2, y + 22, b))
            if not last:
                out.append('<path class="w" d="M%d %d H%d"/><polygon class="ah" points="%d,%d %d,%d %d,%d"/>'
                           % (x + bw, y + bh // 2, x + bw + gap - 9, x + bw + gap - 10, y + bh // 2 - 5, x + bw + gap, y + bh // 2, x + bw + gap - 10, y + bh // 2 + 5))
        if ri == 0 and fl:
            x = 10 + len(row) * (bw + gap) - gap
            out.append('<path class="wf" d="M%d %d H%d"/><polygon class="ahf" points="%d,%d %d,%d %d,%d"/><text class="f" x="%d" y="%d">%s</text>'
                       % (x, y + bh // 2, x + 26, x + 26, y + bh // 2 - 5, x + 36, y + bh // 2, x + 26, y + bh // 2 + 5, x + 42, y + bh // 2 + 4, fl))
    out.append('</svg>')
    return ''.join(out)

def flags_html(flags):
    st, note = flags
    cells = ''.join('<div><span class="n">%s</span><span class="s%s">%s</span></div>' % (f, ' set' if f in st else '', '&bull;' if f in st else '&ndash;') for f in ALL)
    return '<div class="flags">%s</div><p class="key">%s</p>' % (cells, ('&bull; set; &ndash; unchanged. ' if st else '') + (note[0].upper() + note[1:] + '.' if note else ''))

def page(i, words):
    pid = i['mn'].lower()
    fmt_note = ('<p class="alt">Assembler: <code>[pred.]%s dst, src[, imm]</code>; the immediate defaults to 0. One word.</p>' % i['mn'].lower()
                if i['fmt'] == 'std' else '<p class="alt">Assembler: <code>[pred.]%s dst, imm20</code>. Long format: no source field. One word.</p>' % i['mn'].lower())
    if i['mn'] in ('RTI', 'HALT', 'PUTPSR', 'GETPSR'):
        fmt_note = '<p class="alt">Assembler: <code>%s</code>. One word.</p>' % {'RTI': 'rti pc, pc', 'HALT': 'halt r0, r0, number', 'PUTPSR': '[pred.]putpsr psr, src[, imm]', 'GETPSR': '[pred.]getpsr dst, psr'}[i['mn']]
    cpu, hp = T[i['t']]
    if i.get('tnote'): cpu, hp = 'n/a', i['tnote']
    exrows = ''.join('<tr><td class="mono">%s</td><td class="mono">%s</td><td>%s</td></tr>' % (html.escape(a), w, e) for (a, e), w in zip(i['ex'], words))
    return '''<article class="page" id="%s">
  <div class="head"><div class="mn">%s</div><div class="name">%s<b>opcode 0x%02X</b></div></div>
  <div class="row"><div class="lab">Function</div><div class="fn">%s</div></div>
  <div class="row"><div class="lab">Format</div><div>%s%s</div></div>
  <div class="row"><div class="lab">Description</div><div>%s</div></div>
  <div class="row"><div class="lab">Data paths</div><div>%s</div></div>
  <div class="row"><div class="lab">Flags</div><div>%s</div></div>
  <div class="row"><div class="lab">Timing</div><div class="tscroll"><table><thead><tr><th>Processor</th><th>Clock cycles</th></tr></thead><tbody>
    <tr><td>opc7cpu</td><td>%s</td></tr><tr><td>opc7hpcpu</td><td>%s</td></tr></tbody></table></div></div>
  <div class="row"><div class="lab">Examples</div><div class="tscroll"><table><thead><tr><th>Instruction</th><th>Word</th><th>Effect</th></tr></thead><tbody>%s</tbody></table></div></div>
</article>''' % (pid, i['mn'], i['name'], i['op'], i['fn'], word_html(i['op'], i['fmt']), fmt_note,
                 ''.join('<p>%s</p>' % d for d in i['desc']), datapath(i['dp'], i['flags']), flags_html(i['flags']), cpu, hp, exrows)

CSS = open(os.path.join(HERE, 'manual.css')).read()

def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'opc7hp_manual.html')
    order = sorted(INSTR, key=lambda i: i['mn'])     # alphabetical, as in the Zaks books
    allex = [a for i in order for a, e in i['ex']]
    words = assemble(allex)
    pages, k = [], 0
    for i in order:
        n = len(i['ex']); pages.append(page(i, words[k:k + n])); k += n
    ch1 = open(os.path.join(HERE, 'manual_ch1.html')).read()
    toc = ''.join('<a href="#%s"><b>%s</b><span>%s</span></a>' % (i['mn'].lower(), i['mn'], i['name']) for i in order)
    doc = '''<title>OPC7HP Manual</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Barlow+Condensed:wght@600;700&family=IBM+Plex+Mono:wght@400;500&family=Source+Serif+4:opsz,wght@8..60,400;8..60,600&display=swap">
<style>%s</style>
<!-- generated by gen_manual.py from manual_ch1.html and its instruction table: edit those, not this file -->
<div class="wrap">
<div class="page">
  <div class="cover">
    <div class="k">OPC7HP manual &middot; draft</div>
    <h1>OPC7HP: the Harvard, pipelined OPC7</h1>
    <p>Chapter 1 summarises the machine for programmers. Chapter 2 gives each instruction its own page, after the instruction reference in Rodnay Zaks's <i>Programming the Z80</i>.</p>
  </div>
  <section><h2><span class="n">1</span>Programmer's summary</h2></section>
  %s
</div>
<div class="page">
  <section><h2><span class="n">2</span>Instruction reference</h2>
  <nav class="toc" aria-label="Instructions">%s</nav></section>
</div>
%s
</div>
''' % (CSS, ch1, toc, '\n'.join(pages))
    open(out, 'w').write(doc)
    print('gen_manual.py: %s, %d instruction pages, %d examples assembled' % (out, len(INSTR), len(allex)))

main()
