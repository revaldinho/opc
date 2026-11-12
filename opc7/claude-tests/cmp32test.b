GET "libhdr"

// The 32 bit companion of cmptest (OPC7 only): every signed compare, as a value and as a
// conditional jump, between values at the ends of the 32 bit range, where the subtraction in a
// compare overflows; then the eight compares against zero for each value.
LET bit(t) BE wrch('0' - t)

LET start() = VALOF
{ LET v = TABLE #x80000000, #x80000001, -65536, -1, 0, 1, 65536, #x7FFFFFFE, #x7FFFFFFF
  LET n = 9
  FOR i = 0 TO n-1 DO
  { LET a = v!i
    FOR j = 0 TO n-1 DO
    { LET b = v!j
      bit(a<b); bit(a>b); bit(a<=b); bit(a>=b); bit(a=b); bit(a~=b)
      TEST a<b  THEN wrch('1') ELSE wrch('0')
      TEST a>b  THEN wrch('1') ELSE wrch('0')
      TEST a<=b THEN wrch('1') ELSE wrch('0')
      TEST a>=b THEN wrch('1') ELSE wrch('0')
      wrch(' ')
    }
    wrch('|'); bit(a<0); bit(a>0); bit(a<=0); bit(a>=0)
    TEST a<0  THEN wrch('1') ELSE wrch('0')
    TEST a>0  THEN wrch('1') ELSE wrch('0')
    TEST a<=0 THEN wrch('1') ELSE wrch('0')
    TEST a>=0 THEN wrch('1') ELSE wrch('0')
    newline()
  }
  RESULTIS 0
}
