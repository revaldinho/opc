GET "libhdr"

GLOBAL {
  Rkey:ug
  sbox
  rsbox
  mul
  tracing
  MixColumns_ts
  InvMixColumns_st
  Cipher
  InvCipher
  prstate_s
  prstate_t
  prv
  prmat

  // The s state matrix
  s00; s01; s02; s03
  s10; s11; s12; s13
  s20; s21; s22; s23
  s30; s31; s32; s33

  // The t state matrix
  t00; t01; t02; t03
  t10; t11; t12; t13
  t20; t21; t22; t23
  t30; t31; t32; t33
}

MANIFEST {
  n=4         // 4x4 matrices are being used
  Keylen=2*n*n
  Nr=14       // Number of rounds
}

// The ShiftRows() function shifts the rows in the state to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
LET ShiftRows_st() BE
{ t00, t01, t02, t03 := s00, s01, s02, s03
  t10, t11, t12, t13 := s11, s12, s13, s10
  t20, t21, t22, t23 := s22, s23, s20, s21
  t30, t31, t32, t33 := s33, s30, s31, s32
}

LET InvShiftRows_ts() BE
{ s00, s01, s02, s03 := t00, t01, t02, t03
  s10, s11, s12, s13 := t13, t10, t11, t12
  s20, s21, s22, s23 := t22, t23, t20, t21
  s30, s31, s32, s33 := t31, t32, t33, t30
}

// The SubBytes Function Substitutes the values in the
// state matrix with values in the S-box.
LET SubBytes_ts() BE
{ // Apply sbox from t state to s state
  s00, s01, s02, s03 := sbox%t00, sbox%t01, sbox%t02, sbox%t03
  s10, s11, s12, s13 := sbox%t10, sbox%t11, sbox%t12, sbox%t13
  s20, s21, s22, s23 := sbox%t20, sbox%t21, sbox%t22, sbox%t23
  s30, s31, s32, s33 := sbox%t30, sbox%t31, sbox%t32, sbox%t33
}

// The InvSubBytes Function Substitutes the values in the
// state matrix with values in an RS-box.
LET InvSubBytes_st() BE
{ // Apply rsbox from s state to t state
  t00, t01, t02, t03 := rsbox%s00, rsbox%s01, rsbox%s02, rsbox%s03
  t10, t11, t12, t13 := rsbox%s10, rsbox%s11, rsbox%s12, rsbox%s13
  t20, t21, t22, t23 := rsbox%s20, rsbox%s21, rsbox%s22, rsbox%s23
  t30, t31, t32, t33 := rsbox%s30, rsbox%s31, rsbox%s32, rsbox%s33
}

LET inittables() BE
{ sbox  := TABLE 
    #x7B777C63, #xC56F6BF2, #x2B670130, #x76ABD7FE,
    #x7DC982CA, #xF04759FA, #xAFA2D4AD, #xC072A49C,
    #x2693FDB7, #xCCF73F36, #xF1E5A534, #x1531D871,
    #xC323C704, #x9A059618, #xE2801207, #x75B227EB,
    #x1A2C8309, #xA05A6E1B, #xB3D63B52, #x842FE329,
    #xED00D153, #x5BB1FC20, #x39BECB6A, #xCF584C4A,
    #xFBAAEFD0, #x85334D43, #x7F02F945, #xA89F3C50,
    #x8F40A351, #xF5389D92, #x21DAB6BC, #xD2F3FF10,
    #xEC130CCD, #x1744975F, #x3D7EA7C4, #x73195D64,
    #xDC4F8160, #x88902A22, #x14B8EE46, #xDB0B5EDE,
    #x0A3A32E0, #x5C240649, #x62ACD3C2, #x79E49591,
    #x6D37C8E7, #xA94ED58D, #xEAF4566C, #x08AE7A65,
    #x2E2578BA, #xC6B4A61C, #x1F74DDE8, #x8A8BBD4B,
    #x66B53E70, #x0EF60348, #xB9573561, #x9E1DC186,
    #x1198F8E1, #x948ED969, #xE9871E9B, #xDF2855CE,
    #x0D89A18C, #x6842E6BF, #x0F2D9941, #x16BB54B0

  rsbox := TABLE
    #xD56A0952, #x38A53630, #x9EA340BF, #xFBD7F381,
    #x8239E37C, #x87FF2F9B, #x44438E34, #xCBE9DEC4,
    #x32947B54, #x3D23C2A6, #x0B954CEE, #x4EC3FA42,
    #x66A12E08, #xB224D928, #x49A25B76, #x25D18B6D,
    #x64F6F872, #x16986886, #xCC5CA4D4, #x92B6655D,
    #x5048706C, #xDAB9EDFD, #x5746155E, #x849D8DA7,
    #x00ABD890, #x0AD3BC8C, #x0558E4F7, #x0645B3B8,
    #x8F1E2CD0, #x020F3FCA, #x03BDAFC1, #x6B8A1301,
    #x4111913A, #xEADC674F, #xCECFF297, #x73E6B4F0,
    #x2274AC96, #x8535ADE7, #xE837F9E2, #x6EDF751C,
    #x711AF147, #x89C5291D, #x0E62B76F, #x1BBE18AA,
    #x4B3E56FC, #x2079D2C6, #xFEC0DB9A, #xF45ACD78,
    #x33A8DD1F, #x31C70788, #x591012B1, #x5FEC8027,
    #xA97F5160, #x0D4AB519, #x9F7AE52D, #xEF9CC993,
    #x4D3BE0A0, #xB0F52AAE, #x3CBBEBC8, #x61995383,
    #x7E042B17, #x26D677BA, #x631469E1, #x7D0C2155
}

