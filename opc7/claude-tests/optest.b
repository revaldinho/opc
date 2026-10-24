GET "libhdr"

MANIFEST {
  lo4  = SLCT 4:0:0      // bits 0-3
  mid8 = SLCT 8:4:0      // bits 4-11
  top4 = SLCT 4:12:0     // bits 12-15, top of a 16 bit word
  one1 = SLCT 1:15:0     // bit 15 only
  all3 = SLCT 0:3:0      // len 0: all bits from 3 upwards
  w1x  = SLCT 5:2:1      // bits 2-6 of the second word
}

STATIC { cnt = 10 }

// Print the low 16 bits so OPC6 (16 bit) and 32 bit runs can be compared
LET wx(n) BE writef(" %x4", n)

LET pick(n) = VALOF
{ LET dest = 0
  dest := n=0 -> l0, n=1 -> l1, l2
  GOTO dest
l0: RESULTIS 100
l1: RESULTIS 101
l2: RESULTIS 102
}

LET start() = VALOF
{ LET v = VEC 3
  LET pats = TABLE #xA5C3, #x0000, #xFFFF, #x1234, #x8001
  writef("ikl")
  cnt +:= 7;  wx(cnt)
  cnt +:= -20; wx(cnt)
  cnt +:= 1;  wx(cnt)
  newline()
  writef("goto %n %n %n*n", pick(0), pick(1), pick(2))
  FOR i = 0 TO 4 DO
  { LET p = pats!i
    v!0, v!1 := p, p NEQV #x5A5A
    writef("rd %x4:", p)
    wx(lo4 OF v); wx(mid8 OF v); wx(top4 OF v); wx(one1 OF v)
    wx(all3 OF v); wx(w1x OF v)
    newline()
    writef("wr %x4:", p)
    v!0 := p; lo4  OF v := #x9;  wx(v!0)
    v!0 := p; mid8 OF v := #x3C; wx(v!0)
    v!0 := p; top4 OF v := #x6;  wx(v!0)
    v!0 := p; one1 OF v := 1;    wx(v!0)
    v!0 := p; one1 OF v := 0;    wx(v!0)
    v!0 := p; all3 OF v := #x2D; wx(v!0)
    v!0 := p; mid8 OF v := #x1FF; wx(v!0)   // value wider than the field
    v!1 := p; w1x  OF v := #x15; wx(v!1)
    newline()
  }
  RESULTIS 0
}
