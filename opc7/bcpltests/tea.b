// This is a BCPL encoding of David Wheeler's tea encryption algorithm

// Martin Richards  5 April 2000

GET "libhdr"

GLOBAL { kt:200; data }

MANIFEST { SIZE=1000 }


LET MX(z, y, p, e, sum, k) = (z>>5 NEQV y<<2) + (z<<4 NEQV y>>3)    NEQV
                             (sum NEQV y) + (k!(p&3 NEQV e) NEQV z)

MANIFEST { DELTA = #x9e3779b9 }

LET encrypt(v, n, k) BE  // precondition: n>1
{ LET sum = DELTA
  FOR i = 1 TO 6 + 52/n DO
  { LET e = sum>>2 & 3
    v!0     := v!0     + MX(v!(n-1), v!1,       0, e, sum, k)
    FOR p = 1 TO n-2 DO
      v!p   := v!p     + MX(v!(p-1), v!(p+1),   p, e, sum, k)
    v!(n-1) := v!(n-1) + MX(v!(n-2), v!0,     n-1, e, sum, k)
    sum := sum + DELTA
  }
}

AND decrypt(v, n, k) BE // precondition: n>1
{ LET sum = (6 + 52/n) * DELTA
  WHILE sum DO
  { LET e = sum>>2 & 3
    v!(n-1) := v!(n-1) - MX(v!(n-2), v!0,     n-1, e, sum, k)
    FOR p = n-2 TO 1 BY -1 DO
      v!p   := v!p     - MX(v!(p-1), v!(p+1),   p, e, sum, k)
    v!0     := v!0     - MX(v!(n-1), v!1,       0, e, sum, k)
    sum := sum - DELTA
  }
}

AND start() = VALOF
{ data := getvec(SIZE)
writef("%n*n", DELTA)

  UNLESS data DO
  { writef("Insufficient space*n")
    RESULTIS 20
  }

  writef("Testing DJW's tea encryption algorithm*n")
  FOR i=0 TO SIZE DO data!i := i
  kt := TABLE #x00000003,#x00000002,#x00000001,#x00000000

  writef("*nKey Table*n");      pr(kt, 4)

  writef("*nRaw data*n");       pr(data, 32)

  encrypt(data, SIZE, kt)

  writef("*nEncrypted data*n"); pr(data, 32)

  decrypt(data, SIZE, kt)

  writef("*nDecrypted data*n"); pr(data, 32)

  freevec(data)

  RESULTIS 0
}

AND pr(v, n) BE
{ FOR i=0 TO n-1 DO { UNLESS i REM 8 DO newline()
                      writef(" %x8", v!i)
                    }
  newline()
}



