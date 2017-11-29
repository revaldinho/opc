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
   clock,
   reset_b,

   // CPU Signals
   ext_cs_b,
   vpa,
   cpu_rnw,
   cpu_clken,
   cpu_addr,
   cpu_dout,
   ext_dout,

   // Ram Signals
   ram_cs_b,
   ram_oe_b,
   ram_we_b,
   ram_data,
   ram_addr
   );

   parameter DSIZE        = 16;
   parameter ASIZE        = 16;
   parameter INDEX_BITS   = 6;    // Cache size is 2 ** INDEX_BITS

   localparam CSIZE       = clog2(DSIZE) - 1;   // 16->3, 32->4
   localparam TAG_BITS    = ASIZE - INDEX_BITS;
   localparam CACHE_WIDTH = DSIZE + 1 + TAG_BITS;
   localparam CACHE_SIZE  = 2 ** INDEX_BITS;

   input                 clock;
   input                 reset_b;

   // CPU Signals
   input                 ext_cs_b;
   input                 vpa;
   input                 cpu_rnw;
   output                cpu_clken;
   input [ASIZE-1:0]     cpu_addr;
   input [DSIZE-1:0]     cpu_dout;
   output [DSIZE-1:0]    ext_dout;

   // Ram Signals
   output                ram_cs_b;
   output                ram_oe_b;
   output                ram_we_b;
   inout [7:0]           ram_data;
   output [18:0]         ram_addr;


   wire [CSIZE - 3:0] ext_a_lsb;
   reg                ext_we_b;
   reg [DSIZE-8-1:0]  ram_data_last;
   reg [CSIZE-1:0]    count;

   // Simple 2^N-entry direct mapped instruction cache:
   // bits 15..0  == data (16 bits)
   // bits 16     == valid
   // bits 33-N..17 == tag (16 - N bits)
   reg [CACHE_WIDTH-1:0] cache [0:CACHE_SIZE - 1];  (* RAM_STYLE="DISTRIBUTED" *)
   wire [INDEX_BITS-1:0]  addr_index = cpu_addr[INDEX_BITS-1:0];
   wire [TAG_BITS-1:0]      addr_tag = cpu_addr[ASIZE-1:INDEX_BITS];

   wire [CACHE_WIDTH-1:0]  cache_out = cache[addr_index];

   wire [DSIZE-1:0]       cache_dout = cache_out[DSIZE-1:0];
   wire                  cache_valid = cache_out[DSIZE];
   wire [TAG_BITS-1:0]     cache_tag = cache_out[CACHE_WIDTH-1:DSIZE+1];
   wire                    tag_match = cache_valid & (cache_tag == addr_tag);
   wire                    cache_hit = vpa & tag_match;

   integer i;

   initial
     for (i = 0; i < CACHE_SIZE; i = i + 1)
       cache[i] = 0;

   always @(posedge clock)
      if (count == 2 ** CSIZE - 1)
         if (cpu_rnw) begin
            // Populate the cache at end of an instruction fetch from external memory
            if (vpa)
               cache[addr_index] <= {addr_tag, 1'b1, ext_dout};
         end else begin
            // Update the cache for consistecy if a cached instruction is overwritten
            if (tag_match)
               cache[addr_index] <= {addr_tag, 1'b1, cpu_dout};
         end

   // Count 0..7 during external memory cycles
   always @(posedge clock)
     if (!reset_b)
       count <= 0;
     else if (!ext_cs_b && !cache_hit || count > 0)
       count <= count + 1;

   // Drop clken for 7 cycles during an external memory access
   assign cpu_clken = !(!ext_cs_b && !cache_hit && count < 2 ** CSIZE - 1);

   // A0 = 0 for count 0,1,2,3 (low byte) and A0 = 1 for count 4,5,6,7 (high byte)
   assign ext_a_lsb = count[CSIZE - 1 : 2];

   // Generate clean write co-incident with cycles 1,2 and 5,6
   // This gives a cycle of address/data setup and
   // Important this is a register so it is glitch free
   always @(posedge clock)
      if (!cpu_rnw && !ext_cs_b && !count[1])
         ext_we_b <= 1'b0;
      else
         ext_we_b <= 1'b1;

   // The low byte is registered at the end of cycle 3
   // The high byte is consumed directly from RAM at the end of cycle 7
   always @(posedge clock)
     if (count[1:0] == 2'b11)
        ram_data_last <= (ram_data_last >> 8) | (ram_data << (DSIZE - 16));

   assign ext_dout = cache_hit ? cache_dout : { ram_data, ram_data_last };

// ---------------------------------------------
// external RAM
// ---------------------------------------------

   assign ram_addr = {cpu_addr, ext_a_lsb};
   assign ram_cs_b = ext_cs_b;
   assign ram_oe_b = !cpu_rnw;
   assign ram_we_b = ext_we_b;

   assign ram_data = cpu_rnw        ? 8'bZ            :
                     ext_a_lsb == 3 ? cpu_dout[31:24] :
                     ext_a_lsb == 2 ? cpu_dout[23:16] :
                     ext_a_lsb == 1 ? cpu_dout[15:8]  :
                                      cpu_dout[7:0]   ;

// ---------------------------------------------
// functions
// ---------------------------------------------

   function integer clog2;
      input integer value;
      begin
         value = value-1;
         for (clog2=0; value>0; clog2=clog2+1)
           value = value>>1;
      end
   endfunction

endmodule
