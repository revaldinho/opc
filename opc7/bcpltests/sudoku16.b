// This is a really naive program to solve 16x16 SuDoku problems
// as set in the Independent.

// Implemented in BCPL by Martin Richards (c) July 2005

// It consists of a 16x16 grid of cells. Each cell should contain
// a hex digit in the range 0..F. Every row, column and major 4x4
// square should contain all the digits. Some cells have given
// values. The problem is to find digits to place in the unspecified
// cells satisfying the constraints.

// A typical problem is:

//  - - B -   - - 8 9   - 6 F 1   - - - D
//  E C - -   - 5 - 1   7 2 - 3   A 9 - -
//  - - F 8   - - - -   - - - -   - - B 2
//  - - - 9   0 7 2 E   8 - - -   - - - C

//  - D C -   E - F -   9 - - B   4 - - -
//  5 - - -   - - - -   - - 4 -   - - 9 1
//  - - 0 -   1 A - C   - - - -   E 5 2 3
//  F 8 4 -   5 - - D   3 - 7 0   - C - -

//  - - - -   7 C - F   2 1 - -   0 - - E
//  - 3 - -   - 9 6 B   5 0 C -   - A - 4
//  - - D A   - - - -   - - 6 -   - F 3 -
//  - - - -   - - - -   - A - -   - - - -

//  - 2 - -   - 6 - -   - - - C   - - - 5
//  - 6 A -   - E C 5   4 - 8 7   D - - B
//  - 1 - -   2 8 - -   - - 5 -   - - - -
//  - - 9 -   - - - -   - - - A   - 3 - -

// Even when given the hint that the first two digits should be 2A
// it takes 189 seconds to run under Cintcode BCPL on a 1GHz Mobile
// Pentium III.

SECTION "sudoku16"

GET "libhdr"

GLOBAL { count:ug

// The 16x16 board

a0; a1; a2; a3; a4; a5; a6; a7; a8; a9; aa; ab; ac; ad; ae; af
b0; b1; b2; b3; b4; b5; b6; b7; b8; b9; ba; bb; bc; bd; be; bf
c0; c1; c2; c3; c4; c5; c6; c7; c8; c9; ca; cb; cc; cd; ce; cf
d0; d1; d2; d3; d4; d5; d6; d7; d8; d9; da; db; dc; dd; de; df

e0; e1; e2; e3; e4; e5; e6; e7; e8; e9; ea; eb; ec; ed; ee; ef
f0; f1; f2; f3; f4; f5; f6; f7; f8; f9; fa; fb; fc; fd; fe; ff
g0; g1; g2; g3; g4; g5; g6; g7; g8; g9; ga; gb; gc; gd; ge; gf
h0; h1; h2; h3; h4; h5; h6; h7; h8; h9; ha; hb; hc; hd; he; hf

i0; i1; i2; i3; i4; i5; i6; i7; i8; i9; ia; ib; ic; id; ie; if
j0; j1; j2; j3; j4; j5; j6; j7; j8; j9; ja; jb; jc; jd; je; jf
k0; k1; k2; k3; k4; k5; k6; k7; k8; k9; ka; kb; kc; kd; ke; kf
l0; l1; l2; l3; l4; l5; l6; l7; l8; l9; la; lb; lc; ld; le; lf

m0; m1; m2; m3; m4; m5; m6; m7; m8; m9; ma; mb; mc; md; me; mf
n0; n1; n2; n3; n4; n5; n6; n7; n8; n9; na; nb; nc; nd; ne; nf
o0; o1; o2; o3; o4; o5; o6; o7; o8; o9; oa; ob; oc; od; oe; of
p0; p1; p2; p3; p4; p5; p6; p7; p8; p9; pa; pb; pc; pd; pe; pf

rowabits; col0bits; squ0bits
rowbbits; col1bits; squ1bits
rowcbits; col2bits; squ2bits
rowdbits; col3bits; squ3bits
rowebits; col4bits; squ4bits
rowfbits; col5bits; squ5bits
rowgbits; col6bits; squ6bits
rowhbits; col7bits; squ7bits
rowibits; col8bits; squ8bits
rowjbits; col9bits; squ9bits
rowkbits; colabits; squabits
rowlbits; colbbits; squbbits
rowmbits; colcbits; squcbits
rownbits; coldbits; squdbits
rowobits; colebits; squebits
rowpbits; colfbits; squfbits
}

MANIFEST {
N0=1<<0
N1=1<<1
N2=1<<2
N3=1<<3
N4=1<<4
N5=1<<5
N6=1<<6
N7=1<<7
N8=1<<8
N9=1<<9
Na=1<<10
Nb=1<<11
Nc=1<<12
Nd=1<<13
Ne=1<<14
Nf=1<<15
}

LET start() = VALOF
{ count := 0
  initboard()
  ta0()
  writef("*n*nTotal number of solutions: %n*n", count)
  RESULTIS 0
}

AND setrow(p, str) BE
{ FOR i = 1 TO str%0 SWITCHON capitalch(str%i) INTO
  { DEFAULT: LOOP
    CASE '-': !p := 0;  p := p+1; LOOP
    CASE '0': !p := N0; p := p+1; LOOP
    CASE '1': !p := N1; p := p+1; LOOP
    CASE '2': !p := N2; p := p+1; LOOP
    CASE '3': !p := N3; p := p+1; LOOP
    CASE '4': !p := N4; p := p+1; LOOP
    CASE '5': !p := N5; p := p+1; LOOP
    CASE '6': !p := N6; p := p+1; LOOP
    CASE '7': !p := N7; p := p+1; LOOP
    CASE '8': !p := N8; p := p+1; LOOP
    CASE '9': !p := N9; p := p+1; LOOP
    CASE 'A': !p := Na; p := p+1; LOOP
    CASE 'B': !p := Nb; p := p+1; LOOP
    CASE 'C': !p := Nc; p := p+1; LOOP
    CASE 'D': !p := Nd; p := p+1; LOOP
    CASE 'E': !p := Ne; p := p+1; LOOP
    CASE 'F': !p := Nf; p := p+1; LOOP
  }
}

