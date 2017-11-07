// `define use_pll

module system (
               input         clk100,
               output        led1,
               output        led2,
               output        led3,
               output        led4,
               input         sw1_1,
               input         sw1_2,
               input         sw2_1,
               input         sw2_2,
               input         sw3,
               input         sw4,
               output        RAMWE_b,
               output        RAMOE_b,
               output        RAMCS_b,
               output [17:0] ADR,
               inout [15:0]  DAT,
               input         rxd,
               output        txd);

   // CLKSPEED is the main clock speed
   parameter CLKSPEED = 25000000;

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
   wire        vpa;
   wire        vda;
   wire        vio;
   
   wire        cpuclken = 1;
   reg         sw4_sync;
   wire        reset_b;

   // Map the RAM everywhere in IO space (for performance)
   wire        uart_cs_b = !(vio);

   // Map the RAM at both the top and bottom of memory (uart_cs_b takes priority)
   wire         ram_cs_b = !((vpa || vda) && ((|address[15:RAMSIZE] == 1'b0)  || (&address[15:RAMSIZE] == 1'b1)));

   // External RAM signals
   wire         wegate;
   assign RAMCS_b = 1'b0;
   assign RAMOE_b = !rnw;
   assign RAMWE_b = rnw  | wegate;
   assign ADR = { 2'b00, address };

   // This doesn't work yet...
   // assign DAT = rnw ? 'bz : cpu_dout;

   // So instead we must instantiate a SB_IO block
   wire [15:0]  data_pins_in;
   wire [15:0]  data_pins_out = cpu_dout;   
   wire         data_pins_out_en = !(rnw | wegate); // Added wegate to avoid bus conflicts

`ifdef simulate
   assign data_pins_in = DAT;
   assign DAT = data_pins_out_en ? data_pins_out : 16'hZZZZ; 
`else   
   SB_IO #(
           .PIN_TYPE(6'b 1010_01),
           ) sram_data_pins [15:0] (
           .PACKAGE_PIN(DAT),
           .OUTPUT_ENABLE(data_pins_out_en),
           .D_OUT_0(data_pins_out),
           .D_IN_0(data_pins_in),
   );
`endif
   
   // Data Multiplexor
   assign cpu_din = uart_cs_b ? (ram_cs_b ? data_pins_in : ram_dout) : uart_dout;

`ifdef use_pll
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
        .PLLOUTCORE     (wegate),
        .BYPASS         (PLL_BYPASS),
        .RESETB         (PLL_RESETB),
        .LOCK           (LOCK)
   );
`else // !`ifdef use_pll
   wire LOCK = 1'b1;
   reg [1:0] clkdiv = 2'b00;  // divider
   always @(posedge clk100)
     begin
        case (clkdiv)
          2'b11: clkdiv <= 2'b10;  // rising edge of clk
          2'b10: clkdiv <= 2'b00;  // wegate low
          2'b00: clkdiv <= 2'b01;  // wegate low
          2'b01: clkdiv <= 2'b11;
        endcase
     end
   assign clk = clkdiv[1];
   assign wegate = clkdiv[0];
`endif


   always @(posedge clk)
     begin
          sw4_sync <= sw4;
     end

   assign reset_b = sw4_sync & LOCK;

   always @(posedge clk)
     begin
        if (!reset_b)
          clk_counter <= 0;
        else
          clk_counter <= clk_counter + 1;
     end

   assign led1 = !reset_b; // blue
   assign led2 = LOCK;     // green
   assign led3 = !rxd;     // yellow
   assign led4 = !txd;     // red


   // The CPU
`ifdef cpu_opc6
   opc6cpu CPU
     (
      .din(cpu_din),
      .clk(clk),
      .reset_b(reset_b),
      .int_b(2'b11),
      .clken(cpuclken),
      .vpa(vpa),
      .vda(vda),
      .vio(vio),
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
      .clken(cpuclken),
      .vpa(vpa),
      .vda(vda),
      .dout(cpu_dout),
      .address(address),
      .rnw(rnw)
      );
   // Fake vio, just at the UART address
   assign vio = vda && ({address[15:1],  1'b0} == 16'hfe08);
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

endmodule
