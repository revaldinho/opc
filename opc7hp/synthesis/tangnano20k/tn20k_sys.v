// tn20k_sys.v - the OPC7 system (opc7hsys.v) on the Tang Nano 20K: 27 MHz in, 54 MHz from the PLL,
// UART on the onboard USB serial bridge (115200 baud), 16K words of block RAM. Reset is a power-on
// reset released after the PLL locks (the buttons are not used yet). LEDs (active low): LED5 lit when
// the CPU has halted, LEDs 0-4 GPIO output bits 0-4. Built by build_sys.sh with the program's
// rom.hex and ram.hex in the working directory.
module tn20k_sys(input clk27, input uart_rx, output uart_tx, output [5:0] led);
  wire clk, locked;
  tn20k_pll pll(.clock_in(clk27), .clock_out(clk), .locked(locked));
  reg [7:0] por = 8'h0;
  wire rst_n = &por;
  always @(posedge clk)
    if (!locked) por <= 8'h0; else if (!rst_n) por <= por + 8'h1;
  wire [31:0] gpio_out, gpio_oe;
  wire halted;
  opc7hsys #(.RAM_AW(14), .ROM_FILE("rom.hex"), .RAM_FILE("ram.hex"), .UART_DIV(469)) sys(
    .clk(clk), .rst_n(rst_n), .uart_rx(uart_rx), .uart_tx(uart_tx),
    .gpio_in(32'h0), .gpio_out(gpio_out), .gpio_oe(gpio_oe), .halted(halted));
  assign led = ~{halted, gpio_out[4:0]};
endmodule
