// opc7htb.v - opc/opc7/opc7tb.v adapted for opc7h CPUs (separate instruction
// port). idin is read from the same memory at iaddr, latched when ird is high.
// The CPU module is `CPU (default opc7hpcpu; iverilog -DCPU=opc7hcpu for the
// reference). Since mem_cs is only vda here, the write enable is latched
// every cycle (opc7tb.v latches it only when mem_cs is high, which with vpa
// was almost every cycle). Reads test.hex, as opc7tb.v does.
// -DTB_PIPE: the CPU has no state machine to look at (opc7hpcpu.v from the
// pipelining work); the halt and the retirement trace use its tb_halt,
// tb_retire, tb_retire_pc and tb_retire_word signals instead.
// -DWAIT_TEST (with TB_PIPE): random iwait and dwait, high in a cycle with probability +iwp and
// +dwp percent (+waitseed). The memory follows the CPU's port rules (see opc7hpcpu.v): a request
// is taken only in a cycle with its wait low, and idin and din are x while their wait is high.
`ifndef CPU
`define CPU opc7hpcpu
`endif
`timescale 1ns / 1ns
`define HALT 5'b1_0000
`define EXEC 3'b011
module opc7tb() ;  
  reg [31:0]  mem [ 1048575:0 ], iomem[65535:0];
  reg         clk, reset_b, interrupt_b, int_clk, clken;
  reg         iwait = 1'b0, dwait = 1'b0;
  reg 	      vio_q, vda_q, vpa_q, rnw_q;
  reg [19:0]  address_q, iaddr_q ;
  reg [31:0]  din_q;
  reg	      mem_cs_q;
  reg	      mem_we_q;  

  wire [19:0] address, iaddr;
  wire        ird;
  wire [31:0] idin = iwait ? 32'hxxxxxxxx : mem[iaddr_q];
  wire        rnw, vda, vpa, vio;
  wire [31:0] data0 ;
  wire [31:0] dout;
  integer     seed = 10;
  integer     memi;
  wire mem_cs  = vda;
  assign vpa = 1'b0;   // no vpa on opc7h
  wire mem_we  = !rnw;  
  
  assign data0 = dwait ? 32'hxxxxxxxx : (vio_q) ? iomem[address_q[15:0]] : mem[address_q];

  // Need to register the valid signals for controlling a mux for incoming data to CPU on the next clock edge
  always @ (posedge clk or negedge reset_b)
    if ( !reset_b ) begin
      {vio_q, vda_q, vpa_q, rnw_q}  <= 4'b0;
      address_q <= 20'h0; iaddr_q <= 20'h0;      
    end
    else begin	
      if (!dwait) begin {vio_q, vda_q, vpa_q, rnw_q} <= {vio, vda, vpa, rnw}; address_q <= address; end
      if (ird && !iwait) iaddr_q <= iaddr;
    end
  
  // OPC CPU instantiation
  `CPU  dut0_u (
                   .idin(idin), .iaddr(iaddr), .ird(ird),
                   .din(data0), 
                   .clk(clk), 
                   .reset_b(reset_b), 
                   .int_b({1'b1, interrupt_b}), 
                   .clken(clken), 
`ifdef TB_PIPE
                   .iwait(iwait), .dwait(dwait),
`endif
                   .address(address), 
                   .dout(dout), 
                   .rnw(rnw), 
                   .vda(vda), 
                   .vio(vio)
                   );
  
  initial begin
`ifdef _dumpvcd
    $dumpfile("test.vcd");
    $dumpvars;	
