/*
Project Euler Problem 1

Add up integers that are multiples of 3 or 6 that are greater than 1 and less than 1000.

*/

GET "libhdr"

LET start() = VALOF
{ LET sum = 0

  FOR n = 1 TO 999 DO
  { LET x = n
    IF n MOD 3 & n MOD 5 LOOP
    sum := sum + n
    writef("%i4: sum=%i7*n", n, sum)
  }

  RESULTIS 0
}
