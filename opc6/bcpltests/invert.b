/*
This program attempts to find the inverse of a given nxn matrix
whose elements use GF(2^8) arithmetic.

Implemented by Martin Richards (c) June 2015

n is given as a Manifest constant in the program.

The argument -t cause trace output to be generated.

The way this program works is best described by considering
an example.  Let us find the inverse of

                ( 2 3 1 1 )
                ( 1 2 3 1 )
                ( 1 1 2 3 )
                ( 3 1 1 2 )

We first multiply it by a matrix that multiplies row 1
by the inverse of 2 (in GF(2^8)) namely 241, leaving the
other rows unchanged.

     ( 141 0 0 0 )   ( 2 3 1 1 )   ( 1 140 141 141 )
     (   0 1 0 0 ) x ( 1 2 3 1 ) = ( 1   2   3   1 )
     (   0 0 1 0 )   ( 1 1 2 3 )   ( 1   1   2   3 )
     (   0 0 0 1 )   ( 3 1 1 2 )   ( 3   1   1   2 )

Next we multiply by a matrix that adds suitably multiple of row 1 to
the other row so as to clear the non diagonal elements of column 1.

     ( 1 0 0 0 )   ( 1 140 141 141 )   ( 1 140 141 141 )
     ( 1 1 0 0 ) x ( 1   2   3   1 ) = ( 0 142 142 140 )
     ( 1 0 1 0 )   ( 1   1   2   3 )   ( 0 141 143 142 )
     ( 3 0 0 1 )   ( 3   1   1   2 )   ( 0 142 141 142 )

We now process column 2.

     ( 1   0 0 0 )   ( 1 140 141 141 )   ( 1 140 141 141 )
     ( 0 185 0 0 ) x ( 0   1   1 104 ) = ( 0   1   1 104 )
     ( 0   0 1 0 )   ( 0 141 143 142 )   ( 0 141 143 142 )
     ( 0   0 0 1 )   ( 3 142 141 142 )   ( 0 142 141 142 )

and

     ( 1 140 0 0 )   ( 1 140 141 141 )   ( 1  0  1 209 )
     ( 0   1 0 0 ) x ( 0   1   1 104 ) = ( 0  1  1 104 )
     ( 0 141 1 0 )   ( 1 141 143 142 )   ( 0  0  2 186 )
     ( 0 142 0 1 )   ( 3 142 141 142 )   ( 0  0  3   2 )

Four more matrices can be used, in a similar fashion, to eventually
generate the identity matrix.

                   ( 1 0 0 0 )
                   ( 0 1 0 0 )
                   ( 0 0 1 0 )
                   ( 0 0 0 1 )

If we call the origin matrix M and the eight tranformation matrices
A, B, C, D, E, F, G and H, then

            H x G x F x E x D x C x B x A x M = I

where I is the identity matrix. It is thus clear that

            H x G x F x E x D x C x B x A

is the inverse of M, and this is easily calculated. The method only
fails in the rare event when M has no inverse or when a zero element
is encountered on the leading diagonal. If this happens we can just
choose a slightly different M.
*/

GET "libhdr"

MANIFEST { n=4 }  // 4, 8 or 16

GLOBAL {
  m1:ug  // The nxn matrix to invert
  m2     // The inversion of m1
  m3     // Two work matrices
  m4

  tracing
}

LET initmat(m) BE
{ clearmat(m)
  SWITCHON n INTO
  { DEFAULT:
      RETURN

    CASE 4:
    { LET p = TABLE
                2,3,1,1,
                1,2,3,1,
                1,1,2,3,
                3,1,1,2
      copy(p, m1)
      RETURN
    }

    CASE 8:
    { LET p = TABLE
                2,3,4,5,6,1,1,1,
                1,2,3,4,5,6,1,1,
                1,1,2,3,4,5,6,1,
                1,1,1,2,3,4,5,6,
                6,1,1,1,2,3,4,5,
                5,6,1,1,1,2,3,4,
                4,5,6,1,1,1,2,3,
                3,4,5,6,1,1,1,2
      copy(p, m1)
      RETURN
    }

    CASE 16:
    { LET p = TABLE
                2,3,4,5,6,7,8,9,8,1,1,1,1,1,1,1,
                1,2,3,4,5,6,7,8,9,8,1,1,1,1,1,1,
                1,1,2,3,4,5,6,7,8,9,8,1,1,1,1,1,
                1,1,1,2,3,4,5,6,7,8,9,8,1,1,1,1,
                1,1,1,1,2,3,4,5,6,7,8,9,8,1,1,1,
                1,1,1,1,1,2,3,4,5,6,7,8,9,8,1,1,
                1,1,1,1,1,1,2,3,4,5,6,7,8,9,8,1,
                1,1,1,1,1,1,1,2,3,4,5,6,7,8,9,8,
                8,1,1,1,1,1,1,1,2,3,4,5,6,7,8,9,
                9,8,1,1,1,1,1,1,1,2,3,4,5,6,7,8,
                8,9,8,1,1,1,1,1,1,1,2,3,4,5,6,7,
                7,8,9,8,1,1,1,1,1,1,1,2,3,4,5,6,
                6,7,8,9,8,1,1,1,1,1,1,1,2,3,4,5,
                5,6,7,8,9,8,1,1,1,1,1,1,1,2,3,4,
                4,5,6,7,8,9,8,1,1,1,1,1,1,1,2,3,
                3,4,5,6,7,8,9,8,1,1,1,1,1,1,1,2
      copy(p, m1)
      RETURN
    }
  }
}

