GET "libhdr"

LET generate(key, perm) BE
$( LET x = ?

   // generate initial permutation
   FOR n = 0 TO 255 DO
   $( x := (((n+key%0) NEQV key%1)+key%2) NEQV key%3
      perm%(n NEQV key%4) := x
   $)

   // randomise the start permutation
   FOR t = 0 TO 1 DO
   $( perm%256 := perm%0
      FOR n = 0 TO 255 DO
      $( perm%n := perm%x
         perm%x := perm%(n+1)
         x := perm%(x+key%(n&15)&255)
         key%(n&15) := x
      $)
   $)
$)

LET encode(str, n, perm) BE FOR t = 0 TO 2 DO
$( str%0 := str%0 NEQV perm%((str%(n-1)+str%(n-1)) & 255)
   FOR i = 1 TO n-1 DO
      str%i := str%i NEQV perm%((str%(i-1)+str%(n-1-i)) & 255)
$)

LET decode(str, n, perm) BE FOR t = 0 TO 2 DO
$( FOR i = n-1 TO 1 BY -1 DO
      str%i := str%i NEQV perm%((str%(i-1)+str%(n-1-i)) & 255)
   str%0 := str%0 NEQV perm%((str%(n-1)+str%(n-1)) & 255)
$)

MANIFEST $( size = 80 $)

LET start() BE
$( LET key = TABLE #X00000000,#X00000000,#X00000000,#X00000000
   LET perm = VEC 256/bytesperword
   LET str = VEC size/bytesperword

   FOR i = 0 TO 255  DO perm%i := i
   FOR i = 0 TO size DO str%i  := i & 255

   pr("key", key, 15)
   pr("perm",perm,255)
   writes("*NCall generate*N")

   generate(key, perm)

   pr("key", key, 15)
   pr("perm",perm,255)

   pr("str",str,size-1)

   writes("*NCall encode*N")
   encode(str, size, perm)
   pr("str",str,size-1)

   writes("*NCall decode*N")
   decode(str, size, perm)
   pr("str",str,size-1)

   writes("*NEnd of test*N")
$)  

AND pr(text, s, n) BE
$( writef("*N%S*N", text)
   FOR i = 0 TO n DO 
   $( IF i REM 16 = 0 DO newline()
      writef(" %I3", s%i)
   $)
   newline()
$)