AND initboard() BE
{ FOR p = @a1 TO @pf DO !p := 0

  //setrow(@a1, "0123 4567 89ab cdef")

  setrow(@a0, "- - B -   - - 8 9   - 6 F 1   - - - D")
  setrow(@b0, "E C - -   - 5 - 1   7 2 - 3   A 9 - -")
  setrow(@c0, "- - F 8   - - - -   - - - -   - - B 2")
  setrow(@d0, "- - - 9   0 7 2 E   8 - - -   - - - C")

  setrow(@e0, "- D C -   E - F -   9 - - B   4 - - -")
  setrow(@f0, "5 - - -   - - - -   - - 4 -   - - 9 1")
  setrow(@g0, "- - 0 -   1 A - C   - - - -   E 5 2 3")
  setrow(@h0, "F 8 4 -   5 - - D   3 - 7 0   - C - -")

  setrow(@i0, "- - - -   7 C - F   2 1 - -   0 - - E")
  setrow(@j0, "- 3 - -   - 9 6 B   5 0 C -   - A - 4")
  setrow(@k0, "- - D A   - - - -   - - 6 -   - F 3 -")
  setrow(@l0, "- - - -   - - - -   - A - -   - - - -")

  setrow(@m0, "- 2 - -   - 6 - -   - - - C   - - - 5")
  setrow(@n0, "- 6 A -   - E C 5   4 - 8 7   D - - B")
  setrow(@o0, "- 1 - -   2 8 - -   - - 5 -   - - - -")
  setrow(@p0, "- - 9 -   - - - -   - - - A   - 3 - -")

//############# Hint to save time #########################
  a0 := N2
  a1 := Na
//################ End of hint ############################

  rowabits := rowa(); col0bits := col0(); squ0bits := squ0()
  rowbbits := rowb(); col1bits := col1(); squ1bits := squ1()
  rowcbits := rowc(); col2bits := col2(); squ2bits := squ2()
  rowdbits := rowd(); col3bits := col3(); squ3bits := squ3()
  rowebits := rowe(); col4bits := col4(); squ4bits := squ4()
  rowfbits := rowf(); col5bits := col5(); squ5bits := squ5()
  rowgbits := rowg(); col6bits := col6(); squ6bits := squ6()
  rowhbits := rowh(); col7bits := col7(); squ7bits := squ7()
  rowibits := rowi(); col8bits := col8(); squ8bits := squ8()
  rowjbits := rowj(); col9bits := col9(); squ9bits := squ9()
  rowkbits := rowk(); colabits := cola(); squabits := squa()
  rowlbits := rowl(); colbbits := colb(); squbbits := squb()
  rowmbits := rowm(); colcbits := colc(); squcbits := squc()
  rownbits := rown(); coldbits := cold(); squdbits := squd()
  rowobits := rowo(); colebits := cole(); squebits := sque()
  rowpbits := rowp(); colfbits := colf(); squfbits := squf()

prboard()
}

AND rowa() = a0+a1+a2+a3+a4+a5+a6+a7+a8+a9+aa+ab+ac+ad+ae+af
AND rowb() = b0+b1+b2+b3+b4+b5+b6+b7+b8+b9+ba+bb+bc+bd+be+bf
AND rowc() = c0+c1+c2+c3+c4+c5+c6+c7+c8+c9+ca+cb+cc+cd+ce+cf
AND rowd() = d0+d1+d2+d3+d4+d5+d6+d7+d8+d9+da+db+dc+dd+de+df
AND rowe() = e0+e1+e2+e3+e4+e5+e6+e7+e8+e9+ea+eb+ec+ed+ee+ef
AND rowf() = f0+f1+f2+f3+f4+f5+f6+f7+f8+f9+fa+fb+fc+fd+fe+ff
AND rowg() = g0+g1+g2+g3+g4+g5+g6+g7+g8+g9+ga+gb+gc+gd+ge+gf
AND rowh() = h0+h1+h2+h3+h4+h5+h6+h7+h8+h9+ha+hb+hc+hd+he+hf
AND rowi() = i0+i1+i2+i3+i4+i5+i6+i7+i8+i9+ia+ib+ic+id+ie+if
AND rowj() = j0+j1+j2+j3+j4+j5+j6+j7+j8+j9+ja+jb+jc+jd+je+jf
AND rowk() = k0+k1+k2+k3+k4+k5+k6+k7+k8+k9+ka+kb+kc+kd+ke+kf
AND rowl() = l0+l1+l2+l3+l4+l5+l6+l7+l8+l9+la+lb+lc+ld+le+lf
AND rowm() = m0+m1+m2+m3+m4+m5+m6+m7+m8+m9+ma+mb+mc+md+me+mf
AND rown() = n0+n1+n2+n3+n4+n5+n6+n7+n8+n9+na+nb+nc+nd+ne+nf
AND rowo() = o0+o1+o2+o3+o4+o5+o6+o7+o8+o9+oa+ob+oc+od+oe+of
AND rowp() = p0+p1+p2+p3+p4+p5+p6+p7+p8+p9+pa+pb+pc+pd+pe+pf

