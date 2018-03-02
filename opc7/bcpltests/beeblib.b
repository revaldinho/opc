/*
 * beeblib.b
 * 
 * BBC Tube toolbox routines for use with OPC6/7 coprocessors
 *
 */

MANIFEST {
  VDU_GCOL   = 18
  VDU_CLRGFX = 16
  VDU_CLRTXT = 12
  VDA_GRAORG = 29
  VDU_PLOT   = 25
  VDU_MODE   = 22
  GMOVE      =  4
  GDRAW      =  5
  GTRI       = 85  

  GCOL2_BLACK  = 0     // Mode 2 colours
  GCOL2_RED    = 1
  GCOL2_GREEN  = 2
  GCOL2_YELLOW = 3
  GCOL2_BLUE   = 4
  GCOL2_MAGENTA= 5
  GCOL2_CYAN   = 6
  GCOL2_WHITE  = 7  
}

LET istubeplatform(verbose) = VALOF {
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
     writef("Detected Acorn Tube host as %s *n*c", platform_str)
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
