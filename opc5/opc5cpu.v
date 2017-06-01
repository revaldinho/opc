module opc5cpu( inout[15:0] data, output[15:0] address, output rnw, input clk, input reset_b);
   parameter FETCH0=3'h0, FETCH1=3'h1, EA_ED=3'h2, RDMEM=3'h3, EXEC=3'h4, WRMEM=3'h5;
   parameter PRED_C=15, PRED_Z=14, PINVERT=13, STO_INSTR=13, FSM_MAP0=12, FSM_MAP1=11;
   parameter LD=3'b000, ADD=3'b001, AND=3'b010, OR=3'b011, XOR=3'b100, ROR=3'b101, ADC=3'b110, STO=3'b111 ;
   reg [15:0] OR_q, PC_q, result;
   reg [13:0] IR_q;
   (* RAM_STYLE="DISTRIBUTED" *)
   reg [15:0] GRF_q[14:0];
   reg [2:0]  FSM_q;
   reg        C_q, Z_q, carry, predicate_q;
   wire [3:0]  grf_radr=((FSM_q==EXEC)||(FSM_q==WRMEM))?IR_q[3:0]:IR_q[7:4];
   wire [15:0] grf_dout= (grf_radr==4'hF) ? PC_q: (GRF_q[grf_radr] & { 16{(grf_radr!=4'h0)}});
   assign      rnw= ! (FSM_q==WRMEM) ;
   assign      data=(FSM_q==WRMEM)?grf_dout:16'bz ;
   assign      address=( FSM_q==WRMEM || FSM_q == RDMEM)? OR_q : PC_q;
   wire        predicate_d =  (data[PINVERT] ^ ((data[PRED_C]|C_q)&(data[PRED_Z]|Z_q)));

   always @( * )
     begin
        carry = C_q ;
        case (IR_q[10:8])
          LD, STO  : result=OR_q ;
          ADD, ADC : {carry, result}=grf_dout + OR_q + (!IR_q[8] & C_q) ; // IF ADC or ADD, IR_q[8] is enough to distinguish between them
          AND : result=(grf_dout & OR_q);
          OR  : result=(grf_dout | OR_q);
          XOR : result=(grf_dout ^ OR_q);
          ROR : {result,carry} = { carry, OR_q } ;
        endcase // case ( IR_q )
     end

   always @(posedge clk or negedge reset_b )
     if (!reset_b)
       FSM_q <= FETCH0;
     else
       case (FSM_q)
         FETCH0 : FSM_q <= (data[FSM_MAP0])? FETCH1 : (!predicate_d) ? FETCH0: EA_ED;
         FETCH1 : FSM_q <= (!predicate_q)? FETCH0:
                           // Allow instructions with operand=0 to skip EA_ED state to EXEC
                           (grf_radr==0 && !IR_q[FSM_MAP1] && !IR_q[STO_INSTR]) ? EXEC : EA_ED;
         EA_ED  : FSM_q <= (IR_q[FSM_MAP1]) ? RDMEM : (IR_q[STO_INSTR]) ? WRMEM : EXEC;
         RDMEM  : FSM_q <= EXEC;
         default: FSM_q <= FETCH0;
       endcase

   always @(posedge clk)
     case(FSM_q)
       FETCH0        : OR_q <= 16'b0; // Need to zero OR_q in FETCH0 in case of single word instr
       RDMEM, FETCH1 : OR_q <= data;
       EA_ED         : OR_q <= grf_dout + OR_q ;
       default       : OR_q <= 16'bx;
     endcase

   always @(posedge clk or negedge reset_b)
     if ( !reset_b)
       PC_q <= 16'b0;
     else if ( FSM_q == FETCH0 || FSM_q == FETCH1)
       PC_q <= PC_q + 1;
     else if ( FSM_q == EXEC && IR_q[3:0]==4'hF)
       PC_q <= result;

   always @ (posedge clk)
     if ( FSM_q == FETCH0 )
       {predicate_q, IR_q} <= { predicate_d, (data[10:8]==STO), data[12:0]} ;
     else if ( FSM_q == EXEC)
       { C_q, GRF_q[IR_q[3:0]], Z_q}  <= { carry, result, !(|result)};
endmodule