AND col0() = a0+b0+c0+d0+e0+f0+g0+h0+i0+j0+k0+l0+m0+n0+o0+p0
AND col1() = a1+b1+c1+d1+e1+f1+g1+h1+i1+j1+k1+l1+m1+n1+o1+p1
AND col2() = a2+b2+c2+d2+e2+f2+g2+h2+i2+j2+k2+l2+m2+n2+o2+p2
AND col3() = a3+b3+c3+d3+e3+f3+g3+h3+i3+j3+k3+l3+m3+n3+o3+p3
AND col4() = a4+b4+c4+d4+e4+f4+g4+h4+i4+j4+k4+l4+m4+n4+o4+p4
AND col5() = a5+b5+c5+d5+e5+f5+g5+h5+i5+j5+k5+l5+m5+n5+o5+p5
AND col6() = a6+b6+c6+d6+e6+f6+g6+h6+i6+j6+k6+l6+m6+n6+o6+p6
AND col7() = a7+b7+c7+d7+e7+f7+g7+h7+i7+j7+k7+l7+m7+n7+o7+p7
AND col8() = a8+b8+c8+d8+e8+f8+g8+h8+i8+j8+k8+l8+m8+n8+o8+p8
AND col9() = a9+b9+c9+d9+e9+f9+g9+h9+i9+j9+k9+l9+m9+n9+o9+p9
AND cola() = aa+ba+ca+da+ea+fa+ga+ha+ia+ja+ka+la+ma+na+oa+pa
AND colb() = ab+bb+cb+db+eb+fb+gb+hb+ib+jb+kb+lb+mb+nb+ob+pb
AND colc() = ac+bc+cc+dc+ec+fc+gc+hc+ic+jc+kc+lc+mc+nc+oc+pc
AND cold() = ad+bd+cd+dd+ed+fd+gd+hd+id+jd+kd+ld+md+nd+od+pd
AND cole() = ae+be+ce+de+ee+fe+ge+he+ie+je+ke+le+me+ne+oe+pe
AND colf() = af+bf+cf+df+ef+ff+gf+hf+if+jf+kf+lf+mf+nf+of+pf

AND squ0() = a0+a1+a2+a3+b0+b1+b2+b3+c0+c1+c2+c3+d0+d1+d2+d3
AND squ1() = a4+a5+a6+a7+b4+b5+b6+b7+c4+c5+c6+c7+d4+d5+d6+d7
AND squ2() = a8+a9+aa+ab+b8+b9+ba+bb+c8+c9+ca+cb+d8+d9+da+db
AND squ3() = ac+ad+ae+af+bc+bd+be+bf+cc+cd+ce+cf+dc+dd+de+df
AND squ4() = e0+e1+e2+e3+f0+f1+f2+f3+g0+g1+g2+g3+h0+h1+h2+h3
AND squ5() = e4+e5+e6+e7+f4+f5+f6+f7+g4+g5+g6+g7+h4+h5+h6+h7
AND squ6() = e8+e9+ea+eb+f8+f9+fa+fb+g8+g9+ga+gb+h8+h9+ha+hb
AND squ7() = ec+ed+ee+ef+fc+fd+fe+ff+gc+gd+ge+gf+hc+hd+he+hf
AND squ8() = i0+i1+i2+i3+j0+j1+j2+j3+k0+k1+k2+k3+l0+l1+l2+l3
AND squ9() = i4+i5+i6+i7+j4+j5+j6+j7+k4+k5+k6+k7+l4+l5+l6+l7
AND squa() = i8+i9+ia+ib+j8+j9+ja+jb+k8+k9+ka+kb+l8+l9+la+lb
AND squb() = ic+id+ie+if+jc+jd+je+jf+kc+kd+ke+kf+lc+ld+le+lf
AND squc() = m0+m1+m2+m3+n0+n1+n2+n3+o0+o1+o2+o3+p0+p1+p2+p3
AND squd() = m4+m5+m6+m7+n4+n5+n6+n7+o4+o5+o6+o7+p4+p5+p6+p7
AND sque() = m8+m9+ma+mb+n8+n9+na+nb+o8+o9+oa+ob+p8+p9+pa+pb
AND squf() = mc+md+me+mf+nc+nd+ne+nf+oc+od+oe+of+pc+pd+pe+pf


AND c(n) = VALOF SWITCHON n INTO
{ DEFAULT:    RESULTIS '?'
  CASE  0:    RESULTIS '-'
  CASE N0:    RESULTIS '0'
  CASE N1:    RESULTIS '1'
  CASE N2:    RESULTIS '2'
  CASE N3:    RESULTIS '3'
  CASE N4:    RESULTIS '4'
  CASE N5:    RESULTIS '5'
  CASE N6:    RESULTIS '6'
  CASE N7:    RESULTIS '7'
  CASE N8:    RESULTIS '8'
  CASE N9:    RESULTIS '9'
  CASE Na:    RESULTIS 'A'
  CASE Nb:    RESULTIS 'B'
  CASE Nc:    RESULTIS 'C'
  CASE Nd:    RESULTIS 'D'
  CASE Ne:    RESULTIS 'E'
  CASE Nf:    RESULTIS 'F'
}

