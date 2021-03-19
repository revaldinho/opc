`define cpu_opc7 1
`ifdef cpu_opc7
 `define use_lookahead
`endif
`ifdef cpu_opc6
 `define use_lookahead
`endif

module system ( input clk, input[7:0] sw, output[7:0] led, input rxd, output txd,
                    output [6:0] seg, output [3:0] an, input select);

   // CLKSPEED is the input clock speed
   parameter CLKSPEED = 32000000;

   // CLKFX_MULTIPLY/CLKFX_DIVIDE used in PLL to generate cpu_clk
   parameter CLKFX_MULTIPLY = 2;
   parameter CLKFX_DIVIDE = 2;

   // BAUD is the desired serial baud rate
   parameter BAUD = 115200;

   // Duty Cycle controls the brightness of the seven segment display (0..15)
   parameter SEVEN_SEG_DUTY_CYCLE = 0;

   // DSIZE is the size of the CPU data bus
   // ASIZE is the size of the CPU address bus
   // RAMSIZE is the size of the RAM address bus
`ifdef cpu_opc7
   parameter DSIZE   = 32;
   parameter ASIZE   = 20;
   parameter RAMSIZE = 13;
`else
   parameter DSIZE   = 16;
   parameter ASIZE   = 16;
   parameter RAMSIZE = 14;
`endif

   wire               fx_clk;
   wire               cpu_clk;
   wire [DSIZE - 1:0] cpu_din;
   wire [DSIZE - 1:0] cpu_dout;
   wire [DSIZE - 1:0] ram_dout;
   wire [ASIZE - 1:0] address;
   wire               rnw;
   wire [15:0]        uart_dout;
   reg                reset_b;
   wire               vpa;
   wire               vda;
   wire               vio;

`ifdef use_lookahead
  // Need to register the CPU outputs for the UART if using lookahead memory interface
  reg [DSIZE - 1:0] cpu_dout_q;
  reg [ASIZE - 1:0] address_q;
  reg		    rnw_q;
  reg		    vpa_q;
  reg		    vda_q;
  reg		    vio_q;
  // Map the RAM everywhere in IO space (for performance)
  wire               uart_cs_b = !(vio_q);
`else  
  // Map the RAM everywhere in IO space (for performance)
  wire               uart_cs_b = !(vio);
`endif
  
   // Map the RAM everywhere in memory space (for performance)
   wire               ram_cs_b = !(vpa || vda);

   // ---------------------------------------------
   // clock PLL
   //
   // clk = input clock
   // cpu_clk = clk * CLKFX_MULTIPLY / CLKFX_DIVIDE
   //
   // the minimum output clock speed is 18.00MHz
   // ---------------------------------------------

    DCM #(
        .CLKFX_MULTIPLY  (CLKFX_MULTIPLY),
        .CLKFX_DIVIDE    (CLKFX_DIVIDE),
        .CLK_FEEDBACK    ("NONE")      // Used in DFS mode only
     ) inst_dcm (
        .CLKIN           (clk),
        .CLKFB           (1'b0),
        .RST             (1'b0),
        .DSSEN           (1'b0),
        .PSINCDEC        (1'b0),
        .PSEN            (1'b0),
        .PSCLK           (1'b0),
        .CLKFX           (fx_clk)
    );

   BUFG inst_bufg (.I(fx_clk), .O(cpu_clk));

   // Synchronize reset
   always @(posedge cpu_clk)
        reset_b <= select;

   // The CPU
`ifdef cpu_opc7
   opc7cpu CPU
     (
      .din(cpu_din),
      .clk(cpu_clk),
      .reset_b(reset_b),
      .int_b(2'b11),
      .clken(1'b1),
      .vpa(vpa),
      .vda(vda),
      .vio(vio),
      .dout(cpu_dout),
      .address(address),
      .rnw(rnw)
    );
`else `ifdef cpu_opc6
   opc6cpu CPU
     (
      .din(cpu_din),
      .clk(cpu_clk),
      .reset_b(reset_b),
      .int_b(2'b11),
      .clken(1'b1),
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
      .clk(cpu_clk),
      .reset_b(reset_b),
      .int_b(1'b1),
      .clken(1'b1),
      .vpa(vpa),
      .vda(vda),
      .dout(cpu_dout),
      .address(address),
      .rnw(rnw)
      );
   // Fake vio, just at the UART address
   assign vio = vda && ({address[15:1],  1'b0} == 16'hfe08);
`endif
`endif

   // A block RAM - clocked off negative edge to mask output register
   ram #
     (
      .DSIZE(DSIZE),
      .ASIZE(RAMSIZE)
     )
   RAM
     (
      .din(cpu_dout),
      .address(address[RAMSIZE-1:0]),
      .rnw(rnw),
`ifdef use_lookahead
      .clk(cpu_clk),      
`else      
      .clk(!cpu_clk),
`endif      
      .cs_b(ram_cs_b),
      .dout(ram_dout)
      );

   // A simple 115200 baud UART
   uart #
     (
      .CLKSPEED(CLKSPEED * CLKFX_MULTIPLY / CLKFX_DIVIDE),
      .BAUD(BAUD)
      )
   UART
     (
`ifdef use_lookahead
      .din(cpu_dout_q),
      .dout(uart_dout),
      .a0(address_q[0]),
      .rnw(rnw_q),
      .clk(cpu_clk),
      .reset_b(reset_b),
      .cs_b(uart_cs_b),
      .rxd(rxd),
      .txd(txd)      
`else      
      .din(cpu_dout),
      .dout(uart_dout),
      .a0(address[0]),
      .rnw(rnw),
      .clk(cpu_clk),
      .reset_b(reset_b),
      .cs_b(uart_cs_b),
      .rxd(rxd),
      .txd(txd)
`endif      
      );

   // Use the 4-digit hex display for the address
   sevenseg #(SEVEN_SEG_DUTY_CYCLE) DISPLAY
     (
`ifdef use_lookahead
      .value(sw[0] ? cpu_din[15:0] : address_q[15:0]),
`else      
      .value(sw[0] ? cpu_din[15:0] : address[15:0]),
`endif
      .clk(cpu_clk),
      .an(an),
      .seg(seg)
      );

`ifdef use_lookahead
  // For CPUs using lookahead memory interface, need to latch the signals for the UART
  always @ (posedge cpu_clk) begin
    address_q <= address;
    rnw_q <= rnw;
    vio_q <= vio;
    vda_q <= vda;
    vpa_q <= vpa;
    cpu_dout_q <= cpu_dout;
  end
`endif
  
   // Data Multiplexor
   assign cpu_din = uart_cs_b ? ram_dout : { {(DSIZE - 16){1'b0}}, uart_dout};

   // LEDs could be used for debugging in the future
   assign led = sw;

endmodule
