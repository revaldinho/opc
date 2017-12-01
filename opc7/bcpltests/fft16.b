GET "libhdr"

MANIFEST {
upb = 15
modulus = 257
}

STATIC   { v=0; w=0  }

LET start() = VALOF
{ LET data  = VEC 15
  AND roots = VEC 15
  v, w := data, roots

  FOR i = 0 TO 15 DO v!i := i
  //FOR i = 0 TO 15 DO v!i := i & 3
  //v!0 := 1
  //v!1 := 1
  pr(v, 15)
// prints  -- Original data
//    0     1     2     3     4     5     6     7 ...

  w!0 := 1
  FOR i = 1 TO 15 DO w!i := mul(w!(i-1), 2)  // roots of unity
  fft16(v)
  pr(v, 15)
// prints   -- Transformed data
//  120    16    91    39   121   100    90    75 ...

  w!15 := 2
  FOR i = 14 TO 1 BY -1 DO w!i := mul(w!(i+1), 2) // inv roots of unity
  fft16(v)
  FOR i = 0 TO upb DO v!i := ovr(v!i, 16)
  pr(v, 15)
//prints  -- original data (hopefully!)
//   0     1     2     3     4     5     6     7 ...

  RESULTIS 0
}

AND fft16(v) BE { fft(16, v, 0, #b1000)
                  reorder(v, v, #B1000, #B0001)
                }

AND reorder(p, q, bp, bq) BE TEST bp=0
                             THEN IF p<q DO { LET t = !p
                                              !p := !q
                                              !q := t
                                            }
                             ELSE { LET bp1, bq1 = bp>>1, bq<<1
                                    reorder(p+bp, q+bq, bp1, bq1)
                                    reorder(p,    q,    bp1, bq1)
                                  }

AND fft(nn, i, pp, bit) BE { LET n, p = nn>>1, pp>>1
                             FOR j = i TO i+n-1 DO butterfly(j, j+n, w!p)
                             IF n=1 RETURN
                             fft(n,   i,     p, bit)
                             fft(n, i+n, p+bit, bit)
                           }

AND butterfly(i, j, x) BE { LET a, b = !i, mul(!j, x)
                            !i, !j := add(a, b), sub(a, b)
                          }

AND pr(v, upb) BE
{ FOR i = 0 TO upb DO
   { writef("%i5 ", v!i)
      IF i MOD 8 = 7 DO newline()
   }
   newline()
}

AND dv(a, m, b, n) = a=1 -> m,
                     a=0 -> m-n,
                     a<b -> dv(a, m, b MOD a, m*(b/a)+n),
                     dv(a MOD b, m+n*(a/b), b, n)


AND inv(x) = dv(x, 1, modulus-x, 1)

AND add(x, y) = VALOF
{ LET a = x+y
  IF a<modulus RESULTIS a
  RESULTIS a-modulus
}

AND sub(x, y) = add(x, neg(y))

AND neg(x)    = modulus-x

AND mul(x, y) = x=0 -> 0,
                (x&1)=0 -> mul(x>>1, add(y,y)),
                add(y, mul(x>>1, add(y,y)))

AND ovr(x, y) = mul(x, inv(y))



