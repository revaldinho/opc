`timescale 1ns / 1ns
`define HALT 10'b00_0000_0000
`define EXEC 3'b100

module opc5lstb();
  reg [15:0] mem [ 65535:0 ];
  reg clk, reset_b, interrupt_b, int_clk;
  wire [15:0] addr;
  wire rnw ;
  wire ceb = 1'b0;
  wire oeb = !rnw;
  wire [15:0]  data0 = mem[addr];
  wire [15:0]  data1 ;
  integer seed = 10;

  // OPC CPU instantiation
  opc5lscpu  dut0_u (.address(addr), .din(data0), .dout(data1), .rnw(rnw), .clk(clk), .reset_b(reset_b), .int_b(interrupt_b));

  initial
    begin
      $dumpvars;
      $readmemh("test.hex", mem); // Problems with readmemb - use readmemh for now
      clk = 0;
      int_clk = 0;
      reset_b = 0;
      interrupt_b = 1;
      #1005 reset_b = 1;
      #500000000 $finish;
    end

  // Simple negedge synchronous memory to avoid messing with delays initially
  always @ (negedge clk)
    if (!rnw && !ceb && oeb && reset_b)
      mem[addr] <= data1;

  always @ (posedge int_clk)
    if ( (($random(seed) %100)> 90) && interrupt_b ==1'b1)
        interrupt_b = 1'b0;
    else
        interrupt_b = 1'b1;
  always
    begin
        #273 int_clk = !int_clk;
        #5000  int_clk = !int_clk;
    end

  always
    begin
      #500 clk = !clk;
      //$display("%4x %2x %x", dut0_u.PC_q, dut0_u.ACC_q, dut0_u.LINK_q);
    end

  // Always stop simulation on encountering the halt pseudo instruction
  always @ (negedge clk)
    if (dut0_u.IR_q[10:0]== `HALT && dut0_u.FSM_q==`EXEC)
      begin
        $display("Simulation terminated with halt instruction at time", $time);
        $writememh("test.vdump",mem);
        $finish;
      end
endmodule
