module opc5cpu( inout[15:0] data, output[15:0] address, output rnw, input clk, input reset_b);
   parameter FETCH0=3'h0, FETCH1=3'h1, EA_ED=3'h2, RDMEM=3'h3, EXEC=3'h4, WRMEM=3'h5;
   parameter PRED_C=15, PRED_NZ=14, FSM_MAP0=13, FSM_MAP1=12;
   parameter LD=2'b00, STO=2'b11, ADD=2'b01, NAND=2'b10;

   reg [15:0] OR_q, IR_q, PC_q, result;
   (* RAM_STYLE="DISTRIBUTED" *)
   reg [15:0] GRF_q[15:0];
   reg [2:0]  FSM_q;
   reg        C_q, Z_q, carry;
   wire [3:0]  grf_radr=(FSM_q==EXEC || FSM_q==WRMEM)?IR_q[3:0]:IR_q[7:4];
   wire [15:0] grf_dout= (grf_radr==4'hF) ? PC_q: {16{(grf_radr!=4'h0)}} & GRF_q[grf_radr];

   assign      rnw= ! (FSM_q==WRMEM) ;
   assign      data=(FSM_q==WRMEM)?grf_dout:16'bz ;
   assign      address=( FSM_q==WRMEM || FSM_q == RDMEM)? OR_q : PC_q;

   always @( * )
     begin
        {carry, result} = { C_q, 16'bx} ;
        case (IR_q[12:10])
          LD : result=OR_q ;
          ADD : {carry, result}=grf_dout + OR_q;
          NAND : result=~(grf_dout & OR_q);
        endcase // case ( IR_q )
     end

   always @(posedge clk or negedge reset_b )
     if (!reset_b)
       FSM_q <= FETCH0;
     else
       case (FSM_q)
         FETCH0 : FSM_q <= FETCH1; // opc5 always uses 2 word instructions
         FETCH1 : FSM_q <= (! ((IR_q[PRED_C]| C_q)&(IR_q[PRED_NZ]| !Z_q)))? FETCH0: EA_ED ; // Skip to next instruction if predicates are not satisfied;
         EA_ED  : FSM_q <= (IR_q[FSM_MAP1]) ? RDMEM : (IR_q[12:10]==STO ) ? WRMEM : EXEC;
         RDMEM  : FSM_q <= EXEC;
         default: FSM_q <= FETCH0;
       endcase

   always @(posedge clk)
     case(FSM_q)
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
       IR_q <= data;
     else if ( FSM_q == EXEC)
       { C_q, Z_q, GRF_q[IR_q[3:0]]}  <= { carry, !(|result), result};

endmodule
