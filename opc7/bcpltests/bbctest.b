GET "libhdr"

GET "beeblib.b"

LET start()  BE {
  IF ~istubeplatform(1) DO {
    writes("Sorry - this program only works in the Acorn BBC Microcomputer Tube environment*n")
  }
}

