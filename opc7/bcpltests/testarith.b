/*
This program tests the arith high precision library

Implemented by Martin Richards (c) April 2016
*/

MANIFEST {
  ArithGlobs=350
  numupb = 18
}

GET "libhdr"
GET "arith.h"
GET "arith.b"

GLOBAL {
  stdin:ug
  stdout
}

LET start() = VALOF
{ LET argv = VEC 50

  //stdin  := input()
  //stdout := output()

  UNLESS rdargs("", argv, 50) DO
  { writef("Bad arguments for cataopt*n")
    RESULTIS 0
  }

  teststr2num()
  testsettok()
  testintegerpart()
  testroundtoint()
  testcmp()
  testadd()
  //testmul()
  //testinv()
  testdiv()
  testcopy("+0.1234")
  testcopy("+0.1234 5678 9012 3456 7890 1111 2222 3333 4444 5555")
  testcopy("-0.1234 5678 9012 3456 7890 1111 2222 3333 4444 5555")

  testroundnum(2, "+0.1234")
  testroundnum(2, "+0.1234 5678 9012 3456 7890 1111 2222 3333 4444 5555")
  testroundnum(2, "-0.1234 5678 9012 3456 7890 1111 2222 3333 4444 5555")
  testroundnum(3, "+0.1234")
  testroundnum(3, "+0.1234 5678 9012 3456 7890 1111 2222 3333 4444 5555")
  testroundnum(3, "-0.1234 5678 9012 3456 7890 1111 2222 3333 4444 5555")
  testroundnum(4, "+0.1234")
  testroundnum(4, "+0.1234 5678 9012 3456 7890 1111 2222 3333 4444 5555")
  testroundnum(4, "-0.1234 5678 9012 3456 7890 1111 2222 3333 4444 5555")
abort(1000)

  testmulbyk(4, "12.34")
  testmulbyk(4, "-12.34")
  testmulbyk(4, "5000.34")

  testdivbyk(4, "12.34")
  testdivbyk(4, "-12.34")
  testdivbyk(4, "1.34")
  testdivbyk(7, "1.0")


  //testsqrt("2.0")
  testsqrt("1001928")
//RESULTIS 0
  //testsqrt("0.2")
  //testsqrt("0.02")
  //testsqrt("0.00000000000000002000")
  //testsqrt("0.000000000000000000000000000000002000")
  //testsqrt("3,0")
  //testsqrt("200.0")

  testradius("3", "4", "12")
  testradius("-38", "-22", "-1000")

  testnorm("1", "0", "0",
           "1", "1", "0"
          )

  RESULTIS 0
}

AND teststr2num(s) BE
{ LET s = ?
  LET n = VEC 8

  s := " 0123.45 E 10"; writef("%s*n", s)
  str2num(s, n,8); prnum(n,8)
  s := " 001234"; writef("%s*n", s)
  str2num(s, n,8); prnum(n,8)
  s := " 00123"; writef("%s*n", s)
  str2num(s, n,8); prnum(n,8)
  s := " 0012"; writef("%s*n", s)
  str2num(s, n,8); prnum(n,8)
  s := " 001"; writef("%s*n", s)
  str2num(s, n,8); prnum(n,8)
  s := "-00"; writef("%s*n", s)
  str2num(s, n,8); prnum(n,8)

  s := " 00.1234 5"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := "-001.2345"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := " 0012.345"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := "-00123.45"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := " 001234.5"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := "-0012 345."; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := "-00.0123 4567 89"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := " 00.0012 3456 789"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := "-00.0001 2345 6789"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := " 00.0000 1234 5678 9"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := "-00.0000 0123 4567 89"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := " 00.0000 0012 3456 789"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := "-00.0000 0001 2345 6789"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := " 00.0000 0000 1234 5678 9"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := "-00.0000 0000 0123 4567 89"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
  s := " 00.0000 0000 0012 3456 7890"; writef("%s*n",s)
  str2num(s, n,8); prnum(n,8)
}