AND prboard() BE
{ LET form = "%c %c %c %c   %c %c %c %c   %c %c %c %c   %c %c %c %c*n"
  writef("*ncount = %n*n", count)
  newline()
  writef(form, c(a0),c(a1),c(a2),c(a3),c(a4),c(a5),c(a6),c(a7),
               c(a8),c(a9),c(aa),c(ab),c(ac),c(ad),c(ae),c(af))
  writef(form, c(b0),c(b1),c(b2),c(b3),c(b4),c(b5),c(b6),c(b7),
               c(b8),c(b9),c(ba),c(bb),c(bc),c(bd),c(be),c(bf))
  writef(form, c(c0),c(c1),c(c2),c(c3),c(c4),c(c5),c(c6),c(c7),
               c(c8),c(c9),c(ca),c(cb),c(cc),c(cd),c(ce),c(cf))
  writef(form, c(d0),c(d1),c(d2),c(d3),c(d4),c(d5),c(d6),c(d7),
               c(d8),c(d9),c(da),c(db),c(dc),c(dd),c(de),c(df))
  newline()
  writef(form, c(e0),c(e1),c(e2),c(e3),c(e4),c(e5),c(e6),c(e7),
               c(e8),c(e9),c(ea),c(eb),c(ec),c(ed),c(ee),c(ef))
  writef(form, c(f0),c(f1),c(f2),c(f3),c(f4),c(f5),c(f6),c(f7),
               c(f8),c(f9),c(fa),c(fb),c(fc),c(fd),c(fe),c(ff))
  writef(form, c(g0),c(g1),c(g2),c(g3),c(g4),c(g5),c(g6),c(g7),
               c(g8),c(g9),c(ga),c(gb),c(gc),c(gd),c(ge),c(gf))
  writef(form, c(h0),c(h1),c(h2),c(h3),c(h4),c(h5),c(h6),c(h7),
               c(h8),c(h9),c(ha),c(hb),c(hc),c(hd),c(he),c(hf))
  newline()
  writef(form, c(i0),c(i1),c(i2),c(i3),c(i4),c(i5),c(i6),c(i7),
               c(i8),c(i9),c(ia),c(ib),c(ic),c(id),c(ie),c(if))
  writef(form, c(j0),c(j1),c(j2),c(j3),c(j4),c(j5),c(j6),c(j7),
               c(j8),c(j9),c(ja),c(jb),c(jc),c(jd),c(je),c(jf))
  writef(form, c(k0),c(k1),c(k2),c(k3),c(k4),c(k5),c(k6),c(k7),
               c(k8),c(k9),c(ka),c(kb),c(kc),c(kd),c(ke),c(kf))
  writef(form, c(l0),c(l1),c(l2),c(l3),c(l4),c(l5),c(l6),c(l7),
               c(l8),c(l9),c(la),c(lb),c(lc),c(ld),c(le),c(lf))
  newline()
  writef(form, c(m0),c(m1),c(m2),c(m3),c(m4),c(m5),c(m6),c(m7),
               c(m8),c(m9),c(ma),c(mb),c(mc),c(md),c(me),c(mf))
  writef(form, c(n0),c(n1),c(n2),c(n3),c(n4),c(n5),c(n6),c(n7),
               c(n8),c(n9),c(na),c(nb),c(nc),c(nd),c(ne),c(nf))
  writef(form, c(o0),c(o1),c(o2),c(o3),c(o4),c(o5),c(o6),c(o7),
               c(o8),c(o9),c(oa),c(ob),c(oc),c(od),c(oe),c(of))
  writef(form, c(p0),c(p1),c(p2),c(p3),c(p4),c(p5),c(p6),c(p7),
               c(p8),c(p9),c(pa),c(pb),c(pc),c(pd),c(pe),c(pf))
  newline()
//abort(1000)
}

AND try(p, f, rptr, cptr, sptr) BE
{ LET x = !p
  STATIC { pmax=0 }
  TEST x
  THEN f()
  ELSE { LET r, c, s = !rptr, !cptr, !sptr
         LET poss = ~(r | c | s) & #xFFFF // Set of possible digits
         //IF pmax < p-@a0 DO
         //{ pmax := p-@a0
         //  prboard()
         //}
  //prboard()
           // writef("pos=%x2 %bG r=%bG c=%bG s=%bG*n", p-@a0, poss, r, c, s)
//abort(1000)
         WHILE poss DO
         { LET bit = poss & -poss
           poss := poss-bit
           !p, !rptr, !cptr, !sptr := bit, r+bit, c+bit, s+bit
           f()
         }
         !p, !rptr, !cptr, !sptr := 0, r, c, s
       }
}


AND ta0() BE try(@a0, ta1, @rowabits, @col0bits, @squ0bits)
AND ta1() BE try(@a1, ta2, @rowabits, @col1bits, @squ0bits)
AND ta2() BE try(@a2, ta3, @rowabits, @col2bits, @squ0bits)
AND ta3() BE try(@a3, ta4, @rowabits, @col3bits, @squ0bits)
AND ta4() BE try(@a4, ta5, @rowabits, @col4bits, @squ1bits)
AND ta5() BE try(@a5, ta6, @rowabits, @col5bits, @squ1bits)
AND ta6() BE try(@a6, ta7, @rowabits, @col6bits, @squ1bits)
AND ta7() BE try(@a7, ta8, @rowabits, @col7bits, @squ1bits)
AND ta8() BE try(@a8, ta9, @rowabits, @col8bits, @squ2bits)
AND ta9() BE try(@a9, taa, @rowabits, @col9bits, @squ2bits)
AND taa() BE try(@aa, tab, @rowabits, @colabits, @squ2bits)
AND tab() BE try(@ab, tac, @rowabits, @colbbits, @squ2bits)
AND tac() BE try(@ac, tad, @rowabits, @colcbits, @squ3bits)
AND tad() BE try(@ad, tae, @rowabits, @coldbits, @squ3bits)
AND tae() BE try(@ae, taf, @rowabits, @colebits, @squ3bits)
AND taf() BE try(@af, tb0, @rowabits, @colfbits, @squ3bits)

