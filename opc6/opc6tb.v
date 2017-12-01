`timescale 1ns / 1ns
`define HALT 10'b00_0000_0000
`define EXEC 3'b100
module opc6tb();
   reg [15:0] mem [ 65535:0 ], iomem[65535:0];
   reg        clk, reset_b, interrupt_b, int_clk, m1, clken;
   wire [15:0] addr, data1;
   wire        rnw, vda, vpa, vio;
   wire        ceb = 1'b0;
   wire        oeb = !rnw;
   reg [15:0]  data0 ;
   wire          mreq_b = !(vda||vpa);
   integer       seed = 10;
   // OPC CPU instantiation
   opc6cpu  dut0_u (.address(addr), .din(data0), .dout(data1), .rnw(rnw), .clk(clk), .reset_b(reset_b), .int_b({1'b1, interrupt_b}), .clken(clken), .vpa(vpa), .vda(vda), .vio(vio));
   initial begin

`ifdef _dumpvcd
     $dumpvars;
`endif
     $readmemh("test.hex", mem); // Problems with readmemb - use readmemh for now
     iomem[16'hfe08] = 16'b0; 
     { clk, int_clk, reset_b}  = 0;
`ifndef POSEDGE_MEMORY
      clken = 1'b1;
`endif
     interrupt_b = 1;
     #3005 reset_b = 1;
     #50000000000000 ;  // no timeout
     $finish;
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
        if ( !mreq_b) begin
          mem[addr] <= data1;
          $display(" STORE:  Address : 0x%04x ( %d )  : Data : 0x%04x ( %d)",addr,addr,data1,data1);
        end
        else begin  
          iomem[addr]<= data1;    
          $display("   OUT:  Address : 0x%04x ( %6d )       :        Data : 0x%04x ( %6d) %c ",addr,addr,data1,data1,data1);
      end
      data0 <= (!mreq_b) ? mem[addr]: iomem[addr];
      if ( dut0_u.FSM_q == dut0_u.RDM )
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
      $write("0x%04x : ", addr );      
      $write(" : %04x %04x %04x %04x", dut0_u.RF_q[0],dut0_u.RF_q[1],dut0_u.RF_q[2],dut0_u.RF_q[3]);
      $write(" %04x %04x %04x %04x", dut0_u.RF_q[4],dut0_u.RF_q[5],dut0_u.RF_q[6],dut0_u.RF_q[7]);
      $write(" %04x %04x %04x %04x", dut0_u.RF_q[8],dut0_u.RF_q[9],dut0_u.RF_q[10],dut0_u.RF_q[11]);    
      $write(" %04x %04x %04x %04x", dut0_u.RF_q[12],dut0_u.RF_q[13],dut0_u.RF_q[14],dut0_u.PC_q);        
      $display("");
    end
    
    if (dut0_u.IR_q[10:0]== `HALT && dut0_u.FSM_q==`EXEC) begin
      $display("Simulation terminated with halt instruction at time", $time);       
      $writememh("test.vdump",mem);
      $finish;
    end
  end
endmodule
