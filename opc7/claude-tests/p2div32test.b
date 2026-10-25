// / and MOD by constant powers of 2 for 32 bit dividends, and divisors up to
// 2**23, where the rounding constant and mask need the large constant register.
// See p2divtest.b. OPC7 only.

GET "libhdr"

LET id(x) = x

LET start() = VALOF
{ LET xs = TABLE 0, 1, -1, 123456789, -987654321, #x7FFFFFFF, #x80000000, #x80000001, 8388607, -8388608, #x00FFFFFF, -#x01000001
  FOR i = 0 TO 11 DO
  { LET x = xs!i
    writef("x = %n*n", x)
    writef("%i8: %n %n %n %n*n", 2, x/2, x MOD 2, id(x)/2, id(x) MOD 2)
    writef("%i8: %n %n %n %n*n", 4, x/4, x MOD 4, id(x)/4, id(x) MOD 4)
    writef("%i8: %n %n %n %n*n", 128, x/128, x MOD 128, id(x)/128, id(x) MOD 128)
    writef("%i8: %n %n %n %n*n", 8192, x/8192, x MOD 8192, id(x)/8192, id(x) MOD 8192)
    writef("%i8: %n %n %n %n*n", 32768, x/32768, x MOD 32768, id(x)/32768, id(x) MOD 32768)
    writef("%i8: %n %n %n %n*n", 65536, x/65536, x MOD 65536, id(x)/65536, id(x) MOD 65536)
    writef("%i8: %n %n %n %n*n", 131072, x/131072, x MOD 131072, id(x)/131072, id(x) MOD 131072)
    writef("%i8: %n %n %n %n*n", 1048576, x/1048576, x MOD 1048576, id(x)/1048576, id(x) MOD 1048576)
    writef("%i8: %n %n %n %n*n", 8388608, x/8388608, x MOD 8388608, id(x)/8388608, id(x) MOD 8388608)
  }
  RESULTIS 0
}
