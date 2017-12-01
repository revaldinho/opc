GET "libhdr"

MANIFEST {  
  FIXPOINTSCALE = 1_000_000
  PI            = 3_141_593
  MAXTERMS      = 22

  VDU_GCOL   = 18
  VDU_CLRGFX = 16
  VDU_CLRTXT = 12
  VDA_GRAORG = 29
  VDU_PLOT   = 25
  VDU_MODE   = 22
  GMOVE      =  4
  GDRAW      =  5
  GTRI       = 85  
}

LET start() = VALOF { 
  LET x,y = ?,?
  LET scale = 400
  VDU(VDU_CLRGFX)
  VDU(VDU_CLRTXT)  
  VDU(VDU_MODE, 5)

  VDU29(640,512)

  FOR colour = 1 TO 7 DO {
    VDU(VDU_GCOL, 0,colour)  
    VDU(VDU_PLOT,GMOVE,0,0)
    FOR phi= 0 TO 126_000_000 BY 0_250_000 DO {
      x := muldiv(sine(phi), scale, FIXPOINTSCALE)
      y := muldiv(muldiv(cosine(phi), sine(muldiv(phi,0_950_000, FIXPOINTSCALE)), FIXPOINTSCALE),scale,FIXPOINTSCALE)
      //writef("Drawto (%I ,%I )*n*c", x, y)       
      VDU(VDU_PLOT,GDRAW,x,y)  
    }
  }
  RESULTIS 0
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

AND lowbyte(n) = VALOF {
  RESULTIS (n & #x00FF)
}

AND highbyte(n) = VALOF {
  RESULTIS ((n & #xFF00) >> 8)
}

AND VDU29(x,y) BE {  
  LET s = VEC 6
  s%0 := 5
  s%1 := 29    
  s%2 := lowbyte(x)
  s%3 := highbyte(x)                
  s%4 := lowbyte(y)
  s%5 := highbyte(y)            
  writes(s)
}
    
AND VDU(n,a,b,c,d,e) BE {
  LET s = VEC 8
    
  s%0 := 6
  s%1 := lowbyte(n)    
  s%2 := lowbyte(a)
  s%3 := lowbyte(b)
  s%4 := highbyte(b)        
  s%5 := lowbyte(c)
  s%6 := highbyte(c)

  SWITCHON n INTO {
    DEFAULT:         s%0 := 6 ; ENDCASE
    CASE VDU_CLRGFX: s%0 := 1 ; ENDCASE
    CASE VDU_CLRTXT: s%0 := 1 ; ENDCASE    
    CASE VDU_MODE:   s%0 := 2 ; ENDCASE
    CASE VDU_GCOL:   s%0 := 3 ; ENDCASE
    CASE VDU_PLOT:   s%0 := 6 ; ENDCASE        
  }
  TEST s%0 = 1 THEN
    wrch( s%1)
  ELSE
    writes(s)
}













    
