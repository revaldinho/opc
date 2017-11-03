/*
  This is a simulation of the 3 rotor German Enigma M3 Machine.
  Influenced by a C program written by Fauzan Mirza, and
  by the excellent document and Enigma Machine simulator
  written and implemented by Dirk Rijmenants. I strongly
  recommend you visit the following web sites:

  http://users.telenet.be/d.rijmenants
  www.rijmenants.blogspot.com

  Implemented in BCPL by Martin Richards (c) August 2013

  Small changes to run on OPC6 CPU, Revaldinho, 2017
  - use rdch instead of pollrdch for read char (mapped to
    osrdch in PiTubeDirect OPC6 implementation)
  - comment out rdargs section - this stdlib call not
    yet implemented for OPC6
  - remove calls to deplete() - not yet implemented on OPC6
  - change printed line endings to use *n*c pair for
    PiTubeDirect BBC Micro co-pro application
  - reformatting of help screen for mode0 on BBC screen
  - removal of some of the spacers in the rotor display
    again to fit the BBC screen

  Bug fix in BCPL
  - set len:=0 on each rotor setting change otherwise
    example input doesn't work - ie changing the setting
    after finding the key steps 1 place unintentionally
  

Usage:

Entered by the command: enigma-m3

Input:

?        Print this help info
#rst     Set the left, middle and right hand rotors to r, s and t
         where r, s and t are single digits in the range 1 to 5
         representing rotors I, II, ..., V.
!abc     Set the ring positions for the left, middle and right
         rotors where a, b and c are letters or numbers in the
         range 1 to 26 separated by spaces.
=abc     Set the start positions of the left, middle and right
         hand rotors.
/B       Select reflector B.
/C       Select reflector C.
+ab      Set swap pairs on the plug board, a, b are letters.
         Setting a letter to itself removes that plug connection.
|        Toggle rotor stepping.
~        Toggle signal tracing.
-        Remove the latest message character, if any.
.        Exit
'        Add a character from the built-in message.
letter   Add a message letter.
space and newline are ignored.


The following is an example encrypted message (used with permission):

U6Z DE C 1500 = 49 = EHZ TBS =

TVEXS QBLTW LDAHH YEOEF
PTWYB LENDP MKOXL DFAMU
DWIJD XRJZ=

This was sent on the 31 day of the month from C to U6Z at 1510 and
contains 49 letters.

The recipient had the secret daily key sheet containing the following
line for day 31:

31 I II V  06 22 14 PO ML IU KJ NH YT GB VF RE DC  EXS TGY IKJ LOP

This showed that the enigma machine must be set up with rotors I, II
and V in the left, middle and right positions, and be given ring
setting 6, 22 and 14, respectively. The plug board should be with set
the 10 specified connections.

The rotor start positions should be set to EHZ then the three letters
TBS typed.  This generates XWB which is the start positions of the
rotors for the body of the message. The first group TVEXS confirms we
have the right daily key since it contains EXS together with two
random letters. Decoding begins at the second group QBLTW. To decode
message using this program type the following:

#125
!6 22 14
+PO+ML+IU+KJ+NH+YT+GB+VF+RE+DC
=EHZ
TBS
=XWB
QBLTW LDAHH YEOEF PTWYB LENDP MKOXL DFAMU DWIJD XRJZ
 
This generates the following decrypted text (with spaces added).

DER FUEHRER IST TOD X DER KAMPF GEHTWETTER X DOENITZ X 

If you run enigma-m3 with the default settings and type Q, the output
indicates the signal path through the plug board, rotors and
reflector and is as follows:

 ----     ---------     ---------     ---------    -------    - 
|   M|   |J|E     E|   |I|N     N|   |O|B     B|  |M     M|  |M|
| *<L|<<<|I|D<*   D|   |H|M     M|   |N*A     A|  |L     L|  |L|
| v K|   |H|C ^   C|   |G|L     L|   |M|Z     Z|  |K     K|  |K|
| v J|   |G|B ^   B|   |F|K     K|   |L|Y     Y|  |J     J|  |J|
|-v--|   |-|--^----|   |-|-------|   |-|-------|  |-------|  |-|
| v I|   |F*A ^   A|  =|E|J     J|   |K|X     X|  |I     I|  |I|
| v H|   |E|Z ^   Z|   |D|I  *>>I|>>>|J|W>>*  W|  |H     H|  |H|
| *>G|>>>|D|Y>^>* Y|   |C|H  ^  H|   |I|V  v  V|  |G     G|  |G|
|   F|   |C|X ^ v X|   |B|G  ^  G|   |H|U  v  U|  |F     F|  |F|
|----|   |-|--^-v--|   |-|---^---|   |-|---v---|  |-------|  |-|
|   E|   |B|W ^ v W|   |A|F  ^  F|   |G|T  v  T|  |E     E|  |E|
|   D|   |A|V ^ v V|   |Z|E  ^  E|   |F|S  v  S|  |D  *>>D|>>|D|>>D
|   C|   |Z|U ^ v U|   |Y|D  ^  D|   |E|R  *>>R|>>|C>>*  C|  |C|
|   B|   |Y|T ^ v T|   |X|C  ^  C|   |D|Q     Q|  |B     B|  |B|
|----|   |-|--^-v--|   |-|---^---|   |-|-------|  |-------|  |-|
|   A|   [X]S ^ v S|   [W]B  ^  B|   [C]P     P|  |A     A|  |A|
|----|   |-|--^-v--|   |-|---^---|   |-|-------|  |-------|  |-|
|   Z|   |W|R ^ v R|   |V*A  ^  A|   |B|O     O|  |Z     Z|  |Z|
|   Y|   |V|Q ^ v Q|   |U|Z  ^  Z|   |A|N     N|  |Y     Y|  |Y|
|   X|   |U|P ^ v P|   |T|Y  ^  Y|  =|Z|M     M|  |X     X|  |X|
|   W|   |T|O ^ *>O|>>>|S|X>>*  X|   |Y|L     L|  |W     W|  |W|
|----|   |-|--^----|   |-|-------|   |-|-------|  |-------|  |-|
|   V|   |S|N ^   N|   |R|W     W|   |X|K     K|  |V     V|  |V|
|   U|   |R|M ^   M|   |Q|V     V|   |W|J     J|  |U     U|  |U|
|   T|  =|Q|L ^   L|   |P|U  *<<U|<<<|V|I<<*  I|  |T     T|  |T|
|   S|   |P|K ^   K|   |O|T  v  T|   |U|H  ^  H|  |S     S|  |S|
|----|   |-|--^----|   |-|---v---|   |-|---^---|  |-------|  |-|
|   R|   |O|J ^   J|   |N|S  v  S|   |T|G  ^  G|  |R     R|  |R|
|   Q|   |N|I ^   I|   |M|R  v  R|   |S|F  *<<F|<<|Q<<<<<Q|<<|Q|<<Q
|   P|   |M|H ^   H|   |L|Q  v  Q|   |R|E     E|  |P     P|  |P|
|   O|   |L|G *<<<G|<<<|K|P<<*  P|   |Q|D     D|  |O     O|  |O|
|   N|   |K|F     F|   |J|O     O|   |P|C     C|  |N     N|  |N|
 ----     ---------     ---------     ---------    -------    - 
refl B     rotor I       rotor II      rotor V      plugs    kbd
*/

