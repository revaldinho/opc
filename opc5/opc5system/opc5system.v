module opc5system ( input clk, input[7:0] sw, output[7:0] led, input rxd, output txd,
                    output [6:0] seg, output [3:0] an, input select);

   wire [15:0] data;
   wire [15:0] address;
   wire        rnw;
   reg         reset_b;

   wire        uart_cs_b = !({address[15: 1],  1'b0} == 16'hfe08);
   wire         ram_cs_b = !({address[15:11], 11'b0} == 16'h0000);

   // Synchronize reset
   always @(posedge clk)
        reset_b <= select;

   // The OPC5 CPU
   opc5cpu CPU ( data, address, rnw, clk, reset_b);

   // A 2KBx16 RAM - clock off negative edge to mask output register
   ram_2k_16 RAM (data, address[10:0], rnw, !clk, ram_cs_b);

   // A simple 115200 baud UART
   uart UART (data, address[0], rnw, clk, reset_b, uart_cs_b, rxd, txd);

   // Use the 4-digit hex display for the address
   sevenseg DISPLAY (sw[0] ? data : address, clk, an, seg);

   // LEDs could be used for debugging in the future
   assign led = sw;

endmodule
