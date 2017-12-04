//
// Time different approaches to getting quotient and remainder
//
// Typ. result on a linux machine using 32b cintcode interp.
//
// Method 1 - division + multiplication :    0.940 s
// Method 2 - double division           :    0.760 s
// Method 3 - muldiv operation          :    0.610 s
//
// .. but expect the OPC7 native implementation to favour muldiv ?
//

GET "libhdr"

MANIFEST { 
         ITER = 1000
         DIVISOR = 1000
         }

LET start() BE {
    LET s, intp, fracp = ?, ?, ?
    
    newline()   
    s := sys(Sys_cputime)
    FOR i=0 TO ITER DO {
      intp := i / DIVISOR
      fracp:= i - (intp * DIVISOR)
    }
    writes("Method 1 - division + multiplication : ")
    showtimestr(sys(Sys_cputime) - s)    
    newline()

    s := sys(Sys_cputime)
    FOR i=0 TO ITER DO {
      intp := i / DIVISOR
      fracp:= i MOD DIVISOR
    }
    writes("Method 2 - division + MOD operation  : ")
    showtimestr(sys(Sys_cputime) - s)    
    newline()

    s := sys(Sys_cputime)
    FOR i=0 TO ITER DO {
      intp := muldiv(i,1,DIVISOR)
      fracp:= result2
    }
    writes("Method 3 - muldiv operation          : ")
    showtimestr(sys(Sys_cputime) - s)    
    newline()
}

AND showtimestr( interval_ms ) = VALOF {
    LET intp, fracp =  ?, ?
    // Probably should provide a simple div routine to return quo + rem in result2
    intp := interval_ms / 1000
    fracp:= interval_ms MOD 1000
    writef("%I4.%Z3 s", intp, fracp)
}
