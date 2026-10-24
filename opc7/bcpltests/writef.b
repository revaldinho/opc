SECTION "writef"

GET "libhdr"

LET start() = VALOF

{ 
  writef("This is an integer %i4*n", 100)
  writef("This is an string %s*n", "Hello World!")  
  RESULTIS 0
}

