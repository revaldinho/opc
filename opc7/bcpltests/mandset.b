GET "libhdr"

GET "beeblib.b"

GLOBAL {
  a:ug
  b
  size
  limit    // The iteration limit
}

MANIFEST {
  One   = 1<<20      // The number representing 1.00000000 in a 12.20b fixed point system
  width = 320        // BBC plot area
  height= 256  
}

LET start() = VALOF
{ LET region = 0           // Region selector
  LET runagain = 1

  IF ~istubeplatform(1) DO {
    writes("Sorry - this program only works in the Acorn BBC Microcomputer Tube environment*n")
    RESULTIS 0
  }

  // Default settings
  // a, region, size := -50_000_000, 0, 180_000_000
  a      := -(One >>1 )
  b      := 0
  size   := muldiv(One,18,10)

  WHILE runagain DO {
    VDU(VDU_MODE,2)       // Get colours rather than resolution
    writes("Mandelbrot")

    newline()
    writes("Choose region to plot (0-9)*n*c")
    region := nummenu(9)
  
    limit := 38

    IF 1<=region<=7 DO {
       LET limtab = TABLE  38,  38,  38,  54,  70,  //  0 
                           80,  90, 100, 100, 110,  //  5 
                          120, 130, 140, 150, 160,  // 10 
                          170, 180, 190, 200, 210,  // 15 
                          220                       // 20 
      limit := limtab!region
      //a, b, size := -52_990_000, 66_501_089,  50_000_000
      a     := -muldiv(One, 52_990_000, 100_000_000)
      b     := muldiv(One, 66_501_089, 100_000_000)
      size  := muldiv(One, 50_000_000, 100_000_000)
      FOR i = 1 TO region DO size := size / 10
    }  

    plotset()

    writes("Run again ? (Y/N)*n*c")
    runagain := ynchoice()    
  }
  RESULTIS 0
}

AND plotset(b) BE {
  LET mina = a - size
  LET minb = b - size
  LET doublesize = 2 * size
  LET newcolour,colour = 0,0
  LET screenx,screeny = ?,?
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
        screenx := x << 2 // BBC coordinate system is 0..1024 all modes
        screeny := y << 2 
        VDU(VDU_PLOT,GMOVE,screenx, screeny)  
        VDU(VDU_PLOT,GDRAW,screenx, screeny)
      }
  }
}

AND mandset(a, b, n) = VALOF
{ LET x, y = 0, 0  // z = x + iy is initially zero
                   // c = a + ib is the point we are testing
  LET x3,y3,t, rsq = 0,0,0,0
  
  FOR i = 0 TO n DO {
    rsq := muldiv12p20(x3, x3) + muldiv12p20(y3, y3)  
    x3 := x/3 // To avoid possible overflow
    y3 := y/3 
    // Test whether z is diverging, ie is x^2+y^2 > 1
    IF rsq > One RESULTIS i
    // Square z and add c
    // Note that (x + iy)^2 = (x^2-y^2) + i(2xy)
    t := muldiv12p20(x<<1, y) + b
    x := muldiv12p20(x, x) - muldiv12p20(y, y) + a
    y := t 
  }
  // z did not diverge after n iterations
  RESULTIS -1
}

AND muldiv16p16(a,b) BE {
    sys(Sys_muldiv, a, b, 0, 0)
}
AND muldiv12p20(a,b) BE {
    sys(Sys_muldiv, a, b, 0, 1)
}
AND muldiv8p24(a,b) BE {
    sys(Sys_muldiv, a, b, 0, 2)
}

AND nummenu(max) = VALOF {
    WHILE 1 DO {
        LET choice = 0
        LET c = rdch()
        choice := c - '0'
        IF choice >= 0 DO {
           IF choice <= max {
              RESULTIS choice
           }
        }
     sys(Sys_delay, 100)
   }
}

AND ynchoice() = VALOF {
    LET choice = 0
    WHILE 1 DO {
        LET c = capitalch(rdch())
        IF c = 'Y' THEN RESULTIS 1
        IF c = 'N' THEN RESULTIS 0
        sys(Sys_delay, 100)
   }
}










    
