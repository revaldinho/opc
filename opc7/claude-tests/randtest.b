GET "libhdr"

// randno and setseed from the OPC bcpllib (the native generator since
// 24/10/2026). On OPC7 the results must equal a plain native cintsys run,
// both unseeded (cintsys starts with setseed(12345)) and after setseed.
LET start() = VALOF
{ LET max = 0
  writes("unseeded:")
  FOR i = 1 TO 8 DO writef(" %n", randno(1_000_000))
  newline()
  writef("setseed returned %n*n", setseed(98765))
  writes("seeded:  ")
  FOR i = 1 TO 8 DO writef(" %n", randno(1000))
  newline()
  setseed(-7)
  writes("negative:")
  FOR i = 1 TO 8 DO writef(" %n", randno(6))
  newline()
  setseed(0)
  FOR i = 1 TO 20000 DO { LET r = randno(2_000_000_000); IF r > max DO max := r }
  writef("max of 20000 randno(2000000000) %n*n", max)
  RESULTIS 0
}
