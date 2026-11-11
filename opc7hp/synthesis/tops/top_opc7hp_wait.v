// opc7hp (pipelining work on opc7h) with separate instruction and data ports and 4K words of
// dual-port block RAM: the instruction port reads at iaddr, the data port
// reads and writes at address. Only the LEDs reach package pins (written by
// OUT), so the CPU's own ports need none.
// no_rw_check: the CPU never uses din in a write cycle, and only a store into
// the instruction being fetched in the same cycle would see the collision, so
// yosys need not emulate read-first and cross-port transparency (which doubled
// the memory to 16 DPB blocks and added about 50 DFFs).
// top_opc7hp_wait.v: the same with iwait and dwait from a free-running LFSR, so that synthesis
// keeps the stall logic: for measuring its cost (fmax_sweep.sh with TOP=). Not a working system.
module top(input clk, input rst_n, output reg [5:0] led);
  reg  [7:0]  lfsr = 8'h1;
  always @(posedge clk) lfsr <= {lfsr[6:0], lfsr[7]^lfsr[5]^lfsr[4]^lfsr[3]};
  wire [31:0] dout;
  wire [19:0] address, iaddr;
  wire        rnw, ird, vda, vio;
  (* no_rw_check *) reg [31:0] mem [0:4095];
  reg  [31:0] din, idin;
  always @(posedge clk) begin
    if (!rnw && !vio) mem[address[11:0]] <= dout;
    din <= mem[address[11:0]];
    if (!rnw && vio) led <= ~dout[5:0];
  end
  always @(posedge clk)
    idin <= mem[iaddr[11:0]];
  opc7hpcpu cpu(.idin(idin), .din(din), .clk(clk), .reset_b(rst_n), .int_b(2'b11), .clken(1'b1), .iwait(lfsr[0]), .dwait(lfsr[4]), .vda(vda),
               .vio(vio), .dout(dout), .address(address), .rnw(rnw), .iaddr(iaddr), .ird(ird));
endmodule
