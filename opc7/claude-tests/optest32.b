GET "libhdr"

MANIFEST {
  hi8   = SLCT 8:24:0     // top byte
  mid16 = SLCT 16:8:0     // 16 bit field: mask needs the large constant register
  b31   = SLCT 1:31:0     // sign bit
  up0   = SLCT 0:20:0     // len 0 from bit 20
  w20   = SLCT 20:0:0     // low 20 bits
}

STATIC { big = 5 }

LET start() = VALOF
{ LET v = VEC 1
  LET pats = TABLE #x89ABCDEF, #x00000000, #xFFFFFFFF, #x7FFF8001
  big +:= 100000;   writef("ikl %x8", big)
  big +:= -300000;  writef(" %x8*n", big)
  FOR i = 0 TO 3 DO
  { LET p = pats!i
    v!0 := p
    writef("rd %x8: %x8 %x8 %x8 %x8 %x8*n", p, hi8 OF v, mid16 OF v, b31 OF v, up0 OF v, w20 OF v)
    writef("wr %x8:", p)
    v!0 := p; hi8   OF v := #x5A;     writef(" %x8", v!0)
    v!0 := p; mid16 OF v := #x1234;   writef(" %x8", v!0)
    v!0 := p; b31   OF v := 1;        writef(" %x8", v!0)
    v!0 := p; b31   OF v := 0;        writef(" %x8", v!0)
    v!0 := p; up0   OF v := #x7A5;    writef(" %x8", v!0)
    v!0 := p; w20   OF v := #xFEDCB;  writef(" %x8*n", v!0)
  }
  RESULTIS 0
}
