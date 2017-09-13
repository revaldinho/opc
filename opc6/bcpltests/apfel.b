/*
  This is a BCPL translation of a program to
  Draw a Mandelbrot Set using ASCII characters. Resolution = 79x49.
  that was implemented in T3X by Nils M.Holm<fs29@rumms.uni-mannheim.de>

  Translation by Martin Richards,  early July 1998
*/

GET "libhdr"

MANIFEST
{ SCALE = 100

//FULL = 219; UPPER =  223; LOWER = 220; EMPTY = '*s'  // IBM PC
  FULL = 'M'; UPPER = '*"'; LOWER = 'm'; EMPTY = '*s'  // ASCII
}

LET f(x, y) = VALOF
{ LET zr = 0
  LET zi = 0
  LET cr = x*SCALE/25
  LET ci = y*SCALE/20

  FOR i = 0 TO 100 DO
  { LET ir = zr*zr/SCALE - zi*zi/SCALE;
    zi := zr*zi/SCALE + zi*zr/SCALE + ci;
    zr := ir + cr;
    IF zi > 2*SCALE  | zr > 2*SCALE |
       zi < -2*SCALE | zr < -2*SCALE RESULTIS 1
  }
  RESULTIS 0
}


LET start() = VALOF
{ LET line = VEC 80
  LET even = 0;

  FOR y=-24 TO 25 DO
  { FOR x=-59 TO 20 DO
    { LET r = f(x,y);
      TEST even THEN line!(x+59) := line!(x+59)-> r-> FULL,  UPPER,
                                                  r-> LOWER, EMPTY
                ELSE line!(x+59) := r
    }
    FOR i = 0 TO 78 DO wrch(line!i)
    newline()
    even := ~even
  }
  RESULTIS 0
}