LET AddRoundKey_st(i) BE
{ // Add key round i from s state to t state
  LET K = @Rkey!(n*i)   // n = number of elements per row

  t00, t01, t02, t03 := s00 XOR K%00, s01 XOR K%04, s02 XOR K%08, s03 XOR K%12
  t10, t11, t12, t13 := s10 XOR K%01, s11 XOR K%05, s12 XOR K%09, s13 XOR K%13
  t20, t21, t22, t23 := s20 XOR K%02, s21 XOR K%06, s22 XOR K%10, s23 XOR K%14
  t30, t31, t32, t33 := s30 XOR K%03, s31 XOR K%07, s32 XOR K%11, s33 XOR K%15
}

LET AddRoundKey_ts(i) BE
{ // Add key round i from s state to t state
  LET K = @Rkey!(n*i)   // n = number of elements per row

  s00, s01, s02, s03 := t00 XOR K%00, t01 XOR K%04, t02 XOR K%08, t03 XOR K%12
  s10, s11, s12, s13 := t10 XOR K%01, t11 XOR K%05, t12 XOR K%09, t13 XOR K%13
  s20, s21, s22, s23 := t20 XOR K%02, t21 XOR K%06, t22 XOR K%10, t23 XOR K%14
  s30, s31, s32, s33 := t30 XOR K%03, t31 XOR K%07, t32 XOR K%11, t33 XOR K%15
}

LET KeyExpansion(key) BE
{ LET rcon = 1

  // The first two round keys are the
  // first and last 16 bytes of the cipher key.
  FOR i = 0 TO Keylen-1 DO Rkey%i := key%i

  // Add 7 more key pairs to the round schedule
  // making a total of 16 16-byte keys although
  // only 15 are used.
  FOR i = 1 TO 7 DO
  { LET p = Keylen*i
    LET q = p-Keylen

    Rkey%(p+0) := Rkey%(q+0) XOR sbox%(Rkey%(p-3)) XOR rcon
    Rkey%(p+1) := Rkey%(q+1) XOR sbox%(Rkey%(p-2))
    Rkey%(p+2) := Rkey%(q+2) XOR sbox%(Rkey%(p-1))
    Rkey%(p+3) := Rkey%(q+3) XOR sbox%(Rkey%(p-4))

    FOR q = p+4 TO p+15 DO Rkey%q := Rkey%(q-4) XOR Rkey%(q-Keylen)

    rcon := mul(2, rcon)

    Rkey%(p+16) := Rkey%(q+16) XOR sbox%(Rkey%(p+12))
    Rkey%(p+17) := Rkey%(q+17) XOR sbox%(Rkey%(p+13))
    Rkey%(p+18) := Rkey%(q+18) XOR sbox%(Rkey%(p+14))
    Rkey%(p+19) := Rkey%(q+19) XOR sbox%(Rkey%(p+15))

    FOR q = p+20 TO p+31 DO Rkey%q := Rkey%(q-4) XOR Rkey%(q-Keylen)
  }
}

