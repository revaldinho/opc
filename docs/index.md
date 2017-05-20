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
      *   [OPC3 in-browser Emulator](/opc/opc3jsemu.html?d=88000000c000003210000032c000003388000080800000ff8800fff098000001d0000014d800000e80000033d800001a98000001e000001ef8000000c000003088000001f00000008800ffff98000001c800002cd800002608000030e800000000000000000000010002000300050006000700080009000a022b01230977)
          *    [...running a pointer test program ptrtest.s](/opc/opc3jsemu.html?d=88000020c0000010880000f0400000104800001088000021c0000010880000f10000001048000010f8000000)
          *    [...running a Fibonacci test program fib.s](/opc/opc3jsemu.html?d=88000112c000011188000109c000010888000000c000010088000001c000010140000111800000ff0800011198000001c00001118800000040000111800000ff0800011198000001c00001118800ffe9c0000107e000003a800000ff0800010798000001c0000107d0000038d800002af800000040000108800000ff0800010898000001c0000108800000ff0800010018000101c000010240000111800000ff0800011198000001c000011108000101c000010008000102c00001018800ffff98000001080001089800fffec000010848000108e8000000)
  4.  OPC-4  - this spot reserved for a reworking of OPC-3 without any hardware restrictions      
  5.  OPC-5 - a new 16b OPC implementing a 2 operand machine with 16b data and address busses and minimal instruction set
      *   [OPC5 spec](/opc/opc5spec.html)
      *   [OPC5 source code](https://github.com/revaldinho/opc/tree/master/opc5)
