GET "libhdr"

// writef formats: widths written before the letter (%11i), single
// character widths after it (%i5, %ib), %d and %n.mD (added to the OPC
// bcpllib writef 23/10/2026). Values fit in 16 bits for OPC6 and OPC7.

LET start() = VALOF
{ writef("[%11i] [%11i] [%i5] [%5i] [%ib] [%i3]*n", 12345, -321, 42, 42, 7, 9)
  writef("[%2x] [%x2] [%4x] [%12x] [%3o] [%o3] [%10b] [%8z] [%z4]*n",
          #xAB, #xAB, -1, #x1234, 8, 8, 5, -42, 7)
  writef("[%d3] [%d6] [%6d] [%n] [%5s] [%s] [%c] 100%%*n",
          -77, -77, 123, 99, "ab", "cd", 'Q')
  writef("[%6.2d] [%6.2d] [%9.3d] [%5.1d] [%4.0d] [%7.3d] [%7.3d]*n",
          1234, -1234, 12345, 7, 56, 5, -5)
  writef("%11i items, %i3 left*n", 30000, 2)
  RESULTIS 0
}
