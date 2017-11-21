// This is a really naive program to solve Su Doku problems
// as set in many newspapers.

// Implemented in BCPL by Martin Richards (c) January 2005

// Modified 4 August 2014

// It consists of a 9x9 grid of cells. Each cell should contain
// a digit in the range 1..9. Every row, column and major 3x3
// square should contain all the digits 1..9. Some cells have
// given values. The problem is to find digits to place in
// the unspecified cells satisfying the constraints.

// A typical problem is:

//  - - -   6 3 8   - - -
//  7 - 6   - - -   3 - 5
//  - 1 -   - - -   - 4 -

//  - - 8   7 1 2   4 - -
//  - 9 -   - - -   - 5 -
//  - - 2   5 6 9   1 - -

//  - 3 -   - - -   - 1 -
//  1 - 5   - - -   6 - 8
//  - - -   1 8 4   - - -

// The above problem is solved by the command:

// sudoku 000638000 706000305 010000040   -- all on one line
//        008712400 090000050 002569100
//        030000010 105000608 000184000

SECTION "sudoku"

GET "libhdr"

GLOBAL { count:ug

// The 9x9 board consisting of 81 cells

a1; a2; a3; a4; a5; a6; a7; a8; a9
b1; b2; b3; b4; b5; b6; b7; b8; b9
c1; c2; c3; c4; c5; c6; c7; c8; c9
d1; d2; d3; d4; d5; d6; d7; d8; d9
e1; e2; e3; e4; e5; e6; e7; e8; e9
f1; f2; f3; f4; f5; f6; f7; f8; f9
g1; g2; g3; g4; g5; g6; g7; g8; g9
h1; h2; h3; h4; h5; h6; h7; h8; h9
i1; i2; i3; i4; i5; i6; i7; i8; i9

rowabits; col1bits; squ1bits
rowbbits; col2bits; squ2bits
rowcbits; col3bits; squ3bits
rowdbits; col4bits; squ4bits
rowebits; col5bits; squ5bits
rowfbits; col6bits; squ6bits
rowgbits; col7bits; squ7bits
rowhbits; col8bits; squ8bits
rowibits; col9bits; squ9bits
}

MANIFEST {
N1 = #b_000000001 // Bit patterns representing the 9 digits
N2 = #b_000000010
N3 = #b_000000100
N4 = #b_000001000
N5 = #b_000010000
N6 = #b_000100000
N7 = #b_001000000
N8 = #b_010000000
N9 = #b_100000000

All = N1+N2+N3+N4+N5+N6+N7+N8+N9
}

LET start() = VALOF
{ LET argv = VEC 50

  LET r1 = 000_638_000  // The default board setting
  LET r2 = 706_000_305
  LET r3 = 010_000_040
  LET r4 = 008_712_400
  LET r5 = 090_000_050
  LET r6 = 002_569_100
  LET r7 = 030_000_010
  LET r8 = 105_000_608
  LET r9 = 000_184_000

  //LET r1 = 000_000_000 // This version of row 1 gives 14 solutions
  //LET r9 = 000_000_000 // This version of row 9 gives 46 solutions
                         // If both row 1 and row 9 are all zeroes
                         // there are 2096 solutions.

//UNLESS rdargs("r1/n,r2/n,r3/n,r4/n,r5/n,r6/n,r7/n,r8/n,r9/n",
//               argv, 50) DO
//{ writef("Bad arguments for SUDOKU*n*c")
//  RESULTIS 0
//}
//
//IF argv!0 DO
//{ // Set the board from the arguments
//  r1,r2,r3,r4,r5,r6,r7,r8,r9 := 0,0,0,0,0,0,0,0,0
//  IF argv!0 DO r1 := !(argv!0)
//  IF argv!1 DO r2 := !(argv!1)
//  IF argv!2 DO r3 := !(argv!2)
//  IF argv!3 DO r4 := !(argv!3)
//  IF argv!4 DO r5 := !(argv!4)
//  IF argv!5 DO r6 := !(argv!5)
//  IF argv!6 DO r7 := !(argv!6)
//  IF argv!7 DO r8 := !(argv!7)
//  IF argv!8 DO r9 := !(argv!8)
//}

  initboard(r1,r2,r3,r4,r5,r6,r7,r8,r9)
  writef("*n*cInitial board*n*c")
  prboard()
  count := 0
  ta1()
  writef("*n*c*n*cTotal number of solutions: %n*n*c", count)
  RESULTIS 0
}

