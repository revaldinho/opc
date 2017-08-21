module system (
               input        clk100,
               output       led1,
               output       led2,
               output       led3,
               output       led4,
               input        sw1_1,
               input        sw1_2,
               input        sw2_1,
               input        sw2_2,
               input        sw3,
               input        sw4,
               input        rxd,
               output       txd);

   // CLKSPEED is the main clock speed
   parameter CLKSPEED = 40000000;

   // BAUD is the desired serial baud rate
   parameter BAUD = 115200;

   // RAMSIZE is the size of the RAM address bus
   parameter RAMSIZE = 12;

   // Long counter so we can see an LED flashing
   reg  [23:0] clk_counter;

   // CPU signals
   wire        clk;
   wire [15:0] cpu_din;
   wire [15:0] cpu_dout;
   wire [15:0] ram_dout;
   wire [15:0] uart_dout;
   wire [15:0] address;
   wire        rnw;
   reg         reset_b;
   wire        uart_cs_b = !({address[15:1],  1'b0} == 16'hfe08);

   // Map the RAM at both the top and bottom of memory (uart_cs_b takes priority)
   wire         ram_cs_b = !((|address[15:RAMSIZE] == 1'b0)  || (&address[15:RAMSIZE] == 1'b1));


   // PLL to go from 100MHz to 40MHz
   //
   // In PHASE_AND_DELAY_MODE:
   //     FreqOut = FreqRef * (DIVF + 1) / (DIVR + 1)
   //     (DIVF: 0..63)
   //     (DIVR: 0..15)
   //     (DIVQ: 1..6, apparantly not used in this mode)
   //
   // The valid PLL output range is 16 - 275 MHz.
   // The valid PLL VCO range is 533 - 1066 MHz.
   // The valid phase detector range is 10 - 133MHz.
   // The valid input frequency range is 10 - 133MHz.
   //
   //
   // icepll -i 100 -o 40
   // F_PLLIN:   100.000 MHz (given)
   // F_PLLOUT:   40.000 MHz (requested)
   // F_PLLOUT:   40.000 MHz (achieved)
   //
   // FEEDBACK: SIMPLE
   // F_PFD:   20.000 MHz
   // F_VCO:  640.000 MHz
   //
   // DIVR:  4 (4'b0100)
   // DIVF: 31 (7'b0011111)
   // DIVQ:  4 (3'b100)
   //
   // FILTER_RANGE: 2 (3'b010)


   wire         PLL_BYPASS = 0;
   wire         PLL_RESETB = 1;
   wire         LOCK;
   SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
        .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
        .PLLOUT_SELECT("GENCLK"),
        .SHIFTREG_DIV_MODE(1'b0),
        .FDA_FEEDBACK(4'b0000),
        .FDA_RELATIVE(4'b0000),
        .DIVR(4'b0100),
        .DIVF(7'b0011111),
        .DIVQ(3'b100),
        .FILTER_RANGE(3'b010),
   ) uut (
        .REFERENCECLK   (clk100),
        .PLLOUTGLOBAL   (clk),
        .BYPASS         (PLL_BYPASS),
        .RESETB         (PLL_RESETB),
        .LOCK           (LOCK )
   );

   always @(posedge clk)
     begin
          reset_b <= sw3;
     end

   always @(posedge clk)
     begin
        if (!reset_b)
          clk_counter <= 0;
        else
          clk_counter <= clk_counter + 1;
     end

   assign led1 = ~reset_b; // blue
   assign led2 = LOCK;     // green
   assign led3 = ~rxd;     // yellow
   assign led4 = ~txd;     // red


   // The CPU
`ifdef cpu_opc6
   opc6cpu inst_cpu
     (
      .din(cpu_din),
      .clk(clk),
      .reset_b(reset_b),
      .int_b(2'b11),
      .clken(1'b1),
      .vpa(),
      .vda(),
      .vio(),
      .dout(cpu_dout),
      .address(address),
      .rnw(rnw)
    );

`else
   opc5lscpu CPU
     (
      .din(cpu_din),
      .clk(clk),
      .reset_b(reset_b),
      .int_b(1'b1),
      .clken(1'b1),
      .vpa(),
      .vda(),
      .dout(cpu_dout),
      .address(address),
      .rnw(rnw)
      );
`endif

   // A block RAM - clocked off negative edge to mask output register
   ram RAM
     (
      .din(cpu_dout),
      .dout(ram_dout),
      .address(address[RAMSIZE-1:0]),
      .rnw(rnw),
      .clk(!clk),
      .cs_b(ram_cs_b)
      );

   // A simple 115200 baud UART
   uart #(CLKSPEED, BAUD) UART
     (
      .din(cpu_dout),
      .dout(uart_dout),
      .a0(address[0]),
      .rnw(rnw),
      .clk(clk),
      .reset_b(reset_b),
      .cs_b(uart_cs_b),
      .rxd(rxd),
      .txd(txd)
      );

   // Data Multiplexor
   assign cpu_din = uart_cs_b ? (ram_cs_b ? 16'hffff : ram_dout) : uart_dout;


endmodule
