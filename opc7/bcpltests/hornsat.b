/* 

This is an implementation in BCPL of the O(n**2) algorithm to test the
satisfiability of a collection of Horn clause as described in
"Linear-time algorithms for testing the satisfiability of
propositional Horn Formulae" by William Dowling and Jean Gallier,
J. Logic programming 1984:3:267-284

Implemented in BCPL by Martin Richards (c) December 1999

*/

GET "libhdr"

MANIFEST {
  Upb=1000
  Size=50000
}

GLOBAL {
  maxVar: 200
  consistent:  201
  change:      202
  V:           203
  spacev:      204
  spacep:      205
  spacet:      206
  clauses:     207
  retcode:     208
  lineno:      210
  ch:          211
  
}

LET start() = VALOF
{ LET argv = VEC 50

  retcode := 0
  V, spacev := 0, 0

  UNLESS rdargs("FROM,TO/K", argv, 50) DO
  { writef("Bad arguments for HORNSAT*n*c")
    RESULTIS 20
  }

  V := getvec(Upb)
  spacev := getvec(Size)
  spacep := spacev
  spacet := spacev + Size

  UNLESS V & spacev DO
  { writef("Unable to allocate enough space*n*c")
    retcode := 20
    GOTO ret
  }

  writef("HornSat entered*n*c")

  clauses := getClauses(argv!0)

  prClauses(clauses)

  consistent := TRUE
  change := TRUE

  FOR i = 1 TO maxVar DO V!i := FALSE

  WHILE clauses & clauses!2=0 DO
  { LET var = clauses!1
    writef("Considering clause: ")
    prClause(clauses)
    V!var := TRUE
    clauses := !clauses
  }

  WHILE change & consistent DO
  { LET a = @clauses
    LET p = !a
    writef("*n*cStart of interation with TRUE variables:")
    FOR i = 1 TO maxVar IF V!i DO writef(" %n", i)
    newline()
    change := FALSE
    WHILE p & consistent DO
    { LET pos = p!1
      writef("Considering clause: ")
      prClause(p)
      TEST pos
      THEN IF V!pos=FALSE & allTrue(p) DO
           { V!pos := TRUE
             !a := !p
             change := TRUE
           }
      ELSE IF allTrue(p) DO consistent := FALSE
      a := p
      p := !a
    }
  }

  TEST consistent
  THEN { writef("The formula is satisfied by:*n*c")
         FOR i = 1 TO maxVar IF V!i DO writef("%n ", i)
         newline()
       }
  ELSE writef("The formula is inconsistent*n*c")

ret:  
  IF V DO freevec(V)  
  IF spacev DO freevec(spacev)  
  RESULTIS retcode
}

AND allTrue(p) = VALOF
{ LET n = p!2
  LET q = @p!2
  FOR i = 1 TO n UNLESS V!(q!i) RESULTIS FALSE
  writef("RHS of clause: ")
  prClause(p)
  writef("is satisfied*n*c")
  RESULTIS TRUE
}

AND getClauses(filename) = VALOF
{ maxVar := 0
  TEST filename 
  THEN RESULTIS readClauses(filename)
  ELSE RESULTIS defaultClauses()
}

AND readClauses(filename) = VALOF
{ LET list = 0     // List of clauses
  LET clause = 0   // Current clause
  LET var = 0      // The current variable
  LET neg = FALSE  // Is the current variable negated
  LET n = 0        // Number of negated variables in the current clause
  LET oldin = input()
  LET infile = findinput(filename)
  UNLESS infile DO
  { writef("Can't open file: %s*n*c", filename)
    RESULTIS 0
  }

  selectinput(infile)
  ch := rdch()
  lineno := 1

  { SWITCHON ch INTO
    { DEFAULT:  writef("Bad formula at line: %n*n*c", lineno)
                RESULTIS 0

      CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
      CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                var := 10*var + ch - '0'
                ch := rdch()
                LOOP

      CASE endstreamch:
      CASE '*s': 
      CASE '*n':
      CASE '-': 
                IF var DO
                { IF maxVar<var DO maxVar := var
                  UNLESS clause DO { clause := spacep
                                     spacep := clause+3
                                     clause!1, clause!2 := 0, 0
                                   }
                  TEST neg
                  THEN { LET n = clause!2
                         clause!2 := n+1
                         !spacep := var
                         spacep := spacep+1
                       }
                  ELSE TEST clause!1
                       THEN writef("Not a Horn clause at line: %n*c*n*c",
                                   lineno)
                       ELSE clause!1 := var
                }
                var, neg := 0, ch='-'

                IF ch='*s' | ch='-' DO { ch := rdch(); LOOP }

                // ch='*n' or ch=endstreamch
 
                IF clause DO // add a clause
                { LET a = @list
                  LET p = !a
                  // Find place to insert the clause
                  // All clauses of the form: (Pi) go first.
                  IF clause!2 WHILE p DO { a := p; p := !a }
                  !clause := p
                  !a := clause
                }
                clause := 0
                IF ch=endstreamch BREAK
                lineno := lineno + 1
                ch := rdch()
    }
  } REPEAT
  
  endread()
  selectinput(oldin)
  RESULTIS list
}

AND defaultClauses() = VALOF
{ LET p = 0
  addClause(@p, 5, 2, 3, 4)
  addClause(@p, 2, 1, 1)
  addClause(@p, 1, 1, 2)
  addClause(@p, 4, 1, 3)
  addClause(@p, 3, 0)
  addClause(@p, 0, 2, 1, 2)
  RESULTIS p
}

AND addClause(a, pos, n, n1, n2, n3, n4, n5, n6, n7, n8, n9) BE
{ LET p = !a
  LET q = spacep
  IF n WHILE p DO { a := p; p := !a }
  !q := p
  FOR i = 1 TO n+2 DO 
  { LET var = (@a)!i
    q!i := var
    UNLESS i = 2 IF maxVar<var DO maxVar := var
  }
  spacep := spacep + n + 3
  !a := q
}

AND prClauses(p) BE
{ writef("Clauses (maxVar=%n):*n*c", maxVar)
  WHILE p DO
  { prClause(p)
    p := !p
  }
} 

AND prClause(p) BE
{ TEST p!1 THEN writef("%i4", p!1)
           ELSE writef("    ")
  writef(" <- ")
  FOR i = 1 TO p!2 DO writef(" %i4", p!(i+2))
  newline()
}

