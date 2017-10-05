module ram ( input [15:0] din, output [15:0] dout, input[11:0] address, input rnw, input clk, input cs_b);

`ifdef simulate   
 parameter MEM_INIT_FILE = "monitor.mem";
`else
 parameter MEM_INIT_FILE = "monitor_syn.mem";
`endif
   
   reg [15:0] ram [0:4095];
   reg [15:0] dout;

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
