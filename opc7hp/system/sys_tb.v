// sys_tb.v - testbench for the OPC7 system (opc7hsys.v), run in a directory holding rom.hex and ram.hex
// (see sysimg.py). The RAM covers the whole address space (RAM_AW 20) and the UART runs at DIV clocks
// a bit (default 8, for speed). Characters the UART sends are decoded and written, except carriage
// returns, to uart.out (as the claude-tests .expected files are) and to stdout. Bytes in uart.in, if
// there is one, are sent to the UART's RX pin, each when its RX FIFO is empty. The run ends a few
// character times after the CPU halts with the TX FIFO empty, or after +maxcycles (default 200M).
// +resets=N then resets the system N more times, as the Tang Nano's button does, and runs the program
// again from the RAM it left (not from the image), with uart.in sent again from its start.
`timescale 1ns / 1ns
module sys_tb;
  parameter DIV = 8;
  reg clk = 0, rst_n = 0;
  wire tx, halted;
  reg  rx = 1'b1;
  wire [31:0] gpio_out, gpio_oe;
  opc7hsys #(.RAM_AW(20), .UART_DIV(DIV)) sys(.clk(clk), .rst_n(rst_n), .uart_rx(rx), .uart_tx(tx),
                                              .gpio_in(32'h12345678), .gpio_out(gpio_out), .gpio_oe(gpio_oe), .halted(halted));
  always #10 clk = !clk;
  integer cycles = 0, maxcycles = 200000000, out_f, in_f, ch, nchars = 0, halt_cycle = -1, resets = 0;
  initial begin
    if (!$value$plusargs("maxcycles=%d", maxcycles)) maxcycles = 200000000;
    if (!$value$plusargs("resets=%d", resets)) resets = 0;
    out_f = $fopen("uart.out", "w");
    in_f = $fopen("uart.in", "r");
    repeat (4) @(posedge clk);
    rst_n = 1;
  end
  // UART TX line decoder: sample each bit in its middle
  integer t, b;
  reg [7:0] byte_in;
  always begin
    @(negedge tx);
    repeat (DIV / 2) @(posedge clk);
    if (tx == 1'b0) begin
      for (b = 0; b < 8; b = b + 1) begin
        repeat (DIV) @(posedge clk);
        byte_in[b] = tx;
      end
      repeat (DIV) @(posedge clk);             // stop bit
      if (tx !== 1'b1) $display("sys_tb: framing error at cycle %0d", cycles);
      nchars = nchars + 1;
      if (byte_in != 8'h0d) begin $fwrite(out_f, "%c", byte_in); $write("%c", byte_in); end
    end
  end
  // UART RX line driver: one byte at a time from uart.in, when the RX FIFO is empty
  task send(input [7:0] v); begin
    rx = 1'b0; repeat (DIV) @(posedge clk);
    for (t = 0; t < 8; t = t + 1) begin rx = v[t]; repeat (DIV) @(posedge clk); end
    rx = 1'b1; repeat (DIV) @(posedge clk);
  end endtask
  initial if (in_f != 0) forever begin
    wait (rst_n);
    ch = $rewind(in_f);
    ch = $fgetc(in_f);
    while (ch >= 0 && rst_n) begin
      wait (sys.uart.rx_empty && !halted);
      repeat (2 * DIV) @(posedge clk);
      send(ch[7:0]);
      ch = $fgetc(in_f);
    end
    wait (!rst_n);
  end
  // the end
  always @(posedge clk) begin
    cycles = cycles + 1;
    if (halted && halt_cycle < 0) halt_cycle = cycles;
    if (halted && sys.uart.tx_empty && sys.uart.tx_bits == 0 && cycles > halt_cycle + 30 * DIV && resets > 0) begin
      resets = resets - 1; halt_cycle = -1;
      rst_n = 1'b0; repeat (4) @(posedge clk); rst_n = 1'b1;
    end
    else if ((halted && sys.uart.tx_empty && sys.uart.tx_bits == 0 && cycles > halt_cycle + 30 * DIV) || cycles >= maxcycles) begin
      $fclose(out_f);
      $display("");
      $display("sys_tb: %0s at cycle %0d, %0d characters sent, PC 0x%05x", halted ? "halted" : "stopped (maxcycles)", halt_cycle, nchars, sys.cpu.PC_q);
      $finish;
    end
  end
endmodule
