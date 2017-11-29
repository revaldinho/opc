// ---------------------------------------------
// external memory controller
// ---------------------------------------------

// The CPU runs at ~50MHz (20ns)
//
// When accessing byte-wide external memory, sufficient wait states
// need to be added to allow two slower memory cycles to happen
// (low byte then high byte)
//
// IS61WV25616EDBLL-10TLI RAM timings:
// -- Read access time is 10ns
//
// -- Min write pulse is 8ns, write happens on rising edge
// -- Address setup from falling edge of write is 8ns
// -- Address hold from rising edge of write is 0ns
// -- Data setup from rising edge of write is 9ns
// -- Address hold from rising edge of write is 0ns
//
// To err on the safe side, we allow 2 cycles for each half-word access
//
// So a complete external memory access (both 16-bit half-words) takes 4 cycles
//
// Which means the memory controller must insert 3 wait states

module memory_controller
  (
   clock,
   reset_b,

   // CPU Signals
   ext_cs_b,
   cpu_rnw,
   cpu_clken,
   cpu_addr,
   cpu_dout,
   ext_dout,

   // Ram Signals
   ram_cs_b,
   ram_oe_b,
   ram_we_b,
   ram_data_in,
   ram_data_out,
   ram_data_oe,
   ram_addr
   );

   parameter DSIZE        = 32;
   parameter ASIZE        = 20;

   input                 clock;
   input                 reset_b;

   // CPU Signals
   input                 ext_cs_b;
   input                 cpu_rnw;
   output                cpu_clken;
   input [ASIZE-1:0]     cpu_addr;
   input [DSIZE-1:0]     cpu_dout;
   output [DSIZE-1:0]    ext_dout;

   // Ram Signals
   output                ram_cs_b;
   output                ram_oe_b;
   output                ram_we_b;
   output [17:0]         ram_addr;

   input  [15:0]         ram_data_in;
   output [15:0]         ram_data_out;
   output                ram_data_oe;

   wire                  ext_a_lsb;
   reg                   ext_we_b;
   reg [15:0]            ram_data_last;
   reg [1:0]             count;

   // Count 0..3 during external memory cycles
   always @(posedge clock)
     if (!reset_b)
       count <= 0;
     else if (!ext_cs_b || count > 0)
       count <= count + 1;

   // Drop clken for 3 cycles during an external memory access
   assign cpu_clken = !(!ext_cs_b && count < 3);

   // A0 = 0 for count 0,1 (low half-word) and A0 = 1 for count 2,3 (high half-word)
   assign ext_a_lsb = count[1];

   // Generate clean write co-incident with cycles 1 and 3
   // This gives a cycle of address/data setup and
   // Important this is a register so it is glitch free
   always @(posedge clock)
      if (!cpu_rnw && !ext_cs_b && !count[0])
         ext_we_b <= 1'b0;
      else
         ext_we_b <= 1'b1;

   // The low byte is registered at the end of cycle 1
   // The high byte is consumed directly from RAM at the end of cycle 3
   always @(posedge clock)
     if (count[0] == 1'b1)
       ram_data_last <= ram_data_in;

   assign ext_dout = { ram_data_in, ram_data_last };

   // ---------------------------------------------
   // external RAM
   // ---------------------------------------------

   assign ram_addr = {cpu_addr[16:0], ext_a_lsb};
   assign ram_cs_b = ext_cs_b;
   assign ram_oe_b = !cpu_rnw;
   assign ram_we_b = ext_we_b;

   assign ram_data_oe = !cpu_rnw;
   assign ram_data_out  = ext_a_lsb == 1 ? cpu_dout[31:16]  :
                                           cpu_dout[15:0]   ;

endmodule
