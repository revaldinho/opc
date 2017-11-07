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
   wire [31:0] cpu_dout_nxt;
   wire [31:0] cpu_dout;
   wire [31:0] ram_dout;
   wire [15:0] uart_dout;
   wire [19:0] address_nxt;
   wire [19:0] address;
   wire        rnw;
   wire        rnw_nxt;
   wire        vpa;
   wire        vpa_nxt;
   wire        vda;
   wire        vda_nxt;
   wire        vio;
   wire        vio_nxt;

   reg         cpuclken_old = 0;
   wire        cpuclken;
   reg         sw4_sync;
   wire        reset_b;
   wire        uart_cs_b = !({address[15:1],  1'b0} == 16'hfe08);

   // Map the RAM at both the top and bottom of memory (uart_cs_b takes priority)
   wire        ram_cs_b = 1'b0;

   // External RAM signals
   wire         wegate;
   assign RAMCS_b = 1'b0;
   assign RAMOE_b = !rnw;
   assign RAMWE_b = rnw  | wegate;
   assign ADR = address[17:0] ;

   // This doesn't work yet...
   // assign DAT = rnw ? 'bz : cpu_dout;

   // So instead we must instantiate a SB_IO block
   wire [15:0]  data_pins_in;
   wire [15:0]  data_pins_out = cpu_dout[15:0];
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
   assign cpu_din = uart_cs_b ? (ram_cs_b ? {16'b0, data_pins_in} : ram_dout) : {16'b0, uart_dout};

   reg [1:0] clkdiv = 2'b00;
   always @(posedge clk100)
     begin
        clkdiv <= clkdiv + 1;
     end
   assign clk = clkdiv[0];
   assign wegate = 1'b1;

   always @(posedge clk)
     begin
        sw4_sync <= sw4;
        cpuclken_old <= cpuclken;
     end

//   assign cpuclken = !reset_b | !cpuclken_old | !(vda | vpa);
   assign cpuclken = 1'b1;

   assign reset_b = sw4_sync;

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
      .rnw(rnw),
      .vpa_nxt(vpa_nxt),
      .vda_nxt(vda_nxt),
      .vio_nxt(vio_nxt),
      .dout_nxt(cpu_dout_nxt),
      .address_nxt(address_nxt),
      .rnw_nxt(rnw_nxt)
    );

   // A block RAM - clocked off negative edge to mask output register
   ram RAM
     (
      .din(cpu_dout_nxt),
      .dout(ram_dout),
      .address(address_nxt[RAMSIZE-1:0]),
      .rnw(rnw_nxt),
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
