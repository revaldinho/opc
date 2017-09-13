SECTION "prog"

GET "libhdr"
LET start() = VALOF {
	LET c = VEC 5
	FOR i = 1 TO 5 DO c!i := rdch()
//	FOR i = 1 TO 5 wrch(c!i)
//        newline()
//	FOR i = 1 TO 5 writef("%N",c!i)
//        newline()
	FOR i = 1 TO 5 writef("%X2",c!i)
        newline()
	FOR i = 1 TO 5 writef("%O3",c!i)
        newline()
	FOR i = 1 TO 5 writehex(c!i,3)
        newline()
//	FOR i = 1 TO 5 writen(c!i,3)
//        newline()
//	FOR i = 1 TO 5 writeoct(c!i,3)                                
//	newline()
	RESULTIS 0
}
