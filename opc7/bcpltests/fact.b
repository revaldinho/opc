SECTION "fact"

GET "libhdr"

LET start() = VALOF
{ FOR i = 1 TO 12 DO writef("fact(%i2) = %i9*n*c", i, fact(i))
  RESULTIS 0
}

AND fact(n) = n=0 -> 1, n*fact(n-1)
