/*
This program is a simple demonstration of Reed-Soloman error
correction.

Implemented in BCPL by Martin Richards (c) March 2016

Usage:

reedsolomon "testno/n"

eg
reedsolomon      for a small (9,6) demo with three errors
reedsolomon 1    for a larger (26,10) demo with five errors

*/

GET "libhdr"

MANIFEST {
  GFpoly = #b_1_0001_1101
  GFtbit = #b_1_0000_0000  // The test bit
}

GLOBAL {
  gf_log2:ug
  gf_exp2

  n            // The codeword length in bytes
  k            // The message length
  e            // n-k The number of parity bytes

  Msg          // The message polynomial
  G            // The generator polynomial
  M            // The codeword polynomial for Msg and G
  R            // The received corrupted codeword polynomial
  S            // The syndromes polynomial with coefficients
               //    Si = R(2^i)
  Lambda       // The Lambda polynomial, coeffs L1,..
  Ldash        // d/dx of Lambda polynomial
  Omega        // The message polynomial, coeffs O1,..
  e_pos        // For the error positions
  T            // Temp polynomial
  testno       // =0 for small demo, =1 for a larger demo.
}

LET start() = VALOF
{ LET argv = VEC 50

 //  UNLESS rdargs("testno/n", argv, 50) DO
 //  { writef("*n*cBad arguments for qr*n*c")
 //    RESULTIS 0
 //  }

  testno := 0
  IF argv!0 DO testno := !argv!0  // testno/n

  newline()
  initlogs()


  //{ LET r = VEC 20
  //  LET p = TABLE 9, #x12, #x34, #x56, #x78, 0,0,0,0,0,0
  //  LET q = TABLE 6, #x71, #x11, #x22, #x33, #x44, #x55, #x66
  //  gf_poly_divmod(p,q,r)
  //  RETURN
  //}

  // Call rs_demo
  rs_demo()

  IF gf_log2 DO freevec(gf_log2)
  IF gf_exp2 DO freevec(gf_exp2)

  RESULTIS 0
}

// Addition and subtraction are the same in GF arithmetic. Since
// they are so simple we will usually just use XOR rather than
// calling these functions.
AND gf_add(x, y) = x XOR y

AND gf_sub(x, y) = x XOR y

// Multiplication in GF(2^8) can be done efficiently by regular
// multiplication using tables of discrete logarithm and
// anti-logorithms. These are both quite small and can be
// precomputed. We can create these two tables using the function
// initlogs.
AND initlogs() BE
{ LET x = 1
  gf_log2 := getvec(255)
  gf_exp2 := getvec(510) // 510 = 255+255
  UNLESS gf_log2 & gf_exp2 DO
  { writef("initlogs: More space needed*n*c")
    abort(999)
  }

  // Initialise gf_exp2 with powers of 2 in GF(2^8). While doing so
  // place the inverse entries in gf_log2. Using a double sized exp2
  // table improves the efficiency of both functions gf_mul and gf_div.

  gf_log2!0 := -1  // log2 of zero is undefined.

  FOR i = 0 TO 255 DO // All possible element values
  { // 2^i = x  so  i = log2(x)
    gf_exp2!i := x
    gf_exp2!(i+255) := x // Note 2^255=1 in GF(2^8)
    gf_log2!x := i
    // Now set x = 2 * x
    x := x<<1
    UNLESS (x & GFtbit)=0 DO x := x XOR GFpoly
  }
}

AND gf_mul(x, y) = VALOF
{ // Perform GF multiplication using logarithms base 2.
  // Since log 0 is undefined x=0 and y=0 are special cases.
  IF x=0 | y=0 RESULTIS 0
  RESULTIS gf_exp2!(gf_log2!x + gf_log2!y)
}

AND gf_div(x, y) = VALOF
{ // Perform GF division using logarithms base 2.
  // Since log 0 is undefined x=0 and y=0 are special cases.
  IF y=0 DO
  { writef("gf_div: Division by zero*n*c")
    abort(999)
  }
  IF x=0 RESULTIS 0
  RESULTIS gf_exp2!(255 + gf_log2!x - gf_log2!y)
}

AND gf_pow(x,y) = gf_exp2!((gf_log2!x * y) MOD 255)

AND gf_inverse(x) = gf_exp2!(255 - gf_log2!x)

/*
We now implement some some functions that work on polynomials with
coefficients in GF(2^8). We will use a vector to represent a
polynomials. Its zeroth element will be the degree of the polynomial
(n, say) and v!1 will be the coefficient x^n, v!2 will be the
coefficient x^(n-1), and so on. So v!(n+1) will be the coefficient of
x^0, which is the constant term.
*/

AND gf_poly_copy(p, q) BE
{ // Copy polynomial from p to q.
  FOR i = 0 TO p!0+1 DO q!i := p!i
} 

AND gf_poly_scale(p, x, q) BE
{ // Multiply, using gf_mul, every coefficient of polynomial p by
  // scalar x leaving the result in q, assumed to be large enough.
  LET deg = p!0   // The degree of polynomial p
  q!0 := deg      // The degree of the result
  FOR i = 1 TO deg+1 DO q!i := gf_mul(p!i, x)
}

