/*
This contains experimental sorting algorithm.
Implemented in BCPL by Martin Richards (c) November 2005

*/

SECTION "mrsort"

GET "libhdr"

//MANIFEST { upb = 100_000; valupb = upb  }
//MANIFEST { upb = 5_000; valupb = upb  }
MANIFEST { upb = 10; valupb = 99 }


GLOBAL {
  pr:ug
  cmpcount
  swapcount
  data
}

LET cmp(x, y) = VALOF
{ cmpcount := cmpcount+1
//writef("cmp: %i5 with %i5*n", x, y)
  RESULTIS x - y
}

AND swap(p, q) BE
{ LET t = !p
//  pr(data+1, upb)
//writef("swap: %i2:%i5 and %i3:%i5*n", p-data-1, t, q-data-1, !q)
  !p := !q
  !q:= t
  swapcount := swapcount+1
}

LET quicksort(v, n) BE qsort(v+1, v+n)

AND qsort(l, r) BE
{ WHILE l+6<r DO
   { LET a = (3*l+r)/4
     LET midpt = (l+r)/2
     LET c = (l+3*r)/4

     // Select a good(ish) median value of 5 elements.
     LET val   = l+25>r -> !midpt,  median5(l, a, midpt, c, r)
       LET i = partition(val, l, r)
     // Only recurse on the smaller partition.
     TEST i>midpt THEN { qsort(i, r);   r := i-1 }
                  ELSE { qsort(l, i-1); l := i   }
   }

   // Perform insertion sort on 25 or fewer elements.
   FOR p = l+1 TO r DO
     FOR q = p-1 TO l BY -1 TEST cmp(q!0, q!1)<=0 THEN BREAK
                                                  ELSE swap(q, q+1)
}

AND median5(p, q, r, s, t) = VALOF
{ LET a, b, c, d, e = !r, !s, !p, !t, !q // fewest comparisons if already sorted
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
}

AND partition(median, p, q) = VALOF
{ LET t = ?
  WHILE cmp(!p, median) < 0 DO p := p+1
  WHILE cmp(!q, median) > 0 DO q := q-1
  IF p>=q RESULTIS p
  swap(p, q)
  p, q := p+1, q-1
} REPEAT

// Heapsort (modified to only update the array using swap.

LET downheap(v, i, last) BE
{ LET j = i+i  // j = subscript of the left child, if any.
  LET p = v+i  // Pointer to the parent
  LET q = v+j  // Pointer to the left child, if any.

  IF j<last DO
  { // There are two children
    TEST cmp(q!0, q!1) >= 0
    THEN { // The left child is the larger
           IF cmp(p!0, q!0)>=0 RETURN
           swap(p, q)
           i := j
         }
    ELSE { // The right child is the larger
           IF cmp(p!0, q!1)>=0 RETURN
           swap(p, q+1)
           i := j+1
         }
    LOOP
  }

  IF j>last RETURN

  // There is only one child
  IF cmp(p!0, q!0)>=0 RETURN
  swap(p, q)
  i := j
} REPEAT

LET downheap1(v, i, last) BE
// This is an alternative implementation of downheap the
// pushes the root element all the way to a leaf and then
// performs upheap on it.
{ LET r = i // The root of this sub-tree

  { LET j = i+i  // j = subscript of the left child, if any.
    LET p = v+i  // Pointer to the parent
    LET q = v+j  // Pointer to the left child, if any.

    IF j<last DO
    { // There are two children
      TEST cmp(q!0, q!1) >= 0
      THEN { // The left child is the larger
             swap(p, q)
             i := j
           }
      ELSE { // The right child is the larger
             swap(p, q+1)
             i := j+1
           }
      LOOP
    }

    IF j>last BREAK

    // j=last so there is only one child.
    swap(p, q)
    i := j
  } REPEAT

  // Now perform upheap

  UNTIL i=r DO
  { LET j = i/2  // j is the position of the parent
    IF cmp(v!j, v!i)>=0 BREAK
    swap(v+j, v+i)
    i := j
  }
}

