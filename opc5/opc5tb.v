`timescale 1ns / 1ns
`define HALT 16'b11x0_0000_0000_0000

module opc5tb();
  reg [15:0] mem [ 65535:0 ];
  reg clk, reset_b;

  wire [15:0] addr;
  wire rnw ;
  wire ceb = 1'b0;
  wire oeb = !rnw;
  wire [15:0]  data = ( !ceb & rnw & !oeb ) ? mem[ addr ] : 16'bz ;

  // OPC CPU instantiation
  opc5cpu  dut0_u (.address(addr), .data(data), .rnw(rnw), .clk(clk), .reset_b(reset_b));

  initial
    begin
      $dumpvars;
      $readmemh("test.hex", mem); // Problems with readmemb - use readmemh for now
      clk = 0;
      reset_b = 0;
      #1005 reset_b = 1;
      #180000000 $finish;
    end

  // Simple negedge synchronous memory to avoid messing with delays initially
  always @ (negedge clk)
    if (!rnw && !ceb && oeb && reset_b)
      mem[addr] <= data;

  always
    begin
      #500 clk = !clk;
      //$display("%4x %2x %x", dut0_u.PC_q, dut0_u.ACC_q, dut0_u.LINK_q);
    end

  // Always stop simulation on encountering the halt pseudo instruction
  always @ (negedge clk)
    if (dut0_u.IR_q[12:0]== `HALT[12:0])
      begin
        $display("Simulation terminated with halt instruction at time", $time);
        $writememh("test.vdump",mem);
        $finish;
      end
endmodule
