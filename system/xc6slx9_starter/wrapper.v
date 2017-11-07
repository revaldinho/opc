module wrapper ( input clk, input[7:0] sw, output[7:0] led, input rxd, output txd,
                     output [6:0] seg, output [3:0] an, input select);

   system #(
    .CLKSPEED(50000000),
    .BAUD(115200),
    .SEVEN_SEG_DUTY_CYCLE(7)
   ) system (
      .clk(clk),
      .sw(sw),
      .led(led),
      .rxd(rxd),
      .txd(txd),
      .seg(seg),
      .an(an),
      .select(!select)
    );

endmodule