AND testsettok() BE
{ LET k = ?
  LET n = VEC 4

  k := 1234; writef("settok(%n, n,4)*n", k)
  TEST settok(k, n,4) THEN prnum(n,4)
                      ELSE writef("k out of range*n")

  k := 12345; writef("settok(%n, n,4)*n", k)
  TEST settok(k, n,4) THEN prnum(n,4)
                      ELSE writef("k out of range*n")

  k := 0; writef("settok(%n, n,2)*n", k)
  TEST settok(k, n,4) THEN prnum(n,2)
                      ELSE writef("k out of range*n")

  k := -1234; writef("settok(%n, n,4)*n", k)
  TEST settok(k, n,4) THEN prnum(n,4)
                      ELSE writef("k out of range*n")

  k := -10000; writef("settok(%n, n,4)*n", k)
  TEST settok(k, n,4) THEN prnum(n,4)
                      ELSE writef("k out of range*n")

  k := -9999; writef("settok(%n, n,2)*n", k)
  TEST settok(k, n,4) THEN prnum(n,2)
                      ELSE writef("k out of range*n")
}

AND testintegerpart() BE
{ LET s, rc = 0, 0
  LET n = VEC 8

  s := "1234.567822223"; str2num(s, n,8)
  writef("*nrc := integerpart(*"%s*", n,8)*n", s)
  rc := integerpart(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

  s := "0.567822223"; str2num(s, n,8)
  writef("*nrc := integerpart(*"%s*", n,8)*n", s)
  rc := integerpart(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

  s := "123456789.22223"; str2num(s, n,8)
  writef("*nrc := integerpart(*"%s*", n,8)*n", s)
  rc := integerpart(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

  s := "-1234.567822223"; str2num(s, n,8)
  writef("*nrc := integerpart(*"%s*", n,8)*n", s)
  rc := integerpart(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

}

AND testroundtoint() BE
{ LET s, rc = 0, 0
  LET n = VEC 8

  s := "1234.567822223"; str2num(s, n,8)
  newline(); prnum(n,8)
  writef("rc := roundtoint(n,8)*n")
  rc := roundtoint(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

  s := "0.567822223"; str2num(s, n,8)
  newline(); prnum(n,8)
  writef("rc := roundtoint(n,8)*n", s)
  rc := roundtoint(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

  s := "123456789.22223"; str2num(s, n,8)
  newline(); prnum(n,8)
  writef("rc := roundtoint(n,8)*n", s)
  rc := roundtoint(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

  s := "-1234.567822223"; str2num(s, n,8)
  newline(); prnum(n,8)
  writef("rc := roundtoint(n,8)*n", s)
  rc := roundtoint(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

  s := "0.9999 9999 9999"; str2num(s, n,8)
  newline(); prnum(n,8)
  writef("rc := roundtoint(n,8)*n", s)
  rc := roundtoint(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)

  s := "0.4999 9999 9999"; str2num(s, n,8)
  newline(); prnum(n,8)
  writef("rc := roundtoint(n,8)*n", s)
  rc := roundtoint(n,8)
  prnum(n,8)
  writef("rc = %z8*n", rc)
}

AND testcopy(s) BE
{ LET n1 = VEC 8
  LET n2 = VEC 10
  LET n3 = VEC 6
  LET n4 = VEC 8
  writef("*n*ncopy of *"%s*"*n", s)
  UNLESS str2num(s, n1, 8) DO
  { writef("Bad string*n")
    RETURN
  }
  copy(n1,8, n2,10)
  copy(n1,8, n3,6)
  copy(n1,8, n4,8)
  prnum(n1, 8)
  prnum(n2, 10)
  prnum(n3, 6)
  prnum(n4, 8)
}

AND testroundnum(p, s) BE
{ LET n = VEC 8

  //writef("*n*nroundnum of %n *"%s*"*n", p, s)
  UNLESS str2num(s, n, 8) DO
  { writef("Bad string*n")
    RETURN
  }

  newline()
  writef("n= "); prnum(n, 8)
  writef("Calling:  roundnum(%n, n,8)*n", p)
  roundnum(p, n,8)
  writef("n= "); prnum(n, 8)
}

AND testcmp(s1, s2) BE
{ LET s1, s2 = ?, ?
  LET n1 = VEC 3
  AND n2 = VEC 5

  s1, s2 := "1.2", "1.3"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "0", "-1.3"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "0", "0"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "1.2", "0"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))


  s1, s2 := "-1.2", "1.3"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "-5", "-5"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "1.3", "1.3"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "1111.2222 3333 4444 5555 6666 7776",
            "1111.2222 3333 4444 5555 6666 7777"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "+1111.2222 3333 4444 5555 6666 7777",
            "-1111.2222 3333 4444 5555 6666 7777"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "-1111.2222 3333 4444 5555 6666 7778 E7",
            "+1111.2222 3333 4444 5555 6666 E6"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))

  s1, s2 := "1111.2222 3333 4444 5555 6666 7778 E7",
            "1111.2222 3333 4444 5555 6666 E6"
  str2num(s1, n1,3)
  str2num(s2, n2,5)
  newline()
  writef("n1=    "); prnum(n1, 3)
  writef("n2=    "); prnum(n2, 5)
  writef("numcmpu(n1,3, n2,5) => %i2*n", numcmpu(n1,3, n2,5))
  writef("numcmpu(n1,3, n2,3) => %i2*n", numcmpu(n1,3, n2,3))
  writef("numcmpu(n2,5, n1,3) => %i2*n", numcmpu(n2,5, n1,3))
  writef("numcmp(n1,3, n2,5)  => %i2*n", numcmp(n1,3, n2,5))
  writef("numcmp(n1,3, n2,3)  => %i2*n", numcmp(n1,3, n2,3))
  writef("numcmp(n2,5, n1,3)  => %i2*n", numcmp(n2,5, n1,3))
}


AND testadd() BE
{ LET s1, s2, rc = ?, ?, ?
  LET n1 = VEC 5
  AND n2 = VEC 6
  AND n3 = VEC 4
  AND t1 = VEC numupb

  s1, s2 := "0.9999 9999 9999 9333 3333 5555", "0.2000 3333 6666 5555 6666 E-3"
  str2num(s1, n1,5)
  str2num(s2, n2,6)
  newline()
  writef("n1=    "); prnum(n1, 5)
  writef("n2=    "); prnum(n2, 6)
  writef("add(n1,5, n2,6, n3,4)*n")
  TEST add(n1,5, n2,6, n3,4)
  THEN { writef("n3=    "); prnum(n3, 4)
         writef("sub(n3,4, n2,6, t1,5)*n")
         TEST sub(n3,4, n2,6, t1,5)
         THEN { writef("n3-n2= "); prnum(t1, 5) }
         ELSE { writef(" => overflow*n") }
       }
  ELSE { writef(" => overflow*n") }

  s1, s2 := "-1.2", "1.1"
  str2num(s1, n1,5)
  str2num(s2, n2,6)
  newline()
  writef("n1=    "); prnum(n1, 5)
  writef("n2=    "); prnum(n2, 6)
  writef("add(n1,5, n2,6, n3,4)*n")
  TEST add(n1,5, n2,6, n3,4)
  THEN { writef("n3=    "); prnum(n3, 4)
         writef("sub(n3,4, n2,6, t1,5)*n")
         TEST sub(n3,4, n2,6, t1,5)
         THEN { writef("n3-n2= "); prnum(t1, 5) }
         ELSE { writef(" => overflow*n") }
       }
  ELSE { writef(" => overflow*n") }

  s1, s2 := "1.2", "-1.1"
  str2num(s1, n1,5)
  str2num(s2, n2,6)
  newline()
  writef("n1=    "); prnum(n1, 5)
  writef("n2=    "); prnum(n2, 6)
  writef("add(n1,5, n2,6, n3,4)*n")
  TEST add(n1,5, n2,6, n3,4)
  THEN { writef("n3=    "); prnum(n3, 4)
         writef("sub(n3,4, n2,6, t1,5)*n")
         TEST sub(n3,4, n2,6, t1,5)
         THEN { writef("n3-n2= "); prnum(t1, 5) }
         ELSE { writef(" => overflow*n") }
       }
  ELSE { writef(" => overflow*n") }

  s1, s2 := "-1.2", "-1.1"
  str2num(s1, n1,5)
  str2num(s2, n2,6)
  newline()
  writef("n1=    "); prnum(n1, 5)
  writef("n2=    "); prnum(n2, 6)
  writef("add(n1,5, n2,6, n3,4)*n")
  TEST add(n1,5, n2,6, n3,4)
  THEN { writef("n3=    "); prnum(n3, 4)
         writef("sub(n3,4, n2,6, t1,5)*n")
         TEST sub(n3,4, n2,6, t1,5)
         THEN { writef("n3-n2= "); prnum(t1, 5) }
         ELSE { writef(" => overflow*n") }
       }
  ELSE { writef(" => overflow*n") }
}

AND testsub(s1, s2) BE
{ LET n1 = VEC 12
  LET n2 = VEC 14
  LET n3 = VEC 12
  LET t1 = VEC numupb

  str2num(s1, n1,12)
  str2num(s2, n2,14)

  writef("*nTesting sub(%s, %s)*n", s1, s2)
  //newline()
  writef("n1=    "); prnum(n1, 12)
  writef("n2=    "); prnum(n2, 14)

  UNLESS sub(n1,12, n2,14, n3,12) DO
  { writef(" => overflow*n")
    RETURN
  }
  writef("n3=    "); prnum(n3, 12)
  newline()

  add(n3,12, n2,14, t1,numupb)

  UNLESS numcmp(n1,12, t1,numupb)=0 DO
  { writef("ERROR in testsub*n")
    writef("n1=    "); prnum(n1, 12)
    writef("n2=    "); prnum(n2, 14)
    writef("n3=    "); prnum(n3, 12)
    writef("t1=    "); prnum(t1, numupb)
    abort(999)    
  }
}

AND testmul(s1, s2) BE
{ LET k1 = +2345
  LET k2 = -4567
  LET n1 = VEC 12
  LET n2 = VEC 14
  LET n3 = VEC 12
  LET t1 = VEC numupb
  LET t2 = VEC numupb
  LET t3 = VEC numupb

  str2num(s1, n1,12)
  str2num(s2, n2,14)

  writef("*nTesting mul(%s, %s)*n", s1, s2)
  //newline()
  writef("n1=    "); prnum(n1, 12)
  writef("n2=    "); prnum(n2, 14)

  UNLESS mul(n1,12, n2,14, n3,12) DO
  { writef(" => overflow*n")
    RETURN
  }
  writef("n3=    "); prnum(n3, 12)
  newline()

  setzero(t3,numupb)

  // Test mul by comparing ((k1*n1) * (k2*n2)) / k1 / k2
  // with n1 * n2

  writef("testmul, k1=%n k2=%n*n", k1, k2)
  writef("n1=    "); prnum(n1, 12)
  copy(n1,12, t1,numupb)
  mulbyk(k1,  t1,numupb)
  writef("k1**n1= "); prnum(t1, numupb)

  writef("n2=    "); prnum(n2, 14)
  copy(n2,14, t2,numupb)
  mulbyk(k2,  t2,numupb)
  writef("k2**n1= "); prnum(t2, numupb)

  mul(t1,numupb, t2,numupb, t3,numupb)
  writef("(k1**n1) ** (k2**n1)= "); prnum(t3, numupb)

  divbyk(k1,  t3,numupb)
  divbyk(k2,  t3,numupb)
  writef("((k1**n1) ** (k2**n1))/k1/k2= "); prnum(t3, numupb)
  writef("n3=    "); prnum(n3, 12)

  UNLESS numcmp(n3,12, t3,numupb)=0 DO
  { writef("ERROR in testmul, k1=%n k2=%n*n", k1, k2)
    writef("n3=    "); prnum(n3, 12)
    writef("t3=    "); prnum(t3, numupb)
    newline()
    writef("n2=    "); prnum(n2, 14)
    writef("t1=    "); prnum(t1, numupb)
    writef("t2=    "); prnum(t2, numupb)
    abort(999)    
  }
}

AND testdiv(s1, s2) BE
{ LET s1, s2 = ?, ?
  LET n1 = VEC 12
  LET n2 = VEC 14
  LET n3 = VEC 17
  LET n4 = VEC 17
  LET n5 = VEC 17
  LET t1 = VEC numupb
  LET t2 = VEC numupb
  LET t3 = VEC numupb

  s1, s2 := "3", "7"
  str2num(s1, n1,12)
  str2num(s2, n2,14)

  newline()
  writef("n1=    "); prnum(n1, 12)
  writef("n2=    "); prnum(n2, 14)
  writef("div(n1,12, n2,14, n3,17)*n")
  UNLESS div(n1,12, n2,14, n3,17) DO
  { writef(" => overflow*n")
    RETURN
  }
  writef("n3=    "); prnum(n3, 17)
  writef("Calling div(n2,14, n1,12, n4,17)*n")
  UNLESS div(n2,14, n1,12, n4,17) DO
  { writef(" => overflow*n")
    RETURN
  }
  writef("n4=    "); prnum(n4, 17)
  newline()
  writef("Calling mul(n3,17, n4,12, n5,17)*n")
  mul(n3,17, n4,17, n5,17)
  writef("n3**n4= "); prnum(n5,17)
}

AND testmulbyk(k, s) BE
{ LET n = VEC 14
  LET t1 = VEC numupb
  LET t2 = VEC numupb
  LET t3 = VEC 14

  writef("*ntestmulbyk(%n, %s)*n", k, s)
  str2num(s, n,14)

  copy(n,14, t1,numupb)
  writef("t1= "); prnum(t1,numupb)
  mulbyk(k, t1,numupb)
  writef("t1= "); prnum(t1,numupb)
  copy(t1,numupb, t2,numupb)
  divbyk(k, t2,numupb)

//writef("Calling roundnum(14, t2,numupb)*n")
  //writef("t2=    "); prnum(t2, numupb)
  roundnum(14, t2,numupb)
  copy(t2,numupb, t3,14)
  //writef("t3=    "); prnum(t3, 14)

  UNLESS numcmp(n,14, t3,14)=0 DO
  { writef("ERROR in testmulbyk, k=%n*n", k)
    writef("n=     "); prnum(n,  14)
    writef("t1=    "); prnum(t1, numupb)
    writef("t2=    "); prnum(t2, numupb)
    writef("t3=    "); prnum(t3, 14)
    abort(999)    
  }
}

AND testdivbyk(k, s) BE
{ LET n = VEC 14
  LET t1 = VEC numupb
  LET t2 = VEC numupb
  LET t3 = VEC 14

  writef("*ntestdivbyk(%n, %s)*n", k, s)
  str2num(s, n,14)

  copy(n,14, t1,numupb)
  writef("t1= "); prnum(t1,numupb)
  divbyk(k, t1,numupb)
  writef("t1= "); prnum(t1,numupb)
  copy(t1,numupb, t2,numupb)
  mulbyk(k, t2,numupb)

//writef("Calling roundnum(14, t2,numupb)*n")
  //writef("t2=    "); prnum(t2, numupb)
  roundnum(14, t2,numupb)
  copy(t2,numupb, t3,14)
  //writef("t3=    "); prnum(t3, 14)

  UNLESS numcmp(n,14, t3,14)=0 DO
  { writef("ERROR in testdivbyk, k=%n*n", k)
    writef("n=     "); prnum(n,  14)
    writef("t1=    "); prnum(t1, numupb)
    writef("t2=    "); prnum(t2, numupb)
    writef("t3=    "); prnum(t3, 14)
    abort(999)    
  }
}

AND testinv() BE
{ LET s = 0
  LET n1 = VEC 8
  AND n2 = VEC 11
  AND t1 = VEC 10

  s := "7"
  str2num(s, n1,8)
  writef("*nn1=       "); prnum(n1,8)
  UNLESS inv(n1,8, n2,11) DO
  { writef("  => overflow*n")
    RETURN
  }
  writef("1/n1=     "); prnum(n2,11)
  mul(n1,8, n2,11, t1,10)
  writef("mul(n1,8, n2,11, t1,10)*n")
  writef("n1**1/n1 = "); prnum(t1,10)

  s := "7E-5"
  str2num(s, n1,8)
  writef("*nn1=       "); prnum(n1,8)
  UNLESS inv(n1,8, n2,11) DO
  { writef("  => overflow*n")
    RETURN
  }
  writef("1/n1=     "); prnum(n2,11)
  mul(n1,8, n2,11, t1,10)
  writef("mul(n1,8, n2,11, t1,10)*n")
  writef("n1**1/n1 = "); prnum(t1,10)

  s := "7E5"
  str2num(s, n1,8)
  writef("*nn1=       "); prnum(n1,8)
  UNLESS inv(n1,8, n2,11) DO
  { writef("  => overflow*n")
    RETURN
  }
  writef("1/n1=     "); prnum(n2,11)
  mul(n1,8, n2,11, t1,10)
  writef("mul(n1,8, n2,11, t1,10)*n")
  writef("n1**1/n1 = "); prnum(t1,10)

  s := "1000"
  str2num(s, n1,8)
  writef("*nn1=       "); prnum(n1,8)
  UNLESS inv(n1,8, n2,11) DO
  { writef("  => overflow*n")
    RETURN
  }
  writef("1/n1=     "); prnum(n2,11)
  mul(n1,8, n2,11, t1,10)
  writef("mul(n1,8, n2,11, t1,10)*n")
  writef("n1**1/n1 = "); prnum(t1,10)
}

AND testsqrt(s) BE
{ LET n1 = VEC 8
  LET n2 = VEC 9
  LET n3 = VEC 10

  writef("testsqrt(%s)*n", s)

  str2num(s, n1,8)

  UNLESS sqrt(n1,8, n2,9) DO
  { writef(" => overflow*n")
    RETURN
  }

  writef("sqrt(%s) is in n2*n", s)
  writef("n2=   "); prnum(n2,9)

  writef("*nChecking n2^2 is approximately n1*n")
  mul(n2,9, n2,9, n3,10)
  writef("n2^2= "); prnum(n3,10)
}

AND testradius(s1, s2, s3) BE
{ LET t1 = VEC 10
  AND t2 = VEC 10
  AND t3 = VEC 10
  LET t4 = VEC 12

  writef("*ntestradius(%s, %s, %s)*n", s1,s2,s3)

  str2num(s1, t1,10)
  str2num(s2, t2,10)
  str2num(s3, t3,10)

  newline()

  radius(@t1, 10, t4,12)
  writef("radius= "); prnum(t4, 10)
}

AND testnorm(sx1, sy1, sz1,
             sx2, sy2, sz2) BE
{ LET tx1 = VEC 10
  AND ty1 = VEC 10
  AND tz1 = VEC 10

  LET tx2 = VEC 10
  AND ty2 = VEC 10
  AND tz2 = VEC 10

  LET t4  = VEC 12

  writef("*ntestnorm(%s, %s, %s, %s, %s, %s)*n", sx1,sy1,sz1,sx2,sy2,sz2)

  str2num(sx1, tx1,10)
  str2num(sy1, ty1,10)
  str2num(sz1, tz1,10)

  str2num(sx2, tx2,10)
  str2num(sy2, ty2,10)
  str2num(sz2, tz2,10)

  setzero(t4,12)
writef("calling nornmalize(@tx1, 10)*n")
  normalize(@tx1, 10)

  writef("*nNormalised dir1*n")
  writef("tx1= "); prnum(tx1, 10)
  writef("ty1= "); prnum(ty1, 10)
  writef("tz1= "); prnum(tz1, 10)

  normalize(@tx2, 10)
  writef("*nNormalised dir2*n")
  writef("tx2= "); prnum(tx2, 10)
  writef("ty2= "); prnum(ty2, 10)
  writef("tz2= "); prnum(tz2, 10)

  inprod(@tx1, 10,  @tx2, 10, t4,12)

  writef("*nInner product of normalized dir1 and dir2 is in t4*n")
  writef("t4= "); prnum(t4, 12)
}


