/*
   This will be another encoding of the German Enigma Machine

   Implemented in BCPL by Martin Richards (c) September 2000

   ************** STILL UNDER DEVELOPMENT *******************

   2017-09-04 Revaldinho. Fixed wheel order so encrypted text agrees with expected data
   
*/

GET "libhdr"

GLOBAL {
  plug:ug;    reflect

  wheelA1; wheelA2; posA; notchA
  wheelB1; wheelB2; posB; notchB
  wheelC1; wheelC2; posC; notchC

  permA;   permB;   permC
}

LET start() = VALOF
{ LET mess = VEC 1000
  LET data = "THERAININSPAINSTAYSMAINLYONTHEPLANE"
  LET reference = "ZXRQNLEAWAGHZFRDNVCZRKDUXMPHRHGUWZL"
  
  mess%0 := data%0
  
  writef("*n*cdata =     %s*n*c*n*c", data)
  
  init()

  // encode data
  setup(2,1,0)
  plugswap("AB")
  plugswap("CD")
  plugswap("EF")
  plugswap("GH")
  plugswap("IJ")

  setpos("AAA")

  FOR i = 1 TO data%0 DO mess%i := code(data%i)
  writef("*n*cmess =     %s*n*c", mess)
  TEST ( compstring(mess, reference)= 0 ) THEN {
     writes ( "PASS !")
  } ELSE {
   writes ("FAIL")
  }
  newline()
  newline()

  // decode message
  setup(2,1,0)
  plugswap("AB")
  plugswap("CD")
  plugswap("EF")
  plugswap("GH")
  plugswap("IJ")

  setpos("AAA")
  writef("*n*cgives  ")  
  
  FOR i = 1 TO mess%0 DO wrch(code(mess%i))
  newline()
  uninit()
  RESULTIS 0
}

AND init() BE
{ plug    := allocperm()
  reflect := allocperm()
  wheelA1 := allocperm()
  wheelA2 := allocperm()
  wheelB1 := allocperm()
  wheelB2 := allocperm()
  wheelC1 := allocperm()
  wheelC2 := allocperm()
}

AND allocperm() = VALOF
{ LET v = getvec(25)
  FOR i = 0 TO 25 DO v!i := i
  RESULTIS v
}

AND uninit() BE
{ freevec(plug)
  freevec(reflect)
  freevec(wheelA1)
  freevec(wheelA2)
  freevec(wheelB1)
  freevec(wheelB2)
  freevec(wheelC1)
  freevec(wheelC2)
}

AND wheel(i) = VALOF SWITCHON i INTO
{ DEFAULT: RESULTIS abort(9999)

  // Available wheels -- these must be permutations

  CASE  0: result2 := 'Q'
           //       "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
           RESULTIS "EKMFLGDQVZNTOWYHXUSPAIBRCJ"
  CASE  1: result2 := 'E'
           //       "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  
           RESULTIS "AJDKSIRUXBLHWTMCQGZNPYFVOE"
  CASE  2: result2 := 'V'
           //       "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  
           RESULTIS "BDFHJLCPRTXVZNYEIWGAKMUSQO"
  CASE  3: result2 := 'J'
           //       "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  
           RESULTIS "ESOVPZJAYQUIRHXLNFTGKDCMWB"
  CASE  4: result2 := 'Z'
           //       "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  
           RESULTIS "VZBRGITYUPSDNHLXAWMJQOFECK"
}
/*
   bombe THERAININSPAINSTAYSMAINLYONTHEPLANE
         ZXRQNLEAWAGHZFRDNVCZRKDUXMPHRHGUWZL
         x.x.x.xx.x..x.xxx...x.x

This is taken from an E-Mail correspondence between Nik Shaylor and Tony Sale. 
The correct answer is 
     Wheel order:     321,
     Ringstellung:   'AAA',
     Start position: 'AAA',
     Steckers:        AB CD EF GH IJ
*/

AND setup(a, b, c) BE
{ // Plug board setting -- must be self inverse  i->i allowed
  setperm(plug,      "ABCDEFGHIJKLMNOPQRSTUVWXYZ")

  // Reflector setting -- must be self inverse i->i not allowed
  setperm(reflect, "YRUHQSLDPXNGOKMIEBFZCWVJAT")
//setperm(reflect, "FVPJIAOYEDRZXWGCTKUQSBNMHL")

  // Wheel selection
  permA := wheel(a); notchA := result2 - 'A'
  permB := wheel(b); notchB := result2 - 'A'
  permC := wheel(c); notchC := result2 - 'A'

  writef("Wheel selection: %n %n %n*n*c", a, b, c)
}

AND plugswap(str) BE
{ LET a = str%1 - 'A'
  LET b = str%2 - 'A'
  LET t = plug!a
  plug!a := plug!b
  plug!b := t
  
  writef("Plugboard swap: %s*n*c", str)
}


AND setpos(pos) BE // Set the initial wheel positions
{ UNLESS pos%0=3 DO abort(9999)

  writef("Initial wheels positions: %s*n*c", pos)
  writes("Initial wheels positions: ")
  posA := pos%1-'A'
  posB := pos%2-'A'
  posC := pos%3-'A'
  setperms(wheelA1, wheelA2, permA, posA)
  setperms(wheelB1, wheelB2, permB, posB)
  setperms(wheelC1, wheelC2, permC, posC)
}

AND setperm(p, str) BE
{ FOR i = 0 TO 25 DO
    p!i := str%(i+1) - 'A'
}

AND setperms(p1, p2, str, pos) BE
{ FOR i = 0 TO 25 DO
  { LET x = (i+pos) REM 26
    LET y = str%(x+1) - 'A'
    LET j = (y+26-pos) REM 26
    p1!i := j
    p2!j := i
  }
}

AND code(ch) = VALOF
{ // First step the wheels
  IF posC=notchC DO
  { IF posB=notchB DO
    { posA := posA+1
      IF posA>25 DO posA := 0
      setperms(wheelA1, wheelA2, permA, posA)
    }
    posB := posB+1
    IF posB>25 DO posB := 0
    setperms(wheelB1, wheelB2, permB, posB)
  }
  posC := posC+1
  IF posC>25 DO posC := 0
  setperms(wheelC1, wheelC2, permC, posC)

  RESULTIS 'A' + (ch-'A')!plug!
                          wheelC1!wheelB1!wheelA1!
                          reflect!
                          wheelA2!wheelB2!wheelC2!
                          plug
}

AND prperm(str, v) BE 
{ writef("%s: ", str)
  FOR i = 0 TO 25 DO wrch(v!i+'A')
  newline()
}