LET mul(x, y) = VALOF
{ // Return the product of x and y using GF(2**8) arithmetic
  LET res = 0
  WHILE x DO
  { IF (x & 1)>0 DO res := res XOR y
    x := x>>1
    y := y<<1
    IF y > 255 DO y := y XOR #x11B
  }
  RESULTIS res
}

AND inprod(a,b,c,d, x,y,z,w) =
  // Calculate ax+by+cz+dw using GF(2**8) arithmetic
  mul(a,x) XOR mul(b,y) XOR mul(c,z) XOR mul(d,w)

// MixColumns function mixes the columns of the state matrix
LET MixColumns_ts() BE
{ // Compute the matrix product
  // (2 3 1 1)   ( t00 t01 t02 t03)    (s00 s01 s02 s03)
  // (1 2 3 1) x ( t10 t11 t12 t13) => (s10 s11 s12 s13)
  // (1 1 2 3)   ( t20 t21 t22 t23)    (s20 s21 s22 s23)
  // (3 1 1 2)   ( t30 t31 t32 t33)    (s30 s31 s32 s33)

  s00 := inprod(2, 3, 1, 1, t00, t10, t20, t30)
  s01 := inprod(2, 3, 1, 1, t01, t11, t21, t31)
  s02 := inprod(2, 3, 1, 1, t02, t12, t22, t32)
  s03 := inprod(2, 3, 1, 1, t03, t13, t23, t33)

  s10 := inprod(1, 2, 3, 1, t00, t10, t20, t30)
  s11 := inprod(1, 2, 3, 1, t01, t11, t21, t31)
  s12 := inprod(1, 2, 3, 1, t02, t12, t22, t32)
  s13 := inprod(1, 2, 3, 1, t03, t13, t23, t33)

  s20 := inprod(1, 1, 2, 3, t00, t10, t20, t30)
  s21 := inprod(1, 1, 2, 3, t01, t11, t21, t31)
  s22 := inprod(1, 1, 2, 3, t02, t12, t22, t32)
  s23 := inprod(1, 1, 2, 3, t03, t13, t23, t33)

  s30 := inprod(3, 1, 1, 2, t00, t10, t20, t30)
  s31 := inprod(3, 1, 1, 2, t01, t11, t21, t31)
  s32 := inprod(3, 1, 1, 2, t02, t12, t22, t32)
  s33 := inprod(3, 1, 1, 2, t03, t13, t23, t33)
}

// MixColumns function mixes the columns of the state matrix.
LET InvMixColumns_st() BE
{ // Compute the matrix product
  // (14 11 13  9)   (s00 s01 s02 s03)    (t00 t01 t02 t03)
  // ( 9 14 11 13) x (s10 s11 s12 s13) => (t10 t11 t12 t13)
  // (13  9 14 11)   (s20 s21 s22 s23)    (t20 t21 t22 t23)
  // (11 13  9 14)   (s30 s31 s32 s33)    (t30 t31 t32 t33)

  t00 := inprod(14, 11, 13,  9, s00, s10, s20, s30)
  t01 := inprod(14, 11, 13,  9, s01, s11, s21, s31)
  t02 := inprod(14, 11, 13,  9, s02, s12, s22, s32)
  t03 := inprod(14, 11, 13,  9, s03, s13, s23, s33)

  t10 := inprod( 9, 14, 11, 13, s00, s10, s20, s30)
  t11 := inprod( 9, 14, 11, 13, s01, s11, s21, s31)
  t12 := inprod( 9, 14, 11, 13, s02, s12, s22, s32)
  t13 := inprod( 9, 14, 11, 13, s03, s13, s23, s33)

  t20 := inprod(13,  9, 14, 11, s00, s10, s20, s30)
  t21 := inprod(13,  9, 14, 11, s01, s11, s21, s31)
  t22 := inprod(13,  9, 14, 11, s02, s12, s22, s32)
  t23 := inprod(13,  9, 14, 11, s03, s13, s23, s33)

  t30 := inprod(11, 13,  9, 14, s00, s10, s20, s30)
  t31 := inprod(11, 13,  9, 14, s01, s11, s21, s31)
  t32 := inprod(11, 13,  9, 14, s02, s12, s22, s32)
  t33 := inprod(11, 13,  9, 14, s03, s13, s23, s33)
}

