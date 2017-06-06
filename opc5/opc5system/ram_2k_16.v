module ram ( inout[15:0] data, input[10:0] address, input rnw, input clk, input cs_b);

//   parameter MEM_INIT_FILE = "opc5monitor.init";
//
//   reg [15:0] ram [0:2047];
//   reg [15:0] dout;
//
//   initial begin
//      if (MEM_INIT_FILE != "") begin
//         $readmemh(MEM_INIT_FILE, ram);
//      end
//   end
//
//   always @(posedge clk)
//     if (!cs_b) begin
//        if (!rnw)
//          ram[address] <= data;
//        dout <= ram[address];
//     end

   wire en = !cs_b;
   wire we = !rnw;
   wire [15:0] dout;
   
   RAMB16_S9 ram0
     (
      .WE(we),
      .EN(en),
      .SSR(),        
      .CLK(clk),        
      .ADDR(address),        
      .DI(data[7:0]),        
      .DIP(1'b0),        
      .DO(dout[7:0]),        
      .DOP()
      );

   RAMB16_S9 ram1
     (
      .WE(we),
      .EN(en),
      .SSR(),        
      .CLK(clk),        
      .ADDR(address),        
      .DI(data[15:8]),        
      .DIP(1'b0),        
      .DO(dout[15:8]),        
      .DOP()
      );
           
   assign data = (!cs_b && rnw) ? dout : 16'bz;

endmodule