`endif
    for (memi = 0; memi < 1048576; memi = memi + 1) mem[memi] = 0;  // sparse hex files list only non-zero blocks
    $readmemh("test.hex", mem); // Problems with readmemb - use readmemh for now
    iomem[16'hfe08] = 32'h00000000; 
    { clk, int_clk, reset_b}  = 0;
    clken = 1'b1;
    interrupt_b = 1;
    #3005 reset_b = 1;
    #50000000000 ;  // no timeout
    $writememh("test.dump", mem);    
    $finish;    
  end

  always @ (posedge clk) begin
    if ( vio && reset_b && !rnw ) begin
      iomem[address[15:0]]<= dout;
      $display("   OUT :  Address : 0x%05x ( %6d )  : Data : 0x%08x ( %10d) %c ",address,address,dout,dout,dout);
    end    
  end
  
  always @ (posedge clk) begin
    // Latch all control and address signals on rising edge
    if (reset_b) begin   // every cycle: see the header
      mem_cs_q <= mem_cs;
      mem_we_q <= mem_we;
    end
    // Latch incoming data on rising edge
    if (mem_cs && mem_we && reset_b)
      din_q <= dout;
    // Write to RAM on next cycle - whole cycle to complete
    if (mem_cs_q && mem_we_q && reset_b ) begin
      mem[address_q] <= din_q;
      $display(" STORE :  Address : 0x%05x ( %6d )  : Data : 0x%08x ( %d)",address_q,address_q,din_q,din_q);       
    end      
    if ( vda_q )
      $display("  LOAD :  Address : 0x%05x ( %6d )  : Data : 0x%08x ( %d)",address_q,address_q,mem[address_q],mem[address_q]);
//    if ( vio_q && rnw_q)
//      $display("    IN :  Address : 0x%05x ( %6d )  : Data : 0x%08x ( %d)",address_q,address_q,iomem[address_q[15:0]],iomem[address_q[15:0]]);
//    else if ( vpa_q )
//      $display(" FETCH :  Address : 0x%05x ( %6d )  : Data : 0x%08x ( %d)",address_q,address_q,mem[address_q],mem[address_q]);    
  end

  always begin
    #500 clk = !clk;
  end
  
`ifdef RETIRE_TRACE
  // Retirement trace: one line per completed instruction, with its PC and
  // word, then the flags (V SWI EI S C Z) and r1-r14 as they are after it:
  //   RETIRE pc word : V SWI EI S C Z : r1 ... r14
  // Completion is taken from the opc7h state machine: the end of EXEC, the
  // end of WRM, or EAD when the predicate fails. A pipelined CPU needs its own
  // definition here. trace_compare.py checks the lines against opc7emu.py.
  // A line still pending at the halt is printed before the simulation stops.
  reg [19:0] tr_pc;
  reg [31:0] tr_word;
  reg        tr_pending = 1'b0;
  integer    tr_i;
  task tr_print; begin
    $write("RETIRE %08x %08x : %0d %1x %0d %0d %0d %0d :", tr_pc, tr_word,
           dut0_u.PSR_q[31], dut0_u.PSR_q[7:4], dut0_u.PSR_q[3], dut0_u.PSR_q[2], dut0_u.PSR_q[1], dut0_u.PSR_q[0]);
    for (tr_i = 1; tr_i < 15; tr_i = tr_i + 1) $write(" %08x", dut0_u.RF_q[tr_i]);
    $write("\n");
  end endtask
  always @(posedge clk) begin
    if (tr_pending) tr_print;
