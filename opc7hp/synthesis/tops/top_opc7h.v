// OPC7 with separate instruction and data ports (opc7h) and 4K words of
// dual-port block RAM: the instruction port reads at iaddr, the data port
// reads and writes at address. Only the LEDs reach package pins (written by
// OUT), so the CPU's own ports need none.
// no_rw_check: the CPU never uses din in a write cycle, and only a store into
// the instruction being fetched in the same cycle would see the collision, so
// yosys need not emulate read-first and cross-port transparency (which doubled
// the memory to 16 DPB blocks and added about 50 DFFs).
module top(input clk, input rst_n, output reg [5:0] led);
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
  opc7hcpu cpu(.idin(idin), .din(din), .clk(clk), .reset_b(rst_n), .int_b(2'b11), .clken(1'b1), .vda(vda),
               .vio(vio), .dout(dout), .address(address), .rnw(rnw), .iaddr(iaddr), .ird(ird));
endmodule
