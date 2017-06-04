module opc5cpu( inout[15:0] data, output[15:0] address, output rnw, input clk, input reset_b);
   parameter FETCH0=3'h0, FETCH1=3'h1, EA_ED=3'h2, RDMEM=3'h3, EXEC=3'h4, WRMEM=3'h5;
   parameter PRED_C=15, PRED_Z=14, PINVERT=13, FSM_MAP0=12, FSM_MAP1=11;
   parameter LD=3'b000, ADD=3'b001, AND=3'b010, OR=3'b011, XOR=3'b100, ROR=3'b101, ADC=3'b110, STO=3'b111 ;
   reg [15:0] OR_q, IR_q, PC_q, result, result_q;
   (* RAM_STYLE="DISTRIBUTED" *)
   reg [15:0] GRF_q[14:0];
   reg [15:0] GRF2_q[14:0];
   reg [2:0]  FSM_q;
   reg        C_q, zero, carry;
   wire [15:0] grf_dout_p2= (IR_q[7:4]==4'hF) ? PC_q: {16{(IR_q[7:4]!=4'h0)}} & GRF2_q[IR_q[7:4]];
   wire [15:0] grf_dout= (IR_q[3:0]==4'hF) ? PC_q: (GRF_q[IR_q[3:0]] & { 16{(IR_q[3:0]!=4'h0)}});
   wire       predicate = (IR_q[PINVERT]^((IR_q[PRED_C]|C_q)&(IR_q[PRED_Z]|zero)));      // For use once IR_q loaded (FETCH1,EA_ED)
   wire       predicate_data = (data[PINVERT]^((data[PRED_C]|C_q)&(data[PRED_Z]|zero))); // For use before IR_q loaded (FETCH0)
   wire [15:0] operand = (IR_q[FSM_MAP0]==1 || IR_q[FSM_MAP1]==1) ? OR_q : grf_dout_p2; // For one word instructions operand comes from GRF2
   assign      rnw= ! (FSM_q==WRMEM) ;
   assign      data=(FSM_q==WRMEM)?grf_dout:16'bz ;
   assign      address=( FSM_q==WRMEM || FSM_q == RDMEM)? OR_q : PC_q;
   always @( * )
     begin
        {carry, result, zero} = { C_q, 16'bx, !(|result_q) } ;
        case (IR_q[10:8])
          LD  : result=operand ;
          ADD, ADC : {carry, result}= grf_dout + operand + (!IR_q[8] & C_q); // IF ADC or ADD, IR_q[8] distinguishes between them
          AND : result=(grf_dout & operand);
          OR  : result=(grf_dout | operand);
          XOR : result=(grf_dout ^ operand);
          ROR : {result,carry} = { carry, operand } ;
        endcase // case ( IR_q )
     end
   always @(posedge clk or negedge reset_b )
     if (!reset_b)
       FSM_q <= FETCH0;
     else
       case (FSM_q)
         FETCH0 : FSM_q <= (data[FSM_MAP0]) ? FETCH1 : (!predicate_data) ? FETCH0 : ((data[FSM_MAP1]==1) || (data[10:8]==STO)) ? EA_ED : EXEC; // One word instructions direct to EXEC, use GRF2 !
         FETCH1 : FSM_q <= (!predicate)? FETCH0: (IR_q[3:0]==0 && !IR_q[FSM_MAP1] && !(IR_q[10:8]==STO)) ? EXEC : EA_ED;
         EA_ED  : FSM_q <= (!predicate)? FETCH0: (IR_q[FSM_MAP1]) ? RDMEM : (IR_q[10:8]==STO) ? WRMEM : EXEC;
         RDMEM  : FSM_q <= EXEC;
         EXEC   : FSM_q <= (IR_q[3:0]==4'hF)? FETCH0: (data[FSM_MAP0]) ? FETCH1: ((data[FSM_MAP1]==1) || (data[10:8]==STO)) ? EA_ED :
                           // Always predicated  OR carry is available in this cycle but not zero
                           ((data[15:13]==3'b110) ||  ((data[PRED_C:PRED_Z]==2'b01) && (carry ^ data[PINVERT]))) ? EXEC : EA_ED;         
         default: FSM_q <= FETCH0;
       endcase
   always @(posedge clk)
     case(FSM_q)
       FETCH0, EXEC  : OR_q <= 16'b0; // Need to zero OR_q in FETCH0 in case of single word instr
       RDMEM, FETCH1 : OR_q <= data;
       EA_ED         : OR_q <= grf_dout_p2 + OR_q ;
       default       : OR_q <= 16'bx;
     endcase
   always @(posedge clk or negedge reset_b)
     if ( !reset_b)
       PC_q <= 16'b0;
     else if ( FSM_q == FETCH0 || FSM_q == FETCH1)
       PC_q <= PC_q + 1;
     else if ( FSM_q == EXEC)
       PC_q <= (IR_q[3:0]==4'hF) ? result : PC_q + 1;  
   always @ (posedge clk)
     if ( FSM_q == FETCH0 )        
       IR_q <= data;
     else if ( FSM_q == EXEC)
       { C_q, result_q, GRF_q[IR_q[3:0]], GRF2_q[IR_q[3:0]], IR_q}  <= {carry, result, result, result, data };
endmodule
