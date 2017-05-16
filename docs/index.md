OPC - One Page CPU
==================

Welcome to the OPC series of CPUs, where everything fits on one page!

Implementations:-

  1.  OPC-1 - a minimal accumulator based OPC to fit a XC9572 CPLD
      *   [OPC1 spec](/opc/opc1spec.html)
      *   [OPC1 source code](https://github.com/revaldinho/opc/tree/master/opc1)
      *   [OPC1 in-browser Emulator](/opc/opc1jsemu.html?d=88eda800f800)
          *    [...running the test program test.s](/opc/opc1jsemu.html?d=8800c0021002c003888080ff88f09801d114d90e8033d91a9801e11ef800c000f000c0018801f00088ff9800c930d92a0801f0000800e800)
          *    [...running a fibonacci program fib.s](/opc/opc1jsemu.html?d=8812c0118809c0088800c000c001c0038801c002401180ff08119801c0118800401180ff08119801c01188e9c007e13e80ff08079801c007d13cd92ef8004008f000c00680ff08089801c0080806400880ff08089801c00880ff08001802c00408011803c0050804401180ff08119801c0110805401180ff08119801c0110802c0000803c0010804c0020805c0038801f00008089ffec0084808c0068801f00008089ffec0080806f0004808e800)
  2.  OPC-2 - a load/store based OPC to fit a XC9572 CPLD
      *   [OPC2 spec](/opc/opc2spec.html)
      *   [OPC2 source code](https://github.com/revaldinho/opc/tree/master/opc2)
      *   [OPC2 in-browser Emulator](/opc/opc2jsemu.html?d=80003080ff2080103080110010600080183080017000f0007000)
          *    [...running a pointer test program ptrtest.s](/opc/opc2jsemu.html?d=802030601080f030a010c01030802130601080f130a010c010f000)
  3.  OPC-3 - a direct translation of OPC-1 using 16bit datapath and address bus.
      *   [OPC3 spec](/opc/opc3spec.html)
      *   [OPC3 source code](https://github.com/revaldinho/opc/tree/master/opc3)
  4.  OPC-4  - this spot reserved for a reworking of OPC-3 without any hardware restrictions      
  5.  OPC-5 - a new 16b OPC implementing a 2 operand machine with 16b data and address busses and minimal instruction set
      *   [OPC5 spec](/opc/opc5spec.html)
      *   [OPC5 source code](https://github.com/revaldinho/opc/tree/master/opc5)
