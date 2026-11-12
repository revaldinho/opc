// tn20k_sys.v - the OPC7 system (opc7hsys.v) on the Tang Nano 20K: 27 MHz in, 54 MHz from the PLL,
// UART on the onboard USB serial bridge (115200 baud), 16K words of block RAM. Reset is a power-on
// reset released after the PLL locks, and button S1 resets the system while held. The button's level
// is sampled during the power-on reset and a press is any change from it, so its polarity does not
// matter. The RAM keeps what the program left in it, not the loaded image. LEDs (active low): LED5
// lit when the CPU has halted, LEDs 0-4 GPIO output bits 0-4. Built by build_sys.sh with the
// program's rom.hex and ram.hex in the working directory.
module tn20k_sys(input clk27, input btn, input uart_rx, output uart_tx, output [5:0] led);
  wire clk, locked;
  tn20k_pll pll(.clock_in(clk27), .clock_out(clk), .locked(locked));
  reg [7:0] por = 8'h0;
  reg [1:0] btn_s = 2'b0;                 // the button, synchronised
  reg btn_idle = 1'b0;                    // its level when not pressed
  wire pressed = btn_s[1] != btn_idle;
  wire rst_n = &por;
  always @(posedge clk) begin
    btn_s <= {btn_s[0], btn};
    if (!rst_n) btn_idle <= btn_s[1];
    if (!locked || (rst_n && pressed)) por <= 8'h0; else if (!rst_n) por <= por + 8'h1;
  end
  wire [31:0] gpio_out, gpio_oe;
  wire halted;
  opc7hsys #(.RAM_AW(14), .ROM_FILE("rom.hex"), .RAM_FILE("ram.hex"), .UART_DIV(469)) sys(
    .clk(clk), .rst_n(rst_n), .uart_rx(uart_rx), .uart_tx(uart_tx),
    .gpio_in(32'h0), .gpio_out(gpio_out), .gpio_oe(gpio_oe), .halted(halted));
  assign led = ~{halted, gpio_out[4:0]};
endmodule
