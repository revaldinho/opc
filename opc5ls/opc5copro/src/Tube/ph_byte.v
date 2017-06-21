//**************************************************************************
//    ph_byte.v - single byte buffer for transfers in parasite to host direction
//   
//    COPYRIGHT 2010 Richard Evans, Ed Spittles
// 
//    This file is part of tube - an Acorn Tube ULA compatible system.
//   
//    tube is free software: you can redistribute it and/or modify
//    it under the terms of the GNU Lesser General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    tube is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU Lesser General Public License for more details.
//
//    You should have received a copy of the GNU Lesser General Public License
//    along with tube.  If not, see <http://www.gnu.org/licenses/>.
//
// **************************************************************************
`timescale 1ns / 1ns

module ph_byte (
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
   
   reg [7:0]           fifo_q_r ;
   wire [7:0]          fifo_d_r ;
      
   assign h_data = fifo_q_r;   
   assign fifo_d_r = ( p_selectData & !p_rdnw) ? p_data : fifo_q_r;   

   ph_flag_m flag_0 (
                       .rst_b(h_rst_b),
                       .p2_rdnw(h_rd),
                       .p2_select(h_selectData),
                       .p2_clk(h_phi2),
                       .p1_select(p_selectData),
                       .p1_rdnw(p_rdnw),
                       .p1_clk(p_phi2),                      
                       .p2_data_available(h_data_available),
                       .p1_full(p_full)
                       );
   
   // Infer all state
   always @ ( posedge p_phi2 or negedge h_rst_b )   
     begin
        if ( ! h_rst_b)
          fifo_q_r <= 8'h41;             
        else
          fifo_q_r <= fifo_d_r ;             
     end
   
endmodule // ph_byte

   