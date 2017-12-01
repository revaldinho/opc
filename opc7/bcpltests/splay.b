SECTION "splay"

GET "libhdr"

MANIFEST {
  name     = 0  // tree node selectors
  data     = 1
  parent   = 2
  left     = 3
  right    = 4
}

GLOBAL {
  spacev : 200
  spacep : 201
  line   : 202
}


LET printree(t) BE { LET v = VEC 100
                     line := v
                     line!1 := TRUE
                     printree1(left, t, 1)
                     newline()
                     newline()
                   }

AND printree1(side, t, indent) BE UNLESS t=0 DO
{ line!indent := side=left
  printree1(right, right!t, indent+1)

  FOR i = 1 TO indent-1 DO writes(line!i->"|  ", "   ")
  writef("**-+%c%c*n*c", name!t, data!t)  
  line!indent := side=right
  printree1(left, left!t, indent+1)
//  FOR i = 1 TO indent   DO writes(line!i->"|  ", "   ")
//  newline()
}

AND maketree(ch, val, p, l, r) = VALOF
{ LET node = spacep - 5
  spacep := node

  name   ! node  :=  ch
  data   ! node  :=  val
  parent ! node  :=  p
  left   ! node  :=  l
  right  ! node  :=  r

  RESULTIS node
}

AND rotateleft(y) BE
{ LET x = right!y
  AND p = parent!y

  UNLESS p=0 TEST left!p=y THEN left!p  := x
                           ELSE right!p := x
  right!y  := left!x
  left!x   := y
  parent!x := p
  parent!y := x

  UNLESS right!y=0 DO parent!(right!y) := y
}

AND rotateright(y) BE
{ LET x = left!y
  AND p = parent!y

  UNLESS p=0 TEST right!p=y THEN right!p := x
                            ELSE left!p  := x
  left!y   := right!x
  right!x  := y
  parent!x := p
  parent!y := x

  UNLESS left!y=0 DO parent!(left!y) := y
}

AND splay(x) BE UNTIL parent!x=0 DO
{ LET p = parent!x
  LET g = parent!p

  TEST x = left!p
  THEN { TEST g=0 THEN rotateright(p)
                  ELSE TEST p=left!g THEN { rotateright(g)
                                            rotateright(p)
                                          }
                                     ELSE { rotateright(p)
                                            rotateleft(g)
                                          }
       }
  ELSE { TEST g=0 THEN rotateleft(p)
                  ELSE TEST p=right!g THEN { rotateleft(g)
                                             rotateleft(p)
                                           }
                                      ELSE { rotateleft(p)
                                             rotateright(g)
                                           }
       }
}

AND lookup(root, found, key) BE
{ LET t = !root
  !found := FALSE

  writef("lookup: %c*n*c", key)

  UNTIL !found | t=0 TEST name!t=key 
                     THEN { !found := TRUE
                            splay(t)
                            !root := t
                          }
                     ELSE TEST key < name!t THEN t := left!t
                                            ELSE t := right!t
}

AND update(root, key, val) BE
{ LET changed, l = FALSE, ?
  AND t, p       = !root, 0

  writef("Update: %c = %c*n*c", key, val)
  UNTIL t=0 | changed DO
  { p := t
    TEST key=name!t
    THEN { changed := TRUE
           data!t  := val
         }
    ELSE TEST key < name!t THEN { l := TRUE
                                  t := left!t
                                }
                           ELSE { l := FALSE
                                  t := right!t
                                }
  }

  UNLESS changed DO
  { t := maketree(key, val, p, 0, 0)
    UNLESS p = 0 TEST l THEN left!p  := t
                        ELSE right!p := t
  }

  splay(t)
  !root := t
}

LET start() BE
{ LET v     = VEC 10000
  LET root  = 0
  LET found = ?

  spacev, spacep := v, v+10000

  writes("Splay test entered*N*c")

  update(@root,'B', 'b')
  update(@root,'C', 'c')
  update(@root,'D', 'd')
  update(@root,'E', 'e')
  printree(root)

  update(@root,'F', 'f')
  update(@root,'G', 'g')
  update(@root,'H', 'h')
  update(@root,'A', 'a')
  printree(root)
 
  update(@root,'L', 'l')
  update(@root,'K', 'k')
  update(@root,'J', 'j')
  update(@root,'I', 'i')
  printree(root)

  lookup(@root, @found, 'A'); printree(root)
  lookup(@root, @found, 'H'); printree(root)
  lookup(@root, @found, 'K'); printree(root)
  lookup(@root, @found, 'A'); printree(root)
  lookup(@root, @found, 'I'); printree(root)
}