AND tb0() BE
{ writef("*nNew first row*n")
  prboard()
  try(@b0, tb1, @rowbbits, @col0bits, @squ0bits)
}
AND tb1() BE try(@b1, tb2, @rowbbits, @col1bits, @squ0bits)
AND tb2() BE try(@b2, tb3, @rowbbits, @col2bits, @squ0bits)
AND tb3() BE try(@b3, tb4, @rowbbits, @col3bits, @squ0bits)
AND tb4() BE try(@b4, tb5, @rowbbits, @col4bits, @squ1bits)
AND tb5() BE try(@b5, tb6, @rowbbits, @col5bits, @squ1bits)
AND tb6() BE try(@b6, tb7, @rowbbits, @col6bits, @squ1bits)
AND tb7() BE try(@b7, tb8, @rowbbits, @col7bits, @squ1bits)
AND tb8() BE try(@b8, tb9, @rowbbits, @col8bits, @squ2bits)
AND tb9() BE try(@b9, tba, @rowbbits, @col9bits, @squ2bits)
AND tba() BE try(@ba, tbb, @rowbbits, @colabits, @squ2bits)
AND tbb() BE try(@bb, tbc, @rowbbits, @colbbits, @squ2bits)
AND tbc() BE try(@bc, tbd, @rowbbits, @colcbits, @squ3bits)
AND tbd() BE try(@bd, tbe, @rowbbits, @coldbits, @squ3bits)
AND tbe() BE try(@be, tbf, @rowbbits, @colebits, @squ3bits)
AND tbf() BE try(@bf, tc0, @rowbbits, @colfbits, @squ3bits)

AND tc0() BE try(@c0, tc1, @rowcbits, @col0bits, @squ0bits)
AND tc1() BE try(@c1, tc2, @rowcbits, @col1bits, @squ0bits)
AND tc2() BE try(@c2, tc3, @rowcbits, @col2bits, @squ0bits)
AND tc3() BE try(@c3, tc4, @rowcbits, @col3bits, @squ0bits)
AND tc4() BE try(@c4, tc5, @rowcbits, @col4bits, @squ1bits)
AND tc5() BE try(@c5, tc6, @rowcbits, @col5bits, @squ1bits)
AND tc6() BE try(@c6, tc7, @rowcbits, @col6bits, @squ1bits)
AND tc7() BE try(@c7, tc8, @rowcbits, @col7bits, @squ1bits)
AND tc8() BE try(@c8, tc9, @rowcbits, @col8bits, @squ2bits)
AND tc9() BE try(@c9, tca, @rowcbits, @col9bits, @squ2bits)
AND tca() BE try(@ca, tcb, @rowcbits, @colabits, @squ2bits)
AND tcb() BE try(@cb, tcc, @rowcbits, @colbbits, @squ2bits)
AND tcc() BE try(@cc, tcd, @rowcbits, @colcbits, @squ3bits)
AND tcd() BE try(@cd, tce, @rowcbits, @coldbits, @squ3bits)
AND tce() BE try(@ce, tcf, @rowcbits, @colebits, @squ3bits)
AND tcf() BE try(@cf, td0, @rowcbits, @colfbits, @squ3bits)

AND td0() BE try(@d0, td1, @rowdbits, @col0bits, @squ0bits)
AND td1() BE try(@d1, td2, @rowdbits, @col1bits, @squ0bits)
AND td2() BE try(@d2, td3, @rowdbits, @col2bits, @squ0bits)
AND td3() BE try(@d3, td4, @rowdbits, @col3bits, @squ0bits)
AND td4() BE try(@d4, td5, @rowdbits, @col4bits, @squ1bits)
AND td5() BE try(@d5, td6, @rowdbits, @col5bits, @squ1bits)
AND td6() BE try(@d6, td7, @rowdbits, @col6bits, @squ1bits)
AND td7() BE try(@d7, td8, @rowdbits, @col7bits, @squ1bits)
AND td8() BE try(@d8, td9, @rowdbits, @col8bits, @squ2bits)
AND td9() BE try(@d9, tda, @rowdbits, @col9bits, @squ2bits)
AND tda() BE try(@da, tdb, @rowdbits, @colabits, @squ2bits)
AND tdb() BE try(@db, tdc, @rowdbits, @colbbits, @squ2bits)
AND tdc() BE try(@dc, tdd, @rowdbits, @colcbits, @squ3bits)
AND tdd() BE try(@dd, tde, @rowdbits, @coldbits, @squ3bits)
AND tde() BE try(@de, tdf, @rowdbits, @colebits, @squ3bits)
AND tdf() BE try(@df, te0, @rowdbits, @colfbits, @squ3bits)

AND te0() BE try(@e0, te1, @rowebits, @col0bits, @squ4bits)
AND te1() BE try(@e1, te2, @rowebits, @col1bits, @squ4bits)
AND te2() BE try(@e2, te3, @rowebits, @col2bits, @squ4bits)
AND te3() BE try(@e3, te4, @rowebits, @col3bits, @squ4bits)
AND te4() BE try(@e4, te5, @rowebits, @col4bits, @squ5bits)
AND te5() BE try(@e5, te6, @rowebits, @col5bits, @squ5bits)
AND te6() BE try(@e6, te7, @rowebits, @col6bits, @squ5bits)
AND te7() BE try(@e7, te8, @rowebits, @col7bits, @squ5bits)
AND te8() BE try(@e8, te9, @rowebits, @col8bits, @squ6bits)
AND te9() BE try(@e9, tea, @rowebits, @col9bits, @squ6bits)
AND tea() BE try(@ea, teb, @rowebits, @colabits, @squ6bits)
AND teb() BE try(@eb, tec, @rowebits, @colbbits, @squ6bits)
AND tec() BE try(@ec, ted, @rowebits, @colcbits, @squ7bits)
AND ted() BE try(@ed, tee, @rowebits, @coldbits, @squ7bits)
AND tee() BE try(@ee, tef, @rowebits, @colebits, @squ7bits)
AND tef() BE try(@ef, tf0, @rowebits, @colfbits, @squ7bits)