AND heapsort(v, upb) BE
{ FOR i = upb/2 TO 1 BY -1 DO
    downheap(v, i, upb) // downheap is slightly better here.

  FOR i = upb TO 2 BY -1 DO
  { swap(v+1, v+i)
    downheap(v, 1, i-1) // downheap1 is much better here.
  }
}

// mr mergesort version 1

LET mmsort(v, upb) BE ms(v+1, v+upb)

AND ms(l, r) BE TEST r-l<5
THEN { // Perform insertion sort on 5 or fewer elements.
//writef("ms: insertion sort l=%n r=%n*n", l-data-1, r-data-1)
//pr(data+1, upb)
       FOR p = l+1 TO r DO
       FOR q = p-1 TO l BY -1 TEST cmp(q!0, q!1)<=0 THEN BREAK
                                                    ELSE swap(q, q+1)
//pr(data+1, upb)
     }
ELSE { LET t = (l+r)/2  // Midpoint of region
       ms(l, t-1)
       ms(t, r)
       mergeuu(l, t, r)
     }

AND mergeuu(l, t, r) BE
{ // Elements from l to t-1 are sorted up.
  // Elements from t to r are sorted up.
  // On return l to r is sorted up.

// Check input
//LET error = FALSE
//FOR a = l TO t-2 UNLESS a!0<=a!1 DO error := TRUE
//FOR a = t TO r-1 UNLESS a!0<=a!1 DO error := TRUE
//IF error DO
//{ writef("mergeuu: error l=%n t=%n r=%n*n", l-data-1, t-data-1, r-data-1)
//  pr(data+1, upb)
//  abort(999)
//}
// End of check

  IF l<t<=r DO
  { //
    //               *-.         *                     *         *
    //             *---+-.     *                         *     *
    //           *-----+-+-. *                             * *
    //         *       | | *          =>       * *
    //       *         | *                   *     *
    //     *           *                   *         *
    //     l           t         r         l     p     t   q     r
    LET p = t-1
    LET q = t
    WHILE l<=p & q<=r & cmp(!p, !q)>0 DO
    { swap(p, q)
      p, q := p-1, q+1
    }

//pr(data+1, upb)
//abort(1111)
    mergeud(l, p+1, t-1)
    mergedu(t,   q,   r)
    RETURN
  }

  // l to r is already sorted up
//writef("mergeuu: l=%n r=%n already sorted up*n", l-data-1, r-data-1)
}

AND mergeud(l, t, r) BE
{ // Elements from l to t-1 are sorted up.
  // Elements from t to r are sorted down.
  // On return l to r is sorted up.

// Check input
//LET error = FALSE
//FOR a = l TO t-2 UNLESS a!0<=a!1 DO error := TRUE
//FOR a = t TO r-1 UNLESS a!0>=a!1 DO error := TRUE
//IF error DO
//{ writef("mergeud: error l=%n t=%n r=%n*n", l-data-1, t-data-1, r-data-1)
//  pr(data+1, upb)
//  abort(999)
//}
// End of check

//IF t>r DO writef("mergeud: already sorted up*n")
  IF t>r RETURN // Already sorted up

  IF t>l DO
  { //
    //               * *                              *         *
    //             * |   *                              *     *
    //           * | |     *                              * *
    //         * .-|-|-------*       =>       * *
    //       *     .-|---------*            *     *
    //     *         .-----------*        *         *
    //     l           t         r        l   p       t   q     r
    LET p = t-1
    LET q = r
    WHILE l<=p & t<=q & cmp(!p, !q)>0 DO
    { swap(p, q)
      p, q := p-1, q-1
    }
//pr(data+1, upb)
//abort(2222)
    mergeud(l, p+1, t-1)
    mergedu(t, q+1,   r)
    RETURN
  }

  // l to r is already sorted down so reverse the elements.
//writef("mergeud: already sorted down, so reverse*n")
  UNTIL l>=r DO { swap(l, r); l:=l+1; r :=r-1 }
//pr(data+1, upb)
//abort(2222)
}

