 // Insert the SDL library source code as a separate section

GET "libhdr"

GLOBAL {
  a:ug
  b
  size
  limit    // The iteration limit
}

MANIFEST {
  One   = 100_000_000 // The number representing 1.00000000
  width = 1024        // BBC plot area
  height= 1024
  
  VDU_GCOL   = 18     // Constants for the BBC graphics routines
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

  GCOL15_BLACK  = 0     // Mode 1,5 colours
  GCOL15_RED    = 1
  GCOL15_GREEN  = 2
  GCOL15_YELLOW = 3
  GCOL15_BLUE   = 4
  GCOL15_MAGENTA= 5
  GCOL15_CYAN   = 6
  GCOL15_WHITE  = 7  
}

LET start() = VALOF
{ LET s = 0           // Region selector
  // Default settings
  a, b, size := -50_000_000, 0, 180_000_000
  limit := 38

  IF 1<=s<=7 DO
  { LET limtab = TABLE  38,  38,  38,  54,  70,  //  0 
                        80,  90, 100, 100, 110,  //  5 
                       120, 130, 140, 150, 160,  // 10 
                       170, 180, 190, 200, 210,  // 15 
                       220                       // 20 
    limit := limtab!s
    a, b, size := -52_990_000, 66_501_089,  50_000_000
    FOR i = 1 TO s DO size := size / 10
  }

  VDU(VDU_MODE,2)       // Get colours rather than resolution
  writes("Mandelbrot")

  plotset()

  RESULTIS 0
}

AND plotset() BE {
  LET mina = a - size
  LET minb = b - size
  LET doublesize = 2 * size
  LET newcolour,colour = 0,0
  VDU(VDU_GCOL,0,colour)

  FOR x = 0 TO (width-1) DO {
    FOR y = 0 TO (height-1) DO {  
        LET itercount = ?
        LET p, q = ?, ?
    
        // Calculate c = p + iq corresponding to pixel (x,y)
        p := mina + muldiv(doublesize, x, width)
        q := minb + muldiv(doublesize, y, height)
    
        itercount := mandset(p, q, limit)    
    
        TEST itercount<0 
        THEN newcolour := GCOL2_BLACK
        ELSE newcolour := muldiv(itercount,7,limit)  // Pick from 8 (0-7) colours for full range
    
        UNLESS newcolour = colour DO {
            VDU(VDU_GCOL,0,newcolour)
            colour := newcolour
        }
        VDU(VDU_PLOT,GMOVE,x,y)  // Plot x,y
        VDU(VDU_PLOT,GDRAW,x,y)    
      }
  }
}

AND mandset(a, b, n) = VALOF
{ LET x, y = 0, 0  // z = x + iy is initially zero
                   // c = a + ib is the point we are testing
  LET x3,y3,t, rsq = 0,0,0,0
  
  FOR i = 0 TO n DO {
    rsq := muldiv(x3, x3, One) + muldiv(y3, y3, One)
    x3 := x/3 // To avoid possible overflow
    y3 := y/3 
    // Test whether z is diverging, ie is x^2+y^2 > 1
    IF rsq > One RESULTIS i
    // Square z and add c
    // Note that (x + iy)^2 = (x^2-y^2) + i(2xy)
    t := muldiv(2*x, y, One) + b
    x := muldiv(x, x, One) - muldiv(y, y, One) + a
    y := t 
  }
  // z did not diverge after n iterations
  RESULTIS -1
}

/* -------------------------------------------------------------
 *
 * BBC Graphics routines - to be split into a new library later
 *
 * ------------------------------------------------------------- */

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











    