AND tf0() BE try(@f0, tf1, @rowfbits, @col0bits, @squ4bits)
AND tf1() BE try(@f1, tf2, @rowfbits, @col1bits, @squ4bits)
AND tf2() BE try(@f2, tf3, @rowfbits, @col2bits, @squ4bits)
AND tf3() BE try(@f3, tf4, @rowfbits, @col3bits, @squ4bits)
AND tf4() BE try(@f4, tf5, @rowfbits, @col4bits, @squ5bits)
AND tf5() BE try(@f5, tf6, @rowfbits, @col5bits, @squ5bits)
AND tf6() BE try(@f6, tf7, @rowfbits, @col6bits, @squ5bits)
AND tf7() BE try(@f7, tf8, @rowfbits, @col7bits, @squ5bits)
AND tf8() BE try(@f8, tf9, @rowfbits, @col8bits, @squ6bits)
AND tf9() BE try(@f9, tfa, @rowfbits, @col9bits, @squ6bits)
AND tfa() BE try(@fa, tfb, @rowfbits, @colabits, @squ6bits)
AND tfb() BE try(@fb, tfc, @rowfbits, @colbbits, @squ6bits)
AND tfc() BE try(@fc, tfd, @rowfbits, @colcbits, @squ7bits)
AND tfd() BE try(@fd, tfe, @rowfbits, @coldbits, @squ7bits)
AND tfe() BE try(@fe, tff, @rowfbits, @colebits, @squ7bits)
AND tff() BE try(@ff, tg0, @rowfbits, @colfbits, @squ7bits)

AND tg0() BE try(@g0, tg1, @rowgbits, @col0bits, @squ4bits)
AND tg1() BE try(@g1, tg2, @rowgbits, @col1bits, @squ4bits)
AND tg2() BE try(@g2, tg3, @rowgbits, @col2bits, @squ4bits)
AND tg3() BE try(@g3, tg4, @rowgbits, @col3bits, @squ4bits)
AND tg4() BE try(@g4, tg5, @rowgbits, @col4bits, @squ5bits)
AND tg5() BE try(@g5, tg6, @rowgbits, @col5bits, @squ5bits)
AND tg6() BE try(@g6, tg7, @rowgbits, @col6bits, @squ5bits)
AND tg7() BE try(@g7, tg8, @rowgbits, @col7bits, @squ5bits)
AND tg8() BE try(@g8, tg9, @rowgbits, @col8bits, @squ6bits)
AND tg9() BE try(@g9, tga, @rowgbits, @col9bits, @squ6bits)
AND tga() BE try(@ga, tgb, @rowgbits, @colabits, @squ6bits)
AND tgb() BE try(@gb, tgc, @rowgbits, @colbbits, @squ6bits)
AND tgc() BE try(@gc, tgd, @rowgbits, @colcbits, @squ7bits)
AND tgd() BE try(@gd, tge, @rowgbits, @coldbits, @squ7bits)
AND tge() BE try(@ge, tgf, @rowgbits, @colebits, @squ7bits)
AND tgf() BE try(@gf, th0, @rowgbits, @colfbits, @squ7bits)

AND th0() BE try(@h0, th1, @rowhbits, @col0bits, @squ4bits)
AND th1() BE try(@h1, th2, @rowhbits, @col1bits, @squ4bits)
AND th2() BE try(@h2, th3, @rowhbits, @col2bits, @squ4bits)
AND th3() BE try(@h3, th4, @rowhbits, @col3bits, @squ4bits)
AND th4() BE try(@h4, th5, @rowhbits, @col4bits, @squ5bits)
AND th5() BE try(@h5, th6, @rowhbits, @col5bits, @squ5bits)
AND th6() BE try(@h6, th7, @rowhbits, @col6bits, @squ5bits)
AND th7() BE try(@h7, th8, @rowhbits, @col7bits, @squ5bits)
AND th8() BE try(@h8, th9, @rowhbits, @col8bits, @squ6bits)
AND th9() BE try(@h9, tha, @rowhbits, @col9bits, @squ6bits)
AND tha() BE try(@ha, thb, @rowhbits, @colabits, @squ6bits)
AND thb() BE try(@hb, thc, @rowhbits, @colbbits, @squ6bits)
AND thc() BE try(@hc, thd, @rowhbits, @colcbits, @squ7bits)
AND thd() BE try(@hd, the, @rowhbits, @coldbits, @squ7bits)
AND the() BE try(@he, thf, @rowhbits, @colebits, @squ7bits)
AND thf() BE try(@hf, ti0, @rowhbits, @colfbits, @squ7bits)

