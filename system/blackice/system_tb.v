`timescale 1ns / 1ns

module system_tb();


   reg [15:0]  mem [ 0:262143 ];

   reg         clk;
   reg         reset_b = 1'b1;
   wire [17:0] addr;
   wire [15:0] data;
   wire [15:0] data_in;
   reg [15:0]  data_out;
   wire        ramwe_b;
   wire        ramoe_b;
   wire        ramcs_b;
   reg         rxd = 1'b1;
   wire        txd;

   integer     i, j;

   parameter  TEST_DATA_FILE = "test_data.mem";

   parameter  BITTIME = 1000000000 / 115200;

   reg [7:0]   test_data[ 0:1023 ];

   task serial_send_byte;
      input [7:0] byte;
      begin
         if (byte == 10)
           $display("%t: UART Rx:  <lf>", $time);
         else if (byte == 13)
           $display("%t: UART Rx:  <cr>", $time);
         else
           $display("%t: UART Rx:  %s", $time, byte);
         // start bit (0)
         #BITTIME rxd = 1'b0;
         // data bits, LSB first
         for (j = 0; j < 8; j = j + 1)
           #BITTIME rxd = byte[j];
         // stop bit (1)
         #BITTIME rxd = 1'b1;
      end
   endtask

system
   DUT
     (
      .clk100(clk),
      .sw4(reset_b),

      .RAMWE_b(ramwe_b),
      .RAMOE_b(ramoe_b),
      .RAMCS_b(ramcs_b),
      .ADR(addr),
      .DAT(data),

      .rxd(rxd),
      .txd(txd)
      );


   initial begin
      $timeformat(-6, 3, " us", 14);
      $dumpvars;
      // Initialize memory
      for (i = 0; i < 262144; i = i + 1)
        mem[i] = 0;

      // Load test data
      for (i = 0; i < 1024; i = i + 1)
        test_data[i] = 0;
      $readmemh(TEST_DATA_FILE, test_data);


      // initialize 100MHz clock
      clk = 1'b1;
      // external reset
      #1000
        reset_b = 1'b0;
      #1000
        reset_b = 1'b1;

      #(BITTIME * 10 * 30) ; // "OPC6 Monitor -"

      serial_send_byte("l");

      #(BITTIME * 10 * 50) ; // "Paste srecords followed by a blank line"

      // Send srecords
      i = 0;
      while (test_data[i] != 0) begin
         serial_send_byte(test_data[i]);
         i = i + 1;
      end
      serial_send_byte(13);
      serial_send_byte(13); // not sure why two blank lines are necessary

      #(BITTIME * 10 * 10) ; // "-"

      serial_send_byte("1");
      serial_send_byte("0");
      serial_send_byte("0");
      serial_send_byte("0");
      serial_send_byte("g");

      #10000000 // wait a further 10ms for the test program to run

      $finish;

   end

   always
     #5 clk = !clk;

   always @(posedge DUT.clk)
     if (DUT.cpuclken) begin
        if (DUT.vpa) begin
           $display("%t:  Fetch: %04x = %02x", $time, DUT.address, DUT.cpu_din);
        end else if (DUT.vda) begin
           if (DUT.rnw)
             $display("%t: Mem Rd: %04x = %02x", $time, DUT.address, DUT.cpu_din);
           else
             $display("%t: Mem Wr: %04x = %02x", $time, DUT.address, DUT.cpu_dout);
        end else if (DUT.vio) begin
           if (DUT.rnw)
             $display("%t:  IO Rd: %04x = %02x", $time, DUT.address, DUT.cpu_din);
           else
             $display("%t:  IO Wr: %04x = %02x", $time, DUT.address, DUT.cpu_dout);
        end
     end

   always @(posedge DUT.clk)
     if (DUT.cpuclken) begin
        if (DUT.vio && !DUT.rnw && DUT.address[15:0] == 16'hfe09)
          if (DUT.cpu_dout == 10)
            $display("%t: UART Tx:  <lf>", $time);
          else if (DUT.cpu_dout == 13)
            $display("%t: UART Tx:  <cr>", $time);
          else
            $display("%t: UART Tx:  %s", $time, DUT.cpu_dout);
     end
   
   assign data = (!ramcs_b && !ramoe_b && ramwe_b) ? data_out : 16'hZZZZ;

   // This seem a bit of a hack, but the memory write
   // was getting lost because the data was being tristated instantly
   assign #(1) data_in = data;

   always @(posedge ramwe_b)
     if (ramcs_b == 1'b0) begin
        mem[addr] <= data_in;
        $display("%t: Ram Wr: %04x = %02x", $time, addr, data_in);
     end

   always @(addr)
     data_out <= mem[addr];

endmodule