AND mergedu(l, t, r) BE
{ // Elements, if any, from l to t-1 are sorted down.
  // Elements, if any, from t to r are sorted up.
  // On return l to r sorted up.

// Check input
//LET error = FALSE
//FOR a = l TO t-2 UNLESS a!0>=a!1 DO error := TRUE
//FOR a = t TO r-1 UNLESS a!0<=a!1 DO error := TRUE
//IF error DO
//{ pr(data+1, upb)
//  writef("mergedu: l=%n t=%n r=%n*n", l-data-1, t-data-1, r-data-1)
//  abort(999)
//}
// End of check

//IF l=t DO writef("mergeud: already sorted up*n")
  IF l=t RETURN // l to r already sorted up

  IF t<=r DO
  { // l<t<=r holds
    //
    //     *-----------.         *                     *         *
    //       *---------|-.     *                         *     *
    //         *-------|-|-. *                             * *
    //           *     | | *          =>       * *
    //             *   | *                   *     *
    //               * *                   *         *
    //     l           t         r         l     p     t   q     r
    LET p = l
    LET q = t
    WHILE p<t & q<=r & cmp(!p, !q)>0 DO
    { swap(p, q)
      p, q := p+1, q+1
    }
//pr(data+1, upb)
//abort(3333)
    mergeud(l, p, t-1)
    mergedu(t, q, r)
    RETURN
  }

  // l to r is already sorted down, so reverse the elements
//writef("mergeud: already sorted down, so reverse*n")
  UNTIL l>=r DO { swap(l, r); l:=l+1; r :=r-1 }
//pr(data+1, upb)
//abort(3333)
}


// mr mergesort version 2 -- Under development #####################

LET mmsort2(v, upb) BE ms2(v+1, v+upb)

AND ms2(l, r) BE TEST r-l<5
THEN { // Perform insertion sort on 5 or fewer elements.
//writef("ms: insertion sort l=%n r=%n*n", l-data-1, r-data-1)
//pr(data+1, upb)
       FOR p = l+1 TO r DO
       FOR q = p-1 TO l BY -1 TEST cmp(q!0, q!1)<=0 THEN BREAK
                                                    ELSE swap(q, q+1)
//pr(data+1, upb)
     }
ELSE { LET t = (l+r)/2  // Midpoint of region
       ms2(l, t-1)
       ms2(t, r)
       mergeuu2(l, t, r)
     }

AND mergeuu2(l, t, r) BE
{ // Elements from l to t-1 are sorted up.
  // Elements from t to r are sorted up.
  // On return l to r is sorted up.


// Check input
LET error = FALSE
FOR a = l TO t-2 UNLESS a!0<=a!1 DO error := TRUE
FOR a = t TO r-1 UNLESS a!0<=a!1 DO error := TRUE
IF error DO
{ writef("mergeuu: error l=%n t=%n r=%n*n", l-data-1, t-data-1, r-data-1)
  pr(data+1, upb)
  abort(999)
}
// End of check

  IF l<t<=r DO
  { LET m = (l+m)/2
    //
    //               *-.         *                     *         *
    //             *---+-.     *                         *     *
    //           *-----+-+-. *                             * *
    //         *       | | *          =>       * *
    //       *         | *                   *     *
    //     *           *                   *         *
    //     l           t         r         l     p     t   q     r
    LET p = t-1
    LET q = t
    WHILE l<=p & q<=r & cmp(!p, !q)>0 DO
    { swap(p, q)
      p, q := p-1, q+1
    }

//pr(data+1, upb)
//abort(1111)
    mergeud2(l, p+1, t-1)
    mergedu2(t,   q,   r)
    RETURN
  }

  // l to r is already sorted up
//writef("mergeuu: l=%n r=%n already sorted up*n", l-data-1, r-data-1)
}

