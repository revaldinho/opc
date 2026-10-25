// / and MOD by constant powers of 2, which sial2opc.py -o translates inline
// (25/10/2026) as shifts and a mask instead of calls of the divide routines.
// BCPL / truncates towards zero and MOD takes the sign of the dividend, so
// negative dividends are the interesting cases. x/n and id(x)/n give the
// two SIAL forms (l Kn and atbl Kn before div/mod). 16 bit values and
// divisors up to 2**14, for OPC6 and OPC7.

GET "libhdr"

LET id(x) = x

LET start() = VALOF
{ LET xs = TABLE 0, 1, -1, 3, -3, 7, -7, 100, -100, 255, -256, 1000, -1001, 16383, -16384, 32767, -32767, -32768
  FOR i = 0 TO 17 DO
  { LET x = xs!i
    writef("x = %n*n", x)
    writef("%i8: %n %n %n %n*n", 1, x/1, x MOD 1, id(x)/1, id(x) MOD 1)
    writef("%i8: %n %n %n %n*n", 2, x/2, x MOD 2, id(x)/2, id(x) MOD 2)
    writef("%i8: %n %n %n %n*n", 4, x/4, x MOD 4, id(x)/4, id(x) MOD 4)
    writef("%i8: %n %n %n %n*n", 8, x/8, x MOD 8, id(x)/8, id(x) MOD 8)
    writef("%i8: %n %n %n %n*n", 16, x/16, x MOD 16, id(x)/16, id(x) MOD 16)
    writef("%i8: %n %n %n %n*n", 32, x/32, x MOD 32, id(x)/32, id(x) MOD 32)
    writef("%i8: %n %n %n %n*n", 64, x/64, x MOD 64, id(x)/64, id(x) MOD 64)
    writef("%i8: %n %n %n %n*n", 128, x/128, x MOD 128, id(x)/128, id(x) MOD 128)
    writef("%i8: %n %n %n %n*n", 256, x/256, x MOD 256, id(x)/256, id(x) MOD 256)
    writef("%i8: %n %n %n %n*n", 512, x/512, x MOD 512, id(x)/512, id(x) MOD 512)
    writef("%i8: %n %n %n %n*n", 1024, x/1024, x MOD 1024, id(x)/1024, id(x) MOD 1024)
    writef("%i8: %n %n %n %n*n", 2048, x/2048, x MOD 2048, id(x)/2048, id(x) MOD 2048)
    writef("%i8: %n %n %n %n*n", 4096, x/4096, x MOD 4096, id(x)/4096, id(x) MOD 4096)
    writef("%i8: %n %n %n %n*n", 8192, x/8192, x MOD 8192, id(x)/8192, id(x) MOD 8192)
    writef("%i8: %n %n %n %n*n", 16384, x/16384, x MOD 16384, id(x)/16384, id(x) MOD 16384)
  }
  RESULTIS 0
}
