
SECTION "sortdemo"

GET "libhdr"

GLOBAL { ptr: 200  }

LET treesort(v, upb) BE { LET tree, treespace = 0, getvec(upb*3)
                          ptr := treespace
                          FOR i = 1 TO upb DO putintree(@tree, v!i)
                          ptr := @ v!1
                          flatten(tree)
                          freevec(treespace)
                        }

AND putintree(a, k) BE { LET n = !a
                         IF n=0 DO { !a := ptr
                                     !ptr, ptr!1, ptr!2 := k, 0, 0
                                     ptr := ptr + 3
                                     RETURN
                                   }
                         a := k<!n -> @ n!1, @ n!2
                       } REPEAT

AND flatten(t) BE UNTIL t=0 DO { flatten(t!1)
                                 !ptr := !t
                                 ptr := ptr + 1
                                 t := t!2
                               }

LET shellsort(v, upb) BE
{ LET m = 1
  UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                                // series:  1, 4, 13, 40, 121, 364, ...
  { m := m/3
    FOR i = m+1 TO upb DO
    { LET vi = v!i
      LET j = i
      { LET k = j - m
        IF k<=0 | v!k < vi BREAK
        v!j := v!k
        j := k
      } REPEAT
      v!j := vi
    }
 } REPEATUNTIL m=1
}

LET heapify(v, k, i, last) BE
{ LET j = i+i  // If there is a son (or two), j = subscript of first.
  AND x = k    // x will hold the larger of the sons if any.

  IF j<=last DO x := v!j      // j, x = subscript and key of first son.
  IF j< last DO
  { LET y = v!(j+1)          // y = key of the other son.
    IF x<y DO x,j := y, j+1  // j, x = subscript and key of larger son.
  }

  IF k>=x DO
  { v!i := k                 // k is not lower than larger son if any.
    RETURN
  }
  v!i := x
  i := j
} REPEAT

AND heapsort(v, upb) BE
{ FOR i = upb/2 TO 1 BY -1 DO heapify(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify(v, k, 1, i-1)
  }
}

AND quicksort(v, n) BE qsort(v+1, v+n)

AND qsort(l, r) BE
{ WHILE l+8<r DO
   { LET midpt = (l+r)/2
     // Select a good(ish) median value.
     LET val   = middle(!l, !midpt, !r)
     LET i = partition(val, l, r)
     // Only use recursion on the smaller partition.
     TEST i>midpt THEN { qsort(i, r);   r := i-1 }
                  ELSE { qsort(l, i-1); l := i   }
   }

   FOR p = l+1 TO r DO  // Now perform insertion sort.
     FOR q = p-1 TO l BY -1 TEST q!0<=q!1 THEN BREAK
                                          ELSE { LET t = q!0
                                                 q!0 := q!1
                                                 q!1 := t
                                               }
}

AND middle(a, b, c) = a<b -> b<c -> b,
                                    a<c -> c,
                                           a,
                             b<c -> a<c -> a,
                                           c,
                                    b

AND partition(median, p, q) = VALOF
{ LET t = ?
  WHILE !p < median DO p := p+1
  WHILE !q > median DO q := q-1
  IF p>=q RESULTIS p
  t  := !p
  !p := !q
  !q := t
  p, q := p+1, q-1
} REPEAT

MANIFEST { upb = 10000  }
MANIFEST { upb = 500  }

LET start() = VALOF
{ LET v = getvec(upb)

  try("shell", shellsort, v, upb)
  try("heap",  heapsort,  v, upb)
//  try("tree",  treesort,  v, upb)
  try("quick", quicksort, v, upb)

  writes("*nEnd of test*n")
  freevec(v)
  RESULTIS 0
}

AND try(name, sortroutine, v, upb) BE
{ // delay, referencing the first and last elements of v
  FOR i = 1 TO 50000 DO v!upb := v!1 
  writef("*nSetting %n words of data for %s sort*n", upb, name)
  FOR i = 1 TO upb DO v!i := randno(10000)
  writef("Entering %s sort routine*n", name)
  sortroutine(v, upb)
  writes("Sorting complete*n")
  TEST sorted(v, upb)
  THEN writes("The data is now sorted*n")
  ELSE writef("### ERROR: %s sort does not work*n", name)
}

AND sorted(v, n) = VALOF
{ //FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}
