GET "libhdr"

MANIFEST $(
h1=0; h2=1; h3=2; h4=3

s_name=1; s_numb=2; s_lambda=3; s_apply=4
s_plus=10; s_minus=11; s_mult=12; s_div=13; s_rem=14
s_eq=15; s_cond=20
$)

STATIC $(
spacev = 0; spacep = 0; spacet = 0
$)

LET newvec(upb) = VALOF
$( LET p = spacep - upb - 1
   IF p<spacev RESULTIS 0
   spacep := p
   RESULTIS p
$)

AND node(x, y, z, t) = VALOF
$( LET n = newvec(3)
   IF n=0 RESULTIS error("No space left")
   h1!n, h2!n, h3!n, h4!n := x, y, z, t
   RESULTIS n
$)

AND error(mes) = VALOF
$( writef("*NError:- %S*N", mes)
   RESULTIS 0
$)

AND eval(x, e) =
    h1!x=s_name   -> lookup(x, e),
    h1!x=s_numb   -> h2!x,
    h1!x=s_plus   -> eval(h2!x, e) + eval(h3!x, e),
    h1!x=s_minus  -> eval(h2!x, e) - eval(h3!x, e),
    h1!x=s_mult   -> eval(h2!x, e) * eval(h3!x, e),
    h1!x=s_div    -> eval(h2!x, e) / eval(h3!x, e),
    h1!x=s_rem    -> eval(h2!x, e) REM eval(h3!x, e),
    h1!x=s_eq     -> eval(h2!x, e) = eval(h3!x, e),
    h1!x=s_cond   -> (eval(h2!x, e) -> eval(h3!x, e), eval(h4!x, e)),
    h1!x=s_lambda -> node(h2!x, h3!x, e),
    h1!x=s_apply  -> VALOF
       $( LET f = eval(h2!x, e)
          AND a = eval(h3!x, e)
          LET bv, body, env = h1!f, h2!f, h3!f
          RESULTIS eval(body, node(bv, a, env))
       $),
    error("Bad expression")

AND lookup(bv, e) = e=0 -> error("Name not found"),
                    h1!e=bv -> h2!e,
                    lookup(bv, h3!e)

LET try() BE
$( LET f = node(s_name, 'f')
   AND g = node(s_name, 'g')
   AND h = node(s_name, 'h')
   AND n = node(s_name, 'n')
   AND x = node(s_name, 'x')

   LET n0 = node(s_numb, 0)
   LET n1 = node(s_numb, 1)


   LET I = node(s_lambda, x, x)
   LET K = node(s_lambda, x, node(s_lambda, n, x))
   LET S = node(s_lambda, f,
                node(s_lambda, g,
                     node(s_lambda, x,
                          node(s_apply,
                               node(s_apply, f, x),
                               node(s_apply, g, x)
                              )
                         )
                    )
                )

   LET gg = node(s_apply, g, g)
   LET Lg.gg = node(s_lambda, g, gg)
   LET Lg.fgg = node(s_lambda, g, node(s_apply, f, gg))
   LET Y = node(s_lambda, f, node(s_apply, Lg.gg, Lg.fgg))
   // Y = Lf. (Lg. g g) (Lg. f(g g))

   LET fggx = node(s_apply, node(s_apply, f, gg), x)
   LET Lx.fggx = node(s_lambda, x, fggx)
   LET Lg.Lx.fggx = node(s_lambda, g, Lx.fggx)
   LET Y1 = node(s_lambda, f, node(s_apply, Lg.gg, Lg.Lx.fggx))
   // Y1 = Lf. (Lg. g g) (Lg. Lx. (f(g g)) x)

   LET bigf = node(s_lambda, f,
                   node(s_lambda, n,
                        node(s_cond,
                             node(s_eq, n, n0),
                             n1,
                             node(s_mult,
                                  n,
                                  node(s_apply,
                                       f, //node(s_apply, f, n0),
                                       node(s_minus, n, n1))
                                 )
                            )
                       )
                  )

   LET fact = node(s_apply, Y1, bigf)

   FOR j = 1 TO 7 DO
     writef("fact(%N) = %I5*N", j,
                eval(node(s_apply, fact, node(s_numb, j)), 0)
           )

   writes("*NEnd of test*N")
$)

AND start() = VALOF
$( MANIFEST $( upb=10000 $)

   LET v = VEC upb
   spacev, spacep, spacet := v, v+upb, v+upb

   try()
   RESULTIS 0
$)
