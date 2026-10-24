// Test an experimental version of quicksort that uses heapsort
// when quicksort recurses too deeply.

SECTION "heapqsort"

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
{ 
   { LET n = r-l+1 // Number of values in the current region
     LET midpt, val, i = ?, ?, ?

     IF n<10 BREAK

     midpt := (l+r)/2

     // Select a good(ish) median value.
     //val := l+25>r -> !midpt, median3(!l, !midpt, !r)

     // Select the median of three pseudo random elements
     // from the region
     val := l+25>r -> !midpt, median3(l!(maxint   MOD n),
                                      l!(maxint/3 MOD n),
                                      l!(maxint/5 MOD n))

     i := partition(val, l, r)
     // Only recurse on the smaller partition.
     TEST i>midpt THEN { qsort(i, r);   r := i-1 }
                  ELSE { qsort(l, i-1); l := i   }
   } REPEAT

   FOR p = l+1 TO r DO  // Now perform insertion sort.
     FOR q = p-1 TO l BY -1 TEST cmp(q!0, q!1)<=0 THEN BREAK
                                                  ELSE swap(q, q+1)

}

AND median3(a, b, c) = VALOF
  TEST a<=b
  THEN TEST b<=c 
       THEN          { cmpcount := cmpcount+2; RESULTIS b }
       ELSE TEST a<c
            THEN     { cmpcount := cmpcount+3; RESULTIS c }
            ELSE     { cmpcount := cmpcount+3; RESULTIS a }
  ELSE TEST b<c
       THEN TEST a<c
            THEN     { cmpcount := cmpcount+3; RESULTIS a }
            ELSE     { cmpcount := cmpcount+3; RESULTIS c }
       ELSE          { cmpcount := cmpcount+2; RESULTIS b }


AND partition(median, p, q) = VALOF
{ WHILE cmp(!p, median) < 0 DO p := p+1
  WHILE cmp(!q, median) > 0 DO q := q-1
  IF p>=q RESULTIS p
  swap(p, q)
  p, q := p+1, q-1
} REPEAT

AND heapquicksort(v, n) BE heapqsort(v+1, v+n, n>>12)

AND heapqsort(l, r, k) BE
{ LET n = r - l + 1

  IF k=0 DO
  { heapsort(l-1, n)
    RETURN
  }

  IF n <= 6 DO
  { // Perform insertion sort
    FOR p = l+1 TO r DO
      FOR q = p-1 TO l BY -1 TEST cmp(q!0, q!1)<=0 THEN BREAK
                                                   ELSE swap(q, q+1)
    RETURN
  }

  { LET midpt = (l+r)/2

    // Select a good(ish) median value.
    LET val   = l+25>r -> !midpt, median3(!l, !midpt, !r)
    LET i = partition(val, l, r)
    k := k>>1
    // Only recurse on the smaller partition.
    TEST i>midpt THEN { heapqsort(i, r,   k); r := i-1 }
                 ELSE { heapqsort(l, i-1, k); l := i   }
  }
} REPEAT

// Now follows a definition of heapsort

AND heapify(v, k, i, last) BE
{ LET p = i+i  // If there is a son (or two), j = subscript of first.
  LET s, x = ?, ?


  IF p>last DO
  { swapcount := swapcount+1
    v!i := k
    RETURN
  }
  // There is at least one son

  s := v+p
  x := s!0

  IF p<last & cmp(x, s!1)<0 DO x, p := s!1, p+1

  IF cmp(k, x)>=0 DO
  { swapcount := swapcount+1
    v!i := k
    RETURN
  }

  swapcount := swapcount+1
  v!i := x
  i := p
} REPEAT

AND heapifynew(v, k, i, last) BE
{ // First push k down the heap via the larger child
  // until a leaf is found.
  { LET p = i+i  // If there is a son (or two), j = subscript of first.
    LET s, x = ?, ?

    IF p>last BREAK  // No children
    // There is at least one son

    s := v+p
    x := s!0

    IF p<last & cmp(x, s!1) < 0 DO x, p := s!1, p+1

    swapcount := swapcount+1
    v!i := x    // Promote x
    i := p
  } REPEAT

  // Now perform the upheap operation
  // possible moving k up a small number of levels.
  WHILE i>1 DO
  { LET p = i/2 // Find the parent element.
    LET x = v!p
    IF cmp(k, x) <= 0 BREAK
    swapcount := swapcount+1
    v!i := x    // Demote x
    i := p
  }
  swapcount := swapcount+1
  v!i := k // Store k in its proper position    
} 

AND heapsort(v, upb) BE
{ //pr(v+1, upb)
  FOR i = upb/2 TO 1 BY -1 DO
    // Using heapifynew here slows it down a little. 
    heapify(v, v!i, i, upb)

  //pr(v+1, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    //pr(v+1, upb)
    heapifynew(v, k, 1, i-1)
  }
}

