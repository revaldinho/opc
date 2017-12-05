GET "libhdr"
GET "beeblib.b"

MANIFEST {  
  FIXPOINTSCALE = 1_000_000
  PI            = 3_141_593
  MAXTERMS      = 22
}

LET start() = VALOF {
  TEST istubeplatform(1) THEN {
    bbcsphere()
  } ELSE {
    testsphere()
  }
}

AND testsphere() BE {
  LET x,y = ?,?
  LET scale = 400
  FOR phi= 0 TO 126_000_000 BY 0_500_000 DO {
    x := muldiv(sine(phi), scale, FIXPOINTSCALE)
    y := muldiv(muldiv(cosine(phi), sine(muldiv(phi,0_950_000, FIXPOINTSCALE)), FIXPOINTSCALE),scale,FIXPOINTSCALE)
    writef("Drawto (%I ,%I )*n*c", x, y)       
  }
}

AND bbcsphere() BE {
  LET x,y = ?,?
  LET scale = 400
  LET timenow = ?
  VDU(VDU_CLRGFX)
  VDU(VDU_CLRTXT)  
  VDU(VDU_MODE, 5)

  VDU29(640,512)

  FOR colour = 1 TO 7 DO {
    timenow := sys(Sys_cputime)  
    VDU(VDU_GCOL, 0,colour)  
    VDU(VDU_PLOT,GMOVE,0,0)
    FOR phi= 0 TO 126_000_000 BY 0_250_000 DO {
      x := muldiv(sine(phi), scale, FIXPOINTSCALE)
      y := muldiv(muldiv(cosine(phi), sine(muldiv(phi,0_950_000, FIXPOINTSCALE)), FIXPOINTSCALE),scale,FIXPOINTSCALE)
      //writef("Drawto (%I ,%I )*n*c", x, y)       
      VDU(VDU_PLOT,GDRAW,x,y)  
    }
    wrch(30)
    showtimestr( sys(Sys_cputime) - timenow )
  }  
}

AND cosine(phi) = VALOF {
  LET sum, n, negt2, term = 0, 2, ?, FIXPOINTSCALE  // Term starts at 1 for cos
  IF phi >= (2*PI) DO phi := phi MOD (2*PI)
  negt2  := -muldiv(phi, phi, FIXPOINTSCALE)
  UNTIL (term=0 | n>MAXTERMS) DO  { 
    sum  := sum + term                                                
    term := muldiv( term, negt2, FIXPOINTSCALE * n * (n-1) )       
    n := n+2
  }
  RESULTIS sum                   
}

AND sine(phi) = VALOF {
  LET sum, n, negt2, term  = 0, 3, ?, ?
  IF phi >= (2*PI) DO phi := phi MOD (2*PI)
  negt2  := -muldiv(phi, phi, FIXPOINTSCALE)
  term   := phi         // ie start at phi for sine (already in fixed point format)
  UNTIL (term = 0 | n>MAXTERMS) DO  { 
    sum  := sum + term                                                
    term := muldiv( term, negt2, FIXPOINTSCALE * n * (n-1))       
    n := n+2
  }
  RESULTIS sum                   
}

AND print(num) BE {
    LET integer,decimal, sign = 0,0,""
    integer := muldiv(num,1,FIXPOINTSCALE)
    decimal := result2
    IF (integer=0 & (decimal<0)) DO {
        sign := "-"
        decimal := -decimal
    }      
    writef("%s%Z .%Z6", sign, integer, decimal)    
}

AND showtimestr( interval_ms ) = VALOF {
    // BBC timer actually only accurate to 100th of s so show only two decimal places
    LET intp, fracp =  ?, ?
    intp := interval_ms / 1000
    fracp:= (interval_ms MOD 1000)/10
    writef("%I4.%Z2 s", intp, fracp)
}













    
