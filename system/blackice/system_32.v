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
   parameter CLKSPEED = 50000000;

   // BAUD is the desired serial baud rate
   parameter BAUD = 115200;

   // RAMSIZE is the size of the RAM address bus
   parameter RAMSIZE = 12;

   // CPU signals
   wire        clk;
   wire [31:0] cpu_din;
   wire [31:0] cpu_dout;
   wire [31:0] ram_dout;
   wire [31:0] ext_dout;
   wire [15:0] uart_dout;
   wire [19:0] address;
   wire        rnw;
   wire        vpa;
   wire        vda;
   wire        vio;

   wire        ramclken;  // clken signal for a internal ram access
   wire        extclken;  // clken signal for a external ram access
   reg         ramclken_old = 0;
   wire        cpuclken;
   reg         sw4_sync;
   reg         reset_b;

   // Map the RAM everywhere in IO space (for performance)
   wire        uart_cs_b = !(vio);

   // Map the RAM at both the bottom of memory (uart_cs_b takes priority)
   wire        ram_cs_b = !((vpa || vda) && (address[19:8] < 12'h00E));
   // wire     ram_cs_b = !((vpa || vda) && (|address[19:RAMSIZE] == 1'b0));

   // Everywhere else is external RAM
   wire        ext_cs_b = !((vpa || vda) && (address[19:8] >= 12'h00E));
   // wire     ext_cs_b = !((vpa || vda) && (|address[19:RAMSIZE] == 1'b1));

   // External RAM signals
   wire [15:0]  ext_data_in;
   wire [15:0]  ext_data_out;
   wire         ext_data_oe;

`ifdef simulate
   assign ext_data_in = DAT;
   assign DAT = ext_data_oe ? ext_data_out : 16'hZZZZ;
`else
   SB_IO #(
           .PIN_TYPE(6'b 1010_01),
           ) sram_data_pins [15:0] (
           .PACKAGE_PIN(DAT),
           .OUTPUT_ENABLE(ext_data_oe),
           .D_OUT_0(ext_data_out),
           .D_IN_0(ext_data_in),
   );
`endif

   // Data Multiplexor
   assign cpu_din = uart_cs_b ? (ram_cs_b ? ext_dout : ram_dout) : {16'b0, uart_dout};

   reg [1:0] clkdiv = 2'b00;
   always @(posedge clk100)
     begin
        clkdiv <= clkdiv + 1;
     end
   assign clk = clkdiv[0];

   // Reset generation
   reg [9:0] pwr_up_reset_counter = 0; // hold reset low for ~1000 cycles
   wire      pwr_up_reset_b = &pwr_up_reset_counter;

   always @(posedge clk)
     begin
        ramclken_old <= ramclken;
        if (!pwr_up_reset_b)
          pwr_up_reset_counter <= pwr_up_reset_counter + 1;
        sw4_sync <= sw4;
        reset_b <= sw4_sync & pwr_up_reset_b;
     end

   assign ramclken = !ramclken_old | ram_cs_b;

   assign cpuclken = !reset_b | (ext_cs_b ? ramclken : extclken);

   assign led1 = 0;        // blue
   assign led2 = 1;        // green
   assign led3 = !rxd;     // yellow
   assign led4 = !txd;     // red

   // The CPU
   opc7cpu CPU
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

   memory_controller #
     (
      .DSIZE(32),
      .ASIZE(20)
     )
   MEMC
     (
      .clock         (clk),
      .reset_b       (reset_b),
      .ext_cs_b      (ext_cs_b),
      .cpu_rnw       (rnw),
      .cpu_clken     (extclken),
      .cpu_addr      (address),
      .cpu_dout      (cpu_dout),
      .ext_dout      (ext_dout),
      .ram_cs_b      (RAMCS_b),
      .ram_oe_b      (RAMOE_b),
      .ram_we_b      (RAMWE_b),
      .ram_data_in   (ext_data_in),
      .ram_data_out  (ext_data_out),
      .ram_data_oe   (ext_data_oe),
      .ram_addr      (ADR)
      );

   // A block RAM - clocked off negative edge to mask output register
   ram RAM
     (
      .din(cpu_dout),
      .dout(ram_dout),
      .address(address[RAMSIZE-1:0]),
      .rnw(rnw),
      .clk(clk),
      .cs_b(ram_cs_b)
      );

   // A simple 115200 baud UART
   uart #(CLKSPEED, BAUD) UART
     (
      .din(cpu_dout[15:0]),
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
