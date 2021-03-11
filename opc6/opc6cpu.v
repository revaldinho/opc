`define PUSHPOP 1
`define MUL 1
module opc6cpu(input[15:0] din,input clk,input reset_b,input[1:0] int_b,input clken,output vpa,output vda,output vio,output[15:0] dout,output[15:0] address,output rnw);
  parameter MOV=5'h0,AND=5'h1,OR=5'h2,XOR=5'h3,ADD=5'h4,ADC=5'h5,STO=5'h6,LD=5'h7,ROR=5'h8,JSR=5'h9,SUB=5'hA,SBC=5'hB,INC=5'hC,LSR=5'hD,DEC=5'hE,ASR=5'hF;
  parameter HLT=5'h10,BSWP=5'h11,PPSR=5'h12,GPSR=5'h13,RTI=5'h14,NOT=5'h15,OUT=5'h16,IN=5'h17,PUSH=5'h18,POP=5'h19,CMP=5'h1A,CMPC=5'h1B,MUL=5'h1C;
  parameter FET0=3'h0,FET1=3'h1,EAD=3'h2,RDM=3'h3,EXEC=3'h4,WRM=3'h5,INT=3'h6;
  parameter EI=3,S=2,C=1,Z=0,P0=15,P1=14,P2=13,IRLEN=12,IRLD=16,IRSTO=17,IRNPRED=18,IRWBK=19,INT_VECTOR0=16'h0002,INT_VECTOR1=16'h0004;
  reg [15:0]          OR_q,OR_d,PC_q,PC_d,PCI_q,result;
  reg [19:0]          IR_q, IR_d; (* RAM_STYLE="DISTRIBUTED" *)
  reg [15:0]          RF_q[15:0];
  reg [2:0]           FSM_q,FSM_d;
  reg [3:0]           swiid,PSRI_q;
  reg [7:0]           PSR_q ;
  reg                 zero,carry,sign,enable_int,reset_s0_b,reset_s1_b,pred_q, reset_s2_b, reset_s2_q;
  wire [4:0]          op       = {IR_q[IRNPRED],IR_q[11:8]};
  wire [4:0]          op_d     = { (din[15:13]==3'b001),din[11:8] };
  wire                pred_d   = (din[15:13]==3'b001) || (din[P2] ^ (din[P1] ? (din[P0] ? sign : zero): (din[P0] ? carry : 1))); // New data,new flags (in exec/fetch)
  wire                pred_din = (din[15:13]==3'b001) || (din[P2] ^ (din[P1]?(din[P0]?PSR_q[S]:PSR_q[Z]):(din[P0]?PSR_q[C]:1))); // New data,old flags (in fetch0)  
  wire [15:0]         RF_w_p2  = (IR_q[7:4]==4'hF) ? PC_q: {16{(IR_q[7:4]!=4'h0)}} & RF_q[IR_q[7:4]];                          // Port 2 always reads source reg
  wire [15:0]         RF_dout  = (IR_q[3:0]==4'hF) ? PC_q: {16{(IR_q[3:0]!=4'h0)}} & RF_q[IR_q[3:0]];                          // Port 1 always reads dest reg
  wire [15:0]         operand  = (IR_q[IRLEN]||IR_q[IRLD]||(op==INC)||(op==DEC)||(IR_q[IRWBK]))?OR_q:RF_w_p2;           // One word instructions operand usu comes from RF
`ifdef PUSHPOP
  wire [15:0]         RF_dout_d  = (IR_d[3:0]==4'hF) ? PC_d: {16{(IR_d[3:0]!=4'h0)}} & RF_q[IR_d[3:0]];                          // Port 1 always reads dest reg
  wire [15:0]         RF_w_p2_d  = (IR_d[7:4]==4'hF) ? PC_d: {16{(IR_d[7:4]!=4'h0)}} & RF_q[IR_d[7:4]];                          // Port 2 always reads source reg
  assign {rnw,dout,address} = {!(FSM_d==WRM), RF_w_p2_d,(FSM_d==WRM||FSM_d==RDM)? ((op==POP)? RF_dout_d: OR_d)  : PC_d};
`else
  assign {rnw,dout,address} = {!(FSM_d==WRM), RF_dout,(FSM_d==WRM||FSM_d==RDM)? OR_d: PC_d};
`endif
  assign {vpa,vda,vio}      = {((FSM_d==FET0)||(FSM_d==FET1)||(FSM_d==EXEC)),({2{(FSM_d==RDM)||(FSM_d==WRM)}} & {!((op==IN)||(op==OUT)),(op==IN)||(op==OUT)})};
  always @( * ) begin
    case (op)
      AND,OR               :{carry,result} = {PSR_q[C],(IR_q[8])?(RF_dout & operand):(RF_dout | operand)};
`ifdef MUL
      MUL                  :{carry,result} = (RF_dout * operand) & 17'h1FFFF;
