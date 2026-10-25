// Shifts by a variable distance (SIAL lsh and rsh), which sial2opc.py
// translates for OPC7 into whole byte shifts with bperm and a jump into a
// run of single shifts (25/10/2026). Every distance from -33 to 40 in both
// directions, for several bit patterns: as natively, a distance of 32 or
// more gives 0 and a negative distance shifts the other way. minint as a
// distance is left out: natively it leaves the value unchanged, on OPC7 it
// gives 0. Also a few constant distances, which the -o optimiser rewrites.
// OPC7 only (32 bit values).

GET "libhdr"

LET start() = VALOF
{ LET vals = TABLE #x12345678, #x87654321, -1, 1, #x80000001
  FOR i = 0 TO 4 DO
  { LET x = vals!i
    writef("x = %x8*n", x)
    FOR n = -33 TO 40 DO
      writef("%i3: %x8 %x8*n", n, x<<n, x>>n)
  }
  { LET x = #x87654321
    writef("constant: %x8 %x8 %x8 %x8 %x8 %x8*n", x<<1, x>>7, x<<8, x>>12, x<<24, x>>31)
  }
  RESULTIS 0
}
