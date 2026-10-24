// Test an experimental version of quicksort that partitions
// into 4 regions.

SECTION "nqsort"

GET "libhdr"

GLOBAL {
  pr:ug
  cmpcount
  swapcount
}

LET cmp(x, y) = VALOF
{ cmpcount := cmpcount+1
//  writef("cmp: p=%n q=%n  !p=%n !q=%n*n", p, q, !p, !q)
// abort(1000)
 
  RESULTIS x - y
}

AND swap(p, q) BE
{ LET t = !p
  !p := !q
  !q:= t
  swapcount := swapcount+1
}

// Conventional quicksort
LET quicksort(v, n) BE qsort(v+1, v+n)

AND qsort(l, r) BE
{ WHILE l+6<r DO
   { LET a = (3*l+r)/4
     LET midpt = (l+r)/2
     LET c = (l+3*r)/4

     // Select a good(ish) median value.
     //LET val   = l+25>r -> !midpt, median3(!l, !midpt, !r)
     LET val   = l+25>r -> !midpt, median5(!l, !a, !midpt, !c, !r)
     LET i = partition(val, l, r)
     // Only recurse on the smaller partition.
     TEST i>midpt THEN { qsort(i, r);   r := i-1 }
                  ELSE { qsort(l, i-1); l := i   }
   }

   FOR p = l+1 TO r DO  // Now perform insertion sort.
     FOR q = p-1 TO l BY -1 TEST cmp(q!0, q!1)<=0 THEN BREAK
                                                  ELSE swap(q, q+1)

}