AND mergeud2(l, t, r) BE
{ // Elements from l to t-1 are sorted up.
  // Elements from t to r are sorted down.
  // On return l to r is sorted up.

// Check input
LET error = FALSE
FOR a = l TO t-2 UNLESS a!0<=a!1 DO error := TRUE
FOR a = t TO r-1 UNLESS a!0>=a!1 DO error := TRUE
IF error DO
{ writef("mergeud: error l=%n t=%n r=%n*n", l-data-1, t-data-1, r-data-1)
  pr(data+1, upb)
  abort(999)
}
// End of check

//IF t>r DO writef("mergeud: already sorted up*n")
  IF t>r RETURN // Already sorted up

  IF t>l DO
  { LET m = (l+r)/2
    TEST m<=t
    THEN { // Reverse elements of the smaller region
           LET m1 = (l+t)/2 // Mid point of larger region
           
           //
           //               *                              *
           //             * .-*                          *   *
           //           * |                                    *
           //         * . .-----*       =>         *   *
           //       *   |                *       *
           //     *     .---------*            *     *    
           //     l   m1      t   r            l   m1    x t   r
           LET p = m1+1
           LET q = r
           WHILE p<q DO
           { swap(p, q)
             p, q := p+1, q-1
           }
           t := m1+1+r-t
           // Find position of smallest element in m to t that
           // is >= element at m the make appropriate calls of mergeuu2
           // and mergeud2.

           FOR x = m+1 TO t IF cmp(!p, !t)>=0 DO
           {
//pr(data+1, upb)
//abort(2222)
             mergeuu2(l, m1+1, x-1)
             mergedu2(x,   m1,   r)
             RETURN
           }
         }
    ELSE { // Reverse elements of the smaller region
           LET m1 = (t+r)/2 // Mid point of larger region
           
           //
           //           *                      *
           //         *-. *                  *   *
           //             | *              *     
           //       *-----. | *       =>           *   *
           //               |   *                        *
           //     *---------.     *                  *     *    
           //     l     t     m1  r        l   t x     m1  r
           LET p = l
           LET q = m1-1
           WHILE p<q DO
           { swap(p, q)
             p, q := p+1, q-1
           }
           t := m1-1+t-l
           // Find position of smallest element in m to t that
           // is >= element at m the make appropriate calls of mergeud2
           // and mergedd2.

           FOR x = m1-1 TO t BY -1 IF cmp(!p, !t)>=0 DO
           {
//pr(data+1, upb)
//abort(2222)
             mergeud2(  l,  t, x)
             mergedd2(x+1, m1, r)
             RETURN
           }
         }
  }

  // l to r is already sorted down so reverse the elements.
//writef("mergeud: already sorted down, so reverse*n")
  UNTIL l>=r DO { swap(l, r); l:=l+1; r :=r-1 }
//pr(data+1, upb)
//abort(2222)
}

AND mergedu2(l, t, r) BE
{ // Elements, if any, from l to t-1 are sorted down.
  // Elements, if any, from t to r are sorted up.
  // On return l to r sorted up.

// Check input
LET error = FALSE
FOR a = l TO t-2 UNLESS a!0>=a!1 DO error := TRUE
FOR a = t TO r-1 UNLESS a!0<=a!1 DO error := TRUE
IF error DO
{ pr(data+1, upb)
  writef("mergedu: l=%n t=%n r=%n*n", l-data-1, t-data-1, r-data-1)
  abort(999)
}
// End of check

//IF l=t DO writef("mergeud: already sorted up*n")
  IF l=t RETURN // l to r already sorted up

  IF t<=r DO
  { // l<t<=r holds
    //
    //     *-----------.         *                     *         *
    //       *---------|-.     *                         *     *
    //         *-------|-|-. *                             * *
    //           *     | | *          =>       * *
    //             *   | *                   *     *
    //               * *                   *         *
    //     l           t         r         l     p     t   q     r
    LET p = l
    LET q = t
    WHILE p<t & q<=r & cmp(!p, !q)>0 DO
    { swap(p, q)
      p, q := p+1, q+1
    }
//pr(data+1, upb)
//abort(3333)
    mergeud2(l, p, t-1)
    mergedu2(t, q, r)
    RETURN
  }

  // l to r is already sorted down, so reverse the elements
//writef("mergeud: already sorted down, so reverse*n")
  UNTIL l>=r DO { swap(l, r); l:=l+1; r :=r-1 }
//pr(data+1, upb)
//abort(3333)
}

