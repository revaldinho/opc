GET "libhdr"

MANIFEST $(
// selectors
H1=0; H2=1; H3=2; H4=3
// expression operators
Name=1; Numb=2
Plus=3; Minus=4; Mult=5; Eq=6; Cond=7
Lambda=8; Apply=9; Y=10
$)

GLOBAL $( space:200 $)

LET mk1(x) = VALOF
$( space := space-1
   space!0 := x
   RESULTIS space
$)

AND mk2(x,y) = VALOF $( mk1(y); RESULTIS mk1(x)  $)

AND mk3(x,y,z) = VALOF $( mk2(y,z); RESULTIS mk1(x)  $)

AND mk4(x,y,z,t) = VALOF $( mk3(y,z,t); RESULTIS mk1(x)  $)

AND eval(x, e) = 
    H1!x=Name   -> lookup(x, e),
    H1!x=Numb   -> H2!x,
    H1!x=Plus   -> eval(H2!x, e) + eval(H3!x, e),
    H1!x=Minus  -> eval(H2!x, e) - eval(H3!x, e),
    H1!x=Mult   -> eval(H2!x, e) * eval(H3!x, e),
    H1!x=Eq     -> eval(H2!x, e) = eval(H3!x, e),
    H1!x=Cond   -> eval(H2!x, e) -> eval(H3!x, e), eval(H4!x, e),
    H1!x=Lambda -> mk3(H2!x, H3!x, e),
    H1!x=Apply  -> VALOF 
                   $( LET f, a = eval(H2!x, e), eval(H3!x, e)
                      LET bv, body, env = H1!f, H2!f, H3!f
                      RESULTIS eval(body, mk3(bv, a, env))
                   $),
    H1!x=Y      -> VALOF
                   $( LET f   = eval(H2!x, e)
                      LET bv, body, env = H1!f, H2!f, H3!f
                      LET ne  = mk3(bv, ?, env)
                      LET yf  = mk3(H2!body, H3!body, ne)
                      H2!ne := yf
                      RESULTIS yf
                   $),
    error("Unknown operator %n*n*c", H1!x)

AND lookup(bv, e) =
    e=0 -> error("Undeclared name %c*n*c", H2!bv),
    bv=H1!e -> H2!e,
    lookup(bv, H3!e)

AND error(mess, a) = VALOF $( writef(mess, a); RESULTIS 0  $)

LET try(k) = VALOF
$( LET f, n, i = mk2(Name,'f'), mk2(Name,'n'), mk2(Name,'i')
   LET zero, one, nk = mk2(Numb,0), mk2(Numb,1), mk2(Numb,k)
   LET F = mk3(Lambda,
               f,
               mk3(Lambda,
                   n,
                   mk4(Cond,
                       mk3(Eq,n,zero),
                           one,
                           mk3(Mult,
                               n,
                               mk3(Apply,
                                   f,
                                   mk3(Minus,
                                       n,
                                       one
                                      )
                                  )
                              )
                      )
                  )
              )
   LET expr = mk3(Apply, mk2(Y,F), nk)

   RESULTIS eval(expr, 0)
$)

LET start() = VALOF
$( LET v = getvec(10000)

   writef("Computing factorials using lamdba functions*n*c")

   space := v+10000
   FOR i = 1 TO 7 DO
      writef("Factorial %i2 = %i9*n*c", i, try(i))
   freevec(v)
   RESULTIS 0
$)