AND gf_poly_add(p, q, r) BE
{ // Add polynomials p and q leaving the result in r
  LET degp = p!0 // The number of coefficients is one larger
  LET degq = q!0 // than the degree of the polynomial.
  LET degr = degp
  IF degq>degr DO degr := degq
  // degr is the larger of the degrees of p and q.
  r!0 := degr    // The degree of the result
  FOR i = 1 TO degp+1    DO r!(i+degr-degp) := p!i
  FOR i = 1 TO degr-degp DO r!i := 0 // Pad higher coeffs with 0s
  FOR i = 1 TO degq+1 DO r!(i+degr-degq) := r!(i+degr-degq) XOR q!i
}

// GF addition and subtraction are the same.
AND gf_poly_sub(p, q, r) BE gf_poly_add(p, q, r)

AND gf_poly_mul(p, q, r) BE
{ // Multiply polynomials p and q leaving the result in r
  LET degp = p!0
  LET degq = q!0
  LET degr = degp+degq

  r!0 := degr    // Degree of the result
  FOR i = 1 TO degr+1 DO r!i := 0
  FOR j = 1 TO degq+1 DO
    FOR i = 1 TO degp+1 DO
      r!(i+j-1) := r!(i+j-1) XOR gf_mul(p!i, q!j)
}

AND gf_poly_mulbyxn(p, n, r) BE
{ // Multiply polynomials p by x^n leaving the result in r
  LET degp = p!0
  LET degr = degp + n
  r!0 := degr
  FOR i = 1 TO degp+1 DO r!i := p!i
  FOR i = degp+2 TO degr+1 DO r!i := 0

  //M!0 := degm 
  //FOR i = 1 TO degmsg+1       DO M!i := Msg!i
  //FOR i =  degmsg+2 TO degm+1 DO M!i := 0
}

AND gf_poly_eval(p, x) = VALOF
{ // Evaluate polynomial p for a given x using Horner's method.
  // Eg use:  ax^3 + bx^2 + cx^1 + d  =  ((ax + b)x + c)x + d
  LET res = p!1
  FOR i = 2 TO p!0+1 DO
    res := gf_mul(res,x) XOR p!i // mul by x and add next coeff
  RESULTIS res
}

AND pr_poly(p) BE
{ FOR i = 1 TO p!0+1 DO writef(" %x2", p!i)
  newline()
}

AND pr_poly_dec(p) BE
{ FOR i = 1 TO p!0+1 DO writef(" %i3", p!i)
  newline()
}

AND gf_poly_divmod(p, q, r) BE
{ // This divides polynomial p by ploynomial q placing
  // the quotient and remainder in r, assumed to be large
  // enough.
  LET degp = p!0   // The degree of polynomial p.
  LET degq = q!0   // The degree of polynomial q.
  LET degr = degp

  LET t = VEC 255  // Vector to hold the next product of the generator

  UNLESS q!1 > 0 DO
  { writef("The divisor must have a non zero leading coefficient*n*c")
    abort(999)
    RETURN
  }

  // Copy polynomial p into r.
  r!0 := degr
  FOR i = 1 TO degr+1 DO r!i := p!i

  writef("p:         "); pr_poly(p)
  writef("q:         "); pr_poly(q)
  writef("initial r: "); pr_poly(r)

  FOR i = 1 TO degp-degq+1 DO
  { LET dig = gf_div(r!i, q!1)
    IF dig DO
    { gf_poly_scale(q, dig, t)
      writef("scaled  q: ")
      FOR j = 2 TO i DO writef("   ")
      pr_poly(t)
      r!i := dig  // Quotient coefficient
      FOR j = 2 TO t!0+1 DO r!(i+j-1) := r!(i+j-1) XOR t!j
    }
    writef("new     r: "); pr_poly(r)
  }
}

AND gf_poly_div(p, q, r) BE
{ gf_poly_divmod(p, q, r)
  r!0 := p!0 - q!0  // Select just the quotient
}

AND gf_poly_mod(p, q, r) BE
{ LET degp = p!0
  LET degq = q!0
  LET degr = degq - 1

  gf_poly_divmod(p, q, r)

  r!0 := degr  // Over write the quotient with the remainder.
  FOR i = 1 TO degr+1 DO r!i := r!(i+degp-degr)
}


AND gf_generator_poly(e, g) BE
{ // Set in g the polynomial resulting from the expansion of
  // (x-2^0)(x-2^1)(x-2^2) ... (x-2^(e-1)).  Note that it is
  // of degree e and that the coeffient of x^e is 1.
  LET t = VEC 255
  g!0, g!1 := 0, 1 // The polynomial: 1.
  FOR i = 0 TO e-1 DO
  { LET d, a, b = 1, 1, gf_pow(2,i) // (x + 2^i)
    // @d points to polynomial:        (x - 2^i)
    // which in GF arithmetic is also: (x + 2^i)
    FOR i = 0 TO g!0+1 DO t!i := g!i // Copy g into t
    gf_poly_mul(t, @d, g) // Multiply t by (x-2^i) into g
  }
}

