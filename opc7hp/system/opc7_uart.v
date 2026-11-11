// opc7_uart.v - UART for the OPC7 system: RX and TX only, 8 data bits, no parity, 1 stop bit, no
// handshaking, a 16 entry FIFO each way. DIV is the clock cycles per bit (54 MHz / 115200 = 469).
// Two registers (a = I/O address bit 0):
//   0  status   read:  bit 0 = room in the TX FIFO, bit 1 = data in the RX FIFO
//               write: empty both FIFOs (a character being sent is finished)
//   1  data     read:  pop a byte from the RX FIFO (0 if it is empty)
//               write: push the low byte into the TX FIFO (lost if it is full)
// rd and wr are one-cycle strobes, acted on at the clock edge; rdata is the value a read at that edge
// returns. A byte received while the RX FIFO is full is lost.
module opc7_uart #(parameter DIV = 469) (
  input clk, input rst, input rd, input wr, input a, input [7:0] wdata, output [31:0] rdata,
  input rx, output tx);
  localparam CW = $clog2(DIV + 1);
  localparam [CW-1:0] D1 = DIV - 1, DH = DIV / 2;
  // FIFOs: 4 bit index, one more bit to tell full from empty
  reg [7:0] tx_mem [0:15], rx_mem [0:15];
  reg [4:0] tx_wp = 0, tx_rp = 0, rx_wp = 0, rx_rp = 0;
  wire tx_empty = tx_wp == tx_rp, tx_full = tx_wp == {~tx_rp[4], tx_rp[3:0]};
  wire rx_empty = rx_wp == rx_rp, rx_full = rx_wp == {~rx_rp[4], rx_rp[3:0]};
  assign rdata = a ? {24'b0, rx_empty ? 8'b0 : rx_mem[rx_rp[3:0]]} : {30'b0, !rx_empty, !tx_full};
  wire flush = wr && !a;
  // transmitter: start bit, 8 data bits LSB first, stop bit
  reg [9:0] tx_sh = 10'h3FF;
  reg [3:0] tx_bits = 0;
  reg [CW-1:0] tx_cnt = 0;
  assign tx = tx_sh[0];
  wire tx_load = tx_bits == 0 && !tx_empty;
  always @(posedge clk) begin
    if (wr && a && !tx_full) begin tx_mem[tx_wp[3:0]] <= wdata; end
    if (rst || flush) {tx_wp, tx_rp} <= 0;
    else begin
      if (wr && a && !tx_full) tx_wp <= tx_wp + 1;
      if (tx_load) tx_rp <= tx_rp + 1;
    end
    if (rst) {tx_sh, tx_bits, tx_cnt} <= {10'h3FF, 4'd0, {CW{1'b0}}};
    else if (tx_load) {tx_sh, tx_bits, tx_cnt} <= {1'b1, tx_mem[tx_rp[3:0]], 1'b0, 4'd10, D1};
    else if (tx_bits != 0) begin
      if (tx_cnt != 0) tx_cnt <= tx_cnt - 1;
      else {tx_sh, tx_bits, tx_cnt} <= {1'b1, tx_sh[9:1], tx_bits - 4'd1, D1};
    end
  end
  // receiver: wait for a start bit, check it half a bit later, then sample each bit in its middle
  reg [1:0] rx_s = 2'b11;                      // synchroniser
  reg [1:0] rx_st = 0;                         // 0 idle, 1 start bit, 2 data, 3 stop bit
  reg [CW-1:0] rx_cnt = 0;
  reg [2:0] rx_bit = 0;
  reg [7:0] rx_sh = 0;
  wire rx_in = rx_s[1];
  wire rx_push = rx_st == 3 && rx_cnt == 0 && rx_in && !rx_full;
  always @(posedge clk) begin
    rx_s <= {rx_s[0], rx};
    if (rx_push) rx_mem[rx_wp[3:0]] <= rx_sh;
    if (rst || flush) {rx_wp, rx_rp} <= 0;
    else begin
      if (rx_push) rx_wp <= rx_wp + 1;
      if (rd && a && !rx_empty) rx_rp <= rx_rp + 1;
    end
    if (rst) rx_st <= 0;
    else case (rx_st)
      0: if (!rx_in) {rx_st, rx_cnt} <= {2'd1, DH};
      1: if (rx_cnt != 0) rx_cnt <= rx_cnt - 1;
         else if (!rx_in) {rx_st, rx_cnt, rx_bit} <= {2'd2, D1, 3'd0};
         else rx_st <= 0;                        // a glitch, not a start bit
      2: if (rx_cnt != 0) rx_cnt <= rx_cnt - 1;
         else begin
           {rx_sh, rx_cnt} <= {rx_in, rx_sh[7:1], D1};
           if (rx_bit == 7) rx_st <= 3; else rx_bit <= rx_bit + 1;
         end
      3: if (rx_cnt != 0) rx_cnt <= rx_cnt - 1;
         else rx_st <= 0;                        // pushed above if the stop bit is good
    endcase
  end
endmodule
