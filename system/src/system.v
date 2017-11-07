module system ( input clk, input[7:0] sw, output[7:0] led, input rxd, output txd,
                    output [6:0] seg, output [3:0] an, input select);

   // CLKSPEED is the main clock speed
   parameter CLKSPEED = 32000000;

   // BAUD is the desired serial baud rate
   parameter BAUD = 115200;

   // RAMSIZE is the size of the RAM address bus

   // Duty Cycle controls the brightness of the seven segment display (0..15)
   parameter SEVEN_SEG_DUTY_CYCLE = 0;

`ifdef cpu_opc7
   parameter DSIZE   = 32;
   parameter ASIZE   = 20;
   parameter RAMSIZE = 13;
`else
   parameter DSIZE   = 32;
   parameter ASIZE   = 20;
   parameter RAMSIZE = 14;
`endif

   wire [DSIZE - 1:0] cpu_din;
   wire [DSIZE - 1:0] cpu_dout;
   wire [DSIZE - 1:0] ram_dout;
   wire [ASIZE - 1:0] address;
   wire [15:0] uart_dout;
   wire        rnw;
   reg         reset_b;

   wire        uart_cs_b = !({address[15:1],  1'b0} == 16'hfe08);

   // Map the RAM at both the top and bottom of memory (uart_cs_b takes priority)
   wire         ram_cs_b = !((|address[15:RAMSIZE] == 1'b0)  || (&address[15:RAMSIZE] == 1'b1));

   // Synchronize reset
   always @(posedge clk)
        reset_b <= select;

   // The CPU
`ifdef cpu_opc7
   opc7cpu CPU
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
`else `ifdef cpu_opc6
   opc6cpu CPU
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
      .dout(ram_dout),
      .address(address[RAMSIZE-1:0]),
      .rnw(rnw),
      .clk(!clk),
      .cs_b(ram_cs_b)
      );

   // A simple 115200 baud UART
   uart #
     (
      .CLKSPEED(CLKSPEED),
      .BAUD(BAUD)
      )
   UART
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

   // Use the 4-digit hex display for the address
   sevenseg #(SEVEN_SEG_DUTY_CYCLE) DISPLAY
     (
      .value(sw[0] ? cpu_din[15:0] : address[15:0]),
      .clk(clk),
      .an(an),
      .seg(seg)
      );

   // Data Multiplexor
   assign cpu_din = uart_cs_b ? (ram_cs_b ? {DSIZE{1'b1}} : ram_dout) : { {(DSIZE - 16){1'b0}}, uart_dout};

   // LEDs could be used for debugging in the future
   assign led = sw;

endmodule