AND ti0() BE try(@i0, ti1, @rowibits, @col0bits, @squ8bits)
AND ti1() BE try(@i1, ti2, @rowibits, @col1bits, @squ8bits)
AND ti2() BE try(@i2, ti3, @rowibits, @col2bits, @squ8bits)
AND ti3() BE try(@i3, ti4, @rowibits, @col3bits, @squ8bits)
AND ti4() BE try(@i4, ti5, @rowibits, @col4bits, @squ9bits)
AND ti5() BE try(@i5, ti6, @rowibits, @col5bits, @squ9bits)
AND ti6() BE try(@i6, ti7, @rowibits, @col6bits, @squ9bits)
AND ti7() BE try(@i7, ti8, @rowibits, @col7bits, @squ9bits)
AND ti8() BE try(@i8, ti9, @rowibits, @col8bits, @squabits)
AND ti9() BE try(@i9, tia, @rowibits, @col9bits, @squabits)
AND tia() BE try(@ia, tib, @rowibits, @colabits, @squabits)
AND tib() BE try(@ib, tic, @rowibits, @colbbits, @squabits)
AND tic() BE try(@ic, tid, @rowibits, @colcbits, @squbbits)
AND tid() BE try(@id, tie, @rowibits, @coldbits, @squbbits)
AND tie() BE try(@ie, tif, @rowibits, @colebits, @squbbits)
AND tif() BE try(@if, tj0, @rowibits, @colfbits, @squbbits)

AND tj0() BE try(@j0, tj1, @rowjbits, @col0bits, @squ8bits)
AND tj1() BE try(@j1, tj2, @rowjbits, @col1bits, @squ8bits)
AND tj2() BE try(@j2, tj3, @rowjbits, @col2bits, @squ8bits)
AND tj3() BE try(@j3, tj4, @rowjbits, @col3bits, @squ8bits)
AND tj4() BE try(@j4, tj5, @rowjbits, @col4bits, @squ9bits)
AND tj5() BE try(@j5, tj6, @rowjbits, @col5bits, @squ9bits)
AND tj6() BE try(@j6, tj7, @rowjbits, @col6bits, @squ9bits)
AND tj7() BE try(@j7, tj8, @rowjbits, @col7bits, @squ9bits)
AND tj8() BE try(@j8, tj9, @rowjbits, @col8bits, @squabits)
AND tj9() BE try(@j9, tja, @rowjbits, @col9bits, @squabits)
AND tja() BE try(@ja, tjb, @rowjbits, @colabits, @squabits)
AND tjb() BE try(@jb, tjc, @rowjbits, @colbbits, @squabits)
AND tjc() BE try(@jc, tjd, @rowjbits, @colcbits, @squbbits)
AND tjd() BE try(@jd, tje, @rowjbits, @coldbits, @squbbits)
AND tje() BE try(@je, tjf, @rowjbits, @colebits, @squbbits)
AND tjf() BE try(@jf, tk0, @rowjbits, @colfbits, @squbbits)

AND tk0() BE try(@k0, tk1, @rowkbits, @col0bits, @squ8bits)
AND tk1() BE try(@k1, tk2, @rowkbits, @col1bits, @squ8bits)
AND tk2() BE try(@k2, tk3, @rowkbits, @col2bits, @squ8bits)
AND tk3() BE try(@k3, tk4, @rowkbits, @col3bits, @squ8bits)
AND tk4() BE try(@k4, tk5, @rowkbits, @col4bits, @squ9bits)
AND tk5() BE try(@k5, tk6, @rowkbits, @col5bits, @squ9bits)
AND tk6() BE try(@k6, tk7, @rowkbits, @col6bits, @squ9bits)
AND tk7() BE try(@k7, tk8, @rowkbits, @col7bits, @squ9bits)
AND tk8() BE try(@k8, tk9, @rowkbits, @col8bits, @squabits)
AND tk9() BE try(@k9, tka, @rowkbits, @col9bits, @squabits)
AND tka() BE try(@ka, tkb, @rowkbits, @colabits, @squabits)
AND tkb() BE try(@kb, tkc, @rowkbits, @colbbits, @squabits)
AND tkc() BE try(@kc, tkd, @rowkbits, @colcbits, @squbbits)
AND tkd() BE try(@kd, tke, @rowkbits, @coldbits, @squbbits)
AND tke() BE try(@ke, tkf, @rowkbits, @colebits, @squbbits)
AND tkf() BE try(@kf, tl0, @rowkbits, @colfbits, @squbbits)

AND tl0() BE try(@l0, tl1, @rowlbits, @col0bits, @squ8bits)
AND tl1() BE try(@l1, tl2, @rowlbits, @col1bits, @squ8bits)
AND tl2() BE try(@l2, tl3, @rowlbits, @col2bits, @squ8bits)
AND tl3() BE try(@l3, tl4, @rowlbits, @col3bits, @squ8bits)
AND tl4() BE try(@l4, tl5, @rowlbits, @col4bits, @squ9bits)
AND tl5() BE try(@l5, tl6, @rowlbits, @col5bits, @squ9bits)
AND tl6() BE try(@l6, tl7, @rowlbits, @col6bits, @squ9bits)
AND tl7() BE try(@l7, tl8, @rowlbits, @col7bits, @squ9bits)
AND tl8() BE try(@l8, tl9, @rowlbits, @col8bits, @squabits)
AND tl9() BE try(@l9, tla, @rowlbits, @col9bits, @squabits)
AND tla() BE try(@la, tlb, @rowlbits, @colabits, @squabits)
AND tlb() BE try(@lb, tlc, @rowlbits, @colbbits, @squabits)
AND tlc() BE try(@lc, tld, @rowlbits, @colcbits, @squbbits)
AND tld() BE try(@ld, tle, @rowlbits, @coldbits, @squbbits)
AND tle() BE try(@le, tlf, @rowlbits, @colebits, @squbbits)
AND tlf() BE try(@lf, tm0, @rowlbits, @colfbits, @squbbits)