`endif
      ADD,ADC,INC          :{carry,result} = RF_dout + operand + (IR_q[8] & PSR_q[C]);
      SUB,SBC,CMP,CMPC,DEC :{carry,result} = RF_dout + (operand ^ 16'hFFFF) + ((IR_q[8])?PSR_q[C]:1);
      XOR,GPSR             :{carry,result} = (IR_q[IRNPRED])?{PSR_q[C],8'b0,PSR_q}:{PSR_q[C],RF_dout ^ operand};
      NOT,BSWP             :{result,carry} = (IR_q[10])? {~operand,PSR_q[C]} : {operand[7:0],operand[15:8],PSR_q[C]};
      ROR,ASR,LSR          :{result,carry} = {(IR_q[10]==0)?PSR_q[C]:(IR_q[8]==1)?operand[15]:1'b0,operand};
      default              :{carry,result} = {PSR_q[C],operand} ; //LD,MOV,STO,JSR,IN,OUT,PUSH,POP and everything else
    endcase // case ( IR_q )
    {swiid,enable_int,sign,carry,zero} = (op==PPSR)?operand[7:0]:(IR_q[3:0]!=4'hF)?{PSR_q[7:3],result[15],carry,!(|result)}:PSR_q;
  end // always @ ( * )
  always @( * ) begin
    case (FSM_q)
`ifdef PUSHPOP
      FET0   : FSM_d = (din[IRLEN]) ? FET1 : (!pred_din) ? FET0 : ((din[11:8]==LD)||(din[11:8]==STO)||(op_d==PUSH)||(op_d==POP)) ? EAD : EXEC;
      EXEC   : FSM_d = ((!(&int_b) & PSR_q[EI])||((op==PPSR) && (|swiid)))?INT:((IR_q[3:0]==4'hF)||(op==JSR))?FET0:
                       (din[IRLEN]) ? FET1 : ((din[11:8]==LD)||(din[11:8]==STO)||(op_d==POP)||(op_d==PUSH))?EAD:(pred_d)?EXEC:FET0;
`else
      FET0   : FSM_d = (din[IRLEN]) ? FET1 : (!pred_din) ? FET0 : ((din[11:8]==LD)||(din[11:8]==STO)) ? EAD : EXEC;
      EXEC   : FSM_d = ((!(&int_b) & PSR_q[EI])||((op==PPSR) && (|swiid)))?INT:((IR_q[3:0]==4'hF)||(op==JSR))?FET0:
                       (din[IRLEN]) ? FET1 : ((din[11:8]==LD)||(din[11:8]==STO))?EAD:(pred_d)?EXEC:FET0;
`endif
      FET1   : FSM_d = (!pred_q )? FET0: ((IR_q[3:0]!=0) || (IR_q[IRLD])||IR_q[IRSTO])?EAD:EXEC;
      EAD    : FSM_d = (IR_q[IRLD]) ? RDM : (IR_q[IRSTO]) ? WRM : EXEC;
      WRM    : FSM_d = (!(&int_b) & PSR_q[EI])?INT:FET0;
      default: FSM_d = (FSM_q==RDM)? EXEC : FET0;  // Applies to INT and RDM plus undefined states
    endcase
  end
  always @ ( * ) begin
    if ( FSM_q == INT )
      PC_d = (!int_b[1])?INT_VECTOR1:INT_VECTOR0 ; // Always clear EI on taking interrupt
    else if (((FSM_q==FET0)||(FSM_q==FET1)) && reset_s2_b) // Wait one extra cycle after reset
      PC_d = PC_q + 1;
    else if ( FSM_q == EXEC)
      PC_d = (op==RTI)?PCI_q: ((IR_q[3:0]==4'hF)||(op==JSR))?result:(((!(&int_b)) && PSR_q[EI])||((op==PPSR)&&(|swiid)))?PC_q:PC_q + 1;
    else
      PC_d = PC_q;
  end
  always @ ( * ) begin
    IR_d = IR_q;
`ifdef PUSHPOP
    OR_d <= ((FSM_q==FET0)||(FSM_q==EXEC))?({16{op_d==PUSH}}^({12'b0,(op_d==DEC)||(op_d==INC)?din[7:4]:{3'b0,(op_d==POP)}})):(FSM_q==EAD)?RF_w_p2+OR_q:din;    
    if ((FSM_q==FET0)||(FSM_q==EXEC))
      IR_d = {(op_d==PUSH)||(op_d==POP),(din[15:13]==3'b001),(din[11:8]==STO)||(op_d==PUSH),(din[11:8]==LD)||(op_d==POP),din};
    else if (((FSM_q==EAD && (IR_q[IRLD]||IR_q[IRSTO]))||(FSM_q==RDM)))
      IR_d[7:0] = {IR_q[3:0],IR_q[7:4]}; // Swap source/dest reg in EA for reads and writes for writeback of 'source' in push/pop .. swap back again in RDMEM
`else    
    OR_d <= ((FSM_q==FET0)||(FSM_q==EXEC))?({12'b0,(op_d==DEC)||(op_d==INC)?din[7:4]:4'b0}):(FSM_q==EAD)?RF_w_p2+OR_q:din;
    if ((FSM_q==FET0)||(FSM_q==EXEC))
      IR_d = {1'b0,(din[15:13]==3'b001),(din[11:8]==STO),(din[11:8]==LD),din};
`endif
  end
  always @(posedge clk) begin
    if (clken) begin
      {reset_s0_b,reset_s1_b,reset_s2_b,pred_q} <= {reset_b,reset_s0_b,reset_s1_b,(FSM_q==FET0)?pred_din:pred_d};
      if (!reset_s1_b)
        {PCI_q,PSRI_q,PSR_q,PC_q,FSM_q,IR_q,OR_q} <= 0;
      else begin
        {PC_q,FSM_q,IR_q, OR_q} <= { PC_d, FSM_d, IR_d, OR_d};
        if ( FSM_q == INT )
          {PCI_q,PSRI_q,PSR_q[EI]} <= {PC_q,PSR_q[3:0],1'b0} ; // Always clear EI on taking interrupt
        else if ( FSM_q == EXEC)
          PSR_q <= (op==RTI)?{4'b0,PSRI_q}:{swiid,enable_int,sign,carry,zero}; // Clear SWI bits on return
        if (((FSM_q==EXEC) && !((op==CMP)||(op==CMPC)))|| (((FSM_q==WRM)||(FSM_q==RDM)) && IR_q[IRWBK]))
          RF_q[IR_q[3:0]] <= (op==JSR)? PC_q : result ;
      end
    end
  end
endmodule