AND setrow(row, r) BE
{ LET tab = TABLE 0, N1, N2, N3, N4, N5, N6, N7, N8, N9
  FOR i = 8 TO 0 BY -1 DO
  { LET n = r MOD 10
    r := r/10
    row!i := tab!n
  }
}

AND initboard(r1,r2,r3,r4,r5,r6,r7,r8,r9) BE
{ // Give all 81 cells their initial settings
  setrow(@a1, r1)
  setrow(@b1, r2)
  setrow(@c1, r3)
  setrow(@d1, r4)
  setrow(@e1, r5)
  setrow(@f1, r6)
  setrow(@g1, r7)
  setrow(@h1, r8)
  setrow(@i1, r9)

  // Set the initial row bit patterns
  rowabits := a1+a2+a3+a4+a5+a6+a7+a8+a9
  rowbbits := b1+b2+b3+b4+b5+b6+b7+b8+b9
  rowcbits := c1+c2+c3+c4+c5+c6+c7+c8+c9
  rowdbits := d1+d2+d3+d4+d5+d6+d7+d8+d9
  rowebits := e1+e2+e3+e4+e5+e6+e7+e8+e9
  rowfbits := f1+f2+f3+f4+f5+f6+f7+f8+f9
  rowgbits := g1+g2+g3+g4+g5+g6+g7+g8+g9
  rowhbits := h1+h2+h3+h4+h5+h6+h7+h8+h9
  rowibits := i1+i2+i3+i4+i5+i6+i7+i8+i9

  // Set the initial column bit patterns
  col1bits := a1+b1+c1+d1+e1+f1+g1+h1+i1
  col2bits := a2+b2+c2+d2+e2+f2+g2+h2+i2
  col3bits := a3+b3+c3+d3+e3+f3+g3+h3+i3
  col4bits := a4+b4+c4+d4+e4+f4+g4+h4+i4
  col5bits := a5+b5+c5+d5+e5+f5+g5+h5+i5
  col6bits := a6+b6+c6+d6+e6+f6+g6+h6+i6
  col7bits := a7+b7+c7+d7+e7+f7+g7+h7+i7
  col8bits := a8+b8+c8+d8+e8+f8+g8+h8+i8
  col9bits := a9+b9+c9+d9+e9+f9+g9+h9+i9

  // Set the initial 3x3 square bit patterns
  squ1bits := a1+a2+a3 + b1+b2+b3 + c1+c2+c3
  squ2bits := a4+a5+a6 + b4+b5+b6 + c4+c5+c6
  squ3bits := a7+a8+a9 + b7+b8+b9 + c7+c8+c9
  squ4bits := d1+d2+d3 + e1+e2+e3 + f1+f2+f3
  squ5bits := d4+d5+d6 + e4+e5+e6 + f4+f5+f6
  squ6bits := d7+d8+d9 + e7+e8+e9 + f7+f8+f9
  squ7bits := g1+g2+g3 + h1+h2+h3 + i1+i2+i3
  squ8bits := g4+g5+g6 + h4+h5+h6 + i4+i5+i6
  squ9bits := g7+g8+g9 + h7+h8+h9 + i7+i8+i9
}

AND try(p, f, rptr, cptr, sptr) BE TEST !p
  THEN f() // The cell pointed to by p is already set
           // so move on to the next cell, if any.
  ELSE { LET r, c, s = !rptr, !cptr, !sptr
         // r, c and s are bit patterns indicating which digits
         // already occupy the current row, column or square.
         LET poss = All - (r | c | s)
         // poss is a bit pattern indicating which digits can
         // be placed in the current cell.
         WHILE poss DO
         { // Try each allowable digit in turn. 
           LET bit = poss & -poss
           poss := poss-bit
           // Update the cell, row, column and square bit patterns.
           !p, !rptr, !cptr, !sptr := bit, r+bit, c+bit, s+bit
           // Move on to the next cell, if any.
           f()
         }
         // Restore the cell, row, column and square bit patterns.
         !p, !rptr, !cptr, !sptr := 0, r, c, s
       }

// The following 81 functions try all possible settings for
// each cell on the board.
AND ta1() BE try(@a1, ta2, @rowabits, @col1bits, @squ1bits)
AND ta2() BE try(@a2, ta3, @rowabits, @col2bits, @squ1bits)
AND ta3() BE try(@a3, ta4, @rowabits, @col3bits, @squ1bits)
AND ta4() BE try(@a4, ta5, @rowabits, @col4bits, @squ2bits)
AND ta5() BE try(@a5, ta6, @rowabits, @col5bits, @squ2bits)
AND ta6() BE try(@a6, ta7, @rowabits, @col6bits, @squ2bits)
AND ta7() BE try(@a7, ta8, @rowabits, @col7bits, @squ3bits)
AND ta8() BE try(@a8, ta9, @rowabits, @col8bits, @squ3bits)
AND ta9() BE try(@a9, tb1, @rowabits, @col9bits, @squ3bits)

