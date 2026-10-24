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
  13122, 13824, 15552, 16384, 17496, 18432, 19683, 20736, 23328, 24576,
  26244, 27648, 31104, 32768, 34992, 36864, 39366, 41472, 46656, 49152,
  52488, 55296, 59049, 62208, 65536, 69984, 73728, 78732, 82944, 93312

   UNTIL !mtab>upb DO mtab := mtab+1
   $( LET k = 0
      mtab := mtab-1
      m := !mtab
      FOR i = m+1 TO upb DO
      $( LET j = i-m
         LET vi, vj = v!i, v!j
         IF vj>vi DO v!j, v!i, k := vi, vj, k+1
      $)
      writef("m = %i4  swaps = %i4*n", m, k)
   $) REPEATUNTIL m=1
$)


MANIFEST $( upb = 5000  $)

LET start() BE
$( LET v = getvec(upb)

   try("shell23", shellsort, v, upb)

   writes("*nEnd of test*n")
   freevec(v)
$)

AND try(name, sortroutine, v, upb) BE
$( writef("*nSetting %n words of data for %s sort*n", upb, name)
   FOR i = 1 TO upb DO v!i := randno(10000)
   writef("Entering %s sort routine*n", name)
   sortroutine(v, upb)
   writes("Sorting complete*n")
   TEST sorted(v, upb)
   THEN writes("The data is now sorted*n")
   ELSE writef("### ERROR: %s sort does not work*n", name)
$)

AND sorted(v, n) = VALOF
$( FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
   RESULTIS TRUE
$)
