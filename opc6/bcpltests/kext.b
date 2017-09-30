//
// Test system extension calls
//

GET "libhdr"

MANIFEST {
         OS_WRCH = #xFFEE
         OS_NEWL = #xFFE7
}


LET start() = VALOF
{

  LET s = "Hello World (via sys_ext)!"

  FOR i=0 TO s%0 DO sys( Sys_ext, OS_WRCH, s%(i+1))
  sys( Sys_ext, OS_NEWL )
  RESULTIS 0
}
