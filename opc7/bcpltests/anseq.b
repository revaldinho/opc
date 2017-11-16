/* This program prints the least significant decimal
   digit of Connell's sequence numbers An where

   An = 2n - int[(1 + sqrt(8i-7))/2]

   This demonstration was suggested to me by Bob Acker.

   Implemented in BCPL by Martin Richards (c) Oct 2000.
*/

GET "libhdr"

LET start() = VALOF
{ LET prevd = 0

/*
// Test sqrt function
FOR i = 0 TO 31 DO
{ LET x = 1<<i
  FOR j = -1 TO 1 DO
  { LET a = x+j
    LET r = sqrt(a)
    writef("%x8: r=%x8  r****2=%x8  (r+1)****2=%x8*n", 
            a,     r,          r*r,            (r+1)*(r+1))
  }
}
RESULTIS 0
*/

  FOR i = 1 TO 2016 DO
  { LET d = (2*i - (1+sqrt(8*i-7))/2) REM 10
    UNLESS ((prevd NEQV d) & 1) = 0 DO newline()
    prevd := d
    writef("%n", d)
  }
  newline()
  RESULTIS 0
}

AND sqrt(x) = VALOF
// If x<=0 return 0
// else Return the largest integer whose square is <= x
// (It might have been better to treat x as unsigned.)
{ LET r = 1
  IF x<=0 RESULTIS 0
  { LET nr = (r + x/r + 1)/2 // The +1 stops possible oscillation 
    IF r=nr BREAK
    r := nr
  } REPEAT
  IF r<0     DO r := -r  // Special care when x close to maxint  
  IF r*r-x>0 DO r := r-1
  RESULTIS r
}