// Cipher is the main function that encrypts the PlainText.
LET Cipher(in, out) BE
{ // Copy the input PlainText into the state array.
  s00, s01, s02, s03 := in%00, in%04, in%08, in%12
  s10, s11, s12, s13 := in%01, in%05, in%09, in%13
  s20, s21, s22, s23 := in%02, in%06, in%10, in%14
  s30, s31, s32, s33 := in%03, in%07, in%11, in%15

  IF tracing DO { writef("%i2.input  ", 0); prstate_s() }
  IF tracing DO { writef("%i2.k_sch  ", 0); prv(Rkey) }

  // Add the First round key to the state before starting the rounds.
  AddRoundKey_st(0) 

  FOR round = 1 TO Nr-1 DO
  {
    IF tracing DO { writef("%i2.start  ", round); prstate_t() }

    SubBytes_ts()
    IF tracing DO { writef("%i2.s_box  ", round); prstate_s() }

    ShiftRows_st()
    IF tracing DO { writef("%i2.s_row  ", round); prstate_t() }

    MixColumns_ts()
    IF tracing DO { writef("%i2.s_col  ", round); prstate_s() }

    AddRoundKey_st(round)
    IF tracing DO { writef("%i2.k_sch  ", round); prv(@Rkey!(4*round)) }
  }
  
  // The last round is given below.
  IF tracing DO { writef("%i2.start  ", Nr); prstate_t() }

  SubBytes_ts()
  IF tracing DO { writef("%i2.s_box  ", Nr); prstate_s() }

  ShiftRows_st()
  IF tracing DO { writef("%i2.s_row  ", Nr); prstate_t() }

  // Do not mix the columns in the final round

  AddRoundKey_ts(Nr)
  IF tracing DO { writef("%i2.k_sch  ", Nr); prv(@Rkey!(4*Nr)) }
  IF tracing DO { writef("%i2.output ", Nr); prstate_s() }

  // The encryption process is over.
  // Copy the state array to output array.
  out%00, out%04, out%08, out%12 := s00, s01, s02, s03
  out%01, out%05, out%09, out%13 := s10, s11, s12, s13
  out%02, out%06, out%10, out%14 := s20, s21, s22, s23
  out%03, out%07, out%11, out%15 := s30, s31, s32, s33

  //abort(1000)
}

LET InvCipher(in, out) BE
{ // Copy the input CipherText to state array.
  s00, s01, s02, s03 := in%00, in%04, in%08, in%12
  s10, s11, s12, s13 := in%01, in%05, in%09, in%13
  s20, s21, s22, s23 := in%02, in%06, in%10, in%14
  s30, s31, s32, s33 := in%03, in%07, in%11, in%15

  IF tracing DO { writef("%i2.iinput ", 0); prstate_s() }
  IF tracing DO { writef("%i2.ik_sch ", 0); prv(@Rkey!(4*Nr)) }

  // Add the Last round key to the state before starting the rounds.
  AddRoundKey_st(Nr)

  FOR round = Nr-1 TO 1 BY -1 DO
  { 
    IF tracing DO { writef("%i2.istart ", Nr-round); prstate_t() }
    InvShiftRows_ts()

    IF tracing DO { writef("%i2.is_row ", Nr-round); prstate_s() }

    InvSubBytes_st()
    IF tracing DO { writef("%i2.is_box ", Nr-round); prstate_t() }

    AddRoundKey_ts(round)
    IF tracing DO { writef("%i2.ik_sch ", Nr-round); prv(@Rkey!(4*round)) }
    IF tracing DO { writef("%i2.is_add ", Nr-round); prstate_s() }

    InvMixColumns_st()
//abort(1000)
  }

  IF tracing DO { writef("%i2.istart ", Nr); prstate_t() }
  
  // The final round is given below.
  InvShiftRows_ts()
  IF tracing DO { writef("%i2.is_row ", Nr); prstate_s() }

  InvSubBytes_st()
  IF tracing DO { writef("%i2.is_box ", Nr); prstate_t() }

  // Do not mix the columns in the final round
  AddRoundKey_ts(0)
  IF tracing DO { writef("%i2.ik_sch ", Nr); prv(@Rkey!(4*0)) }

  IF tracing DO { writef("%i2.ioutput", Nr); prstate_s() }

  // The decryption process is over.
  // Copy the state array to output array.
  out%00, out%04, out%08, out%12 := s00, s01, s02, s03
  out%01, out%05, out%09, out%13 := s10, s11, s12, s13
  out%02, out%06, out%10, out%14 := s20, s21, s22, s23
  out%03, out%07, out%11, out%15 := s30, s31, s32, s33
}

