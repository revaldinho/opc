GET "libhdr"

LET start() = VALOF
{ FOR x = 1 TO 15 DO
  { newline()
    FOR y = 1 TO 15 DO writef(" %i3", x*y)
  }
  newline()
  RESULTIS 0
}
