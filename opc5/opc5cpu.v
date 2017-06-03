module opc5cpu( inout[15:0] data, output[15:0] address, output rnw, input clk, input reset_b);
   parameter FETCH0=3'h0, FETCH1=3'h1, EA_ED=3'h2, RDMEM=3'h3, EXEC=3'h4, WRMEM=3'h5;
   parameter PRED_C=15, PRED_Z=14, PINVERT=13, FSM_MAP0=12, FSM_MAP1=11;
   parameter LD=3'b000, ADD=3'b001, AND=3'b010, OR=3'b011, XOR=3'b100, ROR=3'b101, ADC=3'b110, STO=3'b111;
   reg [15:0] OR_q, PC_q, IR_q, result, result_q ;
   (* RAM_STYLE="DISTRIBUTED" *)
   reg [15:0] GRF_q[15:0];    
   reg [2:0]  FSM_q;
   reg [3:0]  grf_adr_q;        
   reg        C_q, zero, carry;
   wire       predicate = (IR_q[PINVERT]^((IR_q[PRED_C]|C_q)&(IR_q[PRED_Z]|zero)));      // For use once IR_q loaded (FETCH1,EA_ED)
   wire       predicate_data = (data[PINVERT]^((data[PRED_C]|C_q)&(data[PRED_Z]|zero))); // For use before IR_q loaded (FETCH0)
   wire [15:0] grf_dout= (grf_adr_q==4'hF) ? PC_q: (GRF_q[grf_adr_q] & { 16{(grf_adr_q!=4'h0)}});
   wire        skip_eaed = !((grf_adr_q!=0) || (IR_q[FSM_MAP1]) || (IR_q[10:8]==STO));      
   assign      rnw= ! (FSM_q==WRMEM);
   assign      data=(FSM_q==WRMEM)?grf_dout:16'bz;
   assign      address=( FSM_q==WRMEM || FSM_q == RDMEM)? OR_q : PC_q;   
   always @( * )
     begin
        { carry, result, zero}  = { C_q, 16'bx, !(|result_q) } ;
        case (IR_q[10:8])
          LD  : result=OR_q;
          ADD, ADC : {carry, result}= grf_dout + OR_q + (!IR_q[8] & C_q); // IF ADC or ADD, IR_q[8] distinguishes between them
          AND : result=(grf_dout & OR_q);
          OR  : result=(grf_dout | OR_q);
          XOR : result=(grf_dout ^ OR_q);
          ROR : {result,carry} = { carry, OR_q };
        endcase // case ( IR_q )
     end

   always @(posedge clk or negedge reset_b )
     if (!reset_b)
       FSM_q <= FETCH0;
     else
       case (FSM_q)
         FETCH0 : FSM_q <= (data[FSM_MAP0])? FETCH1 : (!predicate_data )? FETCH0: EA_ED;
         FETCH1 : FSM_q <= (!predicate )? FETCH0: ( skip_eaed) ? EXEC : EA_ED;        // Allow FETCH1 to skip through to EXEC
         EA_ED  : FSM_q <= (!predicate )? FETCH0: (IR_q[FSM_MAP1]) ? RDMEM : (IR_q[10:8]==STO) ? WRMEM : EXEC;
         RDMEM  : FSM_q <= EXEC;
         EXEC   : FSM_q <= (IR_q[3:0]==4'hF)? FETCH0: (data[FSM_MAP0]) ? FETCH1 : EA_ED;
         default: FSM_q <= FETCH0;
       endcase // case (FSM_q)

   always @(posedge clk)
     case(FSM_q)
       FETCH0, EXEC  : {grf_adr_q, OR_q } <= {data[7:4], 16'b0}; 
       FETCH1        : {grf_adr_q, OR_q } <= {((skip_eaed)? IR_q[3:0] : IR_q[7:4]), data};  
       RDMEM         : {grf_adr_q, OR_q } <= {IR_q[3:0], data};
       EA_ED         : {grf_adr_q, OR_q } <= {IR_q[3:0], grf_dout + OR_q};
       default       : {grf_adr_q, OR_q } <= {4'bx, 16'bx};
     endcase

   always @(posedge clk or negedge reset_b)
     if ( !reset_b)
       PC_q <= 16'b0;
     else if ( FSM_q == FETCH0 || FSM_q == FETCH1 )
       PC_q <= PC_q + 1;
     else if ( FSM_q == EXEC ) 
       PC_q <= (grf_adr_q==4'hF) ? result : PC_q + 1;  

   always @ (posedge clk)
     if ( FSM_q == FETCH0 )
        IR_q <= data;
     else if ( FSM_q == EXEC )
       { C_q, GRF_q[grf_adr_q], result_q, IR_q} <= { carry, result, result, data};
endmodule