/*
The function rs_encode_msg returns in r the polynomial Msg
concatenated with the e Reed-Solomon check bytes which represent
remainder after the Msg polynomial multiplied by x^e and divided by
the generator polynomial created by rs_generator_poly.  The following
is an example of the calculation with message polynomial 12 34 56 78
and e=6. This value of e gives us the generator polynomial 01 3F 01 DA
20 E3 26.

                                            12 9D 43 57
                           ----------------------------
   01 3F 01 DA 20 E3 26 ) 12 34 56 78 00 00 00 00 00 00
                          12 A9 12 88 7A 4D 16
                             -----------------
                             9D 44 F0 7A 4D 16 00
                             9D 07 9D 3F 4A 51 23
                                -----------------
                                43 6D 45 07 47 23 00
                                43 3A 43 F7 88 5A 1F
                                   -----------------
                                   57 06 F0 CF 79 1F 00
                                   57 11 57 99 32 67 DD
                                   --------------------
                                      17 A7 56 4B 78 DD

It thus computes 12 9D 43 57 as the quotient and 17 A7 56 4B 7B DD as
the remainder.  The process is basically long division using gf_mul
for multiplication and XOR for subtraction. If at each stage the
senior byte is not subtracted, the senior 4 bytes of the accumulator
become the quotient and the junior 6 bytes hold the remainder.  This
assumes the senior coefficient of the generator polynomial is always a
one. If, at the end, we replace the quotient bytes of the accumulator
by the original message bytes, we create the Reed-Solomon codeword, in
this case with 4 message bytes and 6 check bytes.

The definition of rs_encode_msg is as follows.
*/

AND rs_encode_msg() BE
{ // This appends e Reed-Solomon parity bytes onto the end of the
  // message bytes Msg, placing the result in M.
  LET degmsg = Msg!0  // The degree of the message polynomial.
  LET e = G!0         // e = the degree of the generator polynomial
  LET degm = degmsg+e // The degree of the RS codeword polynomial

  // Place Msg multiplied by x^e in M.
  gf_poly_mulbyxn(Msg, e, M)
  gf_poly_copy(M, T)
  gf_poly_divmod(T, G, M)
  // Copy Msg in the senior end of M replacing the bytes that
  // currently hold the quotient.
  FOR i = 1 TO degmsg+1 DO M!i := Msg!i
}


