GET "libhdr"

// Prints, for each pair (a,b), the value compares a<b a>b a<=b a>=b, then the
// same four as conditional jumps; then per row the eight compares against zero.
LET bit(t) BE wrch('0' - t)
LET jb(t) BE TEST t THEN wrch('1') ELSE wrch('0')

LET start() = VALOF
{ LET v = TABLE 0, 1, -1, 2, -2, 100, -100, 32766, -32767, 32767, -32768
  LET n = 11
  FOR i = 0 TO n-1 DO
  { LET a = v!i
    FOR j = 0 TO n-1 DO
    { LET b = v!j
      LET t1 = a<b
      LET t2 = a>b
      LET t3 = a<=b
      LET t4 = a>=b
      bit(t1); bit(t2); bit(t3); bit(t4)
      TEST a<b  THEN wrch('1') ELSE wrch('0')
      TEST a>b  THEN wrch('1') ELSE wrch('0')
      TEST a<=b THEN wrch('1') ELSE wrch('0')
      TEST a>=b THEN wrch('1') ELSE wrch('0')
      wrch(' ')
    }
    { LET z1 = a<0
      LET z2 = a>0
      LET z3 = a<=0
      LET z4 = a>=0
      wrch('|'); bit(z1); bit(z2); bit(z3); bit(z4)
      TEST a<0  THEN wrch('1') ELSE wrch('0')
      TEST a>0  THEN wrch('1') ELSE wrch('0')
      TEST a<=0 THEN wrch('1') ELSE wrch('0')
      TEST a>=0 THEN wrch('1') ELSE wrch('0')
    }
    newline()
  }
  { LET x = 13
    writef("shifts %n %n %n %n*n", x<<1, x<<3, x>>1, (x<<7)>>5)
  }
  RESULTIS 0
}
