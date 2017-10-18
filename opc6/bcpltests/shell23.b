// (c) Martin Richards
//
// REv. 170927. Taken from BCPL distribution and modified number ranges for OPC6 16bit arithmetic
//

SECTION "sort"

GET "libhdr"

LET shellsort(v, upb) BE
$( LET m = ?
   LET mtab = TABLE
      1,     2,     3,     4,     6,     8,     9,    12,    16,    18,
     24,    27,    32,    36,    48,    54,    64,    72,    81,    96,
    108,   128,   144,   162,   192,   216,   243,   256,   288,   324,
    384,   432,   486,   512,   576,   648,   729,   768,   864,   972,
   1024,  1152,  1296,  1458,  1536,  1728,  1944,  2048,  2187,  2304,
   2592,  2916,  3072,  3456,  3888,  4096,  4374,  4608,  5184,  5832,
   6144,  6561,  6912,  7776,  8192,  8748,  9216, 10368, 11664, 12288,
  13122, 13824, 15552, 16384, 17496, 18432, 19683, 20736, 23328, 24576


   UNTIL !mtab>upb DO mtab := mtab+1
   $( LET k = 0
      mtab := mtab-1
      m := !mtab
      FOR i = m+1 TO upb DO
      $( LET j = i-m
         LET vi, vj = v!i, v!j
         IF vj>vi DO v!j, v!i, k := vi, vj, k+1
      $)
      writef("m = %i4  swaps = %i4*n*c", m, k)
   $) REPEATUNTIL m=1
$)


MANIFEST $( upb = 1000  $)

LET start() BE
$( LET v = getvec(upb)

   try("shell23", shellsort, v, upb)
   //   writes("*n*cEnd of test*n*c")
   //   freevec(v)
$)

AND try(name, sortroutine, v, upb) BE
$( writef("*n*cSetting %n words of data for %s sort*n*c", upb, name)

   setseed(#x1234)        // initialise random number system 
   FOR i = 1 TO upb DO {
       v!i := randno(1000)
       //writed(v!i,0)
       //newline()
       }
   writef("Entering %s sort routine*n*c", name)
   sortroutine(v, upb)
   writes("Sorting complete*n*c")
   TEST sorted(v, upb)
   THEN writes("The data is now sorted*n*c")
   ELSE writef("### ERROR: %s sort does not work*n*c", name)
$)

AND sorted(v, n) = VALOF
$( FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
   RESULTIS TRUE
$)
