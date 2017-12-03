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

  IF ~istubeplatform(1) DO {
    writes("Sorry - this program only works in the Acorn BBC Microcomputer Tube environment*n")
    RESULTIS 0
  }

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

AND istubeplatform(verbose) = VALOF {
  LET platform_str = ?
  LET platform_id = sys(Sys_platform)
  IF platform_id \= 255 DO platform_id := platform_id - 32
  SWITCHON platform_id INTO {
    DEFAULT: platform_str := 0               ; ENDCASE  
    CASE 0 : platform_str := "Electron"      ; ENDCASE
    CASE 1 : platform_str := "BBC Micro"     ; ENDCASE
    CASE 2 : platform_str := "BBC B+"        ; ENDCASE
    CASE 3 : platform_str := "Master 128"    ; ENDCASE
    CASE 4 : platform_str := "Master ET"     ; ENDCASE
    CASE 5 : platform_str := "Master Compact"; ENDCASE
    CASE 6 : platform_str := "RISC OS"       ; ENDCASE
  }
  
  TEST (platform_str & verbose) DO {
     writef("Detected Acorn Tube host as %s (%I )*n*c", platform_str, platform_id)
     RESULTIS 1
  } ELSE {
     IF verbose DO writef("Detected Non-Acorn Tube host as ID %I *n*c", platform_id)  
     RESULTIS 0  
  }       
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
