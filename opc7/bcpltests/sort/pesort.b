// Demo of Proportion Extend Sort (PEsort)

// Translated in BCPL from Jingchao Chen's C++ program
SECTION "PEsort"

GET "libhdr"

GLOBAL {
  pr:ug
  cmpcount
  swapcount
}

LET cmp(x, y) = VALOF
{ cmpcount := cmpcount+1
//  writef("cmp: x=%n y=%n*n", x, y)
// abort(1000)
 
  RESULTIS x - y
}

AND swap(p, q) BE
{ LET t = !p
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


// pesort is a hand translation into BCPL of Jingchao Chen's
// C++ program.
AND pesort(v, n) BE pes(v+1, 1, n-1)

AND pes(a, s, n) BE
// Sort elements a!0 ... a!n
// assuming elements a!0 ... a!(s-1) are already sorted

/// while (1) {
{ MANIFEST { p=16 }
  LET pi, pj, pb, pc, pm, n1, s1, s2, s3, ll, rr =
      ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?,  ?, ?, ?
//writef("pes: a=%n s=%n n=%n*n", a, s, n)
//pr(a, n+1)

/// if( s <= 0 ) s=1;
  IF s <= 0 DO s := 1

/// if (n < 7) {
///   for (; s <= n; s++){
///     for ( pj = a+s; pj > a && cmp(pj-1,pj) > 0; pj--) {
///       swap(pj, pj-1);
///     }
///   }
///   return;
/// }
  IF n<7 DO
  { // Do insertion sort if less than or equal to 7 elements.
    WHILE s<=n DO
    { FOR p = a+s TO a+1 BY -1 DO
      { UNLESS cmp(p!-1, p!0)>0 BREAK
        swap(p, p-1)
      }
      s := s+1
    }
//writef("pes: returning a=%n s=%n n=%n*n", a, s, n)
//pr(a, n+1)
    RETURN
  }

  IF s>n DO
  {
//writef("pes: returning a=%n s=%n n=%n*n", a, s, n)
//pr(a, n+1)
  }
/// if( s > n ) return;
  IF s > n RETURN // No unsorted elements

/// s1=(s-1)/2;
/// pm = a+s1;
  s1 := (s-1)/2   // Subscript of the mid point of the sorted region
  pm := a+s1      // Pointer to the chosen median value

/// s3=((p+1)*p*s) > n ? n : (p+1)*s;
  s3 := (p+1)*s          // Size of next region
  IF p*s3 > n DO s3 := n // Round up to n if getting close

/// ll=a[s-1];  
/// rr=a[s3];
/// a[s-1]=a[s3]=*pm; 
  ll := a!(s-1)
  rr := a!s3
  a!s3 := !pm
  a!(s-1) := a!s3

//writef("a=%n s=%n s3=%n n=%n*n", a, s, s3, n)
//abort(1000)

/// pb=pi=a+s;
/// pc=a+s3-1;
  pi := a+s
  pb := pi
  pc := a+s3-1

// <-----sorted -----------> <-- next region --> <-- the rest -->
// a[0] ... a[s1] ... a[s-1] a[s]    ...   a[s3] a[s3+1] ... a[n]
//
// subscripts s1               s             s3                n
//
// pointers   pm               pb            pc

//writef("pes: s1=%n pm=%n s3=%n pb=%n pi=%n pc=%n*n",
//             s1,   pm,   s3,   pb,   pi,   pc)

/// while( pb <= pc ){
///   while (cmp(pb, pm) < 0 ) pb++;
///   while (cmp(pc, pm) > 0 ) pc--;
///   if (pb >= pc) break;
///   swap(pb, pc); 
///   pc--; pb++;
/// }
  WHILE pb<=pc DO
  { LET median = !pm
    WHILE cmp(!pb, median) < 0 DO pb := pb+1
    WHILE cmp(!pc, median) > 0 DO pc := pc-1
    IF pb>=pc BREAK
    swap(pb, pc)
    pc, pb := pc-1, pb+1
  }

/// if(cmp(&rr, pm) >= 0 ) a[s3]=rr;
/// else{
///   a[s3]= *pb;
///   *pb = rr;
///   pb++; 
/// }
  TEST cmp(rr, !pm) >=0
  THEN   a!s3 := rr
  ELSE { a!s3 := !pb
         !pb := rr
         pb := pb+1
       }

// a[s-1]=ll;
// pj=pb;
  a!(s-1) := ll
  pj := pb

//writef("pes: pj=%n pj!-1=%n pj!0=%n pj!1=%n !pm=%n*n",
//             pj, pj!-1, pj!0, pj!1, !pm)


// do{ pi--;pj--; swap(pi, pj);}
// while(pi > pm); 
  { pi, pj := pi-1, pj-1
    swap(pi, pj)
  } REPEATWHILE pi > pm

/// s2=s-s1-1;
/// n1= pb-a-s2-2;
  s2 := s-s1-1
  n1 := pb-a-s2-2

  // a[0] ... a[s1-1] is sorted
///    psort(a, s1, n1, cmp);
///    psort(pb-s2, s2, s3-n1-2, cmp);
  pes(a,     s1,      n1)
  pes(pb-s2, s2, s3-n1-2)

///    s=s3+1;
  s := s3+1
  //pes(a,   s3+1,       n)
} REPEAT


// A variation of pesort

AND pepartition(median, p, q) = VALOF
{ LET t = ?
  WHILE p<=q & cmp(!p, median) < 0 DO p := p+1
  WHILE p<=q & cmp(!q, median) > 0 DO q := q-1
  IF p>=q RESULTIS p
//writef("pepartition: swapping %n with %n*n", p, q)
  swap(p, q)
  p, q := p+1, q-1
} REPEAT


AND psort(v, n) BE
{ LET s = ?
//writef("psort: v=%n n=%n*n", v, n)

  IF n<8 DO
  { // Perform insertion sort
    LET l, r = v+1, v+n
    FOR p = l+1 TO r DO  // Now perform insertion sort.
      FOR q = p-1 TO l BY -1 TEST cmp(q!0, q!1)<=0 THEN BREAK
                                                   ELSE swap(q, q+1)
    RETURN
  }
  s := n/16
  IF s<5 DO s := 5
  psort(v, s)
  psort1(v, s, n)
}

AND psort1(v, s, n) BE
// Sort v!1 ... v!n knowing that v!1 ... v!s is already sorted
TEST s<5
THEN psort(v, n)
ELSE { LET midpt = (1+s)/2
       LET median = v!midpt
       LET i = pepartition(median, v+s+1, v+n)  
       LET q = i
//writef("pesort: v=%n s=%n i=%n n=%n*n", v, s, i, n)
//pr(v+1, n)
//abort(1000)
       FOR p = v+s TO v+midpt+1 BY -1 DO
       { q := q-1
         swap(p, q)
       }

       psort1(v,  midpt,   q-1-v)
       psort1(q-1,  i-q, v+n-q+1)
     }


MANIFEST { upb = 100_000  }
//MANIFEST { upb = 5_000  }

LET start() = VALOF
{ LET v = getvec(upb)

  try("quick",  quicksort, v, upb)
  try("pesort", pesort,    v, upb)
  try("psort",  psort,     v, upb)

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
   FOR i = 1 TO upb DO v!i := randno(upb)  // in range 1...upb
   //FOR i = 1 TO upb DO v!i := randno(999)
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
    IF i REM 10 = 0 DO newline()
  }
  newline()
}

/*
This program outputs the following:

Setting 100000 words of data for quick sort
Entering quick sort routine
Compare count = 1852953
Swap count    = 423245
Sorting complete
The data is now sorted

Setting 100000 words of data for pesort sort
Entering pesort sort routine
Compare count = 1668395
Swap count    = 451424
Sorting complete
The data is now sorted

Setting 100000 words of data for psort sort
Entering psort sort routine
Compare count = 1741793
Swap count    = 600746
Sorting complete
The data is now sorted

End of test

But if the data is already sorted:

Setting 100000 words of data for quick sort
Entering quick sort routine
Compare count = 1523159
Swap count    = 0
Sorting complete
The data is now sorted

Setting 100000 words of data for pesort sort
Entering pesort sort routine
Compare count = 22150250
Swap count    = 279066
Sorting complete
The data is now sorted

Setting 100000 words of data for psort sort
Entering psort sort routine
Compare count = 22490136
Swap count    = 758900
Sorting complete
The data is now sorted

End of test
*/
