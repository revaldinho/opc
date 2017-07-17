// **************************************************************************
//    tube.v - top level module for the Beeb816 Acorn Tube Replacement
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
// Compile time Options
// OMIT_DMA_PINS_D     - if set eliminates drq and dack_b pins, not required 
//                       for 6502 and Z80 coprocessors
// ENABLE_DMA_D        - set this to enable DMA operation. Since the 6502/Z80
//                       don't require it we can't verify it on our board so
//                       leave this disabled (and the logic slightly reduced)
// DEBUG_NO_TUBE_D     - if set forces the LSB of register 0 (the status/
//                       command word) to return '0' and so not be recognized
//                       on boot by the host system
// TWOSTATE_PARASITE_INTERRUPTS_D - if set then parasite interrupt pins are driven high and low
//                                  if not set (default) then they are open collector
// 
// **************************************************************************
`timescale 1ns /1ns

// Interrupts can be open collector type outputs in non-trivial systems
`ifdef TWOSTATE_HOST_INTERRUPTS_D
 `define H_INTERRUPT_OFF_D 1'b1
`else
 `define H_INTERRUPT_OFF_D 1'bz
`endif
`ifdef TWOSTATE_PARASITE_INTERRUPTS_D
 `define P_INTERRUPT_OFF_D 1'b1
`else
 `define P_INTERRUPT_OFF_D 1'bz
`endif

// Define bit positions of all flags
`define S_IDX 7
`define T_IDX 6
`define P_IDX 5   
`define V_IDX 4
`define M_IDX 3
`define J_IDX 2
`define I_IDX 1
`define Q_IDX 0   

module tube (
             input [2:0] h_addr,
             input       h_cs_b,
`ifdef SEPARATE_HOST_DATABUSSES_D
             input [7:0]  h_data_in,
             output [7:0] h_data_out,
`else 
             inout [7:0] h_data,
`endif 
             input       h_phi2,
             input       h_rdnw,
             input       h_rst_b,
             output      h_irq_b,
`ifndef OMIT_DMA_PINS_D            
             output      drq,
             input       dack_b,
`endif
             
             input [2:0] p_addr,
             input       p_cs_b,
`ifdef SEPARATE_PARASITE_DATABUSSES_D
             input [7:0]  p_data_in,
             output [7:0] p_data_out,
`else 
             inout [7:0] p_data,
`endif 
             
             input       p_rdnw,
             input       p_phi2,
             output      p_rst_b,
             output      p_nmi_b,
             output      p_irq_b
             );
   
`ifdef OMIT_DMA_PINS_D   
   wire       dack_b_w = 1'b1;
`else
 `ifdef ENABLE_DMA_D
   wire       dack_b_w = dack_b;
 `else   
   wire       dack_b_w = 1'b1;
 `endif   
