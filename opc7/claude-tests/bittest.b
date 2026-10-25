// setbit and testbit from bcpllib: set and clear bits 0 to 319 in a pattern,
// checking the old state setbit returns and what testbit reads back, then a
// bit vector sieve of Eratosthenes that also serves as a benchmark.
// OPC7 only: bitsperword is 32 in bcpllib, so on 16 bit OPC6 bits 16-31 of
// each word are lost.

GET "libhdr"

MANIFEST { nbits = 320; sieveupb = 20000 }

LET start() = VALOF
{ LET v = VEC nbits/bitsperword
  LET sieve = VEC sieveupb/bitsperword
  LET errors, count = 0, 0
  FOR i = 0 TO nbits/bitsperword DO v!i := 0

  // Set every bit whose number is a multiple of 3 or 7
  FOR b = 0 TO nbits-1 IF b MOD 3 = 0 | b MOD 7 = 0 DO
    IF setbit(b, v, TRUE) DO errors := errors+1     // was clear
  FOR i = 0 TO nbits/bitsperword - 1 DO writef("%x8*n", v!i)
  FOR b = 0 TO nbits-1 DO
  { LET want = b MOD 3 = 0 | b MOD 7 = 0
    UNLESS (testbit(b, v) ~= 0) = want DO errors := errors+1
  }
  // Clear the multiples of 7: setbit must return the old state (set)
  FOR b = 0 TO nbits-1 BY 7 DO
    UNLESS setbit(b, v, FALSE) DO errors := errors+1
  FOR i = 0 TO nbits/bitsperword - 1 DO writef("%x8*n", v!i)
  writef("setbit/testbit errors: %n*n", errors)

  // Sieve: a set bit means composite
  FOR i = 0 TO sieveupb/bitsperword DO sieve!i := 0
  FOR n = 2 TO sieveupb UNLESS testbit(n, sieve) DO
  { LET m = 2*n
    count := count+1
    WHILE m <= sieveupb DO { setbit(m, sieve, TRUE); m := m+n }
  }
  writef("primes up to %n: %n*n", sieveupb, count)
  RESULTIS 0
}