LET start() = VALOF
{ LET argv = VEC 50
  LET plain = TABLE #X33221100, #X77665544, #XBBAA9988, #XFFEEDDCC
  LET key   = TABLE #x03020100, #x07060504, #x0B0A0908, #x0F0E0D0C,
                    #x13121110, #x17161514, #x1B1A1918, #x1F1E1D1C
  // The plain text and key are the same as given in the detailed
  // example in Appendix C.3 in
  // csrc.nist.gov/publications/fips/fips197/fips-197.pdf
  // It provides a useful check that this implementaion is correct.
  // Just execute: aes256 -t
  LET in  = VEC 63
  LET out = VEC 63
  LET v   = VEC 4*15+3 // For the key schedule of 16 keys
                       // although only 15 are used.
  LET countExpand, countCipher, countInvCipher = 0, 0, 0

  Rkey := v

  UNLESS rdargs("-t/s", argv, 50) DO
  { writef("Bad arguments for aes256*n*c")
    RESULTIS 0
  }

  tracing := argv!0

  inittables()

  //KeyExpansion(key)
  countExpand := instrcount(KeyExpansion, key)

  IF tracing DO
  { writef("*n*cKey schedule*n*c")
    FOR i = 0 TO Nr DO
    { LET p = 4*i
      writef("%i2: ", i)
      prv(@Rkey!p)
    }
  }
  newline()

  writef("plain:          "); prv(plain); newline()
  writef("key:            "); prv(key)
  writef("                "); prv(key+4)
  newline()

  //Cipher(plain, out)
  countCipher := instrcount(Cipher, plain, out)

  newline()

  writef("Cipher text:    "); prv(out); newline()

  //InvCipher(out, in)
  countInvCipher := instrcount(InvCipher, out, in)
  IF tracing DO newline()

  writef("InvCipher text: "); prv(in); newline()

  newline()
  writef("Cintcode instruction counts*n*c*n*c")
  writef("KeyExpansion: %i7*n*c", countExpand)
  writef("Cipher:       %i7*n*c", countCipher)
  writef("InvCipher:    %i7*n*c", countInvCipher)

  RESULTIS 0
}

AND prstate_s() BE
{ // For outputting state s matrix
  writef(" %x2%x2%x2%x2", s00, s10, s20, s30)
  writef(" %x2%x2%x2%x2", s01, s11, s21, s31)
  writef(" %x2%x2%x2%x2", s02, s12, s22, s32)
  writef(" %x2%x2%x2%x2", s03, s13, s23, s33)
  newline()
}

AND prstate_t() BE
{ // For outputting state t matrix
  writef(" %x2%x2%x2%x2", t00, t10, t20, t30)
  writef(" %x2%x2%x2%x2", t01, t11, t21, t31)
  writef(" %x2%x2%x2%x2", t02, t12, t22, t32)
  writef(" %x2%x2%x2%x2", t03, t13, t23, t33)
  newline()
}

AND prv(v) BE
{ // For outputting plain and ciphered text and keys
  writef(" %x2%x2%x2%x2", v%00, v%01, v%02, v%03)
  writef(" %x2%x2%x2%x2", v%04, v%05, v%06, v%07)
  writef(" %x2%x2%x2%x2", v%08, v%09, v%10, v%11)
  writef(" %x2%x2%x2%x2", v%12, v%13, v%14, v%15)
  newline()
}

