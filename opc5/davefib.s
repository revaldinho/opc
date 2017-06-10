  ORG 0x0000

fib:
  ld.i     r4, r0, results
  ld.i     r5, r0, fibEnd
  ld.i     r6, r0, fibLoop
  ld.i     r10, r0, 1

  ld.i     r1, r0    # r1 = 0
  ld.i     r2, r10   # r2 = 1
fibLoop:
  add.i    r1, r2
  c.ld.i   pc, r5     # r5 = fibEnd
  sto      r1, r4     #  r4 = results
  add.i    r4, r10    # r10 = 1
  add.i    r2, r1
  c.ld.i   pc, r5     # r5 = fibEnd
  sto      r2, r4     # r4 = results
  add.i    r4, r10    # r10 = 1
  ld.i     pc, r6     # r6 = fibLoop

fibEnd:
  halt    r0, r0, 0x999

  ORG 0x100
results:
