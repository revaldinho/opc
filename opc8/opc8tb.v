
`timescale 1ns / 1ns
`define HALT 5'b0_0000
`define EXEC 3'b100
`define EAD  3'b010

module opc8tb(  ) ;
  
   reg [23:0] mem [ 16777215:0 ];
   reg        clk, reset_b, interrupt_b, int_clk, clken;
   wire [23:0] addr;
   wire [23:0] data1;
   wire        rnw, vda, vpa;
   wire        ceb = 1'b0;
   wire        oeb = !rnw;
   reg [23:0]  data0 ;
   wire          mreq_b = !(vda||vpa);
   integer       seed = 10;
   // OPC CPU instantiation
   opc8cpu  dut0_u (.address(addr), .din(data0), .dout(data1), .rnw(rnw), .clk(clk), .reset_b(reset_b), .int_b({1'b1, interrupt_b}), .clken(clken), .vpa(vpa), .vda(vda));
   initial begin

`ifdef _dumpvcd
     $dumpfile("test.vcd")
     $dumpvars;
`endif
     $readmemh("test.hex", mem); // Problems with readmemb - use readmemh for now
     { clk, int_clk, reset_b}  = 0;
     clken = 1'b1;
     interrupt_b = 1;
     #3005 reset_b = 1;
     #500000000 ;  // no timeout

     $finish;
   end

  always @ (negedge clk) begin
    if (!rnw && !ceb && oeb && reset_b)
      if ( !mreq_b) begin
        mem[addr&24'hFFFFFF] <= data1;
        $display(" STORE :  Address : 0x%06x ( %d )  : Data : 0x%06x ( %d)",addr,addr,data1,data1);       
      end
      else begin
        $display("   OUT :  Address : 0x%04x ( %6d )       :        Data : 0x%08x ( %10d) %c ",addr,addr,data1,data1,data1);             end

    data0 = (!mreq_b) ? mem[addr&24'hFFFFFF]: 24'bx ;  
    if ( dut0_u.FSM_q == dut0_u.RDM )
      $display("  LOAD :  Address : 0x%06x ( %d )  : Data : 0x%06x ( %d)",addr,addr,data0,data0);       

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
  
  // Always stop simulation on encountering the halt instruction  
  always @ (negedge clk) begin
    if ( dut0_u.FSM_q == dut0_u.EAD) begin
        $write("0x%06x : %02x %x %x %06x", addr, dut0_u.IR_q, dut0_u.dst_q,dut0_u.src_q, dut0_u.OR_q);
        $write(" : %04b : %03b : %06x = %06x op %06x ", dut0_u.PSR_q, dut0_u.pred, dut0_u.result, dut0_u.RF_pipe_q, dut0_u.OR_q);
        $write(" : src=%x (0x%6x) dst=%x (0x%6x)", dut0_u.src_q, dut0_u.RF_sout, dut0_u.dst_q, dut0_u.RF_pipe_q);
        $write(" : %06x %06x %06x %06x", dut0_u.RF_q[0],dut0_u.RF_q[1],dut0_u.RF_q[2],dut0_u.RF_q[3]);
        $write(" %06x %06x %06x %06x", dut0_u.RF_q[4],dut0_u.RF_q[5],dut0_u.RF_q[6],dut0_u.RF_q[7]);
        $write(" %06x %06x %06x %06x", dut0_u.RF_q[8],dut0_u.RF_q[9],dut0_u.RF_q[10],dut0_u.RF_q[11]);    
        $write(" %06x %06x %06x %06x", dut0_u.RF_q[12],dut0_u.RF_q[13],dut0_u.RF_q[14],dut0_u.PC_q);        
        $display("");
    end
    if (dut0_u.IR_q== `HALT && dut0_u.FSM_q==`EAD ) begin
      $display("Simulation terminated with halt instruction at time", $time);       
      $writememh("test.dump", mem);
      $finish;
    end
  end
  
endmodule
