module opc5lscpu( input[15:0] din, output[15:0] dout, output[15:0] address, output rnw, input clk, input reset_b);
   parameter MOV=4'h0,AND=4'h1,OR=4'h2,XOR=4'h3,ADD=4'h4,ADC=4'h5,STO=4'h6,LD=4'h7,ROR=4'h8,NOT=4'h9,SUB=4'hA,SBC=4'hB,CMP=4'hC,CMPC=4'hD,BSWP=4'hE,PSR=4'hF;
   parameter FETCH0=3'h0, FETCH1=3'h1, EA_ED=3'h2, RDMEM=3'h3, EXEC=3'h4, WRMEM=3'h5;
   parameter PRED_C=15, PRED_Z=14, PINVERT=13, IRLEN=12, IRLD=16, IRSTO=17, IRGETPSR=18, IRPUTPSR=19, IRCMP=20;
   reg [15:0] OR_q, PC_q, result;
   reg [20:0] IR_q;
   (* RAM_STYLE="DISTRIBUTED" *)
   reg [15:0] GRF_q[14:0];
   reg [2:0]  FSM_q;
   reg [3:0]  grf_radr_q, grf_wadr_q;
   reg        C_q, Z_q, zero, carry;
   wire       predicate = (IR_q[PINVERT]^((IR_q[PRED_C]|C_q)&(IR_q[PRED_Z]|Z_q)));      // For use once IR_q loaded (FETCH1,EA_ED)
   wire       predicate_din = (din[PINVERT]^((din[PRED_C]|C_q)&(din[PRED_Z]|Z_q))); // For use before IR_q loaded (FETCH0)
   wire [15:0] grf_dout_p2= (IR_q[7:4]==4'hF) ? PC_q: {16{(IR_q[7:4]!=4'h0)}} & GRF_q[IR_q[7:4]];
   wire [15:0] grf_dout= (grf_radr_q==4'hF) ? PC_q: (GRF_q[grf_radr_q] & { 16{(grf_radr_q!=4'h0)}});
   wire        skip_eaed = !((grf_radr_q!=0) || (IR_q[IRLD]) || IR_q[IRSTO]);
   wire [15:0] operand = (IR_q[IRLEN]==1 || IR_q[IRLD]==1) ? OR_q : grf_dout_p2; // For one word instructions operand comes from GRF
   assign      { rnw, dout, address } = { !(FSM_q==WRMEM), grf_dout, ( FSM_q==WRMEM || FSM_q == RDMEM)? OR_q : PC_q };
   always @( * )
     begin
        case (IR_q[11:8])     // no real need for STO entry but include it so all instructions are covered, no need for default
          LD, MOV, PSR, STO   : {carry, result} = {C_q, (IR_q[IRGETPSR])? {14'b0, C_q, Z_q}: operand} ;
          AND, OR             : {carry, result} = {C_q, (IR_q[8])? (grf_dout & operand) : (grf_dout | operand)};
          ADD, ADC            : {carry, result} = grf_dout + operand + (IR_q[8] & C_q);
          SUB, SBC, CMP, CMPC : {carry, result} = grf_dout + (operand ^ 16'hFFFF) + ((IR_q[8])? C_q: 1);
          XOR, BSWP           : {carry, result} = {C_q, (!IR_q[11])? (grf_dout ^ operand): { operand[7:0], operand[15:8] }};
          NOT, ROR            : {result, carry} = (IR_q[8]) ? {~operand, C_q} : {C_q, operand} ;
        endcase // case ( IR_q )
        {carry, zero} = (IR_q[IRPUTPSR])? operand[1:0]: (grf_wadr_q!=4'hF)? {carry,!(|result)}: {C_q,Z_q} ; // don't update Carry or Zero on PC dest operations
     end
   always @(posedge clk or negedge reset_b )
     if (!reset_b)
       FSM_q <= FETCH0;
     else
       case (FSM_q)
         FETCH0 : FSM_q <= (din[IRLEN]) ? FETCH1 : (!predicate_din) ? FETCH0 : ( (din[11:8]==LD) || (din[11:8]==STO)) ? EA_ED : EXEC; // One word instructions direct to EXEC, use GRF !
         FETCH1 : FSM_q <= (!predicate )? FETCH0: ( skip_eaed) ? EXEC : EA_ED;        // Allow FETCH1 to skip through to EXEC
         EA_ED  : FSM_q <= (!predicate )? FETCH0: (IR_q[IRLD]) ? RDMEM : (IR_q[IRSTO]) ? WRMEM : EXEC;
         RDMEM  : FSM_q <= EXEC;
         EXEC   : FSM_q <= (IR_q[3:0]==4'hF)? FETCH0: (din[IRLEN]) ? FETCH1 : EA_ED;
         default: FSM_q <= FETCH0;
       endcase // case (FSM_q)
   always @(posedge clk)
     case(FSM_q)
       FETCH0, EXEC  : {grf_wadr_q, grf_radr_q, OR_q } <= {((din[11:8]==CMP)||(din[11:8]==CMPC))?4'b0: din[3:0], din[3:0], 16'b0};
       FETCH1        : {grf_wadr_q, grf_radr_q, OR_q } <= {(IR_q[IRCMP])?4'b0:IR_q[3:0], IR_q[3:0], din};
       RDMEM         : {grf_wadr_q, grf_radr_q, OR_q } <= {(IR_q[IRCMP])?4'b0:IR_q[3:0], IR_q[3:0], din};
       EA_ED         : {grf_wadr_q, grf_radr_q, OR_q } <= {(IR_q[IRCMP])?4'b0:IR_q[3:0], IR_q[3:0], grf_dout_p2 + OR_q};
       default       : {grf_wadr_q, grf_radr_q, OR_q } <= {(IR_q[IRCMP])?4'b0:IR_q[3:0], 4'bx, 16'bx};
     endcase
   always @(posedge clk or negedge reset_b)
     if ( !reset_b)
       PC_q <= 16'b0;
     else if ( FSM_q == FETCH0 || FSM_q == FETCH1 )
       PC_q <= PC_q + 1;
     else if ( FSM_q == EXEC )
       PC_q <= (grf_wadr_q==4'hF) ? result : PC_q + 1;
   always @ (posedge clk)
     if ( FSM_q == EXEC )
        { C_q, Z_q, GRF_q[grf_wadr_q]} <= { carry, zero, result };
   always @ (posedge clk)
     if ( FSM_q == FETCH0 || FSM_q == EXEC)
        IR_q <= { ((din[11:8]==CMP)||(din[11:8]==CMPC)), {2{(din[11:8]==PSR)}} & {(din[3:0]==4'h0),(din[7:4]==4'b0)}, (din[11:8]==STO),(din[11:8]==LD), din};
endmodule
