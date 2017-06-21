//**************************************************************************
//    ph_bytequad.v - wrapper for 4 FIFOs in the parasite to host direction
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
// ============================================================================
`timescale 1ns / 1ns

module ph_bytequad (
                    input h_rst_b,
                    input h_rd,
                    input [3:0] h_selectData,
                    input h_phi2,
                    
                    input [7:0] p_data,                  
                    input [3:0] p_selectData,
                    input p_phi2,
                    input p_rdnw,
                    input one_byte_mode,
                    output ph_zero_r3_bytes_avail,
                    output [7:0] h_data,                  
                    output [3:0] h_data_available,
                    output [3:0] p_full
                    );
   
   reg [7:0]  h_datamux_r;           
   wire [3:0] p_full_pre_w;
   wire [7:0] fifo0_w,
              fifo1_w,
              fifo2_w,
              fifo3_w;   
   
   // assign primary IOs
   assign h_data = h_datamux_r;   
   assign p_full = p_full_pre_w;

   // Combinatorial selection of data output
   always @ (fifo0_w or
             fifo1_w or
             fifo2_w or
             fifo3_w or
             h_selectData
             )
     casex (h_selectData)
       4'bxxx1: h_datamux_r = fifo0_w;
       4'bxx1x: h_datamux_r = fifo1_w;
       4'bx1xx: h_datamux_r = fifo2_w;
       4'b1xxx: h_datamux_r = fifo3_w;
       default: h_datamux_r = 8'bx;
     endcase // case h_selectData

   
   ph_fifo    ph_reg1 ( 
                        .h_rst_b(h_rst_b),
                        .h_rd(h_rd),
                        .h_selectData(h_selectData[0]),
                        .h_phi2(h_phi2),
                        .p_selectData(p_selectData[0]),
                        .p_phi2(p_phi2),
                        .p_rdnw(p_rdnw),
                        .p_data(p_data),
                        .h_data(fifo0_w),
                        .h_data_available(h_data_available[0]),
                        .p_full(p_full_pre_w[0])
                       ); 
   
   
   ph_byte    ph_reg2 (
                       .h_rst_b(h_rst_b),
                       .h_rd(h_rd),
                       .h_selectData(h_selectData[1]),
                       .h_phi2(h_phi2),
                       .p_selectData(p_selectData[1]),
                       .p_phi2(p_phi2),
                       .p_rdnw(p_rdnw),
                       .p_data(p_data),
                       .h_data(fifo1_w),
                       .h_data_available(h_data_available[1]),
                       .p_full(p_full_pre_w[1])
                       ); 
   
   ph_reg3    ph_reg3 (
                       .h_rst_b(h_rst_b),
                       .h_rd(h_rd),
                       .h_selectData(h_selectData[2]),
                       .h_phi2(h_phi2),
                       .p_data(p_data),
                       .p_selectData(p_selectData[2]),
                       .p_phi2(p_phi2),
                       .p_rdnw(p_rdnw),
                       .one_byte_mode(one_byte_mode),
                       .h_data(fifo2_w),
                       .h_data_available(h_data_available[2]),
                       .p_empty(ph_zero_r3_bytes_avail),
                       .p_full(p_full_pre_w[2])
                       );

   ph_byte    ph_reg4 (
                       .h_rst_b(h_rst_b),
                       .h_rd(h_rd),
                       .h_selectData(h_selectData[3]),
                       .h_phi2(h_phi2),
                       .p_selectData(p_selectData[3]),
                       .p_phi2(p_phi2),
                       .p_rdnw(p_rdnw),
                       .p_data(p_data),
                       .h_data(fifo3_w),
                       .h_data_available(h_data_available[3]),
                       .p_full(p_full_pre_w[3])
                       ); 

   
endmodule // ph_byte

   
