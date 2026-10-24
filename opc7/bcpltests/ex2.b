/*
Project Euler Problem 2

The sum of even fibonacci less than or equal to 1000000.

*/

GET "libhdr"

LET start() = VALOF
{ LET sum = 0
  LET a, b = 0, 1

  { LET c = a+b
    a, b := b, c
    IF a > 1_000_000 BREAK
    IF ( a & 1)=0 DO sum := sum + a
 

    writef("%i4: sum=%i7*n", a, sum)
  } REPEAT
  RESULTIS 0
}