`endif

   wire       p_r3_two_bytes_available_w;
   
   wire [3:0] h_select_fifo_d_w;
   wire       h_select_reg0_d_w;      
   reg        h_select_reg0_q_r;   
   reg [3:0]  h_select_fifo_q_r;
   reg [3:0]  p_select_fifo_r;
   reg        h_rdnw_q_r;
   reg        n_flag;
   

   
   reg [7:0]    h_data_r;
   reg [7:0]    p_data_r;
   reg          p_nmi_b_r;
          
   reg [6:0]    h_reg0_q_r;
   reg [5:0]    p_reg0_q_r;   
   
   wire [7:0]   p_data_w;
   wire [7:0]   h_data_w;

   wire [3:0]   p_data_available_w;
   wire [3:0]   p_full_w;
   wire [3:0]   h_data_available_w;
   wire [3:0]   h_full_w;
   
   wire [6:0]   h_reg0_d_w;
   wire         local_rst_b_w;
   wire         ph_zero_r3_bytes_avail_w   ;

   
   // Assign to primary IOs
`ifndef OMIT_DMA_PINS_D
   // "DMA Operation
   //  The DRQ pin (active state = 1) may be used to request a DMA transfer - when M = 1 DRQ will have the
   //  opposite value to PNMI, and depends on V in exactly the same way (see description of interrupt operation)."
   assign drq = h_reg0_q_r[ `M_IDX] & !p_nmi_b_r  ;
`endif   


   // host interrupt active only if enabled and data ready in register 4 
   assign h_irq_b = ( h_reg0_q_r[`Q_IDX] & h_data_available_w[3] ) ? 1'b0 : `H_INTERRUPT_OFF_D ;
   assign p_nmi_b = (p_nmi_b_r) ?  `P_INTERRUPT_OFF_D : 1'b0 ;
   // parasite IRQ active
   assign p_irq_b = ( (h_reg0_q_r[`I_IDX] & p_data_available_w[0]) | (h_reg0_q_r[`J_IDX] & p_data_available_w[3]) ) ? 1'b0 : `P_INTERRUPT_OFF_D  ;

   // Active p_rst_b when '1' in P flag or host reset is applied
   assign p_rst_b = (!h_reg0_q_r[`P_IDX] & h_rst_b) ;   

`ifdef SEPARATE_HOST_DATABUSSES_D
   wire [7:0] 	h_data;
   assign h_data = h_data_in;
   assign h_data_out = h_data_r;
`else // SEPARATE_HOST_DATABUSSES_D
   assign h_data = ( h_rdnw && !h_cs_b && h_phi2 ) ? h_data_r : 8'bzzzzzzzz;
`endif // SEPARATE_HOST_DATABUSSES_D

`ifdef SEPARATE_PARASITE_DATABUSSES_D
   wire [7:0] 	p_data;
   assign p_data = p_data_in;
   assign p_data_out = p_data_r;
`else // SEPARATE_PARASITE_DATABUSSES_D
   assign p_data = ( p_rdnw && !p_cs_b ) ? p_data_r : 8'bzzzzzzzz;   
`endif // SEPARATE_PARASITE_DATABUSSES_D
   
   // Compute register selects for host side
   assign h_select_reg0_d_w    = !h_cs_b && ( h_addr == 3'b0);          
   assign h_select_fifo_d_w[0] = !h_cs_b & ( h_addr == 3'h1);
   assign h_select_fifo_d_w[1] = !h_cs_b & ( h_addr == 3'h3);
   assign h_select_fifo_d_w[2] = !h_cs_b & ( h_addr == 3'h5);
   assign h_select_fifo_d_w[3] = !h_cs_b & ( h_addr == 3'h7);        

   // Flag definitions from the Tube Application Note
   //
   //  Q= 1 enable HIRQ from register 4
   //  I= 1 enable PIRQ from register 1
   //  J= 1 enable PIRQ from register 4
   //  M= 1 enable PNMI from register 3
   //  V =1 two byte operation of register 3 
   //  P =1 activate PRST
   //  T =1 clear all Tube registers  (soft reset)
   //  S= 1 set control flag(s) indicated by mask
   //     
   //
   // These flags are set or cleared according to the value of S, eg writing 92 (hex) 
   // to address 0 will set V and I to 1 but not affect the other flags, whereas 12 (hex) 
   // would clear V and I without changing the other flags. All flags except T are read 
   // out directly as the least significant 6 bits from address 0.

`ifdef DEBUG_NO_TUBE_D
   // Don't allow host interrupts to be enabled and prevent tube from being recognized
   assign h_reg0_d_w[`Q_IDX] = 1;
`else   
   assign h_reg0_d_w[`Q_IDX] = (  !h_rdnw && h_select_reg0_q_r) ? ( h_data[ `Q_IDX] ? h_data[`S_IDX] : h_reg0_q_r[ `Q_IDX] ): h_reg0_q_r [ `Q_IDX];
`endif
   assign h_reg0_d_w[`I_IDX] = (  !h_rdnw && h_select_reg0_q_r) ? ( h_data[ `I_IDX] ? h_data[`S_IDX] : h_reg0_q_r[ `I_IDX] ): h_reg0_q_r [ `I_IDX];
   assign h_reg0_d_w[`J_IDX] = (  !h_rdnw && h_select_reg0_q_r) ? ( h_data[ `J_IDX] ? h_data[`S_IDX] : h_reg0_q_r[ `J_IDX] ): h_reg0_q_r [ `J_IDX];
   assign h_reg0_d_w[`V_IDX] = (  !h_rdnw && h_select_reg0_q_r) ? ( h_data[ `V_IDX] ? h_data[`S_IDX] : h_reg0_q_r[ `V_IDX] ): h_reg0_q_r [ `V_IDX];
   assign h_reg0_d_w[`M_IDX] = (  !h_rdnw && h_select_reg0_q_r) ? ( h_data[ `M_IDX] ? h_data[`S_IDX] : h_reg0_q_r[ `M_IDX] ): h_reg0_q_r [ `M_IDX];
   assign h_reg0_d_w[`P_IDX] = (  !h_rdnw && h_select_reg0_q_r) ? ( h_data[ `P_IDX] ? h_data[`S_IDX] : h_reg0_q_r[ `P_IDX] ): h_reg0_q_r [ `P_IDX];
   assign h_reg0_d_w[`T_IDX] = (  !h_rdnw && h_select_reg0_q_r) ? ( h_data[ `T_IDX] ? h_data[`S_IDX] : h_reg0_q_r[ `T_IDX] ): h_reg0_q_r [ `T_IDX];      

   // Combine hard and soft resets
   assign local_rst_b_w = ! ( !h_rst_b | h_reg0_q_r[`T_IDX] );   
   

//   PNMI  either: 
//   M = 1 V = 0   1 or 2 bytes in host to parasite register 3 FIFO or 
//                 0 bytes in parasite to host register 3 FIFO (this allows 
//                 single byte transfers across register 3) 
//   or:
// 	
//   M = 1 V = 1   2 bytes in host to parasite register 3 FIFO or 0 bytes 
//                 in parasite to host register 3 FIFO. (this allows two 
//                 byte transfers across register 3)
//   
   always @ ( h_reg0_q_r or
              p_data_available_w or
              ph_zero_r3_bytes_avail_w  or
              p_r3_two_bytes_available_w or
              p_full_w
              )
     begin
       if ( h_reg0_q_r[`V_IDX] == 1'b0 )
         n_flag = ( p_data_available_w[2] | ph_zero_r3_bytes_avail_w  ) ;
       else
         n_flag = ( p_r3_two_bytes_available_w |  ph_zero_r3_bytes_avail_w  ) ;
        if ( h_reg0_q_r[`M_IDX] == 1'b1 )
          if ( h_reg0_q_r[`V_IDX] == 1'b0 )
            p_nmi_b_r = ! ( p_data_available_w[2] | ph_zero_r3_bytes_avail_w  ) ;
          else
            p_nmi_b_r = ! ( p_r3_two_bytes_available_w |  ph_zero_r3_bytes_avail_w  ) ;            
        else
          p_nmi_b_r = 1'b1;        
     end     
 

   // Multiplexing of different FIFO IOs
   //
   // NB. App note says that all 'x' bits will read out as '1'
   always @ ( p_data_w or 
              p_addr or  
              p_reg0_q_r or            
              p_data_available_w or
              n_flag or
              p_full_w )
     begin
        case ( p_addr )
          3'h0: p_data_r = { p_data_available_w[0], !p_full_w[0], p_reg0_q_r[5:0]};
          3'h1: p_data_r = p_data_w;          
          3'h2: p_data_r = { p_data_available_w[1], !p_full_w[1], 6'b111111};
          3'h3: p_data_r = p_data_w;
          3'h4: p_data_r = { n_flag, !p_full_w[2], 6'b111111};
          3'h5: p_data_r = p_data_w;          
          3'h6: p_data_r = { p_data_available_w[3], !p_full_w[3], 6'b111111};
          3'h7: p_data_r = p_data_w;          
          // default: p_data_r = p_data_w;
        endcase // case ( p_addr )        
     end     

   always @ ( h_data_w or 
              h_addr or
              h_reg0_q_r or
              h_data_available_w or
              h_full_w )
     begin
        case ( h_addr )
          3'h0: h_data_r = { h_data_available_w[0], !h_full_w[0], h_reg0_q_r[5:0]};
          3'h1: h_data_r = h_data_w;          
          3'h2: h_data_r = { h_data_available_w[1], !h_full_w[1], 6'b111111};
          3'h3: h_data_r = h_data_w;
          3'h4: h_data_r = { h_data_available_w[2], !h_full_w[2], 6'b111111};
          3'h5: h_data_r = h_data_w;          
          3'h6: h_data_r = { h_data_available_w[3], !h_full_w[3], 6'b111111};
          3'h7: h_data_r = h_data_w;
          // default: h_data_r = h_data_w;
        endcase // case ( h_addr )        
     end     


   // Instance all the individual host-parasite direction FIFOs
   hp_bytequad  hp_fifo (
                         .h_rst_b( local_rst_b_w ) ,
                         .h_we_b ( h_rdnw ),
                         .h_selectData( h_select_fifo_q_r ),
                         .h_phi2( h_phi2),
                         .h_data( h_data),
                         .p_selectData( p_select_fifo_r ),
                         .p_phi2(p_phi2),
                         .p_rdnw(p_rdnw),                         
                         .p_data( p_data_w),
                         .one_byte_mode( ! h_reg0_q_r[`V_IDX]),
                         .p_data_available(p_data_available_w),
                         .p_r3_two_bytes_available(p_r3_two_bytes_available_w),
                         .h_full(h_full_w)
                         );

   // Instances of parasite->host modules
   //
   // "DMA Operation ... DACK then selects register 3 independently of PA0-2 and PCS, and forces a 
   //  read cycle if PNWDS is active or a write cycle if PNRDS is active (note inverse sense of 
   //  PNWDS and PNRDS so that the DMA system can read the data from memory an write it into the 
   //  Tube in one cycle)."
   //
   //  Tube App note, p12.   
   always @ ( p_addr or p_cs_b or dack_b_w)
     begin
        p_select_fifo_r[0] = !p_cs_b & (( p_addr == 3'h1) & dack_b_w);  // REG 1
        p_select_fifo_r[1] = !p_cs_b & (( p_addr == 3'h3) & dack_b_w);  // REG 2
        p_select_fifo_r[2] = !p_cs_b & (( p_addr == 3'h5) | !dack_b_w); // REG 3
        p_select_fifo_r[3] = !p_cs_b & (( p_addr == 3'h7) & dack_b_w);  // REG 4       
     end

   ph_bytequad  ph_fifo (
                         .h_rst_b(local_rst_b_w),
                         .h_rd( h_rdnw_q_r ),// Use latched version of rdnw
                         .h_selectData(  h_select_fifo_q_r),
                         .h_phi2(h_phi2 ),
                         .p_data(p_data),                  
                         .p_selectData(p_select_fifo_r ),
                         .p_phi2(p_phi2),
                         .p_rdnw( (!dack_b_w) ^ p_rdnw),
                         .h_data (h_data_w),                
                         .one_byte_mode( ! h_reg0_q_r[`V_IDX]),  
                         .h_data_available( h_data_available_w),
                         .ph_zero_r3_bytes_avail( ph_zero_r3_bytes_avail_w ),
                         .p_full(p_full_w)
                         );
   
   // Remaining state for host side reg 0, note that FIFO is unaffected by soft reset
   always @ ( negedge h_phi2 or negedge h_rst_b )
     if ( ! h_rst_b )
       h_reg0_q_r <= 7'b0;
     else
       h_reg0_q_r <= h_reg0_d_w;

   // Latch host side register select signals on phi2 - found that the L1B CPLD was
   // more robust when this was done avoiding bus hold issues ?
   always @ (posedge h_phi2 or negedge h_rst_b)
     begin
        if ( ! h_rst_b )
          begin
             h_select_fifo_q_r <= 4'h0;
             h_select_reg0_q_r <= 1'b0;
             h_rdnw_q_r <= 1'b0;             
          end
        else
          begin
             h_rdnw_q_r <= h_rdnw;                          
             h_select_reg0_q_r    <= h_select_reg0_d_w;          
             h_select_fifo_q_r[0] <= h_select_fifo_d_w[0];
             h_select_fifo_q_r[1] <= h_select_fifo_d_w[1];
             h_select_fifo_q_r[2] <= h_select_fifo_d_w[2];
             h_select_fifo_q_r[3] <= h_select_fifo_d_w[3];      
          end  
     end // always @ ( posedge h_phi2 or negedge h_rst_b )


   // Provide option for retiming read of status/command reg from host to parasite
   always @ ( posedge p_phi2 or negedge h_rst_b )   
     if ( !h_rst_b )
       p_reg0_q_r <= 6'b000000;
     else
       p_reg0_q_r <= h_reg0_q_r[5:0];
   
endmodule
