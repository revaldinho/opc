module ram_2k_16 ( inout[15:0] data, input[10:0] address, input rnw, input clk, input cs_b);

   parameter MEM_INIT_FILE = "opc5monitor.init";

   reg [15:0] ram [0:2047];
   reg [15:0] dout;

   initial begin
      if (MEM_INIT_FILE != "") begin
         $readmemh(MEM_INIT_FILE, ram);
      end
   end

   always @(posedge clk)
     if (!cs_b) begin
        if (!rnw)
          // 0x0000-0x07FF is read only
          // 0x0800-0x0FFF is read/write
          if (address[10])
            ram[address] <= data;
        dout <= ram[address];
     end
   
   assign data = (!cs_b && rnw) ? dout : 16'bz;

endmodule
