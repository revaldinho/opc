# Tang Nano 20K

The OPC7 system (`../../system`) on the Sipeed Tang Nano 20K (Gowin GW2AR-LV18QN88C8/I7).

| File | |
|---|---|
| `tn20k_sys.v`, `tn20k_sys.cst` | system top level and its pins: 54 MHz from the PLL, 16K words of RAM, UART on the USB serial bridge at 115200 baud, button S1 as reset, LED5 lit when the CPU halts |
| `tn20k_pll.v` | the 27 to 54 MHz PLL |
| `build_sys.sh prog` | bitstream for a program: `build/<prog>/tn20k_sys.fs` (run `../../system/sysrun.sh prog` first) |
| `tangnano20k.cst` | pins for the CPU-only test tops in `../tops` (the `../Makefile` figures) |
| `results.txt` | resource and Fmax figures from `../Makefile` |

The UART pins (69 FPGA TX, 70 FPGA RX) and button S1 (pin 88) follow Sipeed's examples and have not
yet been checked on a board.

## First hardware test: hello and echo

Once on the Linux machine:

    sudo usermod -aG dialout $USER      # then log out and in: the serial port needs the dialout group

openFPGALoader's udev rules are already installed. In a VM, connect the board's USB device to the guest.

1. Find the board: `openFPGALoader --scan-usb` and `ls /dev/ttyUSB*`. The USB bridge shows two
   serial ports; the UART is usually the second (`/dev/ttyUSB1`).
2. Open a terminal on it and leave it running (Ctrl-] quits):

       python3 -m serial.tools.miniterm --eol LF /dev/ttyUSB1 115200

3. In another shell, load the hello bitstream into the FPGA's SRAM (it is lost at power off; add `-f` to
   write the flash instead):

       openFPGALoader -b tangnano20k build/hello/tn20k_sys.fs

   The program runs at once, probably before the terminal sees it, so press S1: each press prints
   `Hello World!` again, and LED5 lights when it has finished.
4. Load `build/echo/tn20k_sys.fs` the same way and press S1: it prints a banner and echoes what you
   type, with Return as a new line, until you type `.`; then it prints `Bye` and LED5 lights.

A reset does not reload the RAM, so the program runs again from the RAM it left;
`SIMARGS=+resets=2 ../../system/sysrun.sh hello` checks that in simulation (both programs pass).

| What you see | Likely cause |
|---|---|
| LED5 does not light | clock, PLL or reset: the CPU is not running the program |
| LED5 lights but no text | UART pins (try 69 and 70 swapped in `tn20k_sys.cst`) or the wrong serial port |
| Garbled text | baud rate: the UART divides 54 MHz by 469 (115139 baud) |
| Text but echo ignores typing | the RX pin (70) |