GET "libhdr"

GLOBAL
{ spacev:ug; spacep; spacet

  instring  // String of input characters in bytes
  inchar    // String of input characters
  outchar   // String of output characters
  len       // Number of characters in the input string
  ch        // Current keyboard character

  stepping  // =FALSE to stop the rotors from stepping
  tracing   // =TRUE causes signal tracing output

  rotorI;   notchI
  rotorII;  notchII
  rotorIII; notchIII
  rotorIV;  notchIV
  rotorV;   notchV
  reflectorB
  reflectorC

  rotorLname; rotorMname; rotorRname
  reflectorname

  // Ring and notch settings of the selected rotors
  ringL;  ringM;  ringR
  notchL; notchM; notchR

  // Rotor start positions at the beginning of the message
  initposL; initposM; initposR
  // Rotor current positions
  posL; posM; posR; 

  // The following vectors have subscripts from 0 to 25
  // representing letters A to Z
  plugboard 
  rotorFR; rotorFM; rotorFL
  reflector
  rotorBL; rotorBM; rotorBR // Inverse rotors

  // Variables for printing signal path
  pluginF
  rotorRinF; rotorMinF; rotorLinF
  reflin
  rotorLinB; rotorMinB; rotorRinB
  pluginB; plugoutB

  // Global functions
  newvec; setvec
  rch; rdlet
  rdrotor; rdringsetting
  setplugpair; prplugboardspairs; setrotor
  step_rotors; rotorfn; encodestr; enigmafn
  prsigwiring; prsigreflector; prsigrotor; prsigplug; prsigkbd
  prsigline; prsigpath
}

LET newvec(upb) = VALOF
{ LET p = spacep - upb -1
  IF p<spacev DO
  { writef("More space needed*n*c")
    RESULTIS 0
  }
  spacep := p
  RESULTIS p
}

LET setvec(str, v) BE
  IF v FOR i = 0 TO 25 DO v!i := str%(i+1) - 'A'

LET setrotor(str, rf, rb) BE
  IF rf & rb FOR i = 0 TO 25 DO
  { rf!i := str%(i+1)-'A'; rb!(rf!i) := i }

