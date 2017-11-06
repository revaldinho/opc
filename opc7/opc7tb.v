
`timescale 1ns / 1ns
`define HALT 5'b1_0000
`define EXEC 3'b011
module opc7tb(  ) ;
  
   reg [31:0] mem [ 1048575:0 ], iomem[65535:0];
   reg        clk, reset_b, interrupt_b, int_clk, clken;
   wire [19:0] addr;
   wire [31:0] data1;
   wire        rnw, vda, vpa, vio;
   wire        ceb = 1'b0;
   wire        oeb = !rnw;
   reg [31:0]  data0 ;
   wire          mreq_b = !(vda||vpa);
   integer       seed = 10;
   // OPC CPU instantiation
   opc7cpu  dut0_u (.address(addr), .din(data0), .dout(data1), .rnw(rnw), .clk(clk), .reset_b(reset_b), .int_b({1'b1, interrupt_b}), .clken(clken), .vpa(vpa), .vda(vda), .vio(vio));
   initial begin

`ifdef _dumpvcd
     $dumpfile("test.vcd")
     $dumpvars;
`endif
     $readmemh("test.hex", mem); // Problems with readmemb - use readmemh for now
     iomem[16'hfe08] = 16'b0; 
     { clk, int_clk, reset_b}  = 0;
     clken = 1'b1;
     interrupt_b = 1;
     #3005 reset_b = 1;
     #50000000000000 ;  // no timeout
     $finish;
   end

  always @ (negedge clk) begin
    if (!rnw && !ceb && oeb && reset_b)
      if ( !mreq_b) begin
        mem[addr&20'hFFFFF] <= data1;
        $display(" STORE :  Address : 0x%05x ( %d )  : Data : 0x%08x ( %d)",addr,addr,data1,data1);       
      end
      else begin
        iomem[addr]<= data1;
        $display("   OUT :  Address : 0x%04x ( %6d )       :        Data : 0x%08x ( %10d) %c ",addr,addr,data1,data1,data1);           
      end
    data0 = (!mreq_b) ? mem[addr&20'hFFFFF]: iomem[addr&16'hFFFF];    
    if ( dut0_u.FSM_q == dut0_u.RDM )
      $display("  LOAD :  Address : 0x%05x ( %d )  : Data : 0x%08x ( %d)",addr,addr,data0,data0);       

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
  
  always @ (negedge clk) begin
    if ( dut0_u.FSM_q == dut0_u.EAD ) begin
        $write("0x%05x : %02x%x%x %08x", addr, dut0_u.IR_q,dut0_u.dst_q,dut0_u.src_q, dut0_u.OR_q);
        $write(" : %04b : %03b : %08x = %08x op %08x ", dut0_u.PSR_q, dut0_u.pred, dut0_u.result, dut0_u.RF_pipe_q, dut0_u.OR_q);
        $write(" : src=%x (0x%8x) dst=%x (0x%8x)", dut0_u.src_q, dut0_u.RF_sout, dut0_u.dst_q, dut0_u.RF_pipe_q);
        
        $write(" : %08x %08x %08x %08x", dut0_u.RF_q[0],dut0_u.RF_q[1],dut0_u.RF_q[2],dut0_u.RF_q[3]);
        $write(" %08x %08x %08x %08x", dut0_u.RF_q[4],dut0_u.RF_q[5],dut0_u.RF_q[6],dut0_u.RF_q[7]);
        $write(" %08x %08x %08x %08x", dut0_u.RF_q[8],dut0_u.RF_q[9],dut0_u.RF_q[10],dut0_u.RF_q[11]);    
        $write(" %08x %08x %08x %08x", dut0_u.RF_q[12],dut0_u.RF_q[13],dut0_u.RF_q[14],dut0_u.PC_q);        
        $display("");
    end
    if (dut0_u.IR_q== `HALT && dut0_u.FSM_q==`EXEC) begin
      $display("Simulation terminated with halt instruction at time", $time);       
      $writememh("test.dump", mem);
      $finish;
    end
  end
  
endmodule
