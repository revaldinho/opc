GET "libhdr"

GLOBAL $( word:200; maxn:201; count:202; len:203 $)

LET start() = VALOF
$( LET a, b, c, d = 1, 3, 1, 2
   LET v = VEC 20
   maxn := a+b+c+d
   word := v
   word%0 := maxn
   count, len := 0, 0
   writef("*nAnagrams with %n As, %n Bs, %n Cs and %n Ds*n*n",
                           a,     b,     c,        d)
   p4(0, a, b, c, d)
   writef("*n*nCount = %n*n", count)
   RESULTIS 0
$)


AND p4(n, a, b, c, d) BE
   TEST n=maxn
   THEN pr(word)
   ELSE $( n := n+1
           IF a>0 DO $( word%n := 'A'; p4(n, a-1, b, c, d) $)
           IF b>0 DO $( word%n := 'B'; p4(n, a, b-1, c, d) $)
           IF c>0 DO $( word%n := 'C'; p4(n, a, b, c-1, d) $)
           IF d>0 DO $( word%n := 'D'; p4(n, a, b, c, d-1) $)
        $)

AND pr(str) BE
$( count := count+1
   writef("%s ", str)
   len := len + maxn + 1
   IF len>72 DO $( newline(); len := 0 $)
$)