LET start() = VALOF
{ LET argv = VEC 50

writef("*n*cEnigma M3 simulator*n*c")
writef("Type ? for help*n*c*n*c")

  tracing := TRUE
  IF argv!0 DO tracing := ~tracing             // -t/s

  spacev := getvec(1000)
  spacet := spacev+1000
  spacep := spacet

// Set the rotor and reflector wirings
// and the notch positions. 

// Input      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  rotorI   := "EKMFLGDQVZNTOWYHXUSPAIBRCJ";  notchI   := 'Q'
  rotorII  := "AJDKSIRUXBLHWTMCQGZNPYFVOE";  notchII  := 'E'
  rotorIII := "BDFHJLCPRTXVZNYEIWGAKMUSQO";  notchIII := 'V'
  rotorIV  := "ESOVPZJAYQUIRHXLNFTGKDCMWB";  notchIV  := 'J'
  rotorV   := "VZBRGITYUPSDNHLXAWMJQOFECK";  notchV   := 'Z'

  reflectorB := "YRUHQSLDPXNGOKMIEBFZCWVJAT"
  reflectorC := "FVPJIAOYEDRZXWGCTKUQSBNMHL"

// Allocate several vectors
  rotorFL   := newvec(25)
  rotorFM   := newvec(25)
  rotorFR   := newvec(25)
  rotorBL   := newvec(25)
  rotorBM   := newvec(25)
  rotorBR   := newvec(25)
  plugboard := newvec(25)
  reflector := newvec(25)
  inchar    := newvec(255)
  outchar   := newvec(255)

  UNLESS rotorFL & rotorFM & rotorFR &
         rotorBL & rotorBM & rotorBR &
         plugboard & reflector &
         inchar & outchar DO
  { writef("*n*cMore memory needed*n*c")
    GOTO fin
  }

// Set default encryption parameters, suitable for the
// example message.

  setvec(reflectorB, reflector)
  reflectorname := "B"
  setrotor(rotorI,  rotorFL, rotorBL)
  rotorLname, notchL := "I  ", notchI  - 'A'
  setrotor(rotorII, rotorFM, rotorBM)
  rotorMname, notchM := "II ", notchII - 'A'
  setrotor(rotorV,  rotorFR, rotorBR)
  rotorRname, notchR := "V  ", notchV  - 'A'
 
  ringL := 06-1; ringM := 22-1; ringR := 14-1

  initposL := 'X'-'A'; posL := initposL
  initposM := 'W'-'A'; posM := initposM
  initposR := 'B'-'A'; posR := initposR

  FOR i = 0 TO 25 DO plugboard!i := i

// Perform +PO+ML+IU+KJ+NH+YT+GB+VF+RE+DC
// to set the plug board.

  setplugpair('P', 'O')
  setplugpair('M', 'L')
  setplugpair('I', 'U')
  setplugpair('K', 'J')
  setplugpair('N', 'H')
  setplugpair('Y', 'T')
  setplugpair('G', 'B')
  setplugpair('V', 'F')
  setplugpair('R', 'E')
  setplugpair('D', 'C')

//writef("Set the the example message string*n*c")

  instring := "QBLTWLDAHHYEOEFPTWYBLENDPMKOXLDFAMUDWIJDXRJZ"
  len := instring%0
  FOR i = 1 TO len DO inchar!i := instring%i

  len := 0
  stepping := TRUE
  ch := '*n'

  encodestr()

  { // Start of main input loop
    IF ch='*n' DO { writef("*n*c> "); ch := 0 }
    IF ch='*c' DO ch:=0    
    UNLESS ch DO rch()

    SWITCHON ch INTO
    { DEFAULT:
      CASE '*s': ch := 0   // Cause another character to be read.
      CASE '*n': LOOP

      CASE endstreamch:
      CASE '.':  BREAK

      CASE '?':
         newline()
         writes("?        Output this help info*n*c")
         writes("#rst     Set the left, middle and right hand rotors to r, s and t where*n*c") 
         writes("         r, s and t are single digits in the range 1 to 5 representing*n*c")
         writes("         rotors I, II, ..., V.*n*c")
         writes("!abc     Set the ring positions for the left, middle and right rotors where*n*c")
         writes("         a, b and c are letters or numbers in the range 1 to 26 separated*n*c")
         writes("         by spaces.*n*c")
         writes("=abc     Set the initial positions of the left, middle and right hand rotors*n*c")
         writes("/B       Select reflector B*n*c")
         writes("/C       Select reflector C*n*c")
         writes("+ab      Set swap pairs on the plug board, a, b are letters.*n*c")
         writes("         Setting a letter to itself removes that plug*n*c")
         writes("|        Toggle rotor stepping*n*c")
         writes(",        Print the current settings*n*c")
         writes("'        Add a character from the built-in message.*n*c")
         writes("letter   Add a message letter*n*c")
         writes("-        Remove the latest message character, if any*n*c")
         writes(".        Exit*n*c")
         writes("space and newline are ignored*n*c")
         ch := '*n'
         LOOP

      CASE '#': // Select the rotors, eg #125
              { LET str, name, notch = 0, 0, 0
                ch := 0
                rdrotor(@str)
                setrotor(str, rotorFL, rotorBL)
                rotorLname, notchL := name, notch-'A'
                rdrotor(@str)
                setrotor(str, rotorFM, rotorBM)
                rotorMname, notchM := name, notch-'A'
                rdrotor(@str)
                setrotor(str, rotorFR, rotorBR)
                rotorRname, notchR := name, notch-'A'
                writef("*n*cRotors: %s %s %s  notches %c%c%c*n*c",
                        rotorLname, rotorMname, rotorRname,
                        notchL+'A', notchM+'A', notchR+'A')
                encodestr()
                len := 0                
                ch := '*n'
                LOOP                
              }

      CASE '!': // Set ring positions
                ch := 0
                ringL := rdringsetting()
                ringM := rdringsetting()
                ringR := rdringsetting()
                writef("*n*cRing settings: %c%c%c*n*c",
                        ringL+'A', ringM+'A', ringR+'A')
                encodestr()
                len := 0                
                ch := '*n'
                LOOP                


      CASE '=': // Set the rotor positions
                ch := 0
                initposL := rdlet() - 'A'
                initposM := rdlet() - 'A'
                initposR := rdlet() - 'A'
                writef("*n*cRotor positions: %c%c%c*n*c", initposL+'A', initposM+'A', initposR+'A')
                len := 0
                encodestr()
                ch := '*n'
                LOOP
                
      CASE '/': // Set reflector B or C
                { rch()
                  IF ch = 'B' DO
                  { setvec(reflectorB, reflector)
                    reflectorname := "B"
                    BREAK
                  }
                  IF ch = 'C' DO
                  { setvec(reflectorC, reflector)
                    reflectorname := "C"
                  BREAK
                  }
                  writef("*n*cB or C required*n*c")
                } REPEAT

                writef("*n*cReflector %s selected*n*c", reflectorname)
                len := 0
                encodestr()
                ch := '*n'
                LOOP
 
      CASE '+': // Set a plug board pair
                { LET a, b = ?, ?
                  rch()
                  a := ch
                  rch()
                  b := ch
                  IF 'A'<=a<='Z' & 'A'<=b<='Z' DO
                  { setplugpair(a, b)
                    BREAK
                  }
                  writef("*n*c+ should be followed by two letters, eg +AB*n*c")
                } REPEAT
                len := 0
                encodestr()
                ch := '*n'
                LOOP

      CASE '|': // Toggle rotor stepping
                stepping := ~stepping
                TEST stepping
                THEN writef("*n*cRotor stepping enabled*n*c")
                ELSE writef("*n*cRotor stepping disabled*n*c")
                ch := '*n'
                LOOP

      CASE ',': // Output the settings
                newline()
                writef("Rotors:            %s %s %s*n*c",
                        rotorLname, rotorMname, rotorRname)
                writef("Notches:           %c %c %c*n*c",
                        notchL+'A', notchM+'A', notchR+'A')
                writef("Ring setting:      %c-%z2 %c-%z2 %c-%z2*n*c",
                        ringL+'A', ringL+1,
                        ringM+'A', ringM+1,
                        ringR+'A', ringR+1)
                writef("Initial positions: %c %c %c*n*c",
                       initposL+'A', initposM+'A', initposR+'A')
                writef("Current positions: %c %c %c*n*c",
                       posL+'A', posM+'A', posR+'A')
                writef("Plug board:        ")
                prplugboardpairs()
                newline()

                writef("in: %n ", len); FOR i = 1 TO len DO wrch(inchar!i)
                newline()
                writef("out:%n ", len); FOR i = 1 TO len DO wrch(outchar!i)
                newline()
                ch := '*n'
                LOOP

      CASE '-': // Remove one message character
                IF len>0 DO len := len-1
                encodestr()
                ch := '*n'
                LOOP

      CASE '~': // Toggle signal tracing
                tracing := ~tracing
                TEST tracing
                THEN writef("*n*cSignal tracing now on*n*c")
                ELSE writef("*n*cSignal tracing turned off*n*c")
                ch := '*n'
                LOOP
      CASE '*'':// Add a character from the built-in *
                IF len<255 DO len := len + 1
                IF len>instring%0 DO len := instring%0
                inchar!len := instring%len
                encodestr()
                ch := '*n'
                LOOP


      CASE 'A':CASE 'B':CASE 'C':CASE 'D':CASE 'E':
      CASE 'F':CASE 'G':CASE 'H':CASE 'I':CASE 'J':
      CASE 'K':CASE 'L':CASE 'M':CASE 'N':CASE 'O':
      CASE 'P':CASE 'Q':CASE 'R':CASE 'S':CASE 'T':
      CASE 'U':CASE 'V':CASE 'W':CASE 'X':CASE 'Y':
      CASE 'Z':
                IF len<255 DO len := len + 1
                inchar!len := ch
                encodestr()
                ch := '*n'
                LOOP

    }
  } REPEAT

  newline()

fin:
  IF spacev DO freevec(spacev)

  RESULTIS 0
}

