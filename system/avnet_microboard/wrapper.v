module wrapper
  (
   input         USER_RESET,
   output        SPI_SCK,
   output [0:0]  SPI_CS_n,
   inout         SPI_IO1,
   inout         SPI_IO2,
   inout         SPI_IO3,
   inout         SPI_IO4,
   input         USER_CLOCK,
   input         GPIO_DIP1,
   input         GPIO_DIP2,
   input         GPIO_DIP3,
   input         GPIO_DIP4,
   output [3:0]  GPIO_LED,
   input         USB_RS232_RXD,
   output        USB_RS232_TXD,
   inout         SCL,
   input         SDA,
   output [12:0] LPDDR_A,
   output [1:0]  LPDDR_BA,
   inout [15:0]  LPDDR_DQ,
   output        LPDDR_LDM,
   output        LPDDR_UDM,
   inout         LPDDR_LDQS,
   inout         LPDDR_UDQS,
   output        LPDDR_CK_N,
   output        LPDDR_CK_P,
   output        LPDDR_CKE,
   output        LPDDR_CAS_n,
   output        LPDDR_RAS_n,
   output        LPDDR_WE_n,
   output        LPDDR_RZQ,
   input         ETH_COL,
   input         ETH_CRS,
   input         ETH_MDC,
   input         ETH_MDIO,
   output        ETH_RESET_n,
   input         ETH_RX_CLK,
   input [3:0]   ETH_RX_D,
   input         ETH_RX_DV,
   input         ETH_RX_ER,
   input         ETH_TX_CLK,
   output [3:0]  ETH_TX_D,
   output        ETH_TX_EN
   );

   wire [7:0]    led;
   assign GPIO_LED = led[3:0];

   system #(
    .CLKSPEED(40000000),
    .BAUD(115200),
    .SEVEN_SEG_DUTY_CYCLE(7)
   ) system (
      .clk(USER_CLOCK),
      .sw({4'b0, GPIO_DIP4, GPIO_DIP3, GPIO_DIP2, GPIO_DIP1}),
      .led(led),
      .rxd(USB_RS232_RXD),
      .txd(USB_RS232_TXD),
      .seg(),
      .an(),
      .select(!USER_RESET)
    );

   // Sensible defaults for AVNet On-board peripherals
   
   assign SPI_SCK     = 1'b1;
   assign SPI_CS_n    = 1'b1;
   assign SPI_IO1     = 1'bz;
   assign SPI_IO2     = 1'bz;
   assign SPI_IO3     = 1'bz;
   assign SPI_IO4     = 1'bz;
   assign SCL         = 1'bz;
   assign LPDDR_A    = 13'b0;
   assign LPDDR_BA    = 1'b0;
   assign LPDDR_DQ   = 16'bz;
   assign LPDDR_LDM   = 1'b0;
   assign LPDDR_UDM   = 1'b0;
   assign LPDDR_LDQS  = 1'bz;
   assign LPDDR_UDQS  = 1'bz;
   assign LPDDR_CKE   = 1'b0;
   assign LPDDR_CAS_n = 1'b1;
   assign LPDDR_RAS_n = 1'b1;
   assign LPDDR_WE_n  = 1'b1;
   assign LPDDR_RZQ   = 1'bz;
   assign ETH_RESET_n = 1'b1;
   assign ETH_TX_D    = 4'bz;
   assign ETH_TX_EN   = 1'b0;
   
   OBUFDS LPDDR_CK_inst (
      .O(LPDDR_CK_P),  // Diff_p output (connect directly to top-level port)
      .OB(LPDDR_CK_N), // Diff_n output (connect directly to top-level port)
      .I(1'b0)
    );

endmodule

