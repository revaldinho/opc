SECTION "fact"

GET "libhdr"

LET start() = VALOF
{ FOR i = 1 TO 13 DO writef("fact(%i2) = %iA*n*c", i, fact(i))
  RESULTIS 0
}

AND fact(n) = n=0 -> 1, n*fact(n-1)
