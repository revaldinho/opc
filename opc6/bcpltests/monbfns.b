// This program calculates the number of monadic boolean 
// functions of n boolean variables

GET "libhdr"

GLOBAL {
  succs: 200  // succs!i = set of successors to vertex i
}

LET start() = VALOF
{ LET v = VEC 32
  FOR i = 0 TO 31 DO
  { v!i := 0
    FOR j = i TO 31 IF (i&j)=i DO v!i := v!i | 1<<j
  }
  succs := v        

//  FOR n = 0 TO 31 DO writef("%b5 %bW*n", n, succs!n)

  FOR n = 0 TO 5 DO
    writef("There are %i4 monotonic boolean functions of %n variables*n",
                      mbfns(0, 1<<n, 0), n)
  RESULTIS 0
}

AND mbfns(i, bit, bits) = VALOF
{ LET count = 0
  //writef("i=%n bits %b4*n", i, bits)
  IF i>=bit RESULTIS 1
  IF (bits>>i & 1)=0 DO
          count := mbfns(i+1, bit, bits | succs!i) // Vi assigned T
  RESULTIS count + mbfns(i+1, bit, bits)           // Vi assigned F
}


