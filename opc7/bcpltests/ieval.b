GET "libhdr"

MANIFEST {
Op=0; Rand1=1; Rand2=2
NUM=1; POS=2; NEG=3; MUL=4; DIV=5; ADD=6; SUB=7
}

LET eval(e) = VALOF SWITCHON Op!e INTO
{ CASE NUM: RESULTIS Rand1!e
  CASE POS:  RESULTIS + eval(Rand1!e)
  CASE NEG:  RESULTIS - eval(Rand1!e)
  CASE MUL:  RESULTIS eval(Rand1!e) * eval(Rand2!e)
  CASE DIV:  RESULTIS eval(Rand1!e) / eval(Rand2!e)
  CASE ADD:  RESULTIS eval(Rand1!e) + eval(Rand2!e)
  CASE SUB:  RESULTIS eval(Rand1!e) - eval(Rand2!e)
}

LET mk1(op, a) = VALOF
{ LET r = getvec(1)
  Op!r, Rand1!r := op, a
  RESULTIS r
}

LET mk2(op, a, b) = VALOF
{ LET r = getvec(2)
  Op!r, Rand1!r, Rand2!r := op, a, b
  RESULTIS r
}

LET start() = VALOF
{ LET exp = mk2(ADD, mk1(NUM, 1),
                     mk2(MUL, mk1(NUM,2), mk1(NUM,3)))
  writef("eval(exp) = %n*n*c", eval(exp))
  RESULTIS 0
}