//AND median5(a, b, c, d, e) = VALOF
AND median5(c, d, a, e, b) = VALOF // fewest comparisons if abcde sorted
// Find the median of 5 values (in 5.866 comparisons on average)
  TEST cmp(a,b)<0
  THEN TEST cmp(a,c)<0
       THEN TEST cmp(b,c)<0
            THEN TEST cmp(b,d)<0
                 THEN TEST cmp(b,e)<0
                      THEN TEST cmp(c,d)<0
                           THEN TEST cmp(c,e)<0
                                THEN RESULTIS c  // 12345 12354
                                ELSE RESULTIS e  // 12453
                           ELSE TEST cmp(d,e)<0
                                THEN RESULTIS d  // 12435 12534
                                ELSE RESULTIS e  // 12543
                      ELSE RESULTIS b            // 13452 13542 23451 23541
                 ELSE TEST cmp(b,e)<0
                      THEN RESULTIS b            // 13425 13524 23415 23514
                      ELSE TEST cmp(a,d)<0
                           THEN TEST cmp(d,e)<0
                                THEN RESULTIS e  // 14523
                                ELSE RESULTIS d  // 14532 24531
                           ELSE TEST cmp(a,e)<0
                                THEN RESULTIS e  // 24513
                                ELSE RESULTIS a  // 34512 34521
            ELSE TEST cmp(c,d)<0
                 THEN TEST cmp(c,e)<0
                      THEN TEST cmp(b,d)<0
                           THEN TEST cmp(b,e)<0
                                THEN RESULTIS b  // 13245 13254
                                ELSE RESULTIS e  // 14253
                           ELSE TEST cmp(d,e)<0
                                THEN RESULTIS d  // 15235 15234
                                ELSE RESULTIS e  // 15243
                      ELSE RESULTIS c            // 14352 15342 24351 25341
                 ELSE TEST cmp(c,e)<0
                      THEN RESULTIS c            // 14325 15324 24315 25314
                      ELSE TEST cmp(a,d)<0
                           THEN TEST cmp(d,e)<0
                                THEN RESULTIS e  // 15423
                                ELSE RESULTIS d  // 15432 25431
                           ELSE TEST cmp(a,e)<0
                                THEN RESULTIS e  // 25413
                                ELSE RESULTIS a  // 35412 35421
       ELSE TEST cmp(a,d)<0
            THEN TEST cmp(a,e)<0
                 THEN TEST cmp(b,d)<0
                      THEN TEST cmp(b,e)<0
                           THEN RESULTIS b  // 23145 23154
                           ELSE RESULTIS e  // 24153
                      ELSE TEST cmp(d,e)<0
                           THEN RESULTIS d  // 24135 25134
                           ELSE RESULTIS e  // 25143
                 ELSE RESULTIS a            // 34152 34251 35142 35241
            ELSE TEST cmp(a,e)<0
                 THEN RESULTIS a            // 34125 34215 35124 35214
                 ELSE TEST cmp(c,d)<0
                      THEN TEST cmp(d,e)<0
                           THEN RESULTIS e  // 45123
                           ELSE RESULTIS d  // 45132 45231
                      ELSE TEST cmp(c,e)<0
                           THEN RESULTIS e  // 45213
                           ELSE RESULTIS c  // 45312 45321

  ELSE TEST cmp(a,c)<0
       THEN TEST cmp(a,d)<0
            THEN TEST cmp(a,e)<0
                 THEN TEST cmp(c,d)<0
                      THEN TEST cmp(c,e)<0
                           THEN RESULTIS c  // 21345 21354
                           ELSE RESULTIS e  // 21453
                      ELSE TEST cmp(d,e)<0
                           THEN RESULTIS d  // 21435 21534
                           ELSE RESULTIS e  // 21543
                 ELSE RESULTIS a            // 31452 31542 32451 32541
            ELSE TEST cmp(a,e)<0
                 THEN RESULTIS a            // 31425 31524 32415 32514
                 ELSE TEST cmp(b,d)<0
                      THEN TEST cmp(d,e)<0
                           THEN RESULTIS e  // 41523
                           ELSE RESULTIS d  // 41532 42531
                      ELSE TEST cmp(b,e)<0
                           THEN RESULTIS e  // 42513
                           ELSE RESULTIS b  // 43512 43521
       ELSE TEST cmp(b,c)<0
            THEN TEST cmp(c,d)<0
                 THEN TEST cmp(c,e)<0
                      THEN TEST cmp(a,d)<0
                           THEN TEST cmp(a,e)<0
                                THEN RESULTIS a  // 31245 31254
                                ELSE RESULTIS e  // 41253
                           ELSE TEST cmp(d,e)<0
                                THEN RESULTIS d  // 41235 51234
                                ELSE RESULTIS e  // 51243
                      ELSE RESULTIS c            // 41352 42351 51342 52341
                 ELSE TEST cmp(c,e)<0
                      THEN RESULTIS c            // 41325 42315 51324 52314
                      ELSE TEST cmp(b,d)<0
                           THEN TEST cmp(d,e)<0
                                THEN RESULTIS e  // 51423
                                ELSE RESULTIS d  // 51432 52431
                           ELSE TEST cmp(b,e)<0
                                THEN RESULTIS e  // 52413
                                ELSE RESULTIS b  // 53412 53421
            ELSE TEST cmp(b,d)<0
                 THEN TEST cmp(b,e)<0
                      THEN TEST cmp(a,d)<0
                           THEN TEST cmp(a,e)<0
                                THEN RESULTIS a  // 32145 32154
                                ELSE RESULTIS e  // 42153
                           ELSE TEST cmp(d,e)<0
                                THEN RESULTIS d  // 42135 52134
                                ELSE RESULTIS e  // 52143
                      ELSE RESULTIS b            // 43152 43251 53142 53241
                 ELSE TEST cmp(b,e)<0
                      THEN RESULTIS b            // 43125 43215 53214 53214
                      ELSE TEST cmp(c,d)<0
                           THEN TEST cmp(d,e)<0
                                THEN RESULTIS e  // 54123
                                ELSE RESULTIS d  // 54132 54231
                           ELSE TEST cmp(c,e)<0
                                THEN RESULTIS e  // 54213
                                ELSE RESULTIS c  // 54312 54321

AND truemedian5(a,b,c,d,e) = VALOF
{ FOR p = @b TO @e DO
  { FOR q = p-1 TO @a BY -1 DO
    { LET x, y = q!0, q!1
      IF x<=y BREAK
      q!0, q!1 := y, x
    }
  }
  RESULTIS c
}

AND median3(a, b, c) = cmp(a, b)<0 -> cmp(b, c)<0 -> b,
                                     cmp(a, c)<0 -> c,
                                                    a,
                      cmp(b, c)<0 -> cmp(a, c)<0 -> a,
                                                    c,
                                                    b

AND partition(median, p, q) = VALOF
{ LET t = ?
  WHILE cmp(!p, median) < 0 DO p := p+1
  WHILE cmp(!q, median) > 0 DO q := q-1
  IF p>=q RESULTIS p
  swap(p, q)
  p, q := p+1, q-1
} REPEAT






LET nquicksort(v, n) BE nqsort(v+1, v+n)

