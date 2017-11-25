GET "libhdr"

MANIFEST {
  VDU_GCOL   = 18
  VDU_CLRGFX = 16
  VDU_PLOT   = 25
  VDU_MODE   = 22
  GMOVE      =  4
  GDRAW      =  5
  GTRI       = 85  
}

LET start() = VALOF {

  VDU(VDU_CLRGFX)
  VDU(VDU_MODE, 2)  
  FOR i=0 TO 25 DO {
    LET w=randno(4)*100
    LET h=randno(4)*100    
    LET x=randno(9)*100 - 100
    LET y=randno(9)*100 - 100
    LET c=randno(7)
    VDU(VDU_GCOL, 0, c)
    
    VDU(VDU_PLOT, GMOVE, x,   y)
    VDU(VDU_PLOT, GDRAW, x+w, y)
    VDU(VDU_PLOT, GTRI,  x+w, y+h)
    VDU(VDU_PLOT, GMOVE, x+w, y+h)    
    VDU(VDU_PLOT, GDRAW, x,   y+h)
    VDU(VDU_PLOT, GDRAW, x,   y)
    VDU(VDU_PLOT, GTRI,  x+w, y+h)    
  }    
  RESULTIS 0
}

AND lowbyte(n) = VALOF {
  RESULTIS (n & #x00FF)
}

AND highbyte(n) = VALOF {
  RESULTIS ((n & #xFF00) >> 8)
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
    DEFAULT:         s%0 := 6; ENDCASE
    CASE VDU_CLRGFX: s%0 := 1; ENDCASE 
    CASE VDU_MODE:   s%0 := 2; ENDCASE 
    CASE VDU_GCOL:   s%0 := 3; ENDCASE     
    CASE VDU_PLOT:   s%0 := 6; ENDCASE 
  }

  writes(s)
}
