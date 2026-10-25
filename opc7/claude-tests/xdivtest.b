// The reversed SIAL divide operations xdiv (a := a / b) and xmod
// (a := a MOD b), which the compiler generates when A and B already hold the
// operands the other way round: after comparing them, or for the result of
// one call divided by another. On OPC7 they call __xdiv and __xmod
// (rewritten 25/10/2026). Signed values including minint and maxint, and an
// xmod used as a byte index. OPC7 only (32 bit values).

GET "libhdr"

LET f(x) = x

AND qr(a, b) = a<b -> b / a, a / b             // like dv in bcpltests/modarith.b
AND rm(a, b) = a<b -> b MOD a, a MOD b

LET start() = VALOF
{ LET vs = TABLE 1, -1, 2, -3, 7, -10, 100, -255, 65536, -65537,
                 #x7FFFFFFF, #x80000001, 123456789, -987654321
  LET nv = 14
  LET s = VEC 64/bytesperword
  FOR i = 0 TO nv-1 FOR j = 0 TO nv-1 DO
  { LET a, b = vs!i, vs!j
    writef("%n %n: %n %n %n %n*n", a, b, f(a)/f(b), f(a) MOD f(b), qr(a, b), rm(a, b))
  }
  FOR i = 0 TO 63 DO s%i := 0
  FOR i = 0 TO 63 DO s%(f(i*7) MOD f(64)) := 'A' + i MOD 26
  FOR i = 0 TO 63 DO wrch(s%i)
  newline()
  RESULTIS 0
}
