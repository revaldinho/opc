// OPC7 with 4K words of block RAM for the hardware stats. Only the LEDs reach
// package pins (written by OUT), so the CPU's own ports need none.
module top(input clk, input rst_n, output reg [5:0] led);
  wire [31:0] dout;
  wire [19:0] address;
  wire        rnw, vpa, vda, vio;
  reg  [31:0] mem [0:4095];
  reg  [31:0] din;
  always @(posedge clk) begin
    if (!rnw && !vio) mem[address[11:0]] <= dout;
    din <= mem[address[11:0]];
    if (!rnw && vio) led <= ~dout[5:0];
  end
  opc7cpu cpu(.din(din), .clk(clk), .reset_b(rst_n), .int_b(2'b11), .clken(1'b1), .vpa(vpa), .vda(vda),
              .vio(vio), .dout(dout), .address(address), .rnw(rnw));
endmodule
