// echo.b - first test of the OPC7HP system's UART in both directions: prints a banner, then echoes
// each character it receives, with Return (CR or LF) echoed as a new line, until it receives a full
// stop.
GET "libhdr"

LET start() = VALOF
{ writef("OPC7HP echo test: type characters, . to finish*n*c")
  { LET ch = rdch()
    IF ch = '.' | ch = endstreamch BREAK
    TEST ch = '*c' | ch = '*n' THEN writef("*n*c") ELSE wrch(ch)
  } REPEAT
  writef("*n*cBye*n*c")
  RESULTIS 0
}
