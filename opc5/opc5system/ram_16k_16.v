module ram ( inout[15:0] data, input[13:0] address, input rnw, input clk, input cs_b);

   wire en = !cs_b;
   wire we = !rnw;
     
   parameter MEM_INIT_FILE = "";

   reg [15:0] ram [0:16383];
   reg [15:0] dout;

   initial begin
      if (MEM_INIT_FILE != "") begin
         $readmemh(MEM_INIT_FILE, ram);
      end
   end

   always @(posedge clk)
     if (!cs_b) begin
        if (!rnw)
          ram[address] <= data;
        dout <= ram[address];
     end
           
   assign data = (!cs_b && rnw) ? dout : 16'bz;

endmodule