AND tb1() BE try(@b1, tb2, @rowbbits, @col1bits, @squ1bits)
AND tb2() BE try(@b2, tb3, @rowbbits, @col2bits, @squ1bits)
AND tb3() BE try(@b3, tb4, @rowbbits, @col3bits, @squ1bits)
AND tb4() BE try(@b4, tb5, @rowbbits, @col4bits, @squ2bits)
AND tb5() BE try(@b5, tb6, @rowbbits, @col5bits, @squ2bits)
AND tb6() BE try(@b6, tb7, @rowbbits, @col6bits, @squ2bits)
AND tb7() BE try(@b7, tb8, @rowbbits, @col7bits, @squ3bits)
AND tb8() BE try(@b8, tb9, @rowbbits, @col8bits, @squ3bits)
AND tb9() BE try(@b9, tc1, @rowbbits, @col9bits, @squ3bits)

AND tc1() BE try(@c1, tc2, @rowcbits, @col1bits, @squ1bits)
AND tc2() BE try(@c2, tc3, @rowcbits, @col2bits, @squ1bits)
AND tc3() BE try(@c3, tc4, @rowcbits, @col3bits, @squ1bits)
AND tc4() BE try(@c4, tc5, @rowcbits, @col4bits, @squ2bits)
AND tc5() BE try(@c5, tc6, @rowcbits, @col5bits, @squ2bits)
AND tc6() BE try(@c6, tc7, @rowcbits, @col6bits, @squ2bits)
AND tc7() BE try(@c7, tc8, @rowcbits, @col7bits, @squ3bits)
AND tc8() BE try(@c8, tc9, @rowcbits, @col8bits, @squ3bits)
AND tc9() BE try(@c9, td1, @rowcbits, @col9bits, @squ3bits)

AND td1() BE try(@d1, td2, @rowdbits, @col1bits, @squ4bits)
AND td2() BE try(@d2, td3, @rowdbits, @col2bits, @squ4bits)
AND td3() BE try(@d3, td4, @rowdbits, @col3bits, @squ4bits)
AND td4() BE try(@d4, td5, @rowdbits, @col4bits, @squ5bits)
AND td5() BE try(@d5, td6, @rowdbits, @col5bits, @squ5bits)
AND td6() BE try(@d6, td7, @rowdbits, @col6bits, @squ5bits)
AND td7() BE try(@d7, td8, @rowdbits, @col7bits, @squ6bits)
AND td8() BE try(@d8, td9, @rowdbits, @col8bits, @squ6bits)
AND td9() BE try(@d9, te1, @rowdbits, @col9bits, @squ6bits)

AND te1() BE try(@e1, te2, @rowebits, @col1bits, @squ4bits)
AND te2() BE try(@e2, te3, @rowebits, @col2bits, @squ4bits)
AND te3() BE try(@e3, te4, @rowebits, @col3bits, @squ4bits)
AND te4() BE try(@e4, te5, @rowebits, @col4bits, @squ5bits)
AND te5() BE try(@e5, te6, @rowebits, @col5bits, @squ5bits)
AND te6() BE try(@e6, te7, @rowebits, @col6bits, @squ5bits)
AND te7() BE try(@e7, te8, @rowebits, @col7bits, @squ6bits)
AND te8() BE try(@e8, te9, @rowebits, @col8bits, @squ6bits)
AND te9() BE try(@e9, tf1, @rowebits, @col9bits, @squ6bits)

AND tf1() BE try(@f1, tf2, @rowfbits, @col1bits, @squ4bits)
AND tf2() BE try(@f2, tf3, @rowfbits, @col2bits, @squ4bits)
AND tf3() BE try(@f3, tf4, @rowfbits, @col3bits, @squ4bits)
AND tf4() BE try(@f4, tf5, @rowfbits, @col4bits, @squ5bits)
AND tf5() BE try(@f5, tf6, @rowfbits, @col5bits, @squ5bits)
AND tf6() BE try(@f6, tf7, @rowfbits, @col6bits, @squ5bits)
AND tf7() BE try(@f7, tf8, @rowfbits, @col7bits, @squ6bits)
AND tf8() BE try(@f8, tf9, @rowfbits, @col8bits, @squ6bits)
AND tf9() BE try(@f9, tg1, @rowfbits, @col9bits, @squ6bits)

