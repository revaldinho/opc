GET "libhdr"

GLOBAL $( C:200; upb; step; i $)

LET start() = VALOF $(
    LET k = 2
    LET count = 0
    LET C = VEC 2500
    upb, step := 2500, 100

    FOR i = 1 TO 7 DO $(
        newline()
        count := 0
        C!0 := 1
        SWITCHON i INTO $(
            DEFAULT:
                writef("Unknown recurrence relation: %n*n", i)
                GOTO fin

            CASE 1:
                writef("C(n) = n + C(n/%n) + C(n**%n/%n)*n", k, k-1, k)
                FOR n = 1 TO upb DO C!n := n + C!(n/k) + C!(n*(k-1)/k)
                ENDCASE
            CASE 2:
                writef("C(n) = n/5 + C(n/%n) + C(n**%n/%n)*n", k, k-1, k)
                FOR n = 1 TO upb DO C!n := n/5 + C!(n/k) + C!(n*(k-1)/k)
                ENDCASE
            CASE 3:
                writef("C(n) = 1 + C(n/%n) + C(n**%n/%n)*n", k, k-1, k)
                FOR n = 1 TO upb DO C!n := 1 + C!(n/k) + C!(n*(k-1)/k)
                ENDCASE
            CASE 4:
                writef("C(n) = 1 + C(n/2)*n")
                FOR n = 1 TO upb DO C!n := 1 + C!(n/2)
                ENDCASE
            CASE 5:
                writef("C(n) = 1 + C(n-1)*n")
                FOR n = 1 TO upb DO C!n := 1 + C!(n-1)
                ENDCASE
            CASE 6:
                writef("C(n) = 2 + C((n-1)/2)*n")
                FOR n = 1 TO upb DO C!n := 2 + C!((n-1)/2)
                ENDCASE
            CASE 7:
                writef("C(n) = 4 + C((n-2)/3)*n")
                FOR n = 1 TO upb DO C!n := 4 + C!((n-2)/3)
                ENDCASE
    $)

    FOR n = 0 TO upb UNLESS n REM step DO $(
        UNLESS count REM 10 DO writef("*n%i5: ", n)
        count := count+1
        writef(" %i6", C!n)
    $)
fin:
    newline()
  $)
  RESULTIS 0
$)
