GET "libhdr"

LET start() BE $(
    LET A = -1
    LET B =  0

    writed(-1,2)
    newline()

    FOR A = -1 TO 1 DO $(
        FOR B = -1 TO 1 DO $(
            writef("A= %i  B= %i*n", A, B)
            newline()
            IF ( A > B ) DO writes ( "A > B*n")
            IF ( A >= B ) DO writes ( "A >= B*n")
            IF ( A = B ) DO writes ( "A = B*n")                        
            IF ( A < B ) DO writes ( "A < B*n")
            IF ( A <= B ) DO writes ( "A <= B*n")
            newline()
        $)
    $)

    FOR A = -1 TO 1 DO $(
        writef("A= %i", A)
        newline()
        IF ( A > 0 ) DO writes ( "A > 0*n")
        IF ( A >= 0 ) DO writes ( "A >= 0*n")
        IF ( A = 0 ) DO writes ( "A = 0*n")                        
        IF ( A < 0 ) DO writes ( "A < 0*n")
        IF ( A <= 0 ) DO writes ( "A <= 0*n")
        newline()
    $)

$)