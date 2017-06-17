module opc5copro (

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

// ---------------------------------------------
// clock and reset signals
// ---------------------------------------------

   wire             clk_fx;
   wire             clk_cpu;
   wire             RSTn;
   reg              RSTn_sync;

// ---------------------------------------------
// parasite wires
// ---------------------------------------------

   wire             p_cs_b;
   wire [7:0]       p_data_out;

// ---------------------------------------------
// internal memory controller wires
// ---------------------------------------------

   wire             int_cs_b;
   wire [15:0]      int_data_out;

// ---------------------------------------------
// external memory controller wires
// ---------------------------------------------

   wire             ext_cs_b;
   wire             ext_a0;
   reg              ext_we_b;
   reg [7:0]        ram_data_last;
   reg [2:0]        count;

// ---------------------------------------------
// cpu wires
// ---------------------------------------------

   wire             cpu_R_W_n;
   wire [15:0]      cpu_addr;
   wire [15:0]      cpu_din;
   wire [15:0]      cpu_dout;
   wire             cpu_IRQ_n;
   reg              cpu_IRQ_n_sync;
   wire             cpu_clken;
   wire             cpu_mreq_b;

// ---------------------------------------------
// clock generator
//
// fastclk = 49.152MHz
// clk_cpu = fast_clk * CLKFX_MULTIPLY / CLKFX_DIVIDE
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
        .CLKFX           (clk_fx)
    );

   BUFG inst_bufg (.I(clk_fx), .O(clk_cpu));

// ---------------------------------------------
// main instantiated components
// ---------------------------------------------

   ram inst_mem
     (
      .din        (cpu_dout),
      .dout       (int_data_out),
      .address    (cpu_addr[12:0]),
      .rnw        (cpu_R_W_n),
      .clk        (!clk_cpu),
      .cs_b       (int_cs_b)
      );

   opc5lscpu inst_opc5ls
     (
      .din        (cpu_din),
      .dout       (cpu_dout),
      .address    (cpu_addr),
      .rnw        (cpu_R_W_n),
      .clk        (clk_cpu),
      .reset_b    (RSTn_sync),
      .int_b      (cpu_IRQ_n_sync),
      .clken      (cpu_clken),
      .mreq_b     (cpu_mreq_b),
      .sync       ()
    );

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
      .p_data_out (p_data_out),
      .p_rdnw     (cpu_R_W_n),
      .p_phi2     (clk_cpu),
      .p_rst_b    (RSTn),
      .p_nmi_b    (),
      .p_irq_b    (cpu_IRQ_n)
    );

// ---------------------------------------------
// address decode logic
// ---------------------------------------------

   // Tube mapped to FEF8-FEFF
   assign p_cs_b   = !((cpu_addr[15:3] == 13'b1111111011111) && !cpu_mreq_b);

   // Internal RAM mapped to 0000:0FFF and F000:FFFF
   assign int_cs_b = !(((cpu_addr[15:12] == 4'h0) || (cpu_addr[15:12] == 4'hF)) && !cpu_mreq_b);

   // External RAM mapped to 1000:EFFF
   assign ext_cs_b = !(((cpu_addr[15:12] > 4'h0) && (cpu_addr[15:12] < 4'hF)) && !cpu_mreq_b);

// ---------------------------------------------
// external memory controller
// ---------------------------------------------

   // The CPU runs at ~50MHz (20ns)
   //
   // When accessing byte-wide external memory, sufficient wait states
   // need to be added to allow two slower memory cycles to happen
   // (low byte then high byte)
   //
   // R1LV0408CSA-5SC RAM timings:
   // -- Read access time is 55ns
   //
   // -- Min write pulse is 40ns, write happens on rising edge
   // -- Address setup from falling edge of write is 0ns
   // -- Address hold from rising edge of write is 0ns
   // -- Data setup from rising edge of write is 25ns
   // -- Address hold from rising edge of write is 0ns
   //
   // To err on the safe side, we allow 4 cycles for each byte access
   //
   // So a complete external memory access (both bytes) takes 8 cycles
   //
   // Which means the memory controller must insert 7 wait stats

   // Count 0..7 during external memory cycles
   always @(posedge clk_cpu)
     if (!RSTn_sync)
       count <= 0;
     else if (!ext_cs_b || count > 0)
       count <= count + 1;

   // Drop clken for 7 cycles during an external memory access
   assign cpu_clken = !(!ext_cs_b && count < 7);

   // A0 = 0 for count 0,1,2,3 (low byte) and A0 = 1 for count 4,5,6,7 (high byte)
   assign ext_a0 = count[2];

   // Generate clean write co-incident with cycles 1,2 and 5,6
   // This gives a cycle of address/data setup and
   // Important this is a register so it is glitch free
   always @(posedge clk_cpu)
      if (!cpu_R_W_n && ((count == 0 && !ext_cs_b) || (count == 1) || count == 4 || count == 5))
         ext_we_b <= 1'b0;
      else
         ext_we_b <= 1'b1;

   // The low byte is registered at the end of cycle 3
   // The high byte is consumed directly from RAM at the end of cycle 7
   always @(posedge clk_cpu)
     if (count == 3)
        ram_data_last <= ram_data;

   // Data multiplexor
   assign cpu_din  =  !p_cs_b ? p_data_out : !int_cs_b ? int_data_out : {ram_data, ram_data_last};

// ---------------------------------------------
// external RAM
// ---------------------------------------------

   assign ram_addr = {2'b0, cpu_addr, ext_a0};
   assign ram_cs_b = ext_cs_b;
   assign ram_oe_b = !cpu_R_W_n;
   assign ram_we_b = ext_we_b;
   assign ram_data = cpu_R_W_n ? 8'bZ : ext_a0 ? cpu_dout[15:8] : cpu_dout[7:0];

// ---------------------------------------------
// synchronise interrupts
// ---------------------------------------------

   always @(posedge clk_cpu)
      begin
         RSTn_sync      <= RSTn;
         cpu_IRQ_n_sync <= cpu_IRQ_n;
      end

// ---------------------------------------------
// test outputs
// ---------------------------------------------

   always @(posedge clk_cpu)
      begin
         test[6] <= cpu_R_W_n;
         test[5] <= (cpu_addr == 16'hFEFF);
         test[4] <= cpu_IRQ_n_sync;
         test[3] <= p_cs_b;
         test[2] <= (cpu_addr == 16'hFEFE);
         test[1] <= RSTn;
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