AND setplugpair(a, b) BE
{ // a and b are capital letters
  LET c = ?
  a := a - 'A'
  b := b - 'A'
  c := plugboard!a
  UNLESS plugboard!a = a DO
  { // Remove previous pairing for a
    plugboard!a := a
    plugboard!c := c
  }
  c := plugboard!b
  UNLESS plugboard!b = b DO
  { // Remove previous pairing for b
    plugboard!b := b
    plugboard!c := c
  }
  UNLESS a=b DO
  { // Set swap pair (a, b).
    plugboard!a := b
    plugboard!b := a
  }
}

AND rdlet() = VALOF
{ IF ch=0 DO rch()
  WHILE ch='*s' DO rch()
  IF 'A'<=ch<='Z' DO
  { LET res = ch
    ch := 0
    RESULTIS res
  }
  writef("*n*cA letter is required*n*c")
  ch := 0
} REPEAT

AND rch() BE
{ // Read a keyboard key as soon as it is pressed.
  ch := capitalch(rdch())
  wrch(ch)
}

AND rdrotor(v) BE
{ // Returns the rotor wiring string
  // result2 is the rotor name: I, II, III, IV or V
  IF ch=0 DO rch()
  WHILE ch='*s' DO rch()

  IF '0'<=ch<='5' DO
  { IF ch='1' DO v!0, v!1, v!2 := rotorI,   "I  ", notchI
    IF ch='2' DO v!0, v!1, v!2 := rotorII,  "II ", notchII
    IF ch='3' DO v!0, v!1, v!2 := rotorIII, "III", notchIII
    IF ch='4' DO v!0, v!1, v!2 := rotorIV,  "IV ", notchIV
    IF ch='5' DO v!0, v!1, v!2 := rotorV,   "V  ", notchV
    ch := 0
    RETURN
  }
  writef("*n*cRotor number not in range 1 to 5*n*c")
  ch := 0
} REPEAT

