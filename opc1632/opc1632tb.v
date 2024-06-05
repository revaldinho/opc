`timescale 1ns / 1ns
`define HALT 6'b10_0000
`define EXEC 3'b100
module opc6tb();
   reg [15:0] mem [ 65535:0 ], iomem[65535:0];
   reg        clk, rst_b, interrupt_b, int_clk, m1, clken;
   wire [31:0] addr;
   wire [15:0] data1;
   wire        rnw, vda, vpa;
   wire        ceb = 1'b0;
   wire        oeb = !rnw;
   reg [15:0]  data0 ;
   //IO space at 0x1xxxx
   wire          mreq_b = !((vda||vpa)&&(addr[16]==1'b1 ));
   integer       seed = 10;
   // OPC CPU instantiation
   opc1632cpu  dut0_u (.address(addr), .din(data0), .dout(data1), .rnw(rnw), .clk(clk), .rst_b(rst_b), .int_b({1'b1, interrupt_b}), .clken(clken), .vpa(vpa), .vda(vda));
   initial begin

`ifdef _dumpvcd
     $dumpvars;
`endif
     $readmemh("test.hex", mem); // Problems with readmemb - use readmemh for now
     iomem[16'hfe08] = 16'b0;
     { clk, int_clk, rst_b}  = 0;
     interrupt_b = 1;
     #3005 rst_b = 1;
     #50000000000000 ;  // no timeout
     $finish;
   end
  always @ (posedge clk or negedge rst_b)
    if ( !rst_b)
      m1 = 1'b0;
    else if (mreq_b == 1)
      m1 <= 0;
    else
      m1 <= !m1;
  always @ (negedge clk or negedge rst_b)
    if ( !rst_b)
      clken = 1'b1;
    else
      clken <= (mreq_b | m1 | !rst_b) ;

  always @ (posedge clk) begin
      if (!rnw && !ceb && oeb && rst_b)
        if ( !mreq_b) begin
          mem[addr] <= data1;
          $display(" STORE:  Address : 0x%08x ( %8d )  : Data : 0x%04x ( %d)",addr,addr,data1,data1);
        end
        else begin
          iomem[addr]<= data1;
          $display("   OUT:  Address : 0x%08x ( %8d )       :        Data : 0x%04x ( %6d) %c ",addr,addr,data1,data1,data1);
      end
      data0 <= (!mreq_b) ? mem[addr]: iomem[addr];
      if ( dut0_u.FSM_q == dut0_u.RD0 || dut0_u.FSM_q == dut0_u.RD1 || dut0_u.FSM_q == dut0_u.RDH )
        $display("  LOAD:  Address : 0x%04x ( %d )  : Data : 0x%04x ( %d)",addr,addr,data0,data0);

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

  always @ (negedge clk)    begin
    if ( dut0_u.FSM_q == dut0_u.EXEC ) begin
      $write("0x%08x : ", addr );
      $write(" : %08x %08x %08x %08x", dut0_u.RF_q[0],dut0_u.RF_q[1],dut0_u.RF_q[2],dut0_u.RF_q[3]);
      $write(" %08x %08x %08x %08x", dut0_u.RF_q[4],dut0_u.RF_q[5],dut0_u.RF_q[6],dut0_u.RF_q[7]);
      $write(" %08x %08x %08x %08x", dut0_u.RF_q[8],dut0_u.RF_q[9],dut0_u.RF_q[10],dut0_u.RF_q[11]);
      $write(" %08x %08x %08x %08x", dut0_u.RF_q[12],dut0_u.RF_q[13],dut0_u.RF_q[14],dut0_u.PC_q);
      $display("");
    end

    if (dut0_u.op_q== `HALT && dut0_u.FSM_q==`EXEC) begin
      $display("Simulation terminated with halt instruction at time", $time);
      $writememh("test.vdump",mem);
      $finish;
    end
  end
endmodule
