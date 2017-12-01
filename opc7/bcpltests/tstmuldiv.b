// This is to test various versions of muldiv
// for both speed and accuracy.

GET "libhdr"

GLOBAL { fails: ug }

LET start() = VALOF
{
  t1()
  t2()
  t3(31000123, 35000123, 541000123)
  t4()

  // Now test the call with fixed dividers
  t5()  // div 2^20
  t6()  // div 2^16
  t7()  // div 2^24  

  TEST fails=0 THEN
       writes("*n*c P A S S - all muldiv() calls match BCPL computed values*n*c")
  ELSE
       writef("*n*c F A I L - %I muldiv() calls failed to match BCPL computed values*n*c", fails)
       
  RESULTIS 0
}

AND t1() BE
{ LET a = 31000123
  LET b = 25000123
  LET c = 29000123
  LET t0 = sys(Sys_cputime)
  FOR i = 1 TO 10 DO
  { muldiv( a,  b,  c)
    muldiv(-a,  b,  c)
    muldiv( a, -b,  c)
    muldiv(-a, -b,  c)
    muldiv( a,  b, -c)
    muldiv(-a,  b, -c)
    muldiv( a, -b, -c)
    muldiv(-a, -b, -c)
    muldiv( a,  b,  c)
    muldiv( a,  b,  c)
  }
  newline()
  writef("time taken t1 = %d  -- 100 calls of muldiv(...)*n*c",
          sys(Sys_cputime)-t0)
}

AND t2() BE
{ LET a = 31000123
  LET b = 25000123
  LET c = 29000123
  LET t0 = sys(Sys_cputime)
  FOR i = 1 TO 10 DO
  { sys(Sys_muldiv,  a,  b,  c, 0)
    sys(Sys_muldiv, -a,  b,  c, 0)
    sys(Sys_muldiv,  a, -b,  c, 0)
    sys(Sys_muldiv, -a, -b,  c, 0)
    sys(Sys_muldiv,  a,  b, -c, 0)
    sys(Sys_muldiv, -a,  b, -c, 0)
    sys(Sys_muldiv,  a, -b, -c, 0)
    sys(Sys_muldiv, -a, -b, -c, 0)
    sys(Sys_muldiv,  a,  b,  c, 0)
    sys(Sys_muldiv,  a,  b,  c, 0)
  }
  newline()
  writef("time taken t2 = %d  -- 100 calls of sys(Sys_muldiv,...)*n*c",
          sys(Sys_cputime)-t0)
}

AND t3(a, b, c) BE
{ LET a1 = muldiv(a,b,c)
  LET r1 = result2
  LET a2 = sys(Sys_muldiv, a, b, c, 0)
  LET r2 = result2
  LET a3 = (a*b)/c
  LET r3 = (a*b) MOD c

  UNLESS a1=a2 & r1=r2 DO {
    writef("muldiv(%n,%n,%n) => %n rem %n  muldiv1 => %n rem %n*n*c",
            a,b,c, a1, r1, a2, r2)
    fails := fails + 1
    }
  IF a=1 | b=1 UNLESS a1=a3 & r1=r3 DO {
    writef("muldiv(%n,%n,%n) => %n rem %n  (a**b)/c => %n rem %n*n*c",
            a,b,c, a1, r1, a3, r3)
    fails := fails + 1
  }
}

AND t4() BE
{ FOR i = 0 TO 5 DO
  {
    t3(0+i, 100, 110)
    t3(0-i, 100, 110)
    t3(minint+i, 100, 110) 
    t3(maxint-i, 100, 110) 

    t3(0+i, -100, 110)
    t3(0-i, -100, 110)
    t3(minint+i, -100, 110) 
    t3(maxint-i, -100, 110) 

    t3(0+i, 100, -110)
    t3(0-i, 100, -110)
    t3(minint+i, 100, -110) 
    t3(maxint-i, 100, -110) 

    t3(0+i, -100, -110)
    t3(0-i, -100, -110)
    t3(minint+i, -100, -110) 
    t3(maxint-i, -100, -110) 


    t3(0+i, 1, 110)
    t3(0-i, 1, 110)
    t3(minint+i, 1, 110) 
    t3(maxint-i, 1, 110) 

    t3(0+i, -1, 110)
    t3(0-i, -1, 110)
    t3(minint+i, -1, 110) 
    t3(maxint-i, -1, 110) 

    t3(0+i, 1, -110)
    t3(0-i, 1, -110)
    t3(minint+i, 1, -110) 
    t3(maxint-i, 1, -110) 

    t3(0+i, -1, -110)
    t3(0-i, -1, -110)
    t3(minint+i, -1, -110) 
    t3(maxint-i, -1, -110) 
  }
}

AND t5() BE
{ LET a = 31001
  LET b = 25001
  LET c = 1 << 20    // 2^20
  LET a1 = (a*b)/c
  LET r1 = (a*b) MOD c
  LET a2 =  sys(Sys_muldiv,  a,  b, 0, 1) 
  LET r2 =  result2
  UNLESS a1=a2 & r1=r2 DO {
    writef("muldiv(%n,%n,%n) => %n rem %n  muldiv1 => %n rem %n*n*c",
            a,b,c, a1, r1, a2, r2)
    fails := fails + 1
    }  
}

AND t6() BE
{ LET a = 31001
  LET b = 25001
  LET c = 1 << 16    // 2^16
  LET a1 = (a*b)/c
  LET r1 = (a*b) MOD c
  LET a2 =  sys(Sys_muldiv,  a,  b, 0, 0) 
  LET r2 =  result2
  UNLESS a1=a2 & r1=r2 DO {
    writef("muldiv(%n,%n,%n) => %n rem %n  muldiv1 => %n rem %n*n*c",
            a,b,c, a1, r1, a2, r2)
    fails := fails + 1
    }  
}

AND t7() BE
{ LET a = 31001
  LET b = 25001
  LET c = 1 << 24    // 2^24
  LET a1 = (a*b)/c
  LET r1 = (a*b) MOD c
  LET a2 =  sys(Sys_muldiv,  a,  b, 0, 2) 
  LET r2 =  result2
  UNLESS a1=a2 & r1=r2 DO {
    writef("muldiv(%n,%n,%n) => %n rem %n  muldiv1 => %n rem %n*n*c",
            a,b,c, a1, r1, a2, r2)
    fails := fails + 1
    }  
}