AND rdringsetting() = VALOF
{ // Return 0 to 25 representing ring setting A to Z
  IF ch=0 DO rch()

  WHILE ch='*s' DO rch()

  IF 'A'<=ch<='Z' DO
  { LET res = ch-'A'
    ch := 0
    RESULTIS res
  }

  IF '0'<= ch <= '9' DO
  { LET n = ch-'0'
    rch()
    IF '0'<= ch <= '9' DO n := 10*n + ch - '0'
    // n = 1 to 26 represent ring settings of A to Z
    // encoded as 0 to 25
    ch := 0
    IF 1<=n<=26 RESULTIS n - 1
    writef("*n*cA letter or a number in range 1 to 26 required*n*c")
  }
} REPEAT

AND prplugboardpairs() BE FOR a = 0 TO 25 DO
{ // Print plug board pairs in alphabetical order
  LET b = plugboard!a
  IF a < b DO writef("%c%c ", a+'A', b+'A')
}

AND step_rotors() BE IF stepping DO
{ LET advM = posR=notchR | posM=notchM
  LET advL = posM=notchM

  posR := (posR+1) MOD 26            // Step the right hand rotor
  IF advM DO posM := (posM+1) MOD 26 // Step the middle rotor
  IF advL DO posL := (posL+1) MOD 26 // Step the left rotor
}

AND encodestr() BE
{ // Set initial state
  posL, posM, posR := initposL, initposM, initposR
  // The rotor numbers and ring settings are already set up.
  IF len=0 RETURN

  FOR i = 1 TO len DO
  { LET x = inchar!i - 'A'         // letter to encode
    IF stepping DO step_rotors()
    outchar!i := enigmafn(x) + 'A'
  }
  TEST tracing
  THEN prsigpath()
  ELSE writef(" %c", plugoutB+'A')
}

AND enigmafn(x) = VALOF
{ // Plug board
  pluginF := x
  rotorRinF := plugboard!pluginF
  // Rotors right to left
  rotorMinF := rotorfn(rotorRinF, rotorFR, posR, ringR)
  rotorLinF := rotorfn(rotorMinF, rotorFM, posM, ringM)
  reflin    := rotorfn(rotorLinF, rotorFL, posL, ringL)
  // Reflector
  rotorLinB := reflector!reflin
  // Rotors left to right
  rotorMinB := rotorfn(rotorLinB, rotorBL, posL, ringL)
  rotorRinB := rotorfn(rotorMinB, rotorBM, posM, ringM)
  pluginB   := rotorfn(rotorRinB, rotorBR, posR, ringR)
  // Plugboard
  plugoutB := plugboard!pluginB

  RESULTIS plugoutB
}

AND rotorfn(x, map, pos, ring) = VALOF
{ LET a = (x+pos-ring+26) MOD 26
  LET b = map!a
  LET c = (b-pos+ring+26) MOD 26
  RESULTIS c
}

