module uart ( inout[15:0] data, input a0, input rnw, input clk, input reset_b, input cs_b, output txd);

   // DIVISOR is the number of clk cycles per bit time
   parameter DIVISOR = 32000000 / 115200;

   // Registers
   reg [8:0]  tx_bit_cnt;
   reg [10:0] tx_shift_reg;

   // Assignments
   assign tx_busy = tx_shift_reg != 11'b1;
   assign data = (!cs_b && rnw) ? (a0 ? {16'hAAAA} : { tx_busy, 15'b0}) : 16'bz;

   // UART Transmitter
   always @ (posedge clk)
     if (!reset_b) begin
        tx_shift_reg <= 11'b1;
     end else if (tx_busy) begin
        if (tx_bit_cnt == 0) begin
           tx_shift_reg <= {1'b0 , tx_shift_reg[10:1]};
           tx_bit_cnt <= DIVISOR - 1;
        end else begin
           tx_bit_cnt <= tx_bit_cnt - 1;
        end
     end else if (!cs_b && !rnw && a0) begin
        tx_shift_reg <= {2'b11, data[7:0], 1'b0};
        tx_bit_cnt <= DIVISOR - 1;
     end
   assign txd = tx_shift_reg[0];

endmodule