AND mergedd2(l, t, r) BE
{ // Elements from l to t-1 are sorted down.
  // Elements from t to r are sorted down.
  // On return l to r is sorted up.

// Check input
LET error = FALSE
FOR a = l TO t-2 UNLESS a!0>=a!1 DO error := TRUE
FOR a = t TO r-1 UNLESS a!0>=a!1 DO error := TRUE
IF error DO
{ writef("mergedd: error l=%n t=%n r=%n*n", l-data-1, t-data-1, r-data-1)
  pr(data+1, upb)
  abort(999)
}
// End of check

//IF t>r DO writef("mergeud: already sorted up*n")
  IF t>r RETURN // Already sorted up

  IF t>l DO
  { LET m = (l+r)/2
    TEST m<=t
    THEN { // Reverse elements of the smaller region
           LET m1 = (l+t)/2 // Mid point of larger region
           
           //
           //               *                              *
           //             * .-*                          *   *
           //           * |                                    *
           //         * . .-----*       =>         *   *
           //       *   |                *       *
           //     *     .---------*            *     *    
           //     l   m1      t   r            l   m1      t   r
           //                                            x
           LET p = m1+1
           LET q = r
           WHILE p<q DO
           { swap(p, q)
             p, q := p+1, q-1
           }
           t := m1+1+r-t
           // Find position of smallest element in m to t that
           // is >= element at m the make appropriate calls of mergeuu2
           // and mergeud2.

           FOR x = m+1 TO t IF cmp(!p, !t)>=0 DO
           {
//pr(data+1, upb)
//abort(2222)
             mergeuu2(l, m1+1, x-1)
             mergedu2(x,    t,   r)
             RETURN
           }
         }
    ELSE { // Reverse elements of the smaller region
           LET m1 = (t+r)/2 // Mid point of larger region
           
           //
           //           *                      *
           //         *-. *                  *   *
           //             | *              *     
           //       *-----. | *       =>           *   *
           //               |   *                        *
           //     *---------.     *                  *     *    
           //     l     t     m1  r        l   t x     m1  r
           LET p = l
           LET q = m1-1
           WHILE p<q DO
           { swap(p, q)
             p, q := p+1, q-1
           }
           t := m1-1+t-l
           // Find position of smallest element in m to t that
           // is >= element at m the make appropriate calls of mergeud2
           // and mergedd2.

           FOR x = m1-1 TO t BY -1 IF cmp(!p, !t)>=0 DO
           {
//pr(data+1, upb)
//abort(2222)
             mergeud2(  l,  t, x)
             mergedd2(x+1, m1, r)
             RETURN
           }
         }
  }

  // l to r is already sorted down so reverse the elements.
//writef("mergeud: already sorted down, so reverse*n")
  UNTIL l>=r DO { swap(l, r); l:=l+1; r :=r-1 }
//pr(data+1, upb)
//abort(2222)
}



