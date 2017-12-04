GET "libhdr"

GET "beeblib.b"

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

