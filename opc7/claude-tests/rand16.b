GET "libhdr"

// randno and setseed on OPC6, where the OPC bcpllib generator is the 16 bit
// form of the native one (multiplier #xA3ED, increment #x1D31). There is no
// native 16 bit system, so rand16.expected comes from a model of it.
LET start() = VALOF
{ writes("unseeded:")
  FOR i = 1 TO 10 DO writef(" %n", randno(30000))
  newline()
  writef("setseed returned %n*n", setseed(321))
  writes("seeded:  ")
  FOR i = 1 TO 10 DO writef(" %n", randno(100))
  newline()
  RESULTIS 0
}
