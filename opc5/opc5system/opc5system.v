module opc5system ( input clk, input[7:0] sw, output[7:0] led, input rxd, output txd,
                    output [6:0] seg, output [3:0] an, input select);

   // CLKSPEED is the main clock speed
   parameter CLKSPEED = 32000000;
   
   // BAUD is the desired serial baud rate
   parameter BAUD = 115200;

   // RAMSIZE is the size of the RAM address bus
   parameter RAMSIZE = 11;
   
   // Duty Cycle controls the brightness of the seven segment display (0..15)
   parameter SEVEN_SEG_DUTY_CYCLE = 0;
      
   wire [15:0] cpu_din;
   wire [15:0] cpu_dout;
   wire [15:0] ram_dout;
   wire [15:0] uart_dout;
   wire [15:0] address;
   wire        rnw;
   reg         reset_b;

   wire        uart_cs_b = !({address[15:1],  1'b0} == 16'hfe08);
   wire         ram_cs_b = !(address[15:RAMSIZE] == 0);
   
   // Synchronize reset
   always @(posedge clk)
        reset_b <= select;

   // The OPC5 CPU
   opc5cpu CPU ( cpu_din, cpu_dout, address, rnw, clk, reset_b);

   // A block RAM - clocked off negative edge to mask output register
   ram RAM (cpu_dout, ram_dout, address[RAMSIZE-1:0], rnw, !clk, ram_cs_b);

   // A simple 115200 baud UART
   uart #(CLKSPEED, BAUD) UART (cpu_dout, uart_dout, address[0], rnw, clk, reset_b, uart_cs_b, rxd, txd);

   // Use the 4-digit hex display for the address
   sevenseg #(SEVEN_SEG_DUTY_CYCLE) DISPLAY (sw[0] ? cpu_din : address, clk, an, seg);

   // Data Multiplexor
   assign cpu_din = ram_cs_b ? (uart_cs_b ? 16'hffff : uart_dout) : ram_dout;
   
   // LEDs could be used for debugging in the future
   assign led = sw;

endmodule