// The following functions are used to output an
// ASCII graphics representation of the signal path
// through the machine when decoding the latest letter.
// All the arguments are in the range 0 to 25
// representing A to Z except n which may be 26.

AND prsigpath() BE
{ wrch(30) // print 'home' character on Beeb
  //newline()
  prsigline(26, TRUE)
  prsigline(25, FALSE)
  prsigline(24, FALSE)
  prsigline(23, FALSE)
  prsigline(22, FALSE)
  //prsigline(22, TRUE)
  prsigline(21, FALSE)
  prsigline(20, FALSE)
  prsigline(19, FALSE)
  prsigline(18, FALSE)
  //prsigline(18, TRUE)
  prsigline(17, FALSE)
  prsigline(16, FALSE)
  prsigline(15, FALSE)
  prsigline(14, FALSE)
  prsigline(14, TRUE)
  prsigline(13, FALSE)
  prsigline(13, TRUE)
  prsigline(12, FALSE)
  prsigline(11, FALSE)
  prsigline(10, FALSE)
  prsigline( 9, FALSE)
  //prsigline( 9, TRUE)
  prsigline( 8, FALSE)
  prsigline( 7, FALSE)
  prsigline( 6, FALSE)
  prsigline( 5, FALSE)
  //prsigline( 5, TRUE)
  prsigline( 4, FALSE)
  prsigline( 3, FALSE)
  prsigline( 2, FALSE)
  prsigline( 1, FALSE)
  prsigline( 0, FALSE)
  prsigline( 0, TRUE)
  writef("refl %s  ",  reflectorname)
  writef("   rotor %s  ", rotorLname)
  writef("   rotor %s  ", rotorMname)
  writef("   rotor %s  ", rotorRname)
  writef("   plugs  ")
  writef("   kbd")
  //newline()
  // Skip the summary on each screen - easy to get with the ',' key
  //writef("in: %n ", len); FOR i = 1 TO len DO wrch(inchar!i)
  //newline()
  //writef("out:%n ", len); FOR i = 1 TO len DO wrch(outchar!i)
  // newline()
}

AND prsigline(n, sp) BE
{ prsigreflector(n, sp, reflin, rotorLinB)
  prsigrotor(n, sp, posL, ringL, notchL,
             rotorLinF, reflin, rotorLinB, rotorMinB)
  prsigrotor(n, sp, posM, ringM, notchM,
             rotorMinF, rotorLinF, rotorMinB, rotorRinB)
  prsigrotor(n, sp, posR, ringR, notchR,
             rotorRinF, rotorMinF, rotorRinB, pluginB)
  prsigplug(n, sp, pluginF, rotorRinF, pluginB, plugoutB)
  prsigkbd(n, sp, pluginF, plugoutB)
  newline()
}

AND prsigreflector(n, sp, inF, outB) BE
{ LET iF = (inF  +13) MOD 26
  LET oB = (outB +13) MOD 26
  LET letter = (n+13) MOD 26 + 'A'
  LET c0, c1, c2, c3 = '|', ' ', ' ', ' '
  LET c4, c5, c6 = letter, '|', ' '

  TEST sp
  THEN { c1,c2,c3,c4 := '-', '-','-','-'
         IF iF<n<=oB DO c2 := '^'
         IF iF>=n>oB DO c2 := 'v'
         IF n=0 | n=26 DO c0,c5 := ' ',' '
       }
  ELSE { IF iF=n | oB=n DO c2 := '**'
         IF iF<n<oB DO c2 := '^'
         IF iF>n>oB DO c2 := 'v'
         IF iF=n DO c3,c6 := '<','<'
         IF oB=n DO c3,c6 := '>','>'
       }
  writef("%c%c%c%c%c%c%c%c", c0,c1,c2,c3,c4,c5,c6,c6)
}

AND prsigrotor(n, sp, pos, ring, notch,
               inF, outF, inB, outB) BE
{ LET iF   = (inF+13)           MOD 26
  LET iB   = (inB+13)           MOD 26
  LET oF   = (outF+13)          MOD 26
  LET oB   = (outB+13)          MOD 26
  LET nch  = (notch-pos+13+26)  MOD 26
  LET rng  = (ring-pos+13+26)   MOD 26
  LET let1 = (n+pos+13+26)      MOD 26 + 'A'
  LET let2 = (n+pos-ring+13+26) MOD 26 + 'A'
  LET c0,c1,c2,c3,c4,c5 = ' ','|',let1,'|',let2,' '
  LET c6,c7,c8,c9 = ' ',let2,'|',' '

  TEST sp
  THEN { c2,c3,c4,c5,c6,c7 := '-','|','-','-','-','-'
         IF n=0 | n=26 DO c1,c3,c8 := ' ','-',' '
       }
  ELSE { IF n=iF  DO c6,c9 := '<','<'
         IF n=oB  DO c6,c9 := '>','>'
         IF n=oF  DO c0,c5 := '<','<'
         IF n=iB  DO c0,c5 := '>','>'
         IF n=nch DO c0 := '='
         IF n=rng DO c3 := '**'
         IF n=13  DO c1,c3 := '[',']'
       }
  writef("%c%c%c%c%c%c", c0,c1,c2,c3,c4,c5)
  prsigwiring(n, sp, iF, oF, iB, oB)
  writef("%c%c%c%c%c", c6,c7,c8,c9,c9)
}

