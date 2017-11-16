GET "libhdr"


LET start() = VALOF
{ LET m, n = 2, 31
  
  writef("m = %n n = %n*n*c", m, n)

  FOR i = 0 TO n-1 DO
  { IF i REM 10 = 0 DO newline()
    writef(" %i4", exp(m, i, n))
  }
  newline()
  RESULTIS 0
}

AND gcd(x, y) = x=y -> x,
                x<y -> gcd(x, y-x), gcd(x-y, y)
                

// Modular arithmetic functions

AND dv(a, m, b, n) = a=1 -> m,
                     a=0 -> m-n,
                     a<b -> dv(a, m, b REM a, m*(b/a)+n),
                     dv(a REM b, m+n*(a/b), b, n)

AND inv(x, m) = dv(x, 1, m-x, 1)

AND add(x, y, m) = VALOF
{ LET a = x+y
  IF a<m RESULTIS a
  RESULTIS a-m
}

AND sub(x, y, m) = add(x, neg(y), m)

AND neg(x, m)    = m-x

AND ovr(x, y, m) = mul(x, inv(y,m), m)

AND mul(x, y, m) = y=0 -> 0,
                   (y&1)=0 -> mul(add(x,x,m), y>>1, m),
                   add(x, mul(add(x,x,m), y>>1, m), m)

AND exp(x, y, m) = y=0 -> 1,
                   (y&1)=0 -> exp(mul(x,x,m), y>>1, m),
                   mul(x, exp(mul(x,x,m), y>>1, m), m)

