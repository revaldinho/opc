`timescale 1ns / 1ns
`define HALT 10'b00_0000_0000
`define EXEC 3'b100
module opc5lstb();
   reg [15:0] mem [ 65535:0 ];
   reg        clk, reset_b, interrupt_b, int_clk, m1, clken;
   wire [15:0] addr, data1;
   wire        rnw, vda, vpa;
   wire        ceb = 1'b0;
   wire        oeb = !rnw;
   reg [15:0]  data0 ;
   wire          mreq_b = !(vda||vpa);
   integer       seed = 10;
   // OPC CPU instantiation
   opc5lscpu  dut0_u (.address(addr), .din(data0), .dout(data1), .rnw(rnw), .clk(clk), .reset_b(reset_b), .int_b(interrupt_b), .clken(clken), .vpa(vpa), .vda(vda));
   initial begin
      $dumpvars;
      $readmemh("test.hex", mem); // Problems with readmemb - use readmemh for now
      { clk, int_clk, reset_b}  = 0;
`ifndef POSEDGE_MEMORY
      clken = 1'b1;
`endif
      interrupt_b = 1;
      #3005 reset_b = 1;
      #50000000000 $finish;
   end
   always @ (posedge clk or negedge reset_b)
     if ( !reset_b)
       m1 = 1'b0;
     else if (mreq_b == 1)
       m1 <= 0;
     else
       m1 <= !m1;
`ifdef POSEDGE_MEMORY
   always @ (negedge clk or negedge reset_b)
     if ( !reset_b)
       clken = 1'b1;
     else
       clken <= (mreq_b | m1 | !reset_b) ;
   always @ (posedge clk) begin
`else // Negedge memory
   always @ (negedge clk) begin
`endif
      if (!rnw && !ceb && oeb && reset_b)
        mem[addr] <= data1;
      data0 <= mem[addr];
   end
   always @ (posedge int_clk)
     if ( (($random(seed) %100)> 85) && interrupt_b ==1'b1)
       interrupt_b = 1'b0;
     else
       interrupt_b = 1'b1;
   always begin
      #273   int_clk = !int_clk;
      #5000  int_clk = !int_clk;
   end
   always begin
      #500 clk = !clk;
   end
   // Always stop simulation on encountering the halt pseudo instruction
   always @ (negedge clk)
     if (dut0_u.IR_q[10:0]== `HALT && dut0_u.FSM_q==`EXEC) begin
        $display("Simulation terminated with halt instruction at time", $time);
        $writememh("test.vdump",mem);
        $finish;
     end
endmodule
