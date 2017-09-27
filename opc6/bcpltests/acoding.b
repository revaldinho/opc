/* This is a simple demonstration of arithmetic encoding
 * using 3-bit arithmetic.
 *
 * Implemented by Martin Richards  30 July 1998
*/

GET "libhdr"

GLOBAL {
 frq:   201
 cumf:  202
 dctab: 203
 bitv:  204
 bitp:  205
 resv:  206
 resp:  207
 data:  208
 datap: 209
 count: 210
}

MANIFEST {
  MSB = #b100
}

LET start() = VALOF
{ LET bv = VEC 50                      // for encoded
  LET rv = VEC 20                      // for decoded result
  LET dv = TABLE 1,3,2,3,3,2,2,3,2,0   // Data to encode
  frq   := TABLE 1,1,3,3
  cumf  := TABLE 0,1,2,5,8
  dctab := TABLE 0,1,2,2,2,3,3,3
  bitv, resv := bv, rv

  writef("Arithmetic encoding demo*n")

  encode(dv, bv)
  decode(bv, rv)

  RESULTIS 0
}


AND encode(dv, bv) BE
{ LET L, H = 0, 7         // Low and High end of range
  datap, bitp := dv, bv
  count := 0              // length of H=1000.. L=0111.. run

  // Main loop
  { LET s = get()         // get next character to encode
    LET range = H-L+1
    LET l = cumf!s
    LET h = cumf!(s+1)

    writef("%c(%n, %n)    L=%b3 H=%b3*n", 'A'+s-1, l, h, L, H)

    H := L + range*h/8 - 1
    L := L + range*l/8

    writef("        => L=%b3 H=%b3*n", L, H)

    WHILE ((H NEQV L)&#b100)=0 DO
    { TEST (H&4)>0
      THEN { IF count DO { wrbit(1)      // output 1000...
                           { wrbit(0)
                             count := count-1
                           } REPEATWHILE count
             }
             wrbit(1)
           }
      ELSE { IF count DO { wrbit(0)      // output 0111...
                           { wrbit(1)
                             count := count-1
                           } REPEATWHILE count
                         }
             wrbit(0)
           }
      H := #b111 & (H<<1 | 1)      // change H from abc => bc1
      L := #b111 & (L<<1)          // change L from xyz => yz0
      writef("        => L=%b3 H=%b3*n", L, H)
    }

    // H=1ax L=0by
    WHILE (H&#b10)=0 & (L&#b10)>0 DO // ie   H=10x  and  L=01y 
    { H := (H&1)<<1 | #b101          // set H = 1x1
      L := (L&1)<<1                  // set L = 0y0
      count := count + 1
      writef("        => L=%b3 H=%b3 count=%n*n", L, H, count)
    }
    IF s=0 BREAK
  } REPEAT

  IF count DO { wrbit(0)    // output 0111...
                { wrbit(1)
                  count := count-1
                } REPEATWHILE count
              }
  wrbit(0)
  wrbit(-1)    // a terminator
}

AND get() = VALOF
{ LET ch = !datap
  datap := datap+1
  RESULTIS ch
}

AND wrbit(bit) BE
{ !bitp := bit
  bitp := bitp+1
  writef("output %n", bit)
  IF count DO writef(" count=%n", count)
  newline()
}


AND decode(p, q) BE
{
  RETURN
}

