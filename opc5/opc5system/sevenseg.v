module sevenseg(input [15:0] value, input clk, output reg [3:0] an, output [6:0] seg);

   // Duty Cycle controls the brightness of the seven segment display (0..15)
   parameter SEVEN_SEG_DUTY_CYCLE = 0;
   
   reg [15:0]   counter;
   reg [3:0]    binary;
   reg [6:0]    sseg;

   always @(posedge clk) begin
      counter <= counter + 1;
      // important to enable anode with a low duty cycle, as no resistors!
      if (counter[13:10] <= SEVEN_SEG_DUTY_CYCLE) begin
         case (counter[15:14])
           2'b00:
             { an[0], binary} <= {1'b0, value[15:12]};
           2'b01:
             { an[1], binary} <= {1'b0, value[11:8]};
           2'b10:
             { an[2], binary} <= {1'b0, value[7:4]};
           2'b11:
             { an[3], binary} <= {1'b0, value[3:0]};
         endcase
      end else begin
         an <= 4'b1111;
      end
   end

   always @(binary)
     case (binary)
       4'b0000 :
         sseg <= 7'b1111110; // ABCDEFG
       4'b0001 :
         sseg <= 7'b0110000;
       4'b0010 :
         sseg <= 7'b1101101;
       4'b0011 :
         sseg <= 7'b1111001;
       4'b0100 :
         sseg <= 7'b0110011;
       4'b0101 :
         sseg <= 7'b1011011;
       4'b0110 :
         sseg <= 7'b1011111;
       4'b0111 :
         sseg <= 7'b1110000;
       4'b1000 :
         sseg <= 7'b1111111;
       4'b1001 :
         sseg <= 7'b1111011;
       4'b1010 :
         sseg <= 7'b1110111;
       4'b1011 :
         sseg <= 7'b0011111;
       4'b1100 :
         sseg <= 7'b1001110;
       4'b1101 :
         sseg <= 7'b0111101;
       4'b1110 :
         sseg <= 7'b1001111;
       4'b1111 :
         sseg <= 7'b1000111;
     endcase

   // segements are active low
   assign seg = sseg ^ 7'b1111111;

endmodule
