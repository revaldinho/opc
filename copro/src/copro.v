module copro (

   // GOP signals
   input            fastclk,
   output reg [8:2] tp,
   output reg [6:1] test,
// input [2:1]      sw,     // unused, commented out to avoid warnings
   output           fcs,

   // Tube signals (use 16 out of 22 DIL pins)
   input            h_phi2, // 1,2,12,21,23 are global clocks
   input [2:0]      h_addr,
   inout [7:0]      h_data,
   input            h_rdnw,
   input            h_cs_b,
   input            h_rst_b,
   inout            h_irq_b,

   // Ram Signals
   output           ram_cs_b,
   output           ram_oe_b,
   output           ram_we_b,
   inout [7:0]      ram_data,
   output [18:0]    ram_addr
);

`ifdef cpu_opc7
   parameter DSIZE   = 32;
   parameter ASIZE   = 20;
   parameter RAMSIZE = 12;
`else
   parameter DSIZE   = 16;
   parameter ASIZE   = 16;
   parameter RAMSIZE = 13;
`endif

// ---------------------------------------------
// clock and reset signals
// ---------------------------------------------

   wire             fx_clk;
   wire             cpu_clk;
   wire             rst_b;
   reg              rst_b_sync;

// ---------------------------------------------
// parasite wires
// ---------------------------------------------

   wire             p_cs_b;
   wire [7:0]       p_dout;

// ---------------------------------------------
// internal memory controller wires
// ---------------------------------------------

   wire             int_cs_b;
   wire [DSIZE-1:0] int_dout;

// ---------------------------------------------
// external memory controller wires
// ---------------------------------------------

   wire             ext_cs_b;
   wire [DSIZE-1:0] ext_dout;

// ---------------------------------------------
// cpu wires
// ---------------------------------------------

   wire             cpu_rnw;
   wire [ASIZE-1:0] cpu_addr;
   wire [DSIZE-1:0] cpu_din;
   wire [DSIZE-1:0] cpu_dout;
   wire             cpu_irq_b;
   reg              cpu_irq_b_sync;
   wire             cpu_clken;
   wire             cpu_mreq_b;
   wire             vpa;
   wire             vda;
   wire             vio;

// ---------------------------------------------
// clock generator
//
// fastclk = 49.152MHz
// cpu_clk = fast_clk * CLKFX_MULTIPLY / CLKFX_DIVIDE
//
// the minimum output clock speed is 18.00MHz
//
// the limit for this design is around 50MHz, as both
// edges of the clock are used.
// ---------------------------------------------

    DCM #(
        .CLKFX_MULTIPLY  (3),
        .CLKFX_DIVIDE    (3),
        .CLK_FEEDBACK    ("NONE")      // Used in DFS mode only
     ) inst_dcm (
        .CLKIN           (fastclk),
        .CLKFB           (1'b0),
        .RST             (1'b0),
        .DSSEN           (1'b0),
        .PSINCDEC        (1'b0),
        .PSEN            (1'b0),
        .PSCLK           (1'b0),
        .CLKFX           (fx_clk)
    );

   BUFG inst_bufg (.I(fx_clk), .O(cpu_clk));

// ---------------------------------------------
// main instantiated components
// ---------------------------------------------

   ram #
     (
      .DSIZE(DSIZE),
      .ASIZE(RAMSIZE)
     )
   inst_mem
     (
      .din        (cpu_dout),
      .dout       (int_dout),
      .address    (cpu_addr[RAMSIZE - 1:0]),
      .rnw        (cpu_rnw),
      .clk        (!cpu_clk),
      .cs_b       (int_cs_b)
      );

`ifdef cpu_opc7
   opc7cpu inst_cpu
     (
      .din        (cpu_din),
      .dout       (cpu_dout),
      .address    (cpu_addr),
      .rnw        (cpu_rnw),
      .clk        (cpu_clk),
      .reset_b    (rst_b_sync),
      .int_b      ({1'b1, cpu_irq_b_sync}),
      .clken      (cpu_clken),
      .vpa        (vpa),
      .vda        (vda),
      .vio        (vio)
    );
`else `ifdef cpu_opc6
   opc6cpu inst_cpu
     (
      .din        (cpu_din),
      .dout       (cpu_dout),
      .address    (cpu_addr),
      .rnw        (cpu_rnw),
      .clk        (cpu_clk),
      .reset_b    (rst_b_sync),
      .int_b      ({1'b1, cpu_irq_b_sync}),
      .clken      (cpu_clken),
      .vpa        (vpa),
      .vda        (vda),
      .vio        (vio)
    );

`else
   opc5lscpu inst_cpu
     (
      .din        (cpu_din),
      .dout       (cpu_dout),
      .address    (cpu_addr),
      .rnw        (cpu_rnw),
      .clk        (cpu_clk),
      .reset_b    (rst_b_sync),
      .int_b      (cpu_irq_b_sync),
      .clken      (cpu_clken),
      .vpa        (vpa),
      .vda        (vda)
    );
   // Fake vio, just at the UART address
   assign vio = vda && ({cpu_addr[15:3],  3'b000} == 16'hfef8);
`endif
`endif

`ifdef no_memory_controller
   assign ram_cs_b  = 1'b1;
   assign ram_oe_b  = 1'b1;
   assign ram_we_b  = 1'b1;
   assign ram_data  = 8'b0;
   assign ram_addr  = 19'b0;
   assign ext_dout  = 32'hAAAAAAAA;
   assign cpu_clken = 1'b1;
`else
   memory_controller #
     (
      .DSIZE(DSIZE),
      .ASIZE(ASIZE),
`ifdef cpu_opc7
      .INDEX_BITS(4) // 16 entry cache
`else
      .INDEX_BITS(6) // 64 entry cache
`endif
     )
   inst_memory_controller
     (
      .clock      (cpu_clk),
      .reset_b    (rst_b_sync),
      .vpa        (vpa),
      .ext_cs_b   (ext_cs_b),
      .cpu_rnw    (cpu_rnw),
      .cpu_clken  (cpu_clken),
      .cpu_addr   (cpu_addr),
      .cpu_dout   (cpu_dout),
      .ext_dout   (ext_dout),
      .ram_cs_b   (ram_cs_b),
      .ram_oe_b   (ram_oe_b),
      .ram_we_b   (ram_we_b),
      .ram_data   (ram_data),
      .ram_addr   (ram_addr)
      );
`endif

   tube inst_tube
     (
      .h_addr     (h_addr),
      .h_cs_b     (h_cs_b),
      .h_data     (h_data),
      .h_phi2     (h_phi2),
      .h_rdnw     (h_rdnw),
      .h_rst_b    (h_rst_b),
      .h_irq_b    (h_irq_b),
      .p_addr     (cpu_addr[2:0]),
      .p_cs_b     (p_cs_b),
      .p_data_in  (cpu_dout[7:0]),
      .p_data_out (p_dout),
      .p_rdnw     (cpu_rnw),
      .p_phi2     (cpu_clk),
      .p_rst_b    (rst_b),
      .p_nmi_b    (),
      .p_irq_b    (cpu_irq_b)
    );

// ---------------------------------------------
// address decode logic
// ---------------------------------------------

   assign cpu_mreq_b = !(vpa | vda);

   // Tube mapped to FEF8-FEFF
   assign p_cs_b   = !vio;

`ifdef cpu_opc7
   // Internal RAM mapped to 00000:00FFF
   assign int_cs_b = !((|cpu_addr[ASIZE-1:RAMSIZE] == 1'b0) && !cpu_mreq_b);
   // External RAM mapped to everywhere else
   assign ext_cs_b = !((|cpu_addr[ASIZE-1:RAMSIZE] == 1'b1) && !cpu_mreq_b);
`else
   // Internal RAM mapped to 0000:0FFF and F000:FFFF
   assign int_cs_b = !(((|cpu_addr[ASIZE-1:RAMSIZE-1] == 1'b0) || (&cpu_addr[ASIZE-1:RAMSIZE-1] == 1'b1)) && !cpu_mreq_b);
   // External RAM mapped to 1000:EFFF
   assign ext_cs_b = !(((|cpu_addr[ASIZE-1:RAMSIZE-1] == 1'b1) && (&cpu_addr[ASIZE-1:RAMSIZE-1] == 1'b0)) && !cpu_mreq_b);
`endif

   // Data multiplexor
   assign cpu_din  =  !p_cs_b ? p_dout : !int_cs_b ? int_dout : ext_dout;

// ---------------------------------------------
// synchronise interrupts
// ---------------------------------------------

   always @(posedge cpu_clk)
      begin
         rst_b_sync     <= rst_b;
         cpu_irq_b_sync <= cpu_irq_b;
      end

// ---------------------------------------------
// test outputs
// ---------------------------------------------

   always @(posedge cpu_clk)
      begin
         test[6] <= cpu_rnw;
         test[5] <= (cpu_addr == 16'hFEFF);
         test[4] <= cpu_irq_b_sync;
         test[3] <= p_cs_b;
         test[2] <= (cpu_addr == 16'hFEFE);
         test[1] <= rst_b;
         tp[8]   <= cpu_addr[6];
         tp[7]   <= cpu_addr[5];
         tp[6]   <= cpu_addr[4];
         tp[5]   <= cpu_addr[3];
         tp[4]   <= cpu_addr[2];
         tp[3]   <= cpu_addr[1];
         tp[2]   <= cpu_addr[0];
      end

// ---------------------------------------------
// unused outputs
// ---------------------------------------------

   assign fcs      = 1'b1;

endmodule
