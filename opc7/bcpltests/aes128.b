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
  prstate
  prbytes

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

  stateS
  stateT
}

MANIFEST {
  Keylen=16   // 16 = 4x4
  Nr=10       // Number of rounds
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
  FOR i = 0 TO 15 DO stateS!i := sbox%(stateT!i)
}

// The InvSubBytes Function Substitutes the values in the
// state matrix with values in an RS-box.
LET InvSubBytes_st() BE
{ // Apply rsbox from s state to t state
  FOR i = 0 TO 15 DO stateT!i := rsbox%(stateS!i)
}

LET inittables() BE
{ // This assuming a little ender 32-bit implementation.
  sbox  := TABLE 
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
  LET K = @Rkey!(16*i)   // n = number of elements per row
  FOR i = 0 TO 15 DO stateT!i := stateS!i XOR K!i
}

LET AddRoundKey_ts(i) BE
{ // Add key round i from s state to t state
  LET K = @Rkey!(16*i)   // n = number of elements per row
  FOR i = 0 TO 15 DO stateS!i := stateT!i XOR K!i
}

LET KeyExpansion(key) BE
{ LET rcon = 1

  // The first round key is the cipher key itself,
  // stored column by column.
  Rkey!00, Rkey!01, Rkey!02, Rkey!03 := key%00, key%04, key%08, key%12
  Rkey!04, Rkey!05, Rkey!06, Rkey!07 := key%01, key%05, key%09, key%13
  Rkey!08, Rkey!09, Rkey!10, Rkey!11 := key%02, key%06, key%10, key%14
  Rkey!12, Rkey!13, Rkey!14, Rkey!15 := key%03, key%07, key%11, key%15

  // Add 10 more keys to the round schedule
  FOR i = 1 TO 10 DO
  { LET p = @Rkey!(16*i) // Pointer to space for key in round i
    LET q = p-16        // Pointer to round key i-1

    p!00 := q!00 XOR sbox%(q!07) XOR rcon
    p!04 := q!04 XOR sbox%(q!11)
    p!08 := q!08 XOR sbox%(q!15)
    p!12 := q!12 XOR sbox%(q!03)

    FOR j = 1 TO 3 DO
    { p!(00+j) := q!(00+j) XOR p!(j-01)
      p!(04+j) := q!(04+j) XOR p!(j+03)
      p!(08+j) := q!(08+j) XOR p!(j+07)
      p!(12+j) := q!(12+j) XOR p!(j+11)
    }

    rcon := mul(2, rcon)
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

  IF tracing DO
  { writef("%i2.input  ", 0); prstate(stateS)
    writef("%i2.k_sch  ", 0); prstate(Rkey)
  }

  // Add the First round key to the state before starting the rounds.
  AddRoundKey_st(0) 

  FOR round = 1 TO Nr-1 DO
  { IF tracing DO
    { writef("%i2.start  ", round); prstate(stateT) }

    SubBytes_ts()
    IF tracing DO
    { writef("%i2.s_box  ", round); prstate(stateS) }

    ShiftRows_st()
    IF tracing DO
    { writef("%i2.s_row  ", round); prstate(stateT) }

    MixColumns_ts()
    IF tracing DO
    { writef("%i2.s_col  ", round); prstate(stateS) }

    AddRoundKey_st(round)
    IF tracing DO
    { writef("%i2.k_sch  ", round); prstate(@Rkey!(16*round)) }
  }
  
  // The last round is given below.
  IF tracing DO
  { writef("%i2.start  ", Nr); prstate(stateT) }

  SubBytes_ts()
  IF tracing DO
  { writef("%i2.s_box  ", Nr); prstate(stateS) }

  ShiftRows_st()
  IF tracing DO
  { writef("%i2.s_row  ", Nr); prstate(stateT) }

  // Do not mix the columns in the final round

  AddRoundKey_ts(Nr)
  IF tracing DO
  { writef("%i2.k_sch  ", Nr); prstate(@Rkey!(16*Nr))
    writef("%i2.output ", Nr); prstate(stateS)
  }

  // The encryption process is over.
  // Copy the state array to output array.
  out%00, out%04, out%08, out%12 := s00, s01, s02, s03
  out%01, out%05, out%09, out%13 := s10, s11, s12, s13
  out%02, out%06, out%10, out%14 := s20, s21, s22, s23
  out%03, out%07, out%11, out%15 := s30, s31, s32, s33

}

LET InvCipher(in, out) BE
{ // Copy the input CipherText to state array.
  s00, s01, s02, s03 := in%00, in%04, in%08, in%12
  s10, s11, s12, s13 := in%01, in%05, in%09, in%13
  s20, s21, s22, s23 := in%02, in%06, in%10, in%14
  s30, s31, s32, s33 := in%03, in%07, in%11, in%15

  IF tracing DO
  { writef("%i2.iinput ", 0); prstate(stateS)
    writef("%i2.ik_sch ", 0); prstate(@Rkey!(16*Nr))
  }

  // Add the Last round key to the state before starting the rounds.
  AddRoundKey_st(Nr)

  FOR round = Nr-1 TO 1 BY -1 DO
  { IF tracing DO
    { writef("%i2.istart ", Nr-round); prstate(stateT) }

    InvShiftRows_ts()
    IF tracing DO
    { writef("%i2.is_row ", Nr-round); prstate(stateS) }

    InvSubBytes_st()
    IF tracing DO
    { writef("%i2.is_box ", Nr-round); prstate(stateT) }

    AddRoundKey_ts(round)
    IF tracing DO
    { writef("%i2.ik_sch ", Nr-round); prstate(@Rkey!(16*round))
      writef("%i2.is_add ", Nr-round); prstate(stateS)
    }

    InvMixColumns_st()
  }

  IF tracing DO
  { writef("%i2.istart ", Nr); prstate(stateT) }
  
  // The final round is given below.
  InvShiftRows_ts()
  IF tracing DO { writef("%i2.is_row ", Nr); prstate(stateS) }

  InvSubBytes_st()
  IF tracing DO { writef("%i2.is_box ", Nr); prstate(stateT) }

  // Do not mix the columns in the final round
  AddRoundKey_ts(0)
  IF tracing DO
  { writef("%i2.ik_sch ", Nr); prstate(@Rkey!(16*0))
    writef("%i2.ioutput", Nr); prstate(stateS)
  }

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
  LET key   = TABLE #x03020100, #x07060504, #x0B0A0908, #x0F0E0D0C
  // The plain text and key are the same as given in the detailed
  // example in Appendix C.1 in
  // csrc.nist.gov/publications/fips/fips197/fips-197.pdf
  // It provides a useful check that this implementaion is correct.
  // Just execute: aes128 -t
  LET in  = VEC 63
  LET out = VEC 63
  LET v   = VEC 10*16+15 // For the key schedule of 11 keys
  LET countExpand, countCipher, countInvCipher = 0, 0, 0

  Rkey := v
  stateS, stateT := @s00, @t00

  UNLESS rdargs("-t/s", argv, 50) DO
  { writef("Bad arguments for aes128*n")
    RESULTIS 0
  }

  tracing := argv!0

  inittables()

  //KeyExpansion(key)
  countExpand := instrcount(KeyExpansion, key)

  IF tracing DO
  { writef("*nKey schedule*n")
    FOR i = 0 TO Nr DO
    { LET p = 16*i
      writef("%i2: ", i)
      prstate(@Rkey!p)
    }
  }
  newline()

  writef("plain:          "); prbytes(plain); newline()
  writef("key:            "); prbytes(key)
  newline()

  //Cipher(plain, out)
  countCipher := instrcount(Cipher, plain, out)

  newline()

  writef("Cipher text:    "); prbytes(out); newline()

  //InvCipher(out, in)
  countInvCipher := instrcount(InvCipher, out, in)
  IF tracing DO newline()

  writef("InvCipher text: "); prbytes(in); newline()

  newline()
  writef("Cintcode instruction counts*n*n")
  writef("KeyExpansion: %i7*n", countExpand)
  writef("Cipher:       %i7*n", countCipher)
  writef("InvCipher:    %i7*n", countInvCipher)

  RESULTIS 0
}

AND prstate(m) BE
{ // For outputting state matrix or keys, column by column.
  FOR i = 0 TO 3 DO
  { wrch(' ')
    FOR j = 0 TO 3 DO
      writef("%x2", m!(4*j+i))
  }
  newline()
}

AND prbytes(v) BE
{ // For outputting plain and ciphered text.
  FOR i = 0 TO 15 DO
  { IF i MOD 4 = 0 DO wrch(' ')
    writef("%x2", v%i)
  }
  newline()
}