AND prsigplug(n, sp, inF, outF, inB, outB) BE
{ LET iF = (inF +13) MOD 26
  LET oF = (outF+13) MOD 26
  LET iB = (inB +13) MOD 26
  LET oB = (outB+13) MOD 26

  LET letter = (n+13) MOD 26 +'A'
  LET c0,c1,c2,c3 = ' ','|', letter, ' '
  LET c4,c5,c6,c7 = ' ', letter, '|', ' '

  TEST sp
  THEN { c2,c3,c4,c5 := '-','-','-','-'
         IF n=0 | n=26 DO c1,c6,c7 := ' ',' ',' '
       }
  ELSE { IF n=iF DO c4,c7 := '<','<'
         IF n=oF DO c0,c3 := '<','<'
         IF n=iB DO c0,c3 := '>','>'
         IF n=oB DO c4,c7 := '>','>'
       }
  writef("%c%c%c%c", c0,c1,c2,c3)
  prsigwiring(n, sp, iF,oF,iB,oB)
  writef("%c%c%c%c%c%c", c4,c5,c6,c7,c7,c7)
}

AND prsigkbd(n, sp, inF, outB) BE
{ LET iF = (inF +13) MOD 26
  LET oB = (outB+13) MOD 26

  LET letter = (n+13) MOD 26 + 'A'
  LET c0,c1,c2 = '|',letter,'|'

  IF sp DO
  { c1 := '-'
    IF n=0 | n=26 DO c0,c2 := ' ',' '
  }

  writef("%c%c%c", c0,c1,c2)
  UNLESS sp THEN {
     TEST n=iF THEN { writef("<<%c", letter); RETURN }
     ELSE TEST n=oB THEN { writef(">>%c", letter); RETURN }
          ELSE { writef("   ") ; RETURN }
  }
}