/*

This algorithm is related to heapsort but uses a set of fully balanced
binary trees instead of heapsort's heap to hold the remaining unsorted
elements. The number of elements in any such tree is 2**(k+1)-1
(k>=0), and so is a number in the set {1, 3, 7, 15, 31,...). If a tree
has only one element, it is a leaf and has no children, it otherwise
has a root, at position i say, and two children of size 2**k-1 at
positions i+1 and i+2*k. The n elements a!0,..,a!(n-1) are formed (or
prepared) into a set of fully balanced trees by first forming the
largest possible fully balanced tree using elements a!p,..,a!(n-1),
where p is the smallest value >= 0 of the form n-2**(k+1)+1.

Its root at p is either a leaf node, or has two children of size
2**k-1 located at p+1 and p+2**k. The elements of this tree are then
arranged so that the value at any node is no greater than the values
at either child, if any. Preparation continues by preparing the
remaining elements a!0,..,a!(p-1), if any.  The root elements of the
resulting trees are not sorted, so, to find the least of all the
roots, every one must be inspected, but there are typically only about
(log2 n)/2 of them. Note that there may be two trees of smallest size
but the sizes of all the other tree are distinct.

As an example, a prepared vector with 23 elements has the following
stucture:

      largest 2**k-1<=1    root of a fully balanced tree
     /  largest 2**k-1<=8 /     largest 2**k-1<=23
0=1-1   /                /     /
:  1=8-7                8=23-15                                     23
:  :                    :                                            :
*--*--------------------*  <- set of fully balanced trees            :
   |  2=1+1    5=1+4    |  9=8+1               16=8+8                :
    --+--------+         --+--------------------+                    :
      |  3  4  |  6  7     | 10=9+1   13=9+4    | 17       20=16+4   :
      *--+--+  *--+--+     *--+--------+        *--+--------+        :
         |  |     |  |        | 11 12  | 14 15     | 18 19  | 21 22  :
         *  *     *            IF cmp(v+i, v+j)>=0 RETURN
 *        *--+--+  *--+--+     *--+--+  *--+--+  :
                                 |  |     |  |        |  |     |  |  :
                                 *  *     *  *        *  *     *  *  :
   \                 /     \                 /  \                 /
    -----------------       -----------------    -----------------
       7 elements               7 elements           7 elements
                        \                                         /
                         -----------------------------------------
                                        15 elements
\                                                                /
 ----------------------------------------------------------------
                            23 elements

The roots of the fully balanced trees (at 0, 1 and 8). These are
inspected to find the tree, t say, with the minimum root.  This will
be the smallest of all 23 elements. It is then swapped with the root
of the leftmost tree and the new root of tree t pushed into into its
tree. Note that this value was the root element of another tree an so
should usually not need to be push down very far.

The root of the leftmost tree is now the least of all the unsorted
elements and is located in its correct final position. It is left in
place but removed from the leftmost tree, promoting its children, if
any, to the top level.

In the following diagrams, unsorted elements appear as asterisks (*)
and elements that are known to be in their correct final position are
appear as hashes (#). After the first iteration of the algorithm the
structure is as follows:


   1=8-7                8=23-15                                     23
   :                    :                                            :
#  *--------------------*  <- set of fully balanced trees            :
   |  2=1+1    5=1+4    |  9=8+1               16=8+8                :
    --+--------+         --+--------------------+                    :
      |  3  4  |  6  7     | 10=9+1   13=9+4    | 17=16+1  20=16+4   :
      *--+--+  *--+--+     *--+--------+        *--+--------+        :
         |  |     |  |        | 11 12  | 14 15     | 18 19  | 21 22  :
         *  *     *  *        *--+--+  *--+--+     *--+--+  *--+--+  :
                                 |  |     |  |        |  |     |  |  :
                                 *  *     *  *        *  *     *  *  :
   \                 /     \                 /  \                 /
    -----------------       -----------------    -----------------
       7 elements               7 elements           7 elements
                        \                                         /
                         -----------------------------------------
                                        15 elements
   \                                                              /
    --------------------------------------------------------------
                            22 elements

The same process is repeated until all the data is sorted. The structure
after next iteration is as follows:

      2=5-3    5=8-3     8=23-15                                     23
      :        :         :                                            :
#  #  *--------*---------*   <- set of fully balanced trees           :
      |  3  4  |  6  7   |  9=8+1               16=8+8                :
       --+--+   --+--+    --+--------------------+                    :
         |  |     |  |      | 10=9+1   13=9+4    | 17=16+1  20=16+4   :
         *  *     *  *      *--+--------+        *--+--------+        :
                               | 11 12  | 14 15     | 18 19  | 21 22  :
                               *--+--+  *--+--+     *--+--+  *--+--+  :
                                  |  |     |  |        |  |     |  |  :
                                  *  *     *  *        *  *     *  *  :
     \       /\       /    \                   /\                   /
      -------  -------      -------------------  -------------------
         3        3               7 elements           7 elements
                        \                                           /
                         -------------------------------------------
                                         15 elements
      \                                                           /
       -----------------------------------------------------------
                            21 elements

and after the next:

         3=4-1                                                       23
         :  4=5-1                                                     :
         :  :  5=8-3     8=23-15                                      :
         :  :  :         :                                            :
#  #  #  *--*--*---------*   <- set of fully balanced trees           :
               |  6  7   |  9=8+1               16=8+8                :
                --+--+    --+--------------------+                    :
                  |  |      | 10=9+1   13=9+4    | 17=16+1  20=16+4   :
                  *  *      *--+--------+        *--+--------+        :
                               | 11 12  | 14 15     | 18 19  | 21 22  :
                               *--+--+  *--+--+     *--+--+  *--+--+  :
                                  |  |     |  |        |  |     |  |  :
                                  *  *     *  *        *  *     *  *  :
        \ /\ /\       /    \                   /\                   /
         -  -  -------      -------------------  -------------------
         1  1     3               7 elements           7 elements
                        \                                           /
                         -------------------------------------------
                                         15 elements
        \                                                           /
         -----------------------------------------------------------
                            20 elements

The process continues until all elements are sorted.
*/