AND heapsortold(v, upb) BE
{ //pr(v+1, upb)
  FOR i = upb/2 TO 1 BY -1 DO
    // Using heapifynew here slows it down a little. 
    heapify(v, v!i, i, upb)
  //pr(v+1, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    //pr(v+1, upb)
    heapify(v, k, 1, i-1)
  }
}


GLOBAL { upb:300; tst  }

LET start() = VALOF
{ LET v, upb, tst, instr, seed = ?, 50_000, 1, ?, 12345
  LET argv = VEC 50

  UNLESS rdargs("upb/n,seed/n,r/s,p/s,count/s", argv, 50) DO
  { writef("")
    RETURN
  }

  IF argv!0 DO upb  := argv!0!0  // UPB
  IF argv!1 DO seed := argv!1!0  // SEED  -- Random number seed
  IF argv!2 DO tst  := 1         // R     -- Random data
  IF argv!3 DO tst  := 2         // P     -- Pathalogical data
  instr := argv!4                // COUNT -- Instruction count

  v := getvec(upb)

  try("quicksort",        quicksort,     v, upb, seed, tst, instr)
  try("heapsortold",      heapsortold,   v, upb, seed, tst, instr)
  try("heapsort",         heapsort,      v, upb, seed, tst, instr)
  try("heapquicksort",    heapquicksort, v, upb, seed, tst, instr)

  writes("*nEnd of test*n")
  freevec(v)
  RESULTIS 0
}

AND try(name, sortroutine, v, upb, seed, tst, instr) BE
{ // delay, referencing the first and last elements of v
   FOR i = 1 TO 50000 DO v!upb := v!1

   writef("*nSetting %n words of data for %s*n", upb, name)
   IF tst=1 DO setdata(v, upb, seed)
   IF tst=2 DO setpathodata(v, upb, seed)
   //pr(v+1, upb)

   writef("Entering %s routine*n", name)
   cmpcount, swapcount := 0, 0
   TEST instr
   THEN writef("Instruction count = %11i*n", instrcount(sortroutine, v, upb))
   ELSE sortroutine(v, upb)
   writef("Compare count     = %11i*n", cmpcount)
   writef("Swap count        = %11i*n", swapcount)
   //writes("Sorting complete*n")
   //pr(v+1, upb)
   TEST sorted(v, upb)
   THEN writes("The data is now sorted*n")
   ELSE writef("### ERROR: %s does not work*n", name)
}

AND setdata(v, upb, seed) BE
{  LET max = 5_000_000
   setseed(seed)
   writef("Setting random data with upb %n*n*n", max)

   FOR i = 1 TO upb DO v!i := randno(max+1)

   //FOR i = 1 TO upb DO v!i := i
   //FOR i = 1 TO upb DO v!i := -i
}

AND setpathodata(v, n) BE
{ // Set data designed to be pathologically bad for quicksort
  writef("Setting pathological data for quicksort*n")
  FOR i = 1 TO n-1 BY 2 DO v!i := i
  FOR i = 2 TO n-1 BY 2 DO v!i := i+2
  v!n := 2
}

AND sorted(v, n) = VALOF
{ FOR i = 1 TO n-1 UNLESS v!i <= v!(i+1) RESULTIS FALSE
//{ FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}

AND pr(ptr, n) BE
{ writef("*nn=%n*n", n)
IF n>1000 DO abort(9999)
  FOR i = 1 TO n DO
  { writef(" %i5", !ptr)
    ptr := ptr+1
    IF i REM 10 = 0 DO newline()
  }
  newline()
}

/*

Typical run with random data:

0> heapqsort

Setting 1000000 words of data for quicksort
Setting random data with upb 5000000

Entering quicksort routine
Compare count =  28524700
Swap count    =   5048412
Sorting complete
The data is now sorted

Setting 1000000 words of data for heapsort
Setting random data with upb 5000000

Entering heapsort routine
Compare count =  36793689
Swap count    =  19547918
Sorting complete
The data is now sorted

Setting 1000000 words of data for heapsortnew
Setting random data with upb 5000000

Entering heapsortnew routine
Compare count =  20526450
Swap count    =  19889479
Sorting complete
The data is now sorted

Setting 1000000 words of data for heapquicksort
Setting random data with upb 5000000

Entering heapquicksort routine
Compare count =  29361314
Swap count    =   7506631
Sorting complete
The data is now sorted

Setting 1000000 words of data for heapquicksortnew
Setting random data with upb 5000000

Entering heapquicksortnew routine
Compare count =  27916607
Swap count    =   7753263
Sorting complete
The data is now sorted

End of test
15280> 

Typical run with pathological data:


*/
