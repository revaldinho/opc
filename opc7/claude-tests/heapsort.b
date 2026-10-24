/*
A heapsort experiment implemented by Martin Richards February 1999

This is a collection of variations on heapsort using perfectly balanced 
heap structures with branching degree 2, 3, 4, 6, 8, 12 and 16. The 
optimum seems to be about 6.
*/
 
GET "libhdr"

LET heapify(v, k, i, last) BE
{ LET p = i+i  // If there is a son (or two), j = subscript of first.
  LET s, x = ?, ?

  IF p>last DO { v!i := k; RETURN }
  // There is at least one son

  s := v+p
  x := s!0

  IF p<last & x<s!1 DO x, p := s!1, p+1

  IF k>=x DO { v!i := k; RETURN }

  v!i := x
  i := p
} REPEAT

AND heapsort(v, upb) BE
{ FOR i = upb/2 TO 1 BY -1 DO heapify(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify(v, k, 1, i-1)
  }
}



LET heapify3(v, k, i, last) BE
{ LET p = 3*i-1  // If there is/are son(s), p = subscript of first.
  LET q = p
  LET s, x = ?, ?

  IF p>last DO { v!i := k; RETURN }
  // There is at least one son

  s := v+p
  x := s!0

  TEST p+1<last                // Are there three sons
  THEN { IF x<s!1 DO x, q := s!1, p+1
         IF x<s!2 DO x, q := s!2, p+2
       }
  ELSE IF p<last & x<s!1 DO x, q := s!1, p+1

  IF k>=x DO { v!i := k; RETURN }

  v!i := x
  i := q
} REPEAT

AND heapsort3(v, upb) BE
{ FOR i = (upb+1)/3 TO 1 BY -1 DO heapify3(v, v!i, i, upb)
  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify3(v, k, 1, i-1)
  }
}



LET heapify4(v, k, i, last) BE
{ LET p = 4*i-2  // p = subscript of first son, if any.
  LET q = p
  LET s, x = ?, ?

  IF p>last DO { v!i := k; RETURN }
  // There is at least one son

  s := v+p
  x := s!0

  TEST p+2<last                // Are there four sons
  THEN { IF x<s!1 DO x, q := s!1, p+1
         IF x<s!2 DO x, q := s!2, p+2
         IF x<s!3 DO x, q := s!3, p+3
       }
  ELSE { IF p  <last & x<s!1 DO x, q := s!1, p+1
         IF p+1<last & x<s!2 DO x, q := s!2, p+2
       }

  IF k>=x DO { v!i := k; RETURN }
  // Largest son was > k

  v!i := x  // Promote the son
  i := q
} REPEAT

AND heapsort4(v, upb) BE
{ FOR i = (upb+2)/4 TO 1 BY -1 DO heapify4(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify4(v, k, 1, i-1)
  }
}




LET heapify6(v, k, i, last) BE
{ LET p = 6*i-4  // j = subscript of first son, if any.
  LET q = p
  LET s, x = ?, ?

  IF p>last DO { v!i := k; RETURN }
  // There is at least one son

  s := v+p
  x := s!0

  TEST p+4<last                // Are there six sons
  THEN { IF x<s!1 DO x, q := s!1, p+1
         IF x<s!2 DO x, q := s!2, p+2
         IF x<s!3 DO x, q := s!3, p+3
         IF x<s!4 DO x, q := s!4, p+4
         IF x<s!5 DO x, q := s!5, p+5
       }
  ELSE { IF p  <last & x<s!1 DO x, q := s!1, p+1
         IF p+1<last & x<s!2 DO x, q := s!2, p+2
         IF p+2<last & x<s!3 DO x, q := s!3, p+3
         IF p+3<last & x<s!4 DO x, q := s!4, p+4
       }

  IF k>=x DO { v!i := k; RETURN }
  // Largest son was > k

  v!i := x  // Promote the son
  i := q
} REPEAT

AND heapsort6(v, upb) BE
{ FOR i = (upb+4)/6 TO 1 BY -1 DO heapify6(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify6(v, k, 1, i-1)
  }
}




LET heapify8(v, k, i, last) BE
{ LET p = 8*i-6  // j = subscript of first son, if any.
  LET q = p
  LET s, x = ?, ?

  IF p>last DO { v!i := k; RETURN }
  // There is at least one son

  s := v+p
  x := s!0

  TEST p+6<last                // Are there eight sons
  THEN { IF x<s!1 DO x, q := s!1, p+1
         IF x<s!2 DO x, q := s!2, p+2
         IF x<s!3 DO x, q := s!3, p+3
         IF x<s!4 DO x, q := s!4, p+4
         IF x<s!5 DO x, q := s!5, p+5
         IF x<s!6 DO x, q := s!6, p+6
         IF x<s!7 DO x, q := s!7, p+7
       }
  ELSE { IF p  <last & x<s!1 DO x, q := s!1, p+1
         IF p+1<last & x<s!2 DO x, q := s!2, p+2
         IF p+2<last & x<s!3 DO x, q := s!3, p+3
         IF p+3<last & x<s!4 DO x, q := s!4, p+4
         IF p+4<last & x<s!5 DO x, q := s!5, p+5
         IF p+5<last & x<s!6 DO x, q := s!6, p+6
       }

  IF k>=x DO { v!i := k; RETURN }
  // Largest son was > k

  v!i := x  // Promote the son
  i := q
} REPEAT

AND heapsort8(v, upb) BE
{ FOR i = (upb+6)/8 TO 1 BY -1 DO heapify8(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify8(v, k, 1, i-1)
  }
}



