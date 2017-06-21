//**************************************************************************
//    hp_reg3.v - 2 byte FIFO for 16b transfers in host to parasite direction
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

module hp_reg3 (
                input h_rst_b,
                input h_we_b,
                input h_selectData,
                input h_phi2,
                input [7:0] h_data,
                
                input       p_selectData,
                input p_phi2,
                input p_rdnw,
                input       one_byte_mode,
                
                output [7:0] p_data,
                output       p_data_available,
                output       p_two_bytes_available,
                output       h_full
);

   wire [1:0]    h_full_w;   
   wire [1:0]    p_data_available_w;
   reg [7:0]     byte0_q_r ;
   reg [7:0]     byte1_q_r ;   
   wire [7:0]    byte0_d_w ;
   wire [7:0]    byte1_d_w ;   

   // assign primary IOs
   assign p_data = ( p_data_available_w[0] ) ? byte0_q_r: byte1_q_r;
   // assign p_data = byte0_q_r;
   assign p_two_bytes_available = !(one_byte_mode) & ( &p_data_available_w );   

   // Compute D and resets for state bits
   assign byte0_d_w = ( h_selectData & (!h_full_w[0] | one_byte_mode) & !h_we_b ) ? h_data : byte0_q_r;
   assign byte1_d_w = ( h_selectData & ( h_full_w[0] & !one_byte_mode) & !h_we_b ) ? h_data : byte1_q_r;
   
// Register 3 is intended to enable high speed transfers of large blocks of data across the tube. 
// It can operate in one or two byte mode, depending on the V flag. In one byte mode the status 
// bits make each FIFO appear to be a single byte latch - after one byte is written the register 
// appears to be full. In two byte mode the data available flag will only be asserted when two bytes have 
// been entered, and the not full flag will only be asserted when both bytes have been removed. Thus data 
// available going active means that two bytes are available, but it will remain active until both bytes 
// have been removed. Not full going active means that the register is empty, but it will remain active 
// until both bytes have been entered. PNMI, N and DRQ also remain active until the full two 
// byte operation is completed
   assign p_data_available = (p_data_available_w[0] & one_byte_mode) | p_data_available_w[1];
   assign h_full = ( one_byte_mode ) ? h_full_w[0] : h_full_w[1];
   
   // Instance the appropriate flag logic

   
   hp_flag_m flag_0 (
                       .rst_b(h_rst_b),
                       .p1_rdnw( h_we_b),
                       .p1_select(h_selectData & (!h_full_w[0] | one_byte_mode)),
                       .p1_clk(h_phi2),
                       .p2_select(p_selectData & (p_data_available_w[0] | one_byte_mode)),
                       .p2_rdnw(p_rdnw),
                       .p2_clk(p_phi2),                      
                       .p2_data_available(p_data_available_w[0]),
                       .p1_full(h_full_w[0])
                       );

   hp_flag_m flag_1 (
                       .rst_b(h_rst_b),
                       .p1_rdnw( h_we_b),
                       .p1_select(h_selectData & (h_full_w[0] & !one_byte_mode)),
                       .p1_clk(h_phi2),
                       .p2_select(p_selectData & (!p_data_available_w[0] & !one_byte_mode)),
                       .p2_rdnw(p_rdnw),
                       .p2_clk(p_phi2),                      
                       .p2_data_available(p_data_available_w[1]),
                       .p1_full(h_full_w[1])
                       );
   
   always @ ( negedge h_phi2 or negedge h_rst_b )
     begin
        if ( ! h_rst_b)
          begin
             byte0_q_r <= 8'h0;
             byte1_q_r <= 8'h0;
          end        
        else
          begin
             byte0_q_r <= byte0_d_w ;
             byte1_q_r <= byte1_d_w ;             
          end
        
     end
   
endmodule // hp_reg3

   