GET "libhdr"

MANIFEST $( Emp=0; Out=1; Peg=2 $)

STATIC $( board=?; moves=?; dir=? $)

LET solve(m) = VALOF
$( IF m=31 RESULTIS board!(9*4+4)=Peg
   FOR i = 9 TO 7*9 BY 9 DO
   FOR p = i+1 TO i+7 IF board!p=Peg DO
   FOR k = 0 TO 3 DO
   $( LET d = dir!k
      LET p1 = d+p
      LET p2 = d+p1
      IF board!p1=Peg & board!p2=Emp DO
      $( board!p, board!p1, board!p2 := Emp, Emp, Peg
         IF solve(m+1) DO
         $( moves!m := p<<8 | p2
            print_board(board)
            board!p, board!p1, board!p2 := Peg, Peg, Emp
            RESULTIS TRUE
         $)
         board!p, board!p1, board!p2 := Peg, Peg, Emp
      $)
   $)
   RESULTIS FALSE
$)

AND print_peg(x) BE writes(x=Out -> "  ",
                           x=Emp -> " 0",
                           x=Peg -> " **",
                                    " ?")

AND print_board(board) BE {
    wrch(30)           // Home char on Beeb to provide animated display
    FOR i = 9 TO 8*9 BY 9 DO
    $( FOR p = i TO i+8 DO print_peg (board!p)
       newline()
    $)
}

AND start() = VALOF
$( LET v = VEC 31

   wrch( 12 ) // Clear BBC Text Area

   moves := v
   board := TABLE
      //  0    1    2    3    4    5    6    7    8
         Out, Out, Out, Out, Out, Out, Out, Out, Out, // 0
         Out, Out, Out, Peg, Peg, Peg, Out, Out, Out, // 1
         Out, Out, Out, Peg, Peg, Peg, Out, Out, Out, // 2
         Out, Peg, Peg, Peg, Peg, Peg, Peg, Peg, Out, // 3
         Out, Peg, Peg, Peg, Emp, Peg, Peg, Peg, Out, // 4
         Out, Peg, Peg, Peg, Peg, Peg, Peg, Peg, Out, // 5
         Out, Out, Out, Peg, Peg, Peg, Out, Out, Out, // 6
         Out, Out, Out, Peg, Peg, Peg, Out, Out, Out, // 7
         Out, Out, Out, Out, Out, Out, Out, Out, Out  // 8

   dir := TABLE 1, 9, -1, -9

   TEST solve(0) THEN print_board(board)
                 ELSE writef("Not found*n*c")
   RESULTIS 0
$)

/*
                  
       0 0 0      
       0 0 0      
   0 0 0 0 0 0 0  
   0 0 0 * 0 0 0  
   0 0 0 0 0 0 0  
       0 0 0      
       0 0 0      
                  
*/

