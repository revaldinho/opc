/*
 * Program to generate Pi using the basic spigot algorithm from
 * 
 * http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
 *
 * Revaldinho 2017
 *
 */

GET "libhdr"

MANIFEST {
         DIGITS         = 32                    // Digits to compute
         BASE           = 10                    // Base to use
         DIGIT_GROUPS   = 32                    // should be DIGITS/log10(BASE)
         COLS           = 1 + DIGITS *10/3      // Columns requires for digit count
         BUFSIZE        = 4                     // Buffer size to allow for predigit correction
}         

LET start() = VALOF
{  
  LET rem = VEC COLS                             // vector for remainder data
  LET predigit = VEC BUFSIZE                     // buffer digits in case corrections are needed
  LET digit = 0                                  
  LET c = 0                                     

  // Preload remainder data
  FOR i=0 TO (COLS-1) DO rem[i] := 2 * BASE/10
  
  FOR dignum=0 TO (DIGIT_GROUPS-1) DO {
      LET q = 0
      LET i = COLS-1
      LET denom = 0
      UNTIL i=0 DO {
          q := q + (rem[i])*BASE
          denom := (i<<1) - 1
          rem[i] := (q REM denom)
          q := q / denom
          i := i - 1
          IF i>0 THEN  {
             q := q * i
             }
      }
      digit := c + q / BASE
      c := q REM BASE

      // Predigit correction
      IF digit=BASE THEN {
         LET carry = 1
         LET ptr = (BUFSIZE-1)
         UNTIL carry = 0 DO {   
               carry := 0      
               predigit!ptr := predigit!ptr + 1
               IF predigit!ptr = BASE THEN {
                  carry := 1
                  predigit!ptr := 0
                  ptr := ptr - 1
                  IF ptr < 0 THEN BREAK
               }
         }         
         digit := 0
      }

      TEST dignum >= BUFSIZE THEN { 
         writed(predigit!0,1)
         FOR j=1 TO BUFSIZE-1 DO predigit!(j-1) := predigit!j
         predigit!(BUFSIZE-1) := digit
         IF ( BASE=10 & dignum=BUFSIZE) THEN wrch('.')
      } ELSE {
         predigit!dignum := digit
      }
  }

  // Empty the buffer
  FOR i = 0 TO BUFSIZE-1 DO writed(predigit!i,1)
  newline()
  RESULTIS 0
}
