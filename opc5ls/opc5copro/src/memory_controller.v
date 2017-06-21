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
// Which means the memory controller must insert 7 wait states

module memory_controller
  (
   input         clock,
   input         reset_b,

   // CPU Signals
   input         ext_cs_b,
   input         cpu_rnw,
   output        cpu_clken,
   input [15:0]  cpu_addr,
   input [15:0]  cpu_dout,
   output [15:0] ext_dout,

   // Ram Signals
   output        ram_cs_b,
   output        ram_oe_b,
   output        ram_we_b,
   inout [7:0]   ram_data,
   output [18:0] ram_addr

   );

   wire          ext_a0;
   reg           ext_we_b;
   reg [7:0]     ram_data_last;
   reg [2:0]     count;

   // Count 0..7 during external memory cycles
   always @(posedge clock)
     if (!reset_b)
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
   always @(posedge clock)
      if (!cpu_rnw && ((count == 0 && !ext_cs_b) || (count == 1) || count == 4 || count == 5))
         ext_we_b <= 1'b0;
      else
         ext_we_b <= 1'b1;

   // The low byte is registered at the end of cycle 3
   // The high byte is consumed directly from RAM at the end of cycle 7
   always @(posedge clock)
     if (count == 3)
        ram_data_last <= ram_data;

   assign ext_dout = { ram_data, ram_data_last };

// ---------------------------------------------
// external RAM
// ---------------------------------------------

   assign ram_addr = {2'b0, cpu_addr, ext_a0};
   assign ram_cs_b = ext_cs_b;
   assign ram_oe_b = !cpu_rnw;
   assign ram_we_b = ext_we_b;
   assign ram_data = cpu_rnw ? 8'bZ : ext_a0 ? cpu_dout[15:8] : cpu_dout[7:0];

endmodule