AND start() = VALOF
{ LET v1 = VEC n*n-1
  AND v2 = VEC n*n-1
  AND v3 = VEC n*n-1
  AND v4 = VEC n*n-1

  AND argv = VEC 50

  m1, m2, m3, m4 := v1, v2, v3, v4

// rdargs  not yet implemented for OPC6 system
//
//  UNLESS rdargs("-t/s", argv, 50) DO
//  { writef("Bad argument for invert*n")
//    RESULTIS 0
//  }
//  tracing := argv!0    // -t/s
  tracing := 1

  initmat(m1) // m1 is the matrix to invert
  setmati(m2) // m2 is the identity matrix

  newline()
  IF tracing DO
    prmat("m1", m1)

  FOR i = 0 TO n-1 DO
  { // Process column i
    // First multiply row i by the inverse of m1[i,i]
    setmati(m3)
    m3!(i*n+i) := inv(m1!(i*n+i))
    IF tracing DO
    { writef("Pre-multiply by*n*c")
      prmat("m3", m3)
    }
    matmul(m3,m1,m4)
    copy(m4,m1)
    IF tracing DO
    { writef("gives*n*c")
      prmat("m1", m1)
    }
    // Accumulate the inverse matrix
    matmul(m3,m2,m4)
    copy(m4,m2)

    // Add suitable multiples of row i to the other rows
    // to clear all elements of column i, but leaving m1[i,i]=1
    setmati(m3)
    FOR j = 0 TO n-1 DO m3!(i + j*n) := m1!(i + j*n)
    IF tracing DO
    { writef("Pre-multiply by*n*c")
      prmat("m3", m3)
    }
    matmul(m3,m1,m4)
    copy(m4,m1)
    IF tracing DO
    { writef("gives*n*c")
      prmat("m1", m1)
    }

    matmul(m3,m2,m4)
    copy(m4,m2)
  }

  IF tracing DO
  { writef("The inverse matrix is thus*n*n*c")
    prmat("m2", m2)
  }

  initmat(m1)
  matmul(m2,m1,m3)
  
  writef("Multiplying*n*n*c")
  prmat("m2", m2)
  writef("by*n*n*c")
  prmat("m1", m1)
  writef("gives*n*n*c")
  prmat("m3", m3)

  RESULTIS 0
}

AND copy(a, b) BE
{ FOR i = 0 TO n*n-1 DO b!i := a!i
}

AND clearmat(m) BE
  FOR i = 0 TO n*n-1 DO m!i := 0

AND setmati(m) BE
{ clearmat(m)
  FOR i = 0 TO n-1 DO m!(i*n+i) := 1
}

AND prmat(str, m) BE
{ //sawritef("%s*n", str)
  FOR i = 0 TO n-1 DO
  { LET r = m + i*n
    FOR j = 0 TO n-1 DO writef(" %i3", r!j)
    newline()
  }
  newline()
}

AND inv(x) = VALOF
{ FOR i = 1 TO 255 IF mul(i, x)=1 RESULTIS i
  writef("*nERROR: Cannot invert x=%n*n*n*c", x)
  abort(999)
  RESULTIS 0
}

AND mul(x, y) = VALOF
{ LET r = 0
  WHILE x DO
  { IF (x & 1) > 0 DO r := r XOR y
    x, y := x>>1, y<<1
    IF y > 255 DO y := y XOR #x11B
  }
  RESULTIS r
}

AND matmul(a, b, c) BE
{ // Set c = a * b where a, b and c are nxn matrices using GP(2^8)
  FOR i = 0 TO n-1 DO
  {
    FOR j = 0 TO n-1 DO
    { // Set the (i,j) element of c to be the inner product
      // row i of a and column j of b
      LET row = a + i*n // Left most element of row i
      AND col = b + j   // Top element of column j
      LET x = 0
      FOR k = 0 TO n-1 DO
        x := x XOR mul(row!k, col!(k*n))
      c!(i*n+j) := x
    }
  }
}

AND setvec(m, v0, v1, v2, v3,
              v4, v5, v6, v7,
              v8, v9,v10,v11,
             v12,v13,v14,v15) BE
{ LET p = @v0
  FOR i = 0 TO 15 DO m!i := p!i
}