AND mrsort(v, n) BE
{ // Prepare the set of fully balanced trees.
//^1
  LET s = prep(v+1, n)  // The size of the leftmost tree.
  LET r = result2       // The sizes bit pattern.

  // Extract the values one at a time, in increasing order.
  FOR t = v+1 TO v+n-1 DO
  { // t = leftmost of the remaining trees.
    // s = the size of this tree
    // r = the bit pattern giving the sizes of the remaining trees.
//  ^4999
    LET p  = t    // p will be the tree with the smallest root.
    LET q  = t    // The next tree to inspect.
    LET ps = s    // The size of tree rooted at p.
    LET qs = s    // The size of tree rooted at q.
    LET nr = r    // The sizes bit pattern for the remaining trees.

    //writef("leftmost tree at %n size %n, bits = %b8*n", t-v-1, s, r)
    //pr(v+1, n)

    // Find the tree with the smallest root element.

    WHILE nr DO      // While there are more trees
    { // Inspect their root elements
//    ^24828
      LET b = nr&-nr // The size bit of the next tree.
      nr := nr - b   // Remove from sizes bit pattern
      q  := q+qs     // Position of next tree     
      qs := b-1      // Its size

      // Compare current smallest with the root element at q
//writef("comparing %i2:%i3 with %i2: %i3*n", p-v-1, !p, q-v-1, !q)
      IF cmp(!p, !q) > 0 DO
        p, ps := q, qs // Update p if necessary.
//      ^19380
    }

//writef("Smallest element is at %n: %n*n", p-v-1, !p)

    // p is now the root of the tree with the smallest element.
    UNLESS t=p DO
//  ^4999
    { // The root element at p is the smallest and must be moved.
//    ^4965
      swap(t, p)
      pusht(p, ps) // Re-prepare the tree at p
    }

    TEST s>1 // Does the leftmost tree have children?
//  ^4999
    THEN { // Yes
//         ^2496
           LET cs = s>>1 // The size of each child.
           LET b = r & -r
           // The size of the new leftmost tree is the size of
           // the lefthand child.
           s := cs
           // Add the size bit for the righthand child to the
           // sizes bit pattern
           r := r + cs + 1
         }
    ELSE { LET b = r & -r // The size bit for the next tree
//         ^2503
           r := r - b   // Remove this bit from the sizes bit pattern
           s := b - 1   // Set the size of the new leftmost tree.
         }

    //writef("mrsort: i=%n %i4 set s=%n r=%b8*n", i, t!i, s, r)
//  ^4999
  }

  // The data is now sorted.
  //pr(v+1, n)
//^1
}

AND prep(t, n) = VALOF
// A vector of n elements can be arranged as a set of fully
// balanced trees with sizes of the form 2**(k+1)-1, ie from
// the set {1, 3, 7, 15, 31, 63, ...}. The set of trees is
// formed by successively forming and removing the largest
// possible fully balanced tree each time.

// prep(n) returns the size of the leftmost tree in the set.
// It also returns a bit pattern, in result2, specifiying the
// sizes of all the other trees in the set.

// If (result2>>k & 1)=1, a tree of size 2**k-1 is in the set.
// So for example, if result2=#b11010, the remaining trees have
// sizes 1, 7 and 15.

// Note that if w is the sizes bit pattern, then (w&-w)-1 is the size
// of the smallest tree it specifies, and w-(w&-1) is the bit pattern
// specifying the sizes of the trees with the smallest tree removed.

// The following table shows the results for small values of n.

//            n      result      result2   tree sizes

//            0         0       00000000    0 -- no trees
//            1         1       00000000    1 = 1
//            2         1       00000010    2 = 1 + 1
//            3         3       00000000    3 = 3
//            4         1       00000100    4 = 1 + 3
//            5         1       00000110    5 = 1 + 1 + 3
//            6         3       00000100    6 = 3 + 3
//            7         7       00000000    7 = 7
//           20         1       00010110   20 = 1 + 1 + 3 + 15
//           23         1       00011010   23 = 1 + 7 + 15
//           24         1       00011010   24 = 1 + 1 + 7 + 15
//                                 || |
//                                 || *--  1
//                                 |*----  7
//                                 *----- 15

