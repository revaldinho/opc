//**************************************************************************
//    ph_reg3.v - 2 byte FIFO for 16b transfers in parasite to host direction
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

module ph_reg3 (
                input h_rst_b,
                input h_rd,
                input h_selectData,
                input h_phi2,
                
                input [7:0] p_data,                  
                input       p_selectData,
                input p_phi2,
                input p_rdnw,
                input       one_byte_mode,                
                output [7:0] h_data,                  
                output       h_data_available,
                output       p_empty,               
                output       p_full
                );

   wire [1:0]    p_full_w;   
   wire [1:0]    h_data_available_w;
   reg [7:0]     byte0_q_r ;
   reg [7:0]     byte1_q_r ;   
   wire [7:0]    byte0_d_w ;
   wire [7:0]    byte1_d_w ;

   assign byte0_d_w = ( p_selectData & !p_rdnw & ( !p_full_w[0] | one_byte_mode) ) ? p_data : byte0_q_r;
   assign byte1_d_w = ( p_selectData & !p_rdnw & (  p_full_w[0] & !one_byte_mode) ) ? p_data : byte1_q_r;      
      
   assign h_data = ( h_data_available_w[0]) ? byte0_q_r : byte1_q_r;   

   //This was a work around for a SAVE issue cause by too much latency through the sumchronizers 
   //reg           h_zero_bytes_available;  
   //wire          h_zero_bytes_available0;  
   //reg           h_zero_bytes_available1;  
   //always @ ( negedge h_phi2) begin
   //  h_zero_bytes_available1 <= h_zero_bytes_available0;
   //  h_zero_bytes_available <= h_zero_bytes_available1;
   //end
   
   // Register 3 is intended to enable high speed transfers of large blocks of data across the tube. 
   // It can operate in one or two byte mode, depending on the V flag. In one byte mode the status 
   // bits make each FIFO appear to be a single byte latch - after one byte is written the register 
   // appears to be full. In two byte mode the data available flag will only be asserted when two bytes have 
   // been entered, and the not full flag will only be asserted when both bytes have been removed. Thus data 
   // available going active means that two bytes are available, but it will remain active until both bytes 
   // have been removed. Not full going active means that the register is empty, but it will remain active 
   // until both bytes have been entered. PNMI, N and DRQ also remain active until the full two 
   // byte operation is completed
   
   assign h_data_available = (h_data_available_w[0] &  one_byte_mode) | h_data_available_w[1];
   assign p_full = ( one_byte_mode ) ? p_full_w[0] : p_full_w[1];

   // DMB: 13/01/2016
   // On the ARM2 in the SAVE (p->h) direction, we were seeing NMI happening twice
   // After writing data to R3, it took approx 1us for NMI to be removed, which was
   // too slow (as NMI is level sensitive, and the handler is only 3 instructions).
   // It seems the bug is that NMI is generated from h_zero_bytes_available, which
   // lags because it is synchronized to the host domain. I don't know why a host domain
   // signal was ever being used in NMI, which is a parasite signal. Anyway, I think
   // the best fix is instead to generate a p_empty signal, which should have the same
   // semantics, but be more reactive to parasite writes. The danger is it's less
   // reacive to host reads, and so we increase the NMI latency, possibly causing some
   // Co Pros to fail. This will need to be tested on all Co Pros.

   // This was the old signal
   // assign h_zero_bytes_available = ! (h_data_available_w[0] | (  h_data_available_w[1] &  !one_byte_mode )) ;

   // This is the new signal
   assign p_empty = !p_full_w[0] & ( !p_full_w[1] | one_byte_mode ) ;
                      
   // Need to set a flag_0 in this register on reset to avoid generating a PNMI on reset...
   ph_flag_m #(1'b1) flag_0 (
                      .rst_b(h_rst_b),
                      .p1_clk(p_phi2),
                      .p1_rdnw(p_rdnw),
                      .p1_select(p_selectData & !p_full_w[0] & (!p_full_w[1] | one_byte_mode)),
                      .p1_full(p_full_w[0]),
                      .p2_clk(h_phi2),
                      .p2_select( h_selectData & (h_data_available_w[0] | one_byte_mode)),
                      .p2_rdnw(h_rd),
                      .p2_data_available(h_data_available_w[0])
                      ); 
   ph_flag_m flag_1 (
                      .rst_b(h_rst_b),
                      .p1_clk(p_phi2),
                      .p1_select(p_selectData & p_full_w[0] & !(p_full_w[1] | one_byte_mode)),
                      .p1_rdnw(p_rdnw),
                      .p1_full(p_full_w[1]),
                      .p2_clk(h_phi2),
                      .p2_select(h_selectData & (!h_data_available_w[0] & h_data_available_w[1]  & !one_byte_mode )),
                      .p2_rdnw(h_rd),
                      .p2_data_available(h_data_available_w[1])
                      ); 

   // Infer all state
   always @ ( posedge p_phi2 or negedge h_rst_b )   
     begin
        if ( ! h_rst_b)
          begin
             byte0_q_r <= 8'hAA;
             byte1_q_r <= 8'hEE;             
          end
        else
          begin
             byte0_q_r <= byte0_d_w ;
             byte1_q_r <= byte1_d_w ;
          end
     end

endmodule // ph_byte

   
