SECTION "fact"

GET "libhdr"

LET start() = VALOF {
  FOR i = 1 TO 7 DO {
      writes("fact(")
      writen(i)
      writes(") = ")
      writen( fact(i) )
      newline()
  }
  RESULTIS 0
}

AND fact(n) = n=0 -> 1, n*fact(n-1)
