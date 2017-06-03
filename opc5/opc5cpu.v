module opc5cpu( inout[15:0] data, output[15:0] address, output rnw, input clk, input reset_b);
    // EXPERIMENTAL VERSION
   parameter FETCH0=3'h0, FETCH1=3'h1, EA_ED=3'h2, RDMEM=3'h3, EXEC=3'h4, WRMEM=3'h5;
   parameter PRED_C=15, PRED_Z=14, PINVERT=13, RESPRED=14, STO_INSTR=13, FSM_MAP0=12, FSM_MAP1=11;
   parameter LD=3'b000, ADD=3'b001, AND=3'b010, OR=3'b011, XOR=3'b100, ROR=3'b101, ADC=3'b110, STO=3'b111 ;
   reg [15:0] OR_q, IR_q, PC_q, result, result_q;
   (* RAM_STYLE="DISTRIBUTED" *)
   reg [15:0] GRF_q[14:0];
   reg [15:0] GRF2_q[14:0];
   reg [2:0]  FSM_q;
   reg        C_q, Z_q, C_d;

   wire [3:0]  grf_radr_p2= IR_q[7:4];
   wire [15:0] grf_dout_p2= (grf_radr_p2==4'hF) ? PC_q: {16{(grf_radr_p2!=4'h0)}} & GRF2_q[grf_radr_p2];
   wire [3:0]  grf_radr= IR_q[3:0];
   wire [15:0] grf_dout= (grf_radr==4'hF) ? PC_q: (GRF_q[grf_radr] & { 16{(grf_radr!=4'h0)}});
   assign      rnw= ! (FSM_q==WRMEM) ;
   assign      data=(FSM_q==WRMEM)?grf_dout:16'bz ;
   assign      address=( FSM_q==WRMEM || FSM_q == RDMEM)? OR_q : PC_q;

   wire [15:0] operand = (IR_q[FSM_MAP0]==1 || IR_q[FSM_MAP1]==1) ? OR_q : grf_dout_p2; // For one word instructions operand comes from GRF2
   wire        predicate_d = (data[PINVERT] ^ ((data[PRED_C]|C_q)&(data[PRED_Z]|Z_q)));

   always @( * )
     begin
        {C_d, result} = { C_q, 16'bx } ;
        case (IR_q[10:8])
          LD  : result=operand ;
          ADD, ADC : {C_d, result}=grf_dout + operand + ((IR_q[10:8]==ADC)?C_q:0) ;
          AND : result=(grf_dout & operand);
          OR  : result=(grf_dout | operand);
          XOR : result=(grf_dout ^ operand);
          ROR : {result,C_d} = { C_d, operand } ;
        endcase // case ( IR_q )
     end

   always @(posedge clk or negedge reset_b )
     if (!reset_b)
       FSM_q <= FETCH0;
     else
       case (FSM_q)
         FETCH0 :
                if (data[FSM_MAP0])
                    FSM_q <= FETCH1;
                else if (!predicate_d)
                    FSM_q <= FETCH0;
                else if ((data[FSM_MAP1]==1) || (data[10:8]==STO))
                    FSM_q <= EA_ED;
                else
                    FSM_q <= EXEC; // One word instructions direct to EXEC, use GRF2 !
         FETCH1 : FSM_q <= (!IR_q[RESPRED])? FETCH0:
                           (grf_radr==0 && !IR_q[FSM_MAP1] && !IR_q[STO_INSTR]) ? EXEC : EA_ED;
         EA_ED  : FSM_q <= (IR_q[FSM_MAP1]) ? RDMEM : (IR_q[STO_INSTR]) ? WRMEM : EXEC;
         RDMEM  : FSM_q <= EXEC;
         default: FSM_q <= FETCH0;
       endcase

   always @(posedge clk)
     case(FSM_q)
       FETCH0        : OR_q <= 16'b0; // Need to zero OR_q in FETCH0 in case of single word instr
       RDMEM, FETCH1 : OR_q <= data;
       EA_ED         : OR_q <= grf_dout_p2 + OR_q ;
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
        IR_q <= { 1'bx, predicate_d, (data[10:8]==STO), data[12:0]} ;
     else if ( FSM_q == EXEC)
        begin
            C_q <= C_d ;
            result_q <= result ;
            GRF_q[IR_q[3:0]] <= result ;
            GRF2_q[IR_q[3:0]] <= result ;
            Z_q = ~( |result);
        end

endmodule
