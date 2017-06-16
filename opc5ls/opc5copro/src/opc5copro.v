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
   output           ram_cs,
   output           ram_oe,
   output           ram_wr,
// inout [7:0]      ram_data, // unused, commented out to avoid warnings
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
// internal memory wires
// ---------------------------------------------

   wire             mem_cs_b;
   wire [15:0]      mem_data_out;

// ---------------------------------------------
// cpu wires
// ---------------------------------------------

   wire             cpu_R_W_n;
   wire [15:0]      cpu_addr;
   wire [15:0]      cpu_din;
   wire [15:0]      cpu_dout;
   wire             cpu_IRQ_n;
   reg              cpu_IRQ_n_sync;

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
      .dout       (mem_data_out),
      .address    (cpu_addr[12:0]),
      .rnw        (cpu_R_W_n),
      .clk        (!clk_cpu),
      .cs_b       (mem_cs_b)
      );

   opc5lscpu inst_opc5ls
     (
      .din        (cpu_din),
      .dout       (cpu_dout),
      .address    (cpu_addr),
      .rnw        (cpu_R_W_n),
      .clk        (clk_cpu),
      .reset_b    (RSTn_sync),
      .int_b      (cpu_IRQ_n_sync)
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
// logic
// ---------------------------------------------

   assign p_cs_b   = !(cpu_addr[15:3] == 13'b1111111011111);

   assign mem_cs_b = !p_cs_b;

   assign cpu_din  =  !p_cs_b ? p_data_out : !mem_cs_b ? mem_data_out : 16'hAAAA;

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

   assign ram_cs   = 1'b1;
   assign ram_oe   = 1'b1;
   assign ram_wr   = 1'b0;
   assign ram_addr = 19'b0;
   assign fcs      = 1'b1;

endmodule