AND prsigwiring(n, sp, iF, oF, iB, oB) BE
{ // iF, oF, iB and oB are in the range 0 to 25 representing
  // line numbers within the wiring diagram of the forward and
  // backward input and output signals.

  LET Flo,Fhi,Blo,Bhi = iF,oF,iB,oB
  LET aF, aB = '^','^'
  LET c1,c2,c3=' ',' ',' '

  IF iF>oF DO Flo,Fhi,aF := oF,iF,'v'
  IF iB>oB DO Blo,Bhi,aB := oB,iB,'v'
  // aF and aB = ^ or v giving the vertical direction
  //             for the forward and backward paths.
  // n = the machine line number in range 0 to 26
  //     by convention n=13 for position A
  // sp = TRUE for space lines
  // c1, c2 and c3 are for the three wiring characters
  //               for this line.

  IF sp DO
  { // Find every spacer line containing no wires.
    IF n>Fhi & n>Bhi   |
       n<=Flo & n<=Blo |
       Bhi<n<=Flo      |
       Fhi<n<=Blo      DO
    { writef("---") // Draw a spacer line with no wires.
      RETURN
    }
    c1,c2,c3 := '-','-','-'
  }

  // Find all non space lines containing no wires.
  IF n>Fhi & n>Bhi |
     n<Flo & n<Blo |
     Bhi<n<Flo     |
     Fhi<n<Blo     DO
  { // Non spacer line at position n contains no wires.
    writef("   ")
    RETURN
  }

  // Position n contains at least one wire.

  IF Flo>Bhi |
     Blo>Fhi DO
  { // There is only one wire at this region so
    // the middle column can be used.
    UNLESS sp DO
    { IF iF=n=oF DO { writef("<<<"); RETURN }
      IF iB=n=oB DO { writef(">>>"); RETURN }
      // Position n has an up or down going wire.
      IF n=iF DO { writef(" **<"); RETURN }
      IF n=oF DO { writef("<** "); RETURN }
      IF n=iB DO { writef(">** "); RETURN }
      IF n=oB DO { writef(" **>"); RETURN }
    }
    IF Flo<n<=Fhi DO c2 := aF
    IF Blo<n<=Bhi DO c2 := aB

    writef("%c%c%c", c1, c2,c3)
    RETURN
  }

  IF iB<oF<iF & oB<iF |
     iF<oB & iF<oF<iB DO
  { // With the F wire on the left, the wires can be
    // drawn without crossing.
    TEST sp
    THEN { // This is a spacer line
           // so only contains vertical wires
           IF Flo<n<=Fhi DO c1 := aF
           IF Blo<n<=Bhi DO c3 := aB
         }
    ELSE { // This is a non spacer line
           IF n=iF DO c1,c2,c3 := '**','<','<'
           IF n=oF DO c1 := '**'
           IF n=iB DO c1,c2,c3 := '>','>','**'
           IF n=oB DO c3 := '**'
           IF Flo<n<Fhi DO c1 := aF
           IF Blo<n<Bhi DO c3 := aB
         }
    writef("%c%c%c", c1,c2,c3)
    RETURN
  }

  IF oB<iF<oF & iB<oF |
     oF<iB & oF<iF<oB DO
  { // With the F wire on the right, the wires can be
    // drawn without crossing.
    TEST sp
    THEN { // This is a spacer line
           // so only contains vertical wires
           IF Flo<n<=Fhi DO c3 := aF
           IF Blo<n<=Bhi DO c1 := aB
            }
    ELSE { // This is a non spacer line
           IF n=oF DO c1,c2,c3 := '<','<','**'
           IF n=iF DO c3 := '**'
           IF n=oB DO c1,c2,c3 := '**','>','>'
           IF n=iB DO c1 := '**'
           IF Flo<n<Fhi DO c3 := aF
           IF Blo<n<Bhi DO c1 := aB
         }
    writef("%c%c%c", c1,c2,c3)
    RETURN
  }

  // There are two wires that must cross.

  IF iF=oF DO
  { // The B wire can use the centre column.
    c2 := aB
    TEST sp
    THEN { IF n=Blo DO c2 := '-'
         }
    ELSE { IF n=iF DO c1,c3 := '<','<'
           IF n=iB DO c1,c2 := '>','**'
           IF n=oB DO c2,c3 := '**','>'
         }
    writef("%c%c%c", c1,c2,c3)
    RETURN
  }

  IF iB=oB DO
  { // The F wire can use the centre column.
    c2 := aF
    TEST sp
    THEN { IF n=Flo DO c2 := '-'
         }
    ELSE { IF n=iB DO c1,c3 := '>','>'
           IF n=oF DO c1,c2 := '<','**'
           IF n=iF DO c2,c3 := '**','<'
         }
    writef("%c%c%c", c1,c2,c3)
    RETURN
  }

  // Test whether the F and B signals enter at the
  // same level, and leave at the same level.
  // Note that iF cannot equal oB,
  //      and  iB cannot equal oF.
  IF iF=iB &
     oF=oB TEST Fhi-Flo<=2
  THEN { // No room for a cross over
         TEST sp
         THEN { IF n>iF | n>oF DO c2 := '|'
              }
         ELSE { IF Flo<n<Fhi DO c2 := '|'
                IF n=iF DO c1,c2,c3 := '>','**','<'
                IF n=oF DO c1,c2,c3 := '<','**','>'
              }
         writef("%c%c%c", c1,c2,c3)
         RETURN
       }
  ELSE { // The gap between iF and oF is more than 1 line
         // so the F wire can use the centre column and
         // the B wire can cross it half way down.
         LET m = (iF+oF)/2
         // Place the F wire down the centre.
         c2 := aF
         IF n=iF DO c2,c3 := '**','<'
         IF n=oF DO c1,c2 := '<','**'
         // Now place the B wire, crossing half way down.
         TEST iB>oB
         THEN { IF n>=m DO c1 := aB
                IF n<=m DO c3 := aB
              }
         ELSE { IF n>=m DO c3 := aB
                IF n<=m DO c1 := aB
              }
         UNLESS sp DO
         { IF n=iB DO c1 := '**'
           IF n=oB DO c3 := '**'
           IF n=m DO c1,c2,c3 := '**','>','**'
         }
         writef("%c%c%c", c1,c2,c3)
         RETURN
       }

  IF Flo<iB<Fhi |
     Blo<iF<Bhi DO
  { // The F wire can be on the left.
    IF Flo<n<=Fhi DO c1 := aF
    IF Blo<n<=Bhi DO c3 := aB

    UNLESS sp DO
    { IF n=iF DO c1,c2,c3 := '**','<','<'
      IF n=iB DO c1,c2,c3 := '>','>','**'
      IF n=oF DO c1 := '**'
      IF n=oB DO c3 := '**'
    }
    writef("%c%c%c", c1,c2,c3)
    RETURN
  }

  IF Flo<oB<Fhi |
     Blo<oF<Bhi DO
  { // The F wire can be on the right.
    IF Flo<n<=Fhi DO c3 := aF
    IF Blo<n<=Bhi DO c1 := aB

    UNLESS sp DO
    { IF n=iF DO c3 := '**'
      IF n=iB DO c1 := '**'
      IF n=oF DO c1,c2,c3 := '<','<','**'
      IF n=oB DO c1,c2 := '**','>'
    }
    writef("%c%c%c", c1,c2,c3)
    RETURN
  }

  // There should be no other possibilities
  writef("???")
}