LET heapify12(v, k, i, last) BE
{ LET p = 12*i-10  // j = subscript of first son, if any.
  LET q = p
  LET s, x = ?, ?

  IF p>last DO { v!i := k; RETURN }
  // There is at least one son

  s := v+p
  x := s!0

  TEST p+10<last                // Are there 12 sons
  THEN { IF x<s!1  DO x, q := s!1,  p+1
         IF x<s!2  DO x, q := s!2,  p+2
         IF x<s!3  DO x, q := s!3,  p+3
         IF x<s!4  DO x, q := s!4,  p+4
         IF x<s!5  DO x, q := s!5,  p+5
         IF x<s!6  DO x, q := s!6,  p+6
         IF x<s!7  DO x, q := s!7,  p+7
         IF x<s!8  DO x, q := s!8,  p+8
         IF x<s!9  DO x, q := s!9,  p+9
         IF x<s!10 DO x, q := s!10, p+10
         IF x<s!11 DO x, q := s!11, p+11
       }
  ELSE { IF p   <last & x<s!1  DO x, q := s!1,  p+1
         IF p+1 <last & x<s!2  DO x, q := s!2,  p+2
         IF p+2 <last & x<s!3  DO x, q := s!3,  p+3
         IF p+3 <last & x<s!4  DO x, q := s!4,  p+4
         IF p+4 <last & x<s!5  DO x, q := s!5,  p+5
         IF p+5 <last & x<s!6  DO x, q := s!6,  p+6
         IF p+6 <last & x<s!7  DO x, q := s!7,  p+7
         IF p+7 <last & x<s!8  DO x, q := s!8,  p+8
         IF p+8 <last & x<s!9  DO x, q := s!9,  p+9
         IF p+9 <last & x<s!10 DO x, q := s!10, p+10
       }

  IF k>=x DO { v!i := k; RETURN }
  // Largest son was > k

  v!i := x  // Promote the son
  i := q
} REPEAT

AND heapsort12(v, upb) BE
{ FOR i = (upb+10)/12 TO 1 BY -1 DO heapify12(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify12(v, k, 1, i-1)
  }
}



LET heapify16(v, k, i, last) BE
{ LET p = 16*i-14  // j = subscript of first son, if any.
  LET q = p
  LET s, x = ?, ?

  IF p>last DO { v!i := k; RETURN }
  // There is at least one son

  s := v+p
  x := s!0

  TEST p+14<last                // Are there 16 sons
  THEN { IF x<s!1  DO x, q := s!1,  p+1
         IF x<s!2  DO x, q := s!2,  p+2
         IF x<s!3  DO x, q := s!3,  p+3
         IF x<s!4  DO x, q := s!4,  p+4
         IF x<s!5  DO x, q := s!5,  p+5
         IF x<s!6  DO x, q := s!6,  p+6
         IF x<s!7  DO x, q := s!7,  p+7
         IF x<s!8  DO x, q := s!8,  p+8
         IF x<s!9  DO x, q := s!9,  p+9
         IF x<s!10 DO x, q := s!10, p+10
         IF x<s!11 DO x, q := s!11, p+11
         IF x<s!12 DO x, q := s!12, p+12
         IF x<s!13 DO x, q := s!13, p+13
         IF x<s!14 DO x, q := s!14, p+14
         IF x<s!15 DO x, q := s!15, p+15
       }
  ELSE { IF p   <last & x<s!1  DO x, q := s!1,  p+1
         IF p+1 <last & x<s!2  DO x, q := s!2,  p+2
         IF p+2 <last & x<s!3  DO x, q := s!3,  p+3
         IF p+3 <last & x<s!4  DO x, q := s!4,  p+4
         IF p+4 <last & x<s!5  DO x, q := s!5,  p+5
         IF p+5 <last & x<s!6  DO x, q := s!6,  p+6
         IF p+6 <last & x<s!7  DO x, q := s!7,  p+7
         IF p+7 <last & x<s!8  DO x, q := s!8,  p+8
         IF p+8 <last & x<s!9  DO x, q := s!9,  p+9
         IF p+9 <last & x<s!10 DO x, q := s!10, p+10
         IF p+10<last & x<s!11 DO x, q := s!11, p+11
         IF p+11<last & x<s!12 DO x, q := s!12, p+12
         IF p+12<last & x<s!13 DO x, q := s!13, p+13
         IF p+13<last & x<s!14 DO x, q := s!14, p+14
       }

  IF k>=x DO { v!i := k; RETURN }
  // Largest son was > k

  v!i := x  // Promote the son
  i := q
} REPEAT

AND heapsort16(v, upb) BE
{ FOR i = (upb+14)/16 TO 1 BY -1 DO heapify16(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify16(v, k, 1, i-1)
  }
}

MANIFEST { upb = 15000  }

LET start() = VALOF
{ LET v = getvec(upb)

  try("heap",   heapsort,   v, upb)
  try("heap3",  heapsort3,  v, upb)
  try("heap4",  heapsort4,  v, upb)
  try("heap6",  heapsort6,  v, upb)
  try("heap8",  heapsort8,  v, upb)
  try("heap12", heapsort12, v, upb)
  try("heap16", heapsort16, v, upb)

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
  { LET t = sys(30)
    sortroutine(v, upb)
    writef("Sorting complete in %n msecs*n", sys(30)-t)
  }
  TEST sorted(v, upb)
  THEN writes("The data is now sorted*n")
  ELSE writef("### ERROR: %s sort does not work*n", name)
}

AND sorted(v, n) = VALOF
{ //FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}