{ LET size = 1  // To hold the size of the smallest tree.
  LET bits = 0  // To hold the sizes of the other trees.
//^1
  UNTIL size>=n DO size := size+size+1
//      ^13        ^12
  // size is the smallest 2**(k+1)-1 >= n

  { UNTIL size<=n DO size := size>>1
//  ^8    ^13        ^12
    // size = the largest 2**(k+1)-1 < n
    n := n-size
//  ^8
    prept(t+n, size) // Prepare the tree rooted at t+n
    IF n=0 BREAK     // Break if no more elements to prepare.
//  ^8     ^1
    bits := bits + size + 1 // Put a one in bit position k
//  ^1
  } REPEAT

  result2 := bits
  RESULTIS size
//^1
}

AND prept(t, s) BE IF s>1 DO
//                 ^5000
{ // Prepare the fully balanced tree of size s at t. Ie ensure that
  // the value in every node is no greater than the values in either
  // child, if any.
//^4999
  LET cs = s>>1          // Size of each child
  LET l = t+1            // Position of left child
  AND r = t + cs + 1     // Position of right child
//writef("prept: t=%n s=%n*n", t-data-1, s)
  prept(l, cs)           // Prepare the left child
  prept(r, cs)           // Prepare the right child
  pusht(t, s)            // Push the root element
}


AND pusht(t, s) BE WHILE s>1 DO
//                 ^7461 ^
// Push the root element at t into a tree of s elements, if necessary.
// s is of the form 2**(k+1)-1
{ LET l = t+1          // Position of left  child
  AND r = t+((s+1)>>1) // Position of right child
  LET c = cmp(l!0, r!0) <= 0 -> l,     r
//^46123                        ^22964 ^23159
  // c is the child with the smaller root value.
  IF cmp(t!0, c!0) <= 0 RETURN
//^46123                ^3409
  swap(t, c)
//^42714
  t, s := c, s>>1
}

LET start() = VALOF
{ LET v = getvec(upb)
  data := v

  try("mmsort",        mmsort, v, upb)
  try("mmsort2",      mmsort2, v, upb)
  try("mrsort",        mrsort, v, upb)
  try("heapsort",    heapsort, v, upb)
  try("quicksort",  quicksort, v, upb)

  writes("*nEnd of test*n")
  freevec(v)
  RESULTIS 0
}

AND try(name, sortroutine, v, upb) BE
{ // delay, referencing the first and last elements of v
   FOR i = 1 TO 50000 DO v!upb := v!1 
   writef("*nSetting %n words of data for %s*n", upb, name)
   setseed(123456)

   FOR i = 1 TO upb DO v!i := randno(valupb)
   //FOR i = 1 TO upb DO v!i := i
   //FOR i = 1 TO upb DO v!i := -i

//   writef("Entering %s routine*n", name)
   cmpcount, swapcount := 0, 0
   //writef("Instruction count = %n*n", instrcount(sortroutine, v, upb))
   sortroutine(v, upb)
   writef("Compare count = %i7   ", cmpcount)
   writef("Swap count = %i7*n", swapcount)
   //writes("Sorting complete*n")
   UNLESS sorted(v, upb) DO
     writef("### ERROR: %s sort does not work*n", name)
}

AND sorted(v, n) = VALOF
{ FOR i = 1 TO n-1 UNLESS v!i <= v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}

AND pr(ptr, n) BE
{ FOR i = 1 TO n DO
  { writef(" %i2", !ptr)
    ptr := ptr+1
    IF i REM 32 = 0 DO newline()
  }
  newline()
}

/*

This program (with upb=5_000) outputs the following:

Setting 5000 words of data for mrsort sort
Entering mrsort sort routine
Compare count = 117074
Swap count    = 47679
Sorting complete
The data is now sorted

Setting 5000 words of data for quick sort
Entering quick sort routine
Compare count = 68143
Swap count    = 15972
Sorting complete
The data is now sorted

End of test

*/
