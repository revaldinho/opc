          ORG 0x10
RESPTR    BYTE 0
          ORG 0x20
RESLOC    BYTE 0

          ORG 0x100
          ldb.i RESLOC
          axb
          sta   RESPTR

          ldb.i 0xF0
          axb
          sta.p RESPTR
          ldb.p RESPTR
          axb
          ldb.i RESLOC+1
          axb
          sta   RESPTR
          ldb.i 0xF1
          axb
          sta.p RESPTR
          ldb.p RESPTR


          halt