/*

We have seen the a Reed-Solomon codeword consists of k bytes of
message followed by e error correction bytes which represent the
remainder after deviding the message polynomial multiplied by x^e by
the generating polynomial. Since addition and subtraction are both the
same in GF arithmetic, the effect is that the codeword is exactly
divisible by the generating polynomial and, since the generator
polynomial is the product of many factors of the form (1 - x*2^i),
each of these factors also exactly divides into the codeword exactly.
However if some bytes of the codeword are corrupted, most of these
factors will not exactly divide the corrupted codeword. We can easily
create a polynomial of degree e-1 whose coefficients are the e
remainders obtained when attempting to divide the corrupted codeword
by each factor of the generator polynomial.

To demonstrate the error correction of a corrupted Reed Solomon
codeword, I will use an example of a 4 byte message 12 34 56 78 and 6
error correcting bytes. We thus have k=4, e=6 and so n=10.  The
generator polynomial g(x) is therefore

g(x) = (x-2^0)(x-2^1)(x-2^2)(x-2^3)(x-2^4)(x-2^5)
     = (x-01)(x-02)(x-04)(x-08)(x-16)(x-32)
     = 01*x^6 + 3F*x^5 + 01*x^4 + DA*x^3 + 20*x^2 + E3*x + 26

generator:  01 3F 01 DA 20 E3 26
codeword:   12 34 56 78 17 A7 56 4B 78 DD

Note the using + rather than - makes no difference in GF
arithmetic. It turns out that using this generator of this form
maximises the Hamming distance between codewords.

For simplicity we will write G, M the codeword and R the corrupted
codeword as:

G = 01 3F 01 DA 20 E3 26
M = 12 34 56 78 17 A7 56 4B 78 DD
R = 12 34 00 00 17 00 56 4B 78 DD

You will notice that bytes 3, 4 and 6 of the codeword have been
zeroed.

In general, when we attempt to read a codeword some of its bytes may
be corrupted resulting in a different polynomial R(x) which can be
written as the sum of M(x), the original codeword, and E(x) an errors
polynomial giving a correction value for each coefficient of R. This
is stated in the following equation:

R(x) = M(x) + E(x)

Suppose the polynomial for a corrupted codeword is

R = 12 34 00 00 17 00 56 4B 78 DD

This will mean that

E = 00 00 56 78 00 A7 00 00 00 00

which when added to R gives the corrected codeword. Our problem is how
to deduce the errors polynomial E knowing only R and the generator
polynomial. It turns out that we can, provided not too many bytes have
been corrupted. With 6 check bytes we can correct the 6/2=3 corrupted
bytes in R.

To do this we first construct a polynomial S (called the syndromes
polynomial) whose coefficients are the remainders after dividing R by
each of the factors of the generator polynomial. In our example e=6 so
the generator has 6 factors (x-2^0), (x-2^1), (x-4^2), (x-2^3),
(x-2^4) and (x-2^5). S can be written as

S(x) = S5*x^5 + S4*x^4 + S3*x^3 + S2*x^2 + S1*x + S0

When we divide R by (x-2^i) we obtain a quotient polynomial Qi and a
remander Si. These, of course, satisfy the following equation

   R(x) = (x-2^i)*Qi(x) + Si

and if we set x = 2^i this reduces to

   R(2^i) = Si

So Si can be calculated just by evaluating the polynomial R(x) at
x=2^i. For our example the syndromes polynomial is:

S = 2E B8 0E CB 50 35

If we happen to know in advance the positions in the codeword that
have been corrupted, in this case 3, 4 and 6, then we could write the
errors polynomial as

E(x) = Y1*x^7 + Y2*x^6 + Y3*x^4         All the other terms are zero

Hopefully there is sufficient information to deduce these positions
and Y1=56, Y2=78 and Y3=A7.

Since we have just shown E(2^i) = Si, and assuming we know the error
positions, we can say

Si = E(2^i)
   = Y1*2^(7*i) + Y2*2^(6*i) + Y3*2^(4*i)
   = Y1*X1^i + Y2*X2^i + Y3*X3^i
where X1 = 2^7, X2 = 2^6 and X3 = 2^4

These 6 equations can be written as a matrix product as follow

( S0 ) =  ( X1^0  X2^0  X3^0 ) x ( Y1 )
( S1 )    ( X1^1  X2^1  X3^1 )   ( Y2 )
( S2 )    ( X1^2  X2^2  X3^2 )   ( Y3 )
( S3 )    ( X1^3  X2^3  X3^3 )
( S4 )    ( X1^4  X2^4  X3^4 )
( S5 )    ( X1^5  X2^5  X3^5 )

We know that S = 2E B8 0E CB 50 35 and assuming we know that X1=2^7, X2=2^6 and
X3=2^4, this product simplifies to

( 2E ) =  ( 2^ 0  2^ 0  2^ 0 ) x ( Y1 )
( B8 )    ( 2^ 7  2^ 6  2^ 4 )   ( Y2 )
( 0E )    ( 2^14  2^12  2^ 8 )   ( Y2 )
( CB )    ( 2^21  2^18  2^12 )
( 50 )    ( 2^28  2^24  2^16 )
( 35 )    ( 2^35  2^30  2^20 )

or

( 2E ) =  ( 01  01  01 ) x ( Y1 )
( B8 )    ( 80  40  10 )   ( Y2 )
( 0E )    ( 13  CD  1D )   ( Y2 )
( CB )    ( 75  2D  CD )
( 50 )    ( 18  8F  4C )
( 35 )    ( 9C  60  B4 )

If these equations are consistent and non singular they can be solved.
The solution in this case turns out to be Y1=56, Y2=78 and
Y3=A7, as expected.

These values for Y1, Y2 and Y3 tells us that E(x)=56*x^7+78*x^6+A7*x^4
giving us the required result

E = 00 00 56 78 00 A7 00 00 00 00

which when added to

R = 12 34 00 00 17 00 56 4B 78 DD

give use the corrected codeword

T = 12 34 56 78 17 A7 56 4B 78 DD

It turns out that iIf we know the locations of 6 error, we could
correct all 6. But, as is usually the case, we do not know the
location of any of them we have more work to do.

The following functions calculate the syndromes polynomial and use it
to confirm the accuracy the description just given.

*/

AND rs_calc_syndromes(codeword, e, s) BE
{ // e = the number of error correction bytes
  //writef("*n*crs_calc_syndromes:*n*c")
  //writef("codeword:  "); pr_poly(codeword)
  LET degs = e-1
  s!0 := degs  // The degree of the syndromes polynomial.
  FOR i = 0 TO e-1 DO
  { LET p2i = gf_pow(2,i)
    LET res = gf_poly_eval(codeword, p2i)
    //writef("%i2 2^i = %x2 => %x2 %i3*n*c", i, p2i, res, res)
    //s!(i+1) := res // s!(i+1) = codeword(2^i)
    s!(degs+1-i) := res // si = codeword(2^i)
  }
}

