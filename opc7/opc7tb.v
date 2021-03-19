`timescale 1ns / 1ns
`define HALT 5'b1_0000
`define EXEC 3'b011
module opc7tb() ;
  reg [31:0]  mem [ 1048575:0 ], iomem[65535:0];
  reg         clk, reset_b, interrupt_b, int_clk, clken;
  reg 	      vio_q, vda_q, vpa_q, rnw_q;
  reg [19:0]  address_q ;
  reg [31:0]  din_q;
  reg	      mem_cs_q;
  reg	      mem_we_q;

  wire [19:0] address;
  wire        rnw, vda, vpa, vio;
  wire [31:0] data0 ;
  wire [31:0] dout;
  integer     seed = 10;
  wire mem_cs  = vpa||vda;
  wire mem_we  = !rnw;

  assign data0 = (vio_q) ? iomem[address_q[15:0]] : mem[address_q];

  // Need to register the valid signals for controlling a mux for incoming data to CPU on the next clock edge
  always @ (posedge clk or negedge reset_b)
    if ( !reset_b ) begin
      {vio_q, vda_q, vpa_q, rnw_q}  <= 4'b0;
      address_q <= 20'h0;
    end
    else begin
      {vio_q, vda_q, vpa_q, rnw_q}  <= {vio, vda, vpa, rnw };
      address_q <= address;
    end

  // OPC CPU instantiation
  opc7cpu  dut0_u (
                   .din(data0),
                   .clk(clk),
                   .reset_b(reset_b),
                   .int_b({1'b1, interrupt_b}),
                   .clken(clken),
                   .address(address),
                   .dout(dout),
                   .rnw(rnw),
                   .vpa(vpa),
                   .vda(vda),
                   .vio(vio)
                   );

  initial begin
`ifdef _dumpvcd
    $dumpfile("test.vcd");
    $dumpvars;
`endif
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
    if (mem_cs && reset_b ) begin
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

  // Always stop simulation on encountering the halt pseudo instruction
  always @ (clk) begin
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
    if (dut0_u.IR_q== `HALT && dut0_u.FSM_q==`EXEC) begin
      $display("Simulation terminated with halt instruction at time", $time);
      $writememh("test.dump", mem);
      $finish;
    end
  end

  always @ (posedge int_clk)
    if ( (($random(seed) %100)> 85) && interrupt_b ==1'b1)
      interrupt_b = 1'b1;
    else
      interrupt_b = 1'b1;
  always begin
    #273   int_clk = !int_clk;
    #5000  int_clk = !int_clk;
  end
endmodule
