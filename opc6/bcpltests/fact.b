SECTION "fact"

GET "libhdr"

LET start() = VALOF
{ FOR i = 1 TO 7 DO writef("fact(%n) = %i4*n*c", i, fact(i))
  RESULTIS 0
}

AND fact(n) = n=0 -> 1, n*fact(n-1)
