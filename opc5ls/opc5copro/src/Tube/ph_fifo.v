`timescale 1ns / 1ns

module ph_fifo (
                input h_rst_b,
                input h_rd,
                input h_selectData,
                input h_phi2,
                input [7:0] p_data,                  
                input p_selectData,
                input p_phi2,
                input p_rdnw,
                output [7:0] h_data,                  
                output h_data_available,
                output p_full
                );
   
wire fifo_rst;
wire fifo_wr_clk; 
wire fifo_rd_clk; 
wire [7:0] fifo_din; 
wire fifo_wr_en; 
wire fifo_rd_en; 
wire [7:0] fifo_dout; 
wire fifo_full;
wire fifo_empty;

`ifdef SPARTAN3
ph_fifo_core_spartan3 ph_fifo_core (
`else
ph_fifo_core_spartan6 ph_fifo_core (
`endif
  .rst(fifo_rst),       // input rst
  .wr_clk(fifo_wr_clk), // input wr_clk
  .rd_clk(fifo_rd_clk), // input rd_clk
  .din(fifo_din),       // input [7 : 0] din
  .wr_en(fifo_wr_en),   // input wr_en
  .rd_en(fifo_rd_en),   // input rd_en
  .dout(fifo_dout),     // output [7 : 0] dout
  .full(fifo_full),     // output full
  .empty(fifo_empty)    // output empty
);

assign fifo_rst = ~h_rst_b;

// Parasite
assign fifo_din = p_data;
assign p_full = fifo_full;
assign fifo_wr_clk = p_phi2;
assign fifo_wr_en = p_selectData & ~p_rdnw;

// Host
assign fifo_rd_clk = ~h_phi2;
assign fifo_rd_en = h_selectData & h_rd;
assign h_data = fifo_empty ? 8'hAA : fifo_dout;
assign h_data_available = ~fifo_empty;

endmodule // ph_fifo

   