AND nqsort(l, r) BE
{ { LET sep = (r-l)/15
    LET lim = sep*10  // = 2/3 n
    LET a, b, c, d, e = l, ?, ?, ?, r+1 // The partition points

//writef("nqsort: n=%n  sep=%n*n", r-l+1, sep)
//pr(l, r-l+1)
//abort(1111)
    IF sep<1 BREAK // Use insertion sort

    // Collect 15 equally spaced elements
    FOR i = 1 TO 14 DO swap(l+i, l+i*sep)
    nqsort(l, l+14) // Sort these elements
    // Partition into 4 regions using 3 pivot values
    npartition(l!3, l!7, l!11, l, r, @b)
    // a-b, b-c, c-d, d-e are the partitions

    r := 0 // Only iterate is a region is larger than 3/4 n

    TEST b-a > lim THEN l, r := a, b-1
                   ELSE nqsort( a, b-1)
    TEST c-b > lim THEN l, r := b, c-1
                   ELSE nqsort( b, c-1)
    TEST d-c > lim THEN l, r := c, d-1
                   ELSE nqsort( c, d-1)
    TEST e-d > lim THEN l, r := d, e-1
                   ELSE nqsort( d, e-1)

   } REPEATUNTIL r=0

   FOR p = l+1 TO r DO  // Now perform insertion sort.
     FOR q = p-1 TO l BY -1 TEST cmp(q!0, q!1)<=0 THEN BREAK
                                                  ELSE swap(q, q+1)

}

AND npartition(m1, m2, m3, p, q, r) = VALOF
// Partition p to q into 4 regions, setting the
// partition points in r!0, r!1 and r!2

// On return
//   elements in  p  to r!0-1 are all <= m1
//   elements in r!0 to r!1-1 are all >=m1 and <= m2
//   elements in r!1 to r!2-1 are all >=m2 and <= m3
//   elements in r!2 to  r    are all >=m3

// An element with value m2 is in the original region

{ LET a, b, c, d = p, p, q, q
 
//writef("npartition: m1=%n, m2=%n, m3=%n*n", m1, m2, m3)

  { WHILE cmp(!b, m2) < 0 DO
    { IF cmp(!b, m1) < 0 DO { swap(a, b); a := a+1 }
      b := b+1
    }

    WHILE cmp(!c, m2) > 0 DO
    { IF cmp(!c, m3) > 0 DO { swap(c, d); d := d-1 }
      c := c-1
    }

    IF b>=c BREAK

    // b<c and !b <= m2 <= !c
    swap(b, c)
    IF cmp(!b, m1) < 0 DO { swap(a, b); a := a+1 }
    IF cmp(!c, m3) > 0 DO { swap(c, d); d := d-1 }
    b, c := b+1, c-1
  } REPEAT

  // Store the partition points
  r!0, r!1, r!2 := a, b, d+1
//pr(p, q-p+1)
//writef("npartition: r0=%n, r1=%n, r2=%n*n", a-p, b-p, d-p+1)
//abort(1000)
}


MANIFEST { upb = 100_000  }
//MANIFEST { upb = 30  }

LET start() = VALOF
{ LET v = getvec(upb)

  testmedian()

  try("quicksort",  quicksort,  v, upb)
//  try("nquicksort", nquicksort, v, upb)

  writes("*nEnd of test*n")
  freevec(v)
  RESULTIS 0
}

AND try(name, sortroutine, v, upb) BE
{ // delay, referencing the first and last elements of v
   FOR i = 1 TO 50000 DO v!upb := v!1 
   writef("*nSetting %n words of data for %s*n", upb, name)
   setseed(123456)

   FOR i = 1 TO upb DO v!i := randno(1_000_000_000)
   //FOR i = 1 TO upb DO v!i := randno(1_000)
   //FOR i = 1 TO upb DO v!i := i
   //FOR i = 1 TO upb DO v!i := -i

   writef("Entering %s routine*n", name)
   cmpcount, swapcount := 0, 0
   //writef("Instruction count = %n*n", instrcount(sortroutine, v, upb))
   sortroutine(v, upb)
   writef("Compare count = %n*n", cmpcount)
   writef("Swap count    = %n*n", swapcount)
   writes("Sorting complete*n")
   TEST sorted(v, upb)
   THEN writes("The data is now sorted*n")
   ELSE writef("### ERROR: %s does not work*n", name)
}

AND sorted(v, n) = VALOF
{ FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}

AND pr(ptr, n) BE
{ FOR i = 1 TO n DO
  { writef(" %i5", !ptr)
    ptr := ptr+1
    IF i REM 10 = 0 DO newline()
  }
  newline()
}

AND testmedian() BE
{ FOR a = 1 TO 5 DO
    FOR b = 1 TO 5 DO
      FOR c = 1 TO 5 DO
        FOR d = 1 TO 5 DO
          FOR e = 1 TO 5 DO
          { LET m = median5(a, b, c, d, e)
            //writef("Median of %n %n %n %n %n is %n*n",
            //        a, b, c, d, e, m)
            UNLESS m=truemedian5(a,b,c,d,e) DO
            { writef("######### ERROR: should be %n*n", truemedian5()) 
              abort(999)
            }
          }
}
