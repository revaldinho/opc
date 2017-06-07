module opc5lscpu( input[15:0] datain, output[15:0] dataout, output[15:0] address, output rnw, input clk, input reset_b);
   parameter MOV=4'h0,AND=4'h1,OR=4'h2,XOR=4'h3,ADD=4'h4,ADC=4'h5,STO=4'h6,LD=4'h7,ROR=4'h8,NOT=4'h9,SUB=4'hA,SBC=4'hB,CMP=4'hC,CMPC=4'hD,BSWP=4'hE,INT=4'hF;
   parameter FETCH0=3'h0, FETCH1=3'h1, EA_ED=3'h2, RDMEM=3'h3, EXEC=3'h4, WRMEM=3'h5;
   parameter PRED_C=15, PRED_Z=14, PINVERT=13, IRLEN=12, IRRDMEM=16, IRWRMEM=17;
   reg [15:0] OR_q, PC_q, result, result_q ;
   reg [17:0] IR_q;
   (* RAM_STYLE="DISTRIBUTED" *)
   reg [15:0] GRF_q[15:0];
   reg [2:0]  FSM_q;
   reg [3:0]  grf_adr_q;
   reg        C_q, zero, carry;
   wire       predicate = (IR_q[PINVERT]^((IR_q[PRED_C]|C_q)&(IR_q[PRED_Z]|zero)));      // For use once IR_q loaded (FETCH1,EA_ED)
   wire       predicate_datain = (datain[PINVERT]^((datain[PRED_C]|C_q)&(datain[PRED_Z]|zero))); // For use before IR_q loaded (FETCH0)
   wire [15:0] grf_dout= (grf_adr_q==4'hF) ? PC_q: (GRF_q[grf_adr_q] & { 16{(grf_adr_q!=4'h0)}});
   wire        skip_eaed = !((grf_adr_q!=0) || (IR_q[IRRDMEM]) || IR_q[IRWRMEM]);
   assign      rnw= ! (FSM_q==WRMEM);
   assign      dataout= grf_dout;
   assign      address=( FSM_q==WRMEM || FSM_q == RDMEM)? OR_q : PC_q;
   always @( * )
     begin
        { carry, result, zero}  = { C_q, 16'bx, !(|result_q) } ;
        case (IR_q[11:8])
          LD, MOV  : result=OR_q;
          AND, OR  : result= (IR_q[8])? (grf_dout & OR_q) : (grf_dout | OR_q);
          ADD, ADC : {carry, result}= grf_dout + OR_q + (IR_q[8] & C_q);
          SUB, SBC, CMP, CMPC : {carry, result}= grf_dout + ((~OR_q)&16'hFFFF) + ((IR_q[8])? C_q: 1);
          XOR, BSWP : result= (!IR_q[11])? (grf_dout ^ OR_q): { OR_q[7:0], OR_q[15:8] };
          NOT : result= ~OR_q;
          ROR : {result,carry} = {carry, OR_q} ;
        endcase // case ( IR_q )
     end
   always @(posedge clk or negedge reset_b )
     if (!reset_b)
       FSM_q <= FETCH0;
     else
       case (FSM_q)
         FETCH0 : FSM_q <= (datain[IRLEN])? FETCH1 : (!predicate_datain )? FETCH0: EA_ED;
         FETCH1 : FSM_q <= (!predicate )? FETCH0: ( skip_eaed) ? EXEC : EA_ED;        // Allow FETCH1 to skip through to EXEC
         EA_ED  : FSM_q <= (!predicate )? FETCH0: (IR_q[IRRDMEM]) ? RDMEM : (IR_q[IRWRMEM]) ? WRMEM : EXEC;
         RDMEM  : FSM_q <= EXEC;
         EXEC   : FSM_q <= (IR_q[3:0]==4'hF)? FETCH0: (datain[IRLEN]) ? FETCH1 : EA_ED;
         default: FSM_q <= FETCH0;
       endcase // case (FSM_q)
   always @(posedge clk)
     case(FSM_q)
       FETCH0, EXEC  : {grf_adr_q, OR_q } <= {datain[7:4], 16'b0};
       FETCH1        : {grf_adr_q, OR_q } <= {((skip_eaed)? IR_q[3:0] : IR_q[7:4]), datain};
       RDMEM         : {grf_adr_q, OR_q } <= {IR_q[3:0], datain};
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
        IR_q <= {(datain[11:8]==STO),(datain[11:8]==LD), datain};
     else if ( FSM_q == EXEC && IR_q[11:8]!=CMP && IR_q[11:8]!=CMPC)
        { C_q, GRF_q[grf_adr_q], result_q, IR_q} <= { carry, result, result, {(datain[11:8]==STO),(datain[11:8]==LD), datain}};
     else if ( FSM_q == EXEC )
        { C_q, result_q, IR_q} <= { carry, result, {(datain[11:8]==STO),(datain[11:8]==LD), datain}};
endmodule