`ifdef TB_PIPE
    {tr_pc, tr_word} <= {dut0_u.tb_retire_pc, dut0_u.tb_retire_word};
    tr_pending <= reset_b && dut0_u.tb_retire;
`else
    if (reset_b && dut0_u.FSM_q == 3'h0) {tr_pc, tr_word} <= {dut0_u.PC_q, idin};   // FET: this instruction
    tr_pending <= reset_b && (dut0_u.FSM_q == 3'h3 || dut0_u.FSM_q == 3'h4 || (dut0_u.FSM_q == 3'h1 && dut0_u.FSM_d == 3'h0));
`endif
  end
`endif

  // Always stop simulation on encountering the halt pseudo instruction  
  always @ (clk) begin
`ifndef TB_PIPE
    if ( dut0_u.FSM_q == dut0_u.EAD ) begin
      
      $write("address=%05x IR_q=%02x DST_q=%02x SRC_Q=%02x OR_q=%08x ", address, dut0_u.IR_q,dut0_u.dst_q,dut0_u.src_q, dut0_u.OR_q);
      $write("psr=%04b result=%08x RF_pipe_q=%08x OR_d=%08x ", dut0_u.PSR_q[3:0], dut0_u.result, dut0_u.RF_pipe_q, dut0_u.OR_d);
//      $write(" : src=%x (%8x) PC_d=%05x PC_q=%05x", dut0_u.src_q, dut0_u.RF_sout, dut0_u.PC_d, dut0_u.PC_q);
//      $write(" vpa,q=%d%d ", vpa,vpa_q);
//      $write(" vda,q=%d%d ", vda,vda_q);      
//      $write(" vio,q=%d%d ", vio,vio_q);      
//      $write("\n R0=%08x R1=%08x R2=%08x R3=%08x", dut0_u.RF_q[0],dut0_u.RF_q[1],dut0_u.RF_q[2],dut0_u.RF_q[3]);
//      $write(" R4=%08x R5=%08x R6=%08x R7=%08x", dut0_u.RF_q[4],dut0_u.RF_q[5],dut0_u.RF_q[6],dut0_u.RF_q[7]);
//      $write(" R8=%08x R9=%08x R10=%08x R11=%08x", dut0_u.RF_q[8],dut0_u.RF_q[9],dut0_u.RF_q[10],dut0_u.RF_q[11]);    
//      $write(" R12=%08x R13=%08x R14=%08x R15=%08x", dut0_u.RF_q[12],dut0_u.RF_q[13],dut0_u.RF_q[14],dut0_u.PC_q);    
//      $write(" IOMEM[fe08]=%08x",iomem[16'hfe08]);
      $display("");
    end
`endif
`ifdef TB_PIPE
    if (dut0_u.tb_halt) begin
`else
    if (dut0_u.IR_q== `HALT && dut0_u.FSM_q==`EXEC) begin
`endif
`ifdef RETIRE_TRACE
      if (tr_pending) tr_print;
`endif
`ifdef INT_TEST
      $display("INTS %0d", dut0_u.RF_q[14]);
`endif
      $display("Simulation terminated with halt instruction at time", $time);       
      $writememh("test.dump", mem);
      $finish;
    end
  end

`ifdef WAIT_TEST
  integer iw_p = 0, dw_p = 0, w_seed = 1;
  initial begin
    if (!$value$plusargs("iwp=%d", iw_p)) iw_p = 0;
    if (!$value$plusargs("dwp=%d", dw_p)) dw_p = 0;
    if (!$value$plusargs("waitseed=%d", w_seed)) w_seed = 1;
  end
  always @ (negedge clk) begin
    iwait = ($unsigned($random(w_seed)) % 100) < iw_p;
    dwait = ($unsigned($random(w_seed)) % 100) < dw_p;
  end
`endif
`ifdef INT_TEST
  // -DINT_TEST: random hardware interrupts, one cycle long, on average one every
  // +intp cycles (0: none), with +intseed; int_check.sh uses this. The halt prints
  // r14, which its test program counts them in.
  integer int_period = 0, int_seed = 1;
  initial begin
    if (!$value$plusargs("intp=%d", int_period)) int_period = 0;
    if (!$value$plusargs("intseed=%d", int_seed)) int_seed = 1;
  end
  always @ (negedge clk)
    interrupt_b = !(reset_b && int_period != 0 && ($random(int_seed) % int_period) == 0);
`else
  always @ (posedge int_clk)
    if ( (($random(seed) %100)> 85) && interrupt_b ==1'b1)
      interrupt_b = 1'b1;
    else
      interrupt_b = 1'b1;
`endif
  always begin
    #273   int_clk = !int_clk;
    #5000  int_clk = !int_clk;
  end
endmodule
