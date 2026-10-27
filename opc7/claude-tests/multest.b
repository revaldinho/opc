// Multiply (SIAL mul, a := b * a), which on OPC7 calls __mul in
// opc7_syslib.s (rewritten 27/10/2026): the low 32 bits of the product for
// all pairs of edge values, signed, including minint, maxint and products
// that overflow. Also multiplies by small constants, the common case, and a
// long chain of multiplies. OPC7 only (32 bit values).

GET "libhdr"

LET f(x) = x

LET start() = VALOF
{ LET vs = TABLE 0, 1, -1, 2, -2, 3, 10, -10, 255, 1000, 65535, 65536, -65537,
                 46341, 123456789, -987654321, #x7FFFFFFF, #x80000000, #x80000001
  LET nv = 19
  LET x = 1
  FOR i = 0 TO nv-1 DO
  { FOR j = 0 TO nv-1 DO writef(" %n", f(vs!i) * f(vs!j))
    newline()
  }
  FOR i = 0 TO nv-1 DO
  { LET v = vs!i
    writef("%n: %n %n %n %n %n*n", v, v*3, v*10, v*(-7), 100*v, v*v)
  }
  FOR i = 1 TO 1000 DO x := x * 69069 + i       // overflowing chain
  writef("chain %n*n", x)
  RESULTIS 0
}
