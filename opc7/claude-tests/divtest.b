// Division and MOD for dividends of every byte length, including those just
// below and above each byte boundary, zero, maxint and minint, by divisors
// small and large, of both signs. The OPC7 divide routine skips leading zero
// bytes of the dividend (25/10/2026), so the edge cases are at the boundaries.
// OPC7 only (32 bit values).

GET "libhdr"

LET start() = VALOF
{ LET as = TABLE 0, 1, 7, 255, 256, 257, 65535, 65536, 65537,
                 #xFFFFFF, #x1000000, #x1000001, #x7FFFFFFF, #x80000000,
                 -1, -255, -256, -65536, -#x1000000, 1234567, -7654321
  AND bs = TABLE 1, 2, 7, 10, 255, 256, 10000, 65536, #x1000000,
                 #x40000001, #x7FFFFFFF, -1, -7, -256, -10000, #x80000000
  LET na, nb = 21, 16
  FOR i = 0 TO na-1 FOR j = 0 TO nb-1 DO
  { LET a, b = as!i, bs!j
    // minint / -1 overflows (and traps natively), so leave it out
    UNLESS a = #x80000000 & b = -1 DO
      writef("%n %n: %n %n*n", a, b, a/b, a MOD b)
  }
  RESULTIS 0
}