//????
AND tm0() BE try(@m0, tm1, @rowmbits, @col0bits, @squcbits)
AND tm1() BE try(@m1, tm2, @rowmbits, @col1bits, @squcbits)
AND tm2() BE try(@m2, tm3, @rowmbits, @col2bits, @squcbits)
AND tm3() BE try(@m3, tm4, @rowmbits, @col3bits, @squcbits)
AND tm4() BE try(@m4, tm5, @rowmbits, @col4bits, @squdbits)
AND tm5() BE try(@m5, tm6, @rowmbits, @col5bits, @squdbits)
AND tm6() BE try(@m6, tm7, @rowmbits, @col6bits, @squdbits)
AND tm7() BE try(@m7, tm8, @rowmbits, @col7bits, @squdbits)
AND tm8() BE try(@m8, tm9, @rowmbits, @col8bits, @squebits)
AND tm9() BE try(@m9, tma, @rowmbits, @col9bits, @squebits)
AND tma() BE try(@ma, tmb, @rowmbits, @colabits, @squebits)
AND tmb() BE try(@mb, tmc, @rowmbits, @colbbits, @squebits)
AND tmc() BE try(@mc, tmd, @rowmbits, @colcbits, @squfbits)
AND tmd() BE try(@md, tme, @rowmbits, @coldbits, @squfbits)
AND tme() BE try(@me, tmf, @rowmbits, @colebits, @squfbits)
AND tmf() BE try(@mf, tn0, @rowmbits, @colfbits, @squfbits)

AND tn0() BE try(@n0, tn1, @rownbits, @col0bits, @squcbits)
AND tn1() BE try(@n1, tn2, @rownbits, @col1bits, @squcbits)
AND tn2() BE try(@n2, tn3, @rownbits, @col2bits, @squcbits)
AND tn3() BE try(@n3, tn4, @rownbits, @col3bits, @squcbits)
AND tn4() BE try(@n4, tn5, @rownbits, @col4bits, @squdbits)
AND tn5() BE try(@n5, tn6, @rownbits, @col5bits, @squdbits)
AND tn6() BE try(@n6, tn7, @rownbits, @col6bits, @squdbits)
AND tn7() BE try(@n7, tn8, @rownbits, @col7bits, @squdbits)
AND tn8() BE try(@n8, tn9, @rownbits, @col8bits, @squebits)
AND tn9() BE try(@n9, tna, @rownbits, @col9bits, @squebits)
AND tna() BE try(@na, tnb, @rownbits, @colabits, @squebits)
AND tnb() BE try(@nb, tnc, @rownbits, @colbbits, @squebits)
AND tnc() BE try(@nc, tnd, @rownbits, @colcbits, @squfbits)
AND tnd() BE try(@nd, tne, @rownbits, @coldbits, @squfbits)
AND tne() BE try(@ne, tnf, @rownbits, @colebits, @squfbits)
AND tnf() BE try(@nf, to0, @rownbits, @colfbits, @squfbits)

AND to0() BE try(@o0, to1, @rowobits, @col0bits, @squcbits)
AND to1() BE try(@o1, to2, @rowobits, @col1bits, @squcbits)
AND to2() BE try(@o2, to3, @rowobits, @col2bits, @squcbits)
AND to3() BE try(@o3, to4, @rowobits, @col3bits, @squcbits)
AND to4() BE try(@o4, to5, @rowobits, @col4bits, @squdbits)
AND to5() BE try(@o5, to6, @rowobits, @col5bits, @squdbits)
AND to6() BE try(@o6, to7, @rowobits, @col6bits, @squdbits)
AND to7() BE try(@o7, to8, @rowobits, @col7bits, @squdbits)
AND to8() BE try(@o8, to9, @rowobits, @col8bits, @squebits)
AND to9() BE try(@o9, toa, @rowobits, @col9bits, @squebits)
AND toa() BE try(@oa, tob, @rowobits, @colabits, @squebits)
AND tob() BE try(@ob, toc, @rowobits, @colbbits, @squebits)
AND toc() BE try(@oc, tod, @rowobits, @colcbits, @squfbits)
AND tod() BE try(@od, toe, @rowobits, @coldbits, @squfbits)
AND toe() BE try(@oe, tof, @rowobits, @colebits, @squfbits)
AND tof() BE try(@of, tp0, @rowobits, @colfbits, @squfbits)

AND tp0() BE try(@p0, tp1, @rowpbits, @col0bits, @squcbits)
AND tp1() BE try(@p1, tp2, @rowpbits, @col1bits, @squcbits)
AND tp2() BE try(@p2, tp3, @rowpbits, @col2bits, @squcbits)
AND tp3() BE try(@p3, tp4, @rowpbits, @col3bits, @squcbits)
AND tp4() BE try(@p4, tp5, @rowpbits, @col4bits, @squdbits)
AND tp5() BE try(@p5, tp6, @rowpbits, @col5bits, @squdbits)
AND tp6() BE try(@p6, tp7, @rowpbits, @col6bits, @squdbits)
AND tp7() BE try(@p7, tp8, @rowpbits, @col7bits, @squdbits)
AND tp8() BE try(@p8, tp9, @rowpbits, @col8bits, @squebits)
AND tp9() BE try(@p9, tpa, @rowpbits, @col9bits, @squebits)
AND tpa() BE try(@pa, tpb, @rowpbits, @colabits, @squebits)
AND tpb() BE try(@pb, tpc, @rowpbits, @colbbits, @squebits)
AND tpc() BE try(@pc, tpd, @rowpbits, @colcbits, @squfbits)
AND tpd() BE try(@pd, tpe, @rowpbits, @coldbits, @squfbits)
AND tpe() BE try(@pe, tpf, @rowpbits, @colebits, @squfbits)
AND tpf() BE try(@pf, suc, @rowpbits, @colfbits, @squfbits)

AND suc() BE
{ count := count + 1
  prboard()
}
