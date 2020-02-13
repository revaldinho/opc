/*

This is a simple demonstration of the RSA mechanism for
public key encryption.

Implemented in BCPL by Martin Richards (c) Sept 2000

24/05/12
Made it work with unsigned numbers
*/

GET "libhdr"

GLOBAL {
p:ug; q    // Private key
N; e       // Public key
d          // Inverse of e mod (p-1)*(q-1)
M; C; M1   // Message, Crypted message, decoded message

}


LET start() = VALOF
{ 
//p, q, e, M :=   5,  11,   7,   2
//p, q, e, M := 541, 883, 691, 113
p, q, e, M := 45007, 35023, 10000691, #x0ABCDEF0
//p, q, e, M := 45007, 35023, 10000691, 45007*35023-2

  N  := p*q

// The message M must be less than N, vied as unsigned numbers

  writef("*n*cRSA demo*n*c")
  writef("*n*cPrivate key:  p=%n q=%n*n*c", p, q)
  writef("Public key:   pq=%n  e=%n*n*c", N, e)

//Test gcd on very large unsigned numbers
//gcd(#x80000000, #x80001000)
//gcd(#x80000000, #x00001000)
//gcd(#x80000000, #x80000002)
//gcd(#x80000000, #xFFFFFFFE)
//gcd(1000003*1003*3, 1000003*1003*3+1003)

  UNLESS e<(p-1)*(q-1) & gcd((p-1)*(q-1), e)=1 DO
  { writef("*n*ce is too large or not co-prime with (p-1)(q-1)*n*c")
    RESULTIS 20
  }

  writef("*n*c(p-1)(q-1) = %n*n*c", (q-1)*(q-1))
  writef("and this is both greater the e(=%n) and coprime with e*n*c", e)

  d := inv(e, (p-1)*(q-1))

  writef("*n*c(1/e) mod (p-1)(q-1) is %n (=d)*n*c", d)

  writef("*n*cMessage:        %10i %x8 (=M)*n*c", M, M)

  C := pow(M, e, N) // M^e mod pq

  writef("M^e mod pq:     %10i %x8 (=C)*n*c", C, C)

  M1 := pow(C, d, N) // C^d mod pq

  writef("C^d mod pq:     %10i %x8*n*c*n*c", M1, M1)

  RESULTIS 0
}

// Modular arithmetic functions, using unsigned integers

// dv needs correction for unsigned integers (both MOD and / assume signed arguments)
AND dv(a, m, b, n) = a=1 -> m,
                     a=0 -> m-n,
                     a-b<0 -> dv(      a,         m, b MOD a, m*(b/a)+n),
                              dv(a MOD b, m+n*(a/b),       b,         n)

AND inv(x, m) = dv(x, 1, m-x, 1)

AND add(x, y, m) = VALOF
{ LET a = x+y

  IF x<0 & y<0 & a>0 RESULTIS a-m

//IF a<0 DO
//{ writef("add: a=%x8 b=%x8 a=%x8*n*c", x, y, a)
//  abort(1000)
//}
  IF a-m<0 RESULTIS a // Unsigned comparison
  RESULTIS a-m
}

AND sub(x, y, m) = add(x, neg(y), m)

AND neg(x, m)    = m-x

AND ovr(x, y, m) = mul(x, inv(y,m), m)

AND mul(x, y, m) = y=0 -> 0,
                   (y&1)=0 -> mul(add(x,x,m), y>>1, m),
                   add(x,     mul(add(x,x,m), y>>1, m), m)

AND pow(x, y, m) = y=0 -> 1,
                   (y&1)=0 -> pow(mul(x,x,m), y>>1, m),
                   mul(x,     pow(mul(x,x,m), y>>1, m), m)

// An alternative to ovr is to repeated add m to x, and divide by the
// gcd of the new x, y, until y=1. x is then the answer.
// eg ovr(3, 20, 31) =>
// 3/20 => 34/20 => 17/10 => 48/10 => 24/5 => 55/5 => 11
// This is too inefficient to use.
AND ovr1(x, y, m) = VALOF
{ writef("ovr1: x=%10u    y=%10u*n*c", x, y)
  UNTIL y=1 DO
  { LET z = x+m
    LET g = gcd(z, y)
writef("ovr1: x=%10u    y=%10u  g=%10u*n*c", x, y, g)
    x, y := z/g, y/g
writef("ovr1: x=%10u    y=%10u*n*c", x, y)
//abort(1000)
  }
writef("ovr1: result=%10u*n*c", x)
  RESULTIS x
} 

AND gcd(a, b) = VALOF
{ // This version is designed to work with unsigned values
  IF a=b RESULTIS a

  IF a=0 | b=0 RESULTIS 0

  // Replace a and b by values in range 0 .. maxint that have the
  // same gcd
//writef("gcd: a=%10u %x8    b=%10u %x8*n*c", a, a, b, b)

  IF a<0 DO
  { TEST b<0
    THEN a := ABS(a-b) // Make a>=0 but with same gcd
    ELSE { // a<0 and b>0
           // so subtract a sufficient multiple of b from a
           // to make it positive, ie <= maxint
           a := a - (maxint/b) * b REPEATWHILE a<0
         }
  }
//writef("gcda:a=%10u %x8    b=%10u %x8*n*c", a, a, b, b)

  // 0 < a <= maxint

  IF b<0 DO
  { // b<0 and a>0
    // so subtract a sufficient multiple of a from b
    // to make it positive, ie <= maxint
    b := b - (maxint/a) * a REPEATWHILE b<0
  }

//writef("gcdb:a=%10u %x8    b=%10u %x8*n*c", a, a, b, b)

  // a and b are both positive and have the same gcd as the original
  // unsigned values

  UNTIL b=0 DO
  { LET r = a MOD b
    a := b
    b := r
//writef("gcd: a=%10u %x8    b=%10u %x8*n*c", a, a, b, b)
  }

//writef("gcd: r=%10u %x8*n*c", a, a)
//abort(1000)
  RESULTIS a
}

