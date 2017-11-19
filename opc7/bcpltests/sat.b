GET "libhdr"

GLOBAL { terms:200; all:201; upb:202 }

LET setdata() BE
{ MANIFEST { A=1;    B=A<<2; C=B<<2; D=C<<2; E=D<<2
             F=E<<2; G=F<<2; H=G<<2; I=H<<2; J=I<<2
             a=2;    b=a<<2; c=b<<2; d=c<<2; e=d<<2
             f=e<<2; g=f<<2; h=g<<2; i=h<<2; j=i<<2
           }

  all := A+B+C+D+E+F+G+H+I+J

  terms := TABLE A+C+e, A+C+I, A+C+j, A+c+I, A+D+g,
                 A+d+e, A+e+H, A+f+J, a+B+j, a+D+H,
                 a+d+g, a+e+F, a+F+i, a+f+j, a+i+J,
                 B+D+f, B+g+i, B+h+i, b+C+f, b+D+h,
                 b+f+g, b+f+j, b+H+J, b+i+J, C+d+F,
                 C+E+h, C+G+j, C+g+j, c+D+e, c+d+h,
                 c+G+h, D+F+h, D+g+i, D+g+j, D+h+J,
                 d+E+F, d+e+F, E+G+i, e+G+H, e+I+j,
                 F+h+I, f+g+i, f+H+i

  upb := 42
}

LET start() = VALOF
{ setdata()
  writef("Solving a 3-SAT problem with %n terms*n*n", upb+1)
  try(0, all, 0, 0)
  RESULTIS 0
}

AND try(settings, avail, tried, i) BE
{ LET term, poss = ?, ?

  IF i>upb DO
  { writef("Solution found:  ")
    prsolution(settings)
    newline()
    RETURN
  }

  term := terms!i

  IF (term & settings) ~= 0 DO // test if term already satisfied
  { try(settings, avail, tried, i+1)
    RETURN
  }

  // term not yet satisfied
  poss := term & #b11*avail & ~tried

  // poss contains all ways in which the term can be satisfied

  UNTIL poss=0 DO // try them in turn
  { LET bit = poss & -poss
    poss := poss - bit
    tried := tried + bit
    TEST (bit & avail)=0
    THEN try(settings+bit, avail-bit/2, tried, i+1)
    ELSE try(settings+bit, avail-bit,   tried, i+1)
  }
}

AND prsolution(settings) BE
{ LET lets = "AaBbCcDdEeFfGgHhIiJj"
  FOR i = 1 TO lets%0 UNLESS (settings>>i-1 & 1)=0 DO wrch(lets%i)
}

/* outputs:

Solving a 3-SAT problem with 43 terms

Solution found AbCDeFghij
Solution found AbDeFghij
Solution found AbcDEFgHij

*/
   







