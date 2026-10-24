/*
This is an experimental (hopefully less hopeless sort algorithm.
Implemented in BCPL by Martin Richards (c) November 2005

*/

SECTION "mrsort"

GET "libhdr"

//MANIFEST { upb = 100_000  }
MANIFEST { upb = 2000 }


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
  //pr(data+1, upb)
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

     // Select a good(ish) median value.
     LET val   = l+25>r -> !midpt,  median5(l, a, midpt, c, r)
     //LET val   = l+25>r -> !midpt,  median5(l, l, midpt, r, r)
     LET i = partition(val, l, r)
     // Only recurse on the smaller partition.
     TEST i>midpt THEN { qsort(i, r);   r := i-1 }
                  ELSE { qsort(l, i-1); l := i   }
   }

   FOR p = l+1 TO r DO  // Now perform insertion sort.
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


/*

This sort algorithm uses fully balanced binary trees.  The number of
elements in such a tree is 2**(k+1)-1 (k>=0), ie a number in the set
{1, 3, 7, 15, 31,...). If a tree has only one element, it is a leaf
and has no children, otherwise it has a root at position i, say, and
two children of size 2**k-1 at positions i+1 and i+2*k. The n elements
a!0,..,a!(n-1) are formed (or prepared) into a collection of
completely balanced trees by first selecting the smallest p>=0 where p
is of the form n-2**(k+1)+1. The 2**(k+1)-1 elements a!p,..,a!(n-1)
are rearranged to form a fully balanced tree. Its root is at p and its
two children, if any, are of size 2**k-1 and are located at p+1 and
p+2**k. The elements are arranged so that the value at any node is no
greated than the values at either child, if any. Preparation continues
by preparing elements a!0,..,a!(p-1), if any. The elements are
rearranged so that the root elements of the trees form a non
decreasing sequence.

For example, a prepared vector with 23 elements has the following
stucture:

      largest 2**k-1<=1    root of a fully balanced tree
     /  largest 2**k-1<=8 /     largest 2**k-1<=23
0=1-1   /                /     /
:  1=8-7                8=23-15                                     23
:  :                    :                                            :
*<<*<<<<<<<<<<<<<<<<<<<<*  <- collection of fully balanced trees     :
   |  2=1+1    5=1+4    |  9=8+1               16=8+8                :
    --+--------+         --+--------------------+                    :
      |  3  4  |  6  7     | 10=9+1   13=9+4    | 17       20=16+4   :
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
\                                                                /
 ----------------------------------------------------------------
                            23 elements

The roots of the perfectly balanced trees (at 0, 1 and 8) are in
increasing order and the value at the root of the leftmost tree is the
smallest of all 23 elements. It is already in the correct and so does
not need to be moved and indicated by a # in the following
diagrams. The algorithm proceeds by reducing the number of unsorted
elements, yielding the following structure:

   1=8-7                8=23-15                                     23
   :                    :                                            :
#  *<<<<<<<<<<<<<<<<<<<<*  <- collection of fully balanced trees     :
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

The element at position 1 is in its correct position (again to be
represented by a #), but since its tree has children they are promoted
to the top level. The value of the right child may be larger than the
root of the next tree (at 8) to the right. If it is, the elements at 5
and 8 are swapped and the new element at 8 pushed into it tree. This
may result in a new value at 8. Whatever value it has it will
certainly be no smaller than that currently at 5, but if there were
more trees to the right it would have to be compared with the next
root, and so on. The same process is then applied to the left child.
The resulting structure is:

      2=5-3    5=8-3     8=23-15                                     23
      :        :         :                                            :
#  #  *<<<<<<<<*<<<<<<<<<*   <- collection of fully balanced trees    :
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

The next iteration yields the following:

         3=4-1                                                       23
         :  4=5-1                                                     :
         :  :  5=8-3     8=23-15                                      :
         :  :  :         :                                            :
#  #  #  *<<*<<*<<<<<<<<<*   <- collection of fully balanced trees    :
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

AND mrsort(v, n) BE IF n>1 DO
{ LET t = v+1  // Elements from t!0 to t!(n-1)
  LET p = 1
  UNTIL p>=n/2 DO p := p+p
  // p is the smallest power of two (2**k) greater than
  // or equal to n/2.

  IF FALSE DO
  { // Test findsizes(..)
    FOR n = 0 TO 31 DO
    { LET s = findsizes(n)
      LET r = result2

      writef("%i2: %i2 %b8 ", n, s, r)

      // List the tree sizes
      { writef("  %i2", s)
        IF r=0 BREAK
        s := r & -r // LS one of r
        r := r - s  // Remove the one from r
        s := s+s-1
      } REPEAT

      newline()
    }
    RETURN
  }

  // Prepare the collection of fully balanced trees.
  //pr(t,   n)
  prep(t, n)
  //pr(t,   n)

  // Extract the values one at a time, in increasing order.
  FOR i = 0 TO n-2 DO
  { // Leave the smallest remaining value at position i
    // and reduce the number of remaining elements by one
    // adjustiong the trees as neccessary.
    LET ct = t+i
    LET s = findsizes(n-i)
    LET r = result2
    LET cs = s>>1         // Size of each child
    //writef("mrsort: i=%n %i4 set s=%n r=%b8*n", i, t!i, s, r)
    IF cs DO
    { // The tree does have children
      pushf(ct+1+cs, cs,  r)             // Adjust the right child
      pushf(ct+1,    cs,  r+((cs+1)>>1)) // Adjust the left  child
    }
    //pr(t, n)
    //abort(2222)
  }

}

AND findsizes(n) = VALOF
// A vector of n elements can be arranged as a collection
// of fully balanced trees with sizes of the form 2**(k+1)-1,
// ie from the set {1, 3, 7, 15, 31, 63, ...}. The set of trees is
// formed by successively removing the largest possible tree each
// time. This yiels a set of sizes that are all distinct except
// possibly for the smallest size selected.
// findsizes(n) returns the size of the smallest tree selected and,
// in result2, it returns the sizes of all the other tree chosen.
// Bit i (0,..31) is a one, iff one of the selected trees had size
// 2**(i+1)-1. The following table shows the results for small
// values of n.
//            n      result      result2   tree sizes
//            0         0       00000000    0 -- no trees
//            1         1       00000000    1 = 1
//            2         1       00000001    2 = 1 + 1
//            3         3       00000000    3 = 3
//            4         1       00000010    4 = 1 + 3
//            5         1       00000011    5 = 1 + 1 + 3
//            6         3       00000010    6 = 3 + 3
//            7         7       00000000    7 = 7
//           20         1       00000000   20 = 1 + 1 + 3 + 15
//           23         1       00000000   23 = 1 + 7 + 15
{ LET size, res = 1, 0
  UNTIL size>=n DO size := size+size+1
  // size is the smallest 2**(k+1)-1 >= n

  { UNTIL size<=n DO size := size>>1
    // size = the largest 2**(k+1)-1 < n
    n := n-size
    IF n=0 BREAK
    res := res + size + 1 // Put a one in bit position k
  } REPEAT

  result2 := res>>1
  RESULTIS size
}

AND prep(t, n) BE
{ // Prepare, as described above, the elements t!0 .. t!(n-1).
  LET r = 0 // This will hold a bit pattern giving the the
            // sizes of the trees to the right of the current one.
  UNTIL n=0 DO
  { LET s = 1 // Will be the size of the rightmost fully balanced
            // tree for a vector of n elements.
    UNTIL s>=n DO s := s+s+1
    // s is the smallest 2**(k+1)-1 >= n
    UNTIL s<=n DO s := s>>1
    // s is the largest 2**(k+1)-1 < n
    prept(t+n-s, s)    // Prepare a fully balanced tree of size s
    pushf(t+n-s, s, r) // Push its root into the next tree, if neccessary.
    n := n-s
    r := r + ((s+1)>>1) // Insert the current size into r
  }
}

AND prept(t, s) BE IF s>1 DO
{ // Prepare the fully balanced tree of size s at t. Ie ensure that
  // the value in every node is no greater than the values in either
  // child, if any.
  LET l = t+1            // Position of left child
  AND r = t + ((s+1)>>1) // Position of right child
  AND cs = s>>1          // Size of each child
//writef("prept: t=%n s=%n*n", t-data-1, s)
  prept(l, cs)
  prept(r, cs)
  pusht(t, s)
}


AND pusht(t, s) BE
{ //writef("pusht: t=%n size=%n*n", t-data-1, s)
  pusht1(t, s)
}

AND pusht1(t, s) BE WHILE s>1 DO
// Push the root element at t into a tree of s elements, if necessary.
// s is of the form 2**(k+1)-1
{ LET l = t+1          // Position of left  child
  AND r = t+((s+1)>>1) // Position of right child
  LET c = cmp(l!0, r!0) <= 0 -> l, r
  // c is the child with the smaller root value.
  IF cmp(t!0, c!0) <= 0 RETURN
  swap(t, c)
  t, s := c, s>>1
}

AND pushf(t, s, r) BE
{ //writef("pushf: t=%n s=%n r=%b8*n", t-data-1, s, r)
  pushf1(t, s, r)
}

AND pushf1(t, s, r) BE WHILE r & cmp(t!0, t!s)>0 DO
{ // Push the root element of t into the next tree, if necessary.
  // s is the size of the tree rooted at t.
  // r gives the sizes of the top level trees to the right.
  LET nt = t + s // The position of the next tree.
  swap(t, nt)
  t := nt        // Next tree
  s := r & -r    // Get the next 2**k
  r := r - s     // Remove it from r
  s := s + s - 1 // Form 2**(k+1)-1, the size of the next tree.
  pusht(t, s)
  //pr(data+1,   12)
//abort(1000)
}

LET start() = VALOF
{ LET v = getvec(upb)
  data := v

  try("mrsort", mrsort,    v, upb)
  try("quick",  quicksort, v, upb)

  writes("*nEnd of test*n")
  freevec(v)
  RESULTIS 0
}

AND try(name, sortroutine, v, upb) BE
{ // delay, referencing the first and last elements of v
   FOR i = 1 TO 50000 DO v!upb := v!1 
   writef("*nSetting %n words of data for %s sort*n", upb, name)
   setseed(123456)

   //FOR i = 1 TO upb DO v!i := randno(1_000_000_000)
   FOR i = 1 TO upb DO v!i := randno(1_000)
   //FOR i = 1 TO upb DO v!i := i
   //FOR i = 1 TO upb DO v!i := -i

   writef("Entering %s sort routine*n", name)
   cmpcount, swapcount := 0, 0
   //writef("Instruction count = %n*n", instrcount(sortroutine, v, upb))
   sortroutine(v, upb)
   writef("Compare count = %n*n", cmpcount)
   writef("Swap count    = %n*n", swapcount)
   writes("Sorting complete*n")
   TEST sorted(v, upb)
   THEN writes("The data is now sorted*n")
   ELSE writef("### ERROR: %s sort does not work*n", name)
}

AND sorted(v, n) = VALOF
{ FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}

AND pr(ptr, n) BE
{ FOR i = 1 TO n DO
  { writef(" %i5", !ptr)
    ptr := ptr+1
    IF i REM 8 = 0 DO newline()
  }
  newline()
}

/*
This program (with upb=1000) outputs the following:

*/