/*

Our problem is now to try and find the locations of errors in the
corrupted codeword using only its syndomes polynomial and the
generator polynomial.

It is common in mathematcs and computing to pick out a seemingly
unrelated construct, as if by magic, and after a little elementary
manipulation suddenly realise it is just what we want.

Let us assume there are three locations e1, e2 and e3 containing
corrupted bytes in the codeword.  Let us now consider the following
polynomial.

Lambda(x) = (1+x*2^e1)(1+x*2^e2)(1+x*2^e3)
           = 1 + L1*x + L2*x^2 + L3*x^3

This polynomial is zero when x=2^-e1, or x=2^-e2 or x=2^-e3. If we
write Xi=2^ei, we can say the root of this Lambda(x)=0 are X1^-1,
X2^-1 and X3^-1. Knowing the roots allows us the write the following:

    1 + L1*2^-ej + L2*2^-2ej + L3*2^-3ej = 0

If we multiply this equation by Yj*2^(i+3)ej, we get

    Yj*2^(i+3)ej + L1*Yj*2^(i+2)ej + L2*Yj*2^(i+1)ej + L3*Yj*2^iej = 0

If we write these for each value of j, we get

    Y1*2^(i+3)e1 + L1*Y1*2^(i+2)e1 + L2*Y1*2^(i+1)e1 + L3*Y1*2^ie1 = 0
    Y2*2^(i+3)e2 + L1*Y2*2^(i+2)e2 + L2*Y2*2^(i+1)e2 + L3*Y2*2^ie2 = 0
    Y3*2^(i+3)e3 + L1*Y3*2^(i+2)e2 + L2*Y3*2^(i+1)e3 + L3*Y3*2^ie3 = 0
or

Y1*(2^(i+3))^e1 + L1*Y1*(2^(i+2))^e1 + L2*Y1*(2^(i+1))^e1 + L3*Y1*(2^i)^e1 = 0
Y2*(2^(i+3))^e2 + L1*Y2*(2^(i+2))^e2 + L2*Y2*(2^(i+1))^e2 + L3*Y2*(2^i)^e2 = 0
Y3*(2^(i+3))^e3 + L1*Y3*(2^(i+2))^e2 + L2*Y3*(2^(i+1))^e3 + L3*Y3*(2^i)^e3 = 0

Remembering that

E(x) = Y1*x^e1 + Y2*x^e2 + Y3*x^e3

We can add these equations together giving:

    E(2^(i+3)) + L1*E(2^(i+2)) + L2*E(2^(i+1)) + L3*E(2^i) = 0

We thus have the 3 following equations by setting i to 0, 1 and 2.

    E(2^3) + L1*E(2^2) + L2*E(2^1) + L3*E(2^0) = 0
    E(2^4) + L1*E(2^3) + L2*E(2^2) + L3*E(2^1) = 0
    E(2^5) + L1*E(2^4) + L2*E(2^3) + L3*E(2^2) = 0

Since we know E(2^i) = R(2^i), these become:

    R(2^3) + L1*R(2^2) + L2*R(2^1) + L3*R(2^0) = 0
    R(2^4) + L1*R(2^3) + L2*R(2^2) + L3*R(2^1) = 0
    R(2^5) + L1*R(2^4) + L2*R(2^3) + L3*R(2^2) = 0

which is the same as:

    S3 + L1*S2 + L2*S1 + L3*S0 = 0
    S4 + L1*S3 + L2*S2 + L3*S1 = 0
    S5 + L1*S4 + L2*S3 + L3*S2 = 0

These equations can be written in matrix form as follows:

    ( S3 ) = ( S2 S1 S0 ) x ( L1 )
    ( S4 )   ( S3 S2 S1 )   ( L2 )
    ( S5 )   ( S4 S3 S2 )   ( L3 )

Provided the 3x3 matrix is not singular, the equations can be solved
giving us the values of L1, L2 and L3. We now have the equation

Lambda(x) = 1 + L1*x + L2*x^2 + L3*x^3

completely defined and we can therefore find its roots 2^-e1, 2^-e2
and 2^-e3 and hence deduce the error positions e1, e2 and e3. We can
easily find the root by trial and error since there are only n
possible values for each ei, where n is the length of the codeword.

For our example, the equations matrix equation is

    ( 6E ) = ( DE 81 89 ) x ( L1 )
    ( 82 )   ( 6E DE 81 )   ( L2 )
    ( 7A )   ( 82 6E DE )   ( L3 )

giving L1=D0, L2=1B and L3=98.

In general, we do not know how many errors there are. If there are
fewer than 3 the 3x3 matrix will have a zero determinant and we will
have to try for 2 errors, but if the top left 2x2 determinant is zero,
we will have to try the top left 1x1 matrix.

The solution, if any, of this matrix equation is normally solved using
Berlekamp-Massey algorithm, described later.

*/

AND rs_find_error_locator() BE
{ // This sets Lambda to the error locator polynomial
  // using the syndromes polynomial in S. It is only used
  // when we do not know the locations of any of the
  // error bytes, so the maximum number of error that
  // can be found is the (S!0+1)/2. It uses the
  // Berlekamp-Massey algorithm.
  LET old_loc = VEC 50
  LET degs    = S!0
  LET k, l    = 1, 0
  LET newL    = VEC 50  // To hold the error locator polynomial
  LET C       = VEC 50  // To hold a correction polynomial
  LET P1      = VEC 50

  //writef("*n*cComputing the error locator polynomial Lambda*n*c")
  //writef("using the Berlekamp-Massey algorithm.*n*c*n*c")

  Lambda!0, Lambda!1 := 0, 1  // Polynomial: Lambda(x) = 1
  C!0, C!1, C!2 := 1, 1, 0    // Polynomial: C(x) = x+0

  UNTIL k > degs+1 DO // degs+1 = number of correction bytes
  { LET delta = 0//S!(degs+1) // S0 = R(2^0)
    LET degL = Lambda!0
    //newline()
    //writef("Lambda: "); pr_poly(Lambda)
    //writef("R:      "); pr_poly(R)
    //writef("S:      "); pr_poly(S)
    //writef("k=%n l=%n*n*c", k, l)

    // First calculate delta
    FOR i = 0 TO l DO
    { LET Li = Lambda!(degL+1-i)   // Li -- Coeff of x^i in current Lambda
      LET f = S!(degs+1 - (k-1-i)) // R(2^(k-1-i))
      LET Lif = gf_mul(Li, f)
      //writef("i=%n delta: %x2*n*c", i, delta)
      delta := delta XOR Lif
      //writef("i=%n Li=%x2 f=%x2 Lif=%x2 => delta=%x2*n*c",
      //        i,   Li,    f,    Lif,       delta)
    }
    //writef("delta: %x2*n*c", delta)

    IF delta DO
    { gf_poly_scale(C, delta, P1)
      //writef("Multiply R by delta=%x2 giving: ", delta); pr_poly(P1)
      gf_poly_add(P1, Lambda, newL)
      //writef("Add L giving newL              "); pr_poly(newL)
      IF 2*l < k DO
      { l := k-l
        gf_poly_scale(Lambda, gf_inverse(delta), C)
        //writef("Since 2xl < k set C = Lambda/delta: "); pr_poly(C)
      }
    }

    // Multiply C by x
    C!0 := C!0 + 1
    C!(C!0+1) := 0
    //writef("Multiply C by x giving: "); pr_poly(C)

    FOR i = 0 TO newL!0+1 DO Lambda!i := newL!i
    //writef("Set new version of Lambda:   "); pr_poly(Lambda)
    k := k+1
  }
}

