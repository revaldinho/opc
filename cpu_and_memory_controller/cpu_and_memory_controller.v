module cpu_and_memory_controller
  (
   input         clk,
   input         reset_b,
   input         int_b,
   output        vpa,
   output        vda, 

   // Ram Signals
   output        ram_cs_b,
   output        ram_oe_b,
   output        ram_we_b,
   inout [7:0]   ram_data,
   output [18:0] ram_addr
);


// ---------------------------------------------
// cpu wires
// ---------------------------------------------

   wire          cpu_clken;
   wire          cpu_rnw;
   wire [15:0]   cpu_addr;
   wire [15:0]   cpu_din;
   wire [15:0]   cpu_dout;
   wire          cpu_mreq_b = !(vpa | vda);

   
   opc5lscpu inst_opc5ls
     (
      .din        (cpu_din),
      .dout       (cpu_dout),
      .address    (cpu_addr),
      .rnw        (cpu_rnw),
      .clk        (clk),
      .reset_b    (reset_b),
      .int_b      (int_b),
      .clken      (cpu_clken),
      .vpa        (vpa),
      .vda        (vda)
    );

   memory_controller inst_memory_controller
     (
      .clock      (clk),
      .reset_b    (reset_b),
      .vpa        (vpa),
      .ext_cs_b   (cpu_mreq_b),
      .cpu_rnw    (cpu_rnw),
      .cpu_clken  (cpu_clken),
      .cpu_addr   (cpu_addr),
      .cpu_dout   (cpu_dout),
      .ext_dout   (cpu_din),
      .ram_cs_b   (ram_cs_b),
      .ram_oe_b   (ram_oe_b),
      .ram_we_b   (ram_we_b),
      .ram_data   (ram_data),
      .ram_addr   (ram_addr)
      );


endmodule