AND tg1() BE try(@g1, tg2, @rowgbits, @col1bits, @squ7bits)
AND tg2() BE try(@g2, tg3, @rowgbits, @col2bits, @squ7bits)
AND tg3() BE try(@g3, tg4, @rowgbits, @col3bits, @squ7bits)
AND tg4() BE try(@g4, tg5, @rowgbits, @col4bits, @squ8bits)
AND tg5() BE try(@g5, tg6, @rowgbits, @col5bits, @squ8bits)
AND tg6() BE try(@g6, tg7, @rowgbits, @col6bits, @squ8bits)
AND tg7() BE try(@g7, tg8, @rowgbits, @col7bits, @squ9bits)
AND tg8() BE try(@g8, tg9, @rowgbits, @col8bits, @squ9bits)
AND tg9() BE try(@g9, th1, @rowgbits, @col9bits, @squ9bits)

AND th1() BE try(@h1, th2, @rowhbits, @col1bits, @squ7bits)
AND th2() BE try(@h2, th3, @rowhbits, @col2bits, @squ7bits)
AND th3() BE try(@h3, th4, @rowhbits, @col3bits, @squ7bits)
AND th4() BE try(@h4, th5, @rowhbits, @col4bits, @squ8bits)
AND th5() BE try(@h5, th6, @rowhbits, @col5bits, @squ8bits)
AND th6() BE try(@h6, th7, @rowhbits, @col6bits, @squ8bits)
AND th7() BE try(@h7, th8, @rowhbits, @col7bits, @squ9bits)
AND th8() BE try(@h8, th9, @rowhbits, @col8bits, @squ9bits)
AND th9() BE try(@h9, ti1, @rowhbits, @col9bits, @squ9bits)

AND ti1() BE try(@i1, ti2, @rowibits, @col1bits, @squ7bits)
AND ti2() BE try(@i2, ti3, @rowibits, @col2bits, @squ7bits)
AND ti3() BE try(@i3, ti4, @rowibits, @col3bits, @squ7bits)
AND ti4() BE try(@i4, ti5, @rowibits, @col4bits, @squ8bits)
AND ti5() BE try(@i5, ti6, @rowibits, @col5bits, @squ8bits)
AND ti6() BE try(@i6, ti7, @rowibits, @col6bits, @squ8bits)
AND ti7() BE try(@i7, ti8, @rowibits, @col7bits, @squ9bits)
AND ti8() BE try(@i8, ti9, @rowibits, @col8bits, @squ9bits)
AND ti9() BE try(@i9, suc, @rowibits, @col9bits, @squ9bits)

// suc is only called when a solution has been found.
AND suc() BE
{ count := count + 1
  writef("*n*cSolution number %n*n*c", count)
  prboard()
}

AND c(n) = VALOF SWITCHON n INTO
{ DEFAULT:    RESULTIS '?'
  CASE  0:    RESULTIS '-'
  CASE N1:    RESULTIS '1'
  CASE N2:    RESULTIS '2'
  CASE N3:    RESULTIS '3'
  CASE N4:    RESULTIS '4'
  CASE N5:    RESULTIS '5'
  CASE N6:    RESULTIS '6'
  CASE N7:    RESULTIS '7'
  CASE N8:    RESULTIS '8'
  CASE N9:    RESULTIS '9'
}

AND prboard() BE
{ LET form = "%c %c %c   %c %c %c   %c %c %c*n*c"
  newline()
  writef(form, c(a1),c(a2),c(a3),c(a4),c(a5),c(a6),c(a7),c(a8),c(a9))
  writef(form, c(b1),c(b2),c(b3),c(b4),c(b5),c(b6),c(b7),c(b8),c(b9))
  writef(form, c(c1),c(c2),c(c3),c(c4),c(c5),c(c6),c(c7),c(c8),c(c9))
  newline()
  writef(form, c(d1),c(d2),c(d3),c(d4),c(d5),c(d6),c(d7),c(d8),c(d9))
  writef(form, c(e1),c(e2),c(e3),c(e4),c(e5),c(e6),c(e7),c(e8),c(e9))
  writef(form, c(f1),c(f2),c(f3),c(f4),c(f5),c(f6),c(f7),c(f8),c(f9))
  newline()
  writef(form, c(g1),c(g2),c(g3),c(g4),c(g5),c(g6),c(g7),c(g8),c(g9))
  writef(form, c(h1),c(h2),c(h3),c(h4),c(h5),c(h6),c(h7),c(h8),c(h9))
  writef(form, c(i1),c(i2),c(i3),c(i4),c(i5),c(i6),c(i7),c(i8),c(i9))

  newline()
}
