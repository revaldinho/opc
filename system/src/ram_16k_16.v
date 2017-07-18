module ram ( input[15:0] din, output reg [15:0] dout, input[13:0] address, input rnw, input clk, input cs_b);

   parameter MEM_INIT_FILE = "";

   reg [15:0] ram [0:16383];

   initial begin
      if (MEM_INIT_FILE != "") begin
         $readmemh(MEM_INIT_FILE, ram);
      end
   end

   always @(posedge clk)
     if (!cs_b) begin
        if (!rnw)
          ram[address] <= din;
        dout <= ram[address];
     end
           
endmodule
