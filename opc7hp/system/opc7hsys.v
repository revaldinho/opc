// opc7hsys.v - OPC7 system, phase 1: opc7hpcpu with a boot ROM, main memory in block RAM (no caches
// or SDRAM yet), and I/O. Board independent; a board top adds the clock, reset and pins.
//
// Memory (word addresses, both CPU ports):
//   0x00000-0x00FFF  boot ROM, 4K words, two read ports (instruction and data): ROM_FILE
//   0x01000-0xFFFFF  RAM: 2**RAM_AW words, repeated through the space (RAM_FILE). The RAM words
//                    under the ROM are not reachable. Writes to the ROM are ignored.
// I/O (IN/OUT, qualified by vio; addresses with bits 15-8 zero, others read 0, writes ignored):
//   0x00-0x01  UART: 0 status (read: bit 0 TX room, bit 1 RX data; write: empty the FIFOs), 1 data
//   0x10-0x12  GPIO: 0x10 input pins (read), 0x11 output register, 0x12 direction (1 = drive)
//   0x20-0x21  CPC-CPLINK (not yet: reads 0)
//   0x30       cache control (no caches yet: writes ignored, reads 0)
// Both ports answer in one cycle, so iwait and dwait are low. A halt instruction stops the CPU until
// reset (halted); I/O and memory writes are blocked from then on.
module opc7hsys #(parameter RAM_AW = 14, ROM_FILE = "rom.hex", RAM_FILE = "ram.hex", UART_DIV = 469) (
  input clk, input rst_n,
  input uart_rx, output uart_tx,
  input [31:0] gpio_in, output [31:0] gpio_out, output [31:0] gpio_oe,
  output halted);
  wire [31:0] din, dout, idin;
  wire [19:0] address, iaddr;
  wire        rnw, vda, vio, ird, hlt;
  reg         halted_q = 1'b0;
  assign halted = halted_q;
  always @(posedge clk)
    if (!rst_n) halted_q <= 1'b0; else if (hlt) halted_q <= 1'b1;

  opc7hpcpu cpu(.idin(idin), .din(din), .clk(clk), .reset_b(rst_n), .int_b(2'b11), .clken(!halted_q),
                .iwait(1'b0), .dwait(1'b0), .vda(vda), .vio(vio), .dout(dout), .address(address), .rnw(rnw),
                .iaddr(iaddr), .ird(ird), .hlt(hlt));

  // memory
  wire        d_rom = address[19:12] == 8'h0, i_rom = iaddr[19:12] == 8'h0;
  wire        ram_we = !halted_q && vda && !rnw && !d_rom;
  reg  [31:0] rom [0:4095];
  initial $readmemh(ROM_FILE, rom);
  reg  [31:0] rom_d, rom_i, ram_d, ram_i;
  always @(posedge clk) rom_d <= rom[address[11:0]];
  always @(posedge clk) rom_i <= rom[iaddr[11:0]];
  // no_rw_check: the CPU never uses din in a write cycle (see top_opc7hp.v)
  (* no_rw_check *) reg [31:0] ram [0:(1 << RAM_AW) - 1];
  integer i;
  initial begin
`ifndef SYNTHESIS
    for (i = 0; i < (1 << RAM_AW); i = i + 1) ram[i] = 32'h0;   // as block RAM starts (and the emulators)
`endif
    $readmemh(RAM_FILE, ram);
  end
  always @(posedge clk) begin
    if (ram_we) ram[address[RAM_AW-1:0]] <= dout;
    ram_d <= ram[address[RAM_AW-1:0]];
  end
  always @(posedge clk) ram_i <= ram[iaddr[RAM_AW-1:0]];

  // I/O
  wire        io    = !halted_q && vio && address[15:8] == 8'h0;
  wire        io_rd = io && rnw, io_wr = io && !rnw;
  wire [3:0]  dev   = address[7:4];
  wire [31:0] uart_rdata;
  opc7_uart #(.DIV(UART_DIV)) uart(.clk(clk), .rst(!rst_n), .rd(io_rd && dev == 4'h0), .wr(io_wr && dev == 4'h0),
                                   .a(address[0]), .wdata(dout[7:0]), .rdata(uart_rdata), .rx(uart_rx), .tx(uart_tx));
  reg  [31:0] gpio_o = 0, gpio_d = 0, gpio_s0 = 0, gpio_s1 = 0;
  assign {gpio_out, gpio_oe} = {gpio_o, gpio_d};
  always @(posedge clk) begin
    {gpio_s1, gpio_s0} <= {gpio_s0, gpio_in};    // synchroniser
    if (!rst_n) {gpio_o, gpio_d} <= 0;
    else if (io_wr && dev == 4'h1) begin
      if (address[1:0] == 2'd1) gpio_o <= dout;
      if (address[1:0] == 2'd2) gpio_d <= dout;
    end
  end
  wire [31:0] gpio_rdata = address[1:0] == 2'd0 ? gpio_s1 : address[1:0] == 2'd1 ? gpio_o :
                           address[1:0] == 2'd2 ? gpio_d : 32'h0;
  wire [31:0] io_rdata = dev == 4'h0 ? uart_rdata : dev == 4'h1 ? gpio_rdata : 32'h0;

  // read data back to the CPU, the cycle after the request
  reg         d_rom_q = 1'b0, d_io_q = 1'b0, i_rom_q = 1'b1;
  reg  [31:0] io_q = 0;
  always @(posedge clk) begin
    {d_rom_q, d_io_q, i_rom_q} <= {d_rom, vio, i_rom};
    if (io_rd) io_q <= io_rdata;
    else if (vio) io_q <= 32'h0;                 // outside the decoded range
  end
  assign din  = d_io_q ? io_q : d_rom_q ? rom_d : ram_d;
  assign idin = i_rom_q ? rom_i : ram_i;
endmodule