AND rs_find_error_evaluator() BE
{ // Compute the error evaluator polynomial Omega
  // using S and Lambda.

  // Omega(x) = (S(x) * Lambda(x)) MOD x^(e+1)
  LET degs = S!0

  // This could be optimised since we are going to
  // through away many of the terms in the product.
  gf_poly_mul(S, Lambda, Omega)
  writef("S:          "); pr_poly(S)
  writef("Lambda:     "); pr_poly(Lambda)
  writef("S x Lambda: "); pr_poly(Omega)
  // Remove terms of degree higher than e
  FOR i = 0 TO degs DO Omega!(i+1) := Omega!(i+1+Omega!0-degs)
  Omega!0 := degs
  writef("Omega:      "); pr_poly(Omega)
}

AND rs_demo() BE
{ // This will test Reed-Solomon decoding typically using
  // either (n,k) = (9,6) or (26,10) depending on testno.

  LET v = getvec(1000)

  writef("reedsolomon entered*n*c")

  S       := v       // For the syndromes polynomial
  M       := v + 100 // For the codeword for msg
  R       := v + 200 // For the corrupted codeword
  G       := v + 300 // For the generator polynomial
  Lambda  := v + 400 // For the erasures polynomial
  Ldash   := v + 500 // For d/dx of Lambda
  Omega   := v + 600 // For the evaluator polynomial
  e_pos   := v + 700 // For the error positions
  T       := v + 800 // temp polynomial

  // A simple test
  Msg := TABLE 3, #x12, #x34, #x56, #x78
  e := 6

  IF testno>0 DO
  { // A larger test from the QR barcode given above.
    Msg := TABLE 15, #x40, #xD2, #X75, #x47, #x76, #x17, #x32, #x06,
                     #x27, #x26, #x96, #xC6, #xC6, #x96, #x70, #xEC
    e := 10
  }

  k := Msg!0 + 1   // Message bytes
  n := k+e         // codeword bytes

  gf_generator_poly(e, G)  // Compute the generator polinomial
  newline()
  //writef("generator: "); pr_poly(G)   // 01 3F 01 DA 20 E3 26
  //newline()
  writef("message:   "); pr_poly(Msg) // 12 34 56 78

  rs_encode_msg()          // Compute in R the RS codeword for Msg.

  writef("codeword:  "); pr_poly(M)   // 12 34 56 78 17 A7 56 4B 78 DD
  FOR i = 0 TO M!0+1 DO R!i := M!i
  R!3 := 0
  R!4 := #xAA
  R!6 := 0
  IF testno>0 DO
  { // Try 5 errors in all
    R!12 := 0
    R!26 := 0
  }
  newline()
  writef("corrupted: "); pr_poly(R)   // 12 34 00 00 17 00 56 4B 78 DD
  rs_calc_syndromes(R, e, S)          // syndromes of polynomial R

  writef("syndromes: "); pr_poly(S)   // 7A 82 6E DE 81 89

  // Typically: Lambda(x) =  L3**x^3 +  L2**x^2 + L1**x^1 + 1

  writef("*n*cLambda(x) =  ")
  FOR i = e/2 TO 1 BY -1 DO
    writef("L%n**x^n +  ", i, i)
  writef("1*n*c")


  writef("*n*cIt can be shown that:*n*c*n*c")

  FOR row = 0 TO e/2-1 DO
  { writef("( S%n ) ", row+e/2)
    wrch(row=0 -> '=', ' ')
    writef(" (")
    FOR col = e/2-1 TO 0 BY -1 DO writef(" S%n", col+row)
    writef(" ) ")
    wrch(row=0 -> 'x', ' ')
    writef(" ( L%n )*n*c", row+1)
  }

  newline()

  writef("*n*cwhere ")
  FOR i = e-1 TO 0 BY -1 DO writef("S%n ", i)
  writef("= ")
  FOR i = e-1 TO 0 BY -1 DO writef("%x2 ", gf_poly_eval(R, gf_exp2!i))
  writef("*n*c*n*c")

  FOR row = 0 TO e/2-1 DO
  { writef("( %x2 ) ", gf_poly_eval(R, gf_exp2!(row+e/2)))
    wrch(row=0 -> '=', ' ')
    writef(" (")
    FOR col = e/2-1 TO 0 BY -1 DO writef(" %x2", gf_poly_eval(R, gf_exp2!(col+row)))
    writef(" ) ")
    wrch(row=0 -> 'x', ' ')
    writef(" ( L%n )*n*c", row+1)
  }

  newline()
  writef("*n*cThis can be solved using the Berlekamp-Massey algorithm.*n*c")

  rs_find_error_locator()
  writef("*n*cLambda:   "); pr_poly(Lambda)  // 98 1B D0 01

  writef("So ")
  FOR i = 1 TO e/2 DO writef(" L%n=%x2", i, Lambda!(e/2+1-i))
  writef("*n*cand")
  FOR i = 0 TO e-1 DO writef(" S%n=%x2", i, S!(S!0+1-i))
  writef("*n*c*n*c")

  FOR row = 0 TO e/2-1 DO
  { LET a = 0
    FOR i = 0 TO e/2-1 DO
    { LET b = gf_poly_eval(R, gf_exp2!(e/2-1-i+row))
      LET c = Lambda!(Lambda!0-i)
      a := a XOR gf_mul(b,c)
      writef("%x2**%x2", b,c)
      TEST i=e/2-1
      THEN writef(" = %x2    -- S%n = %x2*n*c",
                  a, e/2+row, gf_poly_eval(R, gf_exp2!(e/2+row)))
      ELSE writef(" + ") 
    }
  }

  writef("*n*cIf the coeff of x^i in R(x) is corrupt then*
         * Lambda(2^-i) should be zero.*n*c*n*c")

  writef("The solutions of Lambda(x)=0 can be solved by trial and error*n*c*n*c")

  e_pos!0 := -1 // No error positions yet found.
  FOR i = 0 TO R!0 DO
  { LET Xi = gf_exp2!i
    LET a = gf_poly_eval(Lambda, gf_inverse(Xi))
    IF a=0 DO
    { writef("Lambda(2^-%i2) = 0*n*c", i)
      e_pos!0 := e_pos!0+1
      e_pos!(e_pos!0+1) := i
    }
  }

  writef("*n*cSo the error locations numbered from the left are: ")
  pr_poly_dec(e_pos)
  newline()

  rs_find_error_evaluator(S, Lambda, Omega)
  newline()

  writef("Checking Omega*n*c*n*c")

  FOR row = 0 TO e/2-1 DO
  { LET sum = 0
    writef("O%n = %x2    ", row, Omega!(Omega!0+1-row))
    FOR i = 0 TO row DO
    { LET Li = Lambda!(Lambda!0+1-i)
      LET Sj = S!(S!0+1+i-row)
      IF i>0 DO writef(" + ")
      writef("%x2**%x2", Sj, Li)
      sum := sum XOR gf_mul(Sj,Li)
    }
    writef(" = %x2*n*c", sum)
  }
  newline()

  writef("Lambda:     "); pr_poly(Lambda)

  writef("The formal differential of Lambda(x) is*n*c*n*c")
  writef("Ldash(x) = L1 + 2**L2**x^1 + 3**L3**x^2 + *
                         *4**L4**x^3 + 5**L5**x^4 + ...*n*c")
  writef("but here 2=1+1=0,  3=1+1+1=1,  4=1+1+1+1=0, etc, so:*n*c")
  writef("Ldash(x) = L1 + L3**x^2 + L5**x^4 + ...*n*c*n*c")

  gf_poly_copy(Lambda, Ldash)
  // Clear the coefficients of the even powers
  FOR i = Ldash!0+1 TO 1 BY -2 DO Ldash!i := 0
  // Divide through by x
  Ldash!0 := Ldash!0 - 1
  writef("Ldash:      "); pr_poly(Ldash)


  writef("*n*cLet Xi = 2^i and invXi = 2^-i*n*c")
  writef("*n*cIf Lambda(invXi) = 0, i will correspond to*
         * the position of an error in R*n*c*n*c")
  
  writef("To correct the coefficient at this position*
         * we subtract Yi defined as follows:*n*c")
  writef("Yi = Xi ** Omega(invXi) / Ldash(invXi)*n*c")

  newline()
  FOR i = 0 TO R!0 DO
  { LET j = R!0 + 1 - i // Position in R counting from the left.
    LET Xi = gf_exp2!i
    LET invXi = gf_inverse(Xi)
    LET LambdaInvXi = gf_poly_eval(Lambda, invXi)
    IF LambdaInvXi = 0 DO
    { LET OmegaInvXi = gf_poly_eval(Omega, invXi)
      LET LdashInvXi = gf_poly_eval(Ldash, invXi)
      LET q = gf_div(OmegaInvXi, LdashInvXi)
      LET Yi = gf_mul(Xi, q)
      writef("j=%i2 i=%i2 Xi=%x2 invXi=%x2 OmegaInvXi=%x2*
             * LdashInvXi=%x2 q=%x2 Yi=%x2*n*c",
             j, i, Xi, invXi, OmegaInvXi, LdashInvXi, q, Yi)
      writef("So add %x2 to %x2 at position %i2 in R to give %x2*n*c*n*c",
                     Yi,    R!j,            j,              R!j XOR Yi)
      R!j := R!j XOR Yi // Subtract Yi
    }
  }

  newline()
  writef("Corrected R: "); pr_poly(R)
  writef("Original  M: "); pr_poly(M) 

  freevec(v)
}

/*
The following shows the compilation and execution of this program.
For the larger example use: reedsolomon 1

solestreet:$ cintsys

BCPL 32-bit Cintcode System (21 Oct 2015)
0.000> c b reedsolomon
bcpl reedsolomon.b to reedsolomon hdrs BCPLHDRS t32 

BCPL (10 Oct 2014) with simple floating point
Code size =  5096 bytes of 32-bit little ender Cintcode
0.070> reedsolomon

reedsolomon entered

message:    12 34 56 78
generator:  01 3F 01 DA 20 E3 26

initial M:  12 34 56 78 00 00 00 00 00 00
scaled  G:  12 A9 12 88 7A 4D 16
new     M:  12 9D 44 F0 7A 4D 16 00 00 00
scaled  G:     9D 07 9D 3F 4A 51 23
new     M:  12 9D 43 6D 45 07 47 23 00 00
scaled  G:        43 3A 43 F7 88 5A 1F
new     M:  12 9D 43 57 06 F0 CF 79 1F 00
scaled  G:           57 11 57 99 32 67 DD
new     M:  12 9D 43 57 17 A7 56 4B 78 DD
codeword:   12 34 56 78 17 A7 56 4B 78 DD

corrupted:  12 34 00 AA 17 00 56 4B 78 DD
syndromes:  4B 7D 8B BD 54 23

Lambda(x) =  L3*x^n +  L2*x^n +  L1*x^n +  1

It can be shown that:

( S3 ) = ( S2 S1 S0 ) x ( L1 )
( S4 )   ( S3 S2 S1 )   ( L2 )
( S5 )   ( S4 S3 S2 )   ( L3 )


where S5 S4 S3 S2 S1 S0 = 4B 7D 8B BD 54 23 

( 8B ) = ( BD 54 23 ) x ( L1 )
( 7D )   ( 8B BD 54 )   ( L2 )
( 4B )   ( 7D 8B BD )   ( L3 )


This can be solved using the Berlekamp-Massey algorithm.

Lambda:    98 1B D0 01
So  L1=D0 L2=1B L3=98
and S0=23 S1=54 S2=BD S3=8B S4=7D S5=4B

BD*D0 + 54*1B + 23*98 = 8B    -- S3 = 8B
8B*D0 + BD*1B + 54*98 = 7D    -- S4 = 7D
7D*D0 + 8B*1B + BD*98 = 4B    -- S5 = 4B

If the coeff of x^i in R(x) is corrupt then Lambda(2^-i) should be zero.

The solutions of Lambda(x)=0 can be solved by trial and error

Lambda(2^- 4) = 0
Lambda(2^- 6) = 0
Lambda(2^- 7) = 0

So the error locations numbered from the left are:    4   6   7

S:           4B 7D 8B BD 54 23
Lambda:      98 1B D0 01
S x Lambda:  C8 5B D8 00 00 00 0F 26 23
Omega:       00 00 00 0F 26 23

Checking Omega

O0 = 23    23*01 = 23
O1 = 26    54*01 + 23*D0 = 26
O2 = 0F    BD*01 + 54*D0 + 23*1B = 0F

Lambda:      98 1B D0 01
The formal differential of Lambda(x) is

Ldash(x) = L1 + 2*L2*x^1 + 3*L3*x^2 + 4*L4*x^3 + 5*L5*x^4 + ...
but here 2=1+1=0,  3=1+1+1=1,  4=1+1+1+1=0, etc, so:
Ldash(x) = L1 + L3*x^2 + L5*x^4 + ...

Ldash:       98 00 D0

Let Xi = 2^i and invXi = 2^-i

If Lambda(invXi) = 0, i will correspond to the position of an error in R

To correct the coefficient at this position we subtract Yi defined as follows:
Yi = Xi * Omega(invXi) / Ldash(invXi)

j= 6 i= 4 Xi=10 invXi=D8 OmegaInvXi=09 LdashInvXi=EA q=38 Yi=A7
So add A7 to 00 at position  6 in R to give A7

j= 4 i= 6 Xi=40 invXi=36 OmegaInvXi=B8 LdashInvXi=F0 q=28 Yi=D2
So add D2 to AA at position  4 in R to give 78

j= 3 i= 7 Xi=80 invXi=1B OmegaInvXi=51 LdashInvXi=D8 q=79 Yi=56
So add 56 to 00 at position  3 in R to give 56


Corrected R:  12 34 56 78 17 A7 56 4B 78 DD
Original  M:  12 34 56 78 17 A7 56 4B 78 DD
0.020> 
*/
