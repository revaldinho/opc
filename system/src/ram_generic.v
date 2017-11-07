module ram ( din, dout, address, rnw, clk, cs_b);

   parameter MEM_INIT_FILE = "";
   parameter DSIZE = 16;
   parameter ASIZE = 14;
   
   input [DSIZE - 1:0]   din;
   output [DSIZE - 1:0]  dout;
   input [ASIZE - 1:0]   address;
   input                 rnw;
   input                 clk;
   input                 cs_b;
      
   reg [DSIZE - 1:0] ram [0:2**ASIZE - 1];
   reg [DSIZE - 1:0] dout_r;
   
   initial begin
      if (MEM_INIT_FILE != "") begin
         $readmemh(MEM_INIT_FILE, ram);
      end
   end

   always @(posedge clk)
     if (!cs_b) begin
        if (!rnw)
          ram[address] <= din;
        dout_r <= ram[address];
     end

   assign dout = dout_r;
   
endmodule
