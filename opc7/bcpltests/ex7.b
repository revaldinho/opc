/*
Solution to Project Euler problem 7
*/

GET "libhdr"
 
GLOBAL {  count: ug  }
 
MANIFEST {  upb = 541  }
//MANIFEST {  upb = 9999  }
//MANIFEST {  upb = 1_299_850  }   // Too big for OPC7's 1M words of memory
MANIFEST {  upb = 110_000  }      // Enough: the 10001st prime is 104743
 
LET start() = VALOF
{  LET isprime = getvec(upb)
   LET bigp = 0
   count := 0

   FOR i = 2 TO upb DO isprime!i := TRUE  // Until proved otherwise.
 
   FOR p = 2 TO upb IF isprime!p DO
   {  LET i = 2*p // Smaller multiples of p are already crossed out.
      UNTIL i>upb DO {  isprime!i := FALSE; i := i + p }
      out(p)
      bigp := p
//writef("*np=%i3 bigp=%n isprime=%i6*n", p, bigp, isprime)
//abort(1000)
      IF count=10001 BREAK
   }


writef("*n*nLargest prime %n*n", bigp)
   writes("*nEnd of output*n")
   freevec(isprime)
   RESULTIS 0
}
 
AND out(n) BE
{  IF count MOD 10 = 0 DO writef("*n%i5: ", count+1)
   writef(" %i5", n)
   count := count + 1
}
