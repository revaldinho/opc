GET "libhdr"
 
GLOBAL {
  count:ug
  all
}
 
LET try(ld, col, rd) BE
  TEST col=all
  THEN count := count + 1
  ELSE { LET poss = all & ~(ld | col | rd)
         WHILE poss DO
         { LET p = poss & -poss
           poss := poss - p
           try(ld+p << 1, col+p, rd+p >> 1)
         }
       }

LET start() = VALOF
{ all := 1
  
  FOR i = 1 TO 12 DO
  { count := 0
    try(0, 0, 0)
    writef("Number of solutions to %i2-queens is %i9*n*c", i, count)
    all := 2*all + 1
  }

  RESULTIS 0
}
