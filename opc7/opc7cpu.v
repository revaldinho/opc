module opc7cpu(input[31:0] din,input clk,input reset_b,input[1:0] int_b,input clken,output vpa,output vda,output vio,output[31:0] dout,output[19:0] address,output rnw,
               output vpa_nxt,output vda_nxt,output vio_nxt,output[31:0] dout_nxt,output[19:0] address_nxt,output rnw_nxt);

  parameter MOV=5'h0,MOVT=5'h1,XOR=5'h2,AND=5'h3,OR=5'h4,NOT=5'h5,CMP=5'h6,SUB=5'h7,ADD=5'h8,BPERM=5'h9,ROR=5'hA,LSR=5'hB,JSR=5'hC,ASR=5'hD,ROL=5'hE;
  parameter HLT=5'h10,RTI=5'h11,PPSR=5'h12,GPSR=5'h13,OUT=5'h18,IN=5'h19,STO=5'h1A,LD=5'h1B,LJSR=5'h1C,LMOV=5'h1D,LSTO=5'h1E,LLD=5'h1F;
  parameter FET=3'h0,EAD=3'h1,RDM=3'h2,EXEC=3'h3,WRM=3'h4,INT=3'h5,EI=3,S=2,C=1,Z=0,INT_VECTOR0=20'h2,INT_VECTOR1=20'h4;

  reg [19:0]          address_q, address_next;
  reg [19:0]          PC_q,PC_next,PCI_q,PCI_next;(* RAM_STYLE="DISTRIBUTED" *)
  reg [31:0]          RF_q[14:0], RF_pipe_q, RF_pipe_next, OR_q, OR_next, result, EA_next, IDEC_next, IDEC_q;
  reg [7:0]           PSR_q,PSR_next;
  reg [4:0]           IR_q, IR_next;
  reg [3:0]           swiid,PSRI_q,PSRI_next,dst_q,dst_next,src_q,src_next;
  reg [2:0]           FSM_q, FSM_next, FSM_d;
  reg                 zero,carry,sign,enable_int,reset_s0_b,reset_s0_b_next,reset_s1_b,reset_s1_b_next,subnotadd_q,subnotadd_next,rnw_q, rnw_next,vpa_q, vpa_next, vda_q, vda_next, vio_q, vio_next;

  wire                pred          = (OR_q[29] ^ (OR_q[30]?(OR_q[31]?PSR_q[S]:PSR_q[Z]):(OR_q[31]?PSR_q[C]:1)));
  wire [31:0]         RF_sout       = {32{(|src_q)&&IR_q[4:2]!=3'b111}} & ((src_q==4'hF)? {12'b0,PC_q} : RF_q[src_q]);
  wire [7:0]          bytes0        = {8{~OR_q[2] }} & ((OR_q[1])?  ((OR_q[0]) ?RF_sout[31:24] :RF_sout[23:16]):(OR_q[0]) ? RF_sout[15:8]:RF_sout[7:0]);
  wire [7:0]          bytes1        = {8{~OR_q[6] }} & ((OR_q[5])?  ((OR_q[4]) ?RF_sout[31:24] :RF_sout[23:16]):(OR_q[4]) ? RF_sout[15:8]:RF_sout[7:0]);
  wire [7:0]          bytes2        = {8{~OR_q[10]}} & ((OR_q[9])?  ((OR_q[8]) ?RF_sout[31:24] :RF_sout[23:16]):(OR_q[8]) ? RF_sout[15:8]:RF_sout[7:0]);
  wire [7:0]          bytes3        = {8{~OR_q[14]}} & ((OR_q[13])? ((OR_q[12])?RF_sout[31:24] :RF_sout[23:16]):(OR_q[12])? RF_sout[15:8]:RF_sout[7:0]);
  wire [31:0]         din_sxt       = (IR_q[4:2]==3'h7)? {{12{OR_q[19]}},OR_q[19:0]} : {{16{OR_q[15]}}, OR_q[15:0]};

  integer             i;

  assign {rnw,dout,address} = {rnw_q, RF_pipe_q, address_q};
  assign {rnw_nxt,dout_nxt,address_nxt} = {rnw_next, RF_pipe_next, address_next};
  assign {vpa,vda,vio}      = {vpa_q, vda_q, vio_q };
  assign {vpa_nxt,vda_nxt,vio_nxt}      = {vpa_next, vda_next, vio_next };

  always @( * ) begin
    if ( FSM_q == EAD ) 
      for (i=0 ; i<32 ; i= i+1)
        IDEC_next[i] = (IR_q==i) ? 1'b1 : 1'b0;
    else
      IDEC_next = IDEC_q;      
  end
  
  always @( * ) begin
    case (1'b1)
      IDEC_q[AND],IDEC_q[OR]              :{carry,result} = {PSR_q[C],(IDEC_q[AND])?(RF_pipe_q & OR_q):(RF_pipe_q | OR_q)};
      IDEC_q[MOVT],IDEC_q[ROL]            :{carry,result} = (IDEC_q[ROL])? {OR_q, PSR_q[C]} :{PSR_q[C], OR_q[15:0], RF_pipe_q[15:0]} ;
      IDEC_q[ADD],IDEC_q[SUB],IDEC_q[CMP] :{carry,result} = RF_pipe_q + OR_q + subnotadd_q; // OR_q negated in EAD if required for sub/cmp
      IDEC_q[XOR],IDEC_q[GPSR]            :{carry,result} = (IDEC_q[GPSR])?{PSR_q[C],8'b0,PSR_q}:{PSR_q[C],RF_pipe_q ^ OR_q};
      IDEC_q[NOT]                         :{result,carry} = {~OR_q,PSR_q[C]};
      IDEC_q[ROR],IDEC_q[ASR],IDEC_q[LSR] :{result,carry} = {(IDEC_q[ROR])?PSR_q[C]:(IDEC_q[ASR])?OR_q[31]:1'b0,OR_q};
      IDEC_q[JSR],IDEC_q[LJSR]            :{result,carry} = { 12'b0, PC_q, PSR_q[C]};
      default                             :{carry,result} = {PSR_q[C],OR_q} ;
    endcase // case ( IR_q )
    {swiid,enable_int,sign,carry,zero} = (IDEC_q[PPSR])?OR_q[7:0]:(dst_q!=4'hF)?{PSR_q[7:3],result[31],carry,!(|result)}:PSR_q;
  end // always @ ( * )
  
  always @( * ) begin
    case (FSM_q)
      FET    : FSM_d = EAD;
      EAD    : FSM_d = (!pred) ? FET : (IDEC_next[LD]||IDEC_next[LLD]||IDEC_next[IN]) ? RDM : (IDEC_next[STO]||IDEC_next[LSTO]||IDEC_next[OUT]) ? WRM : EXEC;
      EXEC   : FSM_d = ((!(&int_b) & PSR_q[EI])||(IDEC_q[PPSR]&&(|swiid)))?INT:(dst_q==4'hF||IDEC_q[JSR]||IDEC_q[LJSR])?FET:EAD;
      WRM    : FSM_d = (!(&int_b) & PSR_q[EI])?INT:FET;
      default: FSM_d = (FSM_q==RDM)? EXEC : FET;
    endcase
  end // always @ ( * )
  
  always @( * ) begin
    RF_pipe_next = RF_pipe_q;
    OR_next = OR_q;
    reset_s0_b_next = reset_s0_b;
    reset_s1_b_next = reset_s1_b;
    subnotadd_next = subnotadd_q;
    PC_next = PC_q;
    PCI_next = PCI_q;
    PSRI_next = PSRI_q;
    PSR_next = PSR_q;
    FSM_next = FSM_q;
    vda_next = vda_q;
    vio_next = vio_q;
    rnw_next = rnw_q;
    vpa_next = vpa_q;
    IR_next = IR_q;
    dst_next = dst_q;
    src_next = src_q;
    RF_pipe_next = (dst_q==4'hF)? {12'b0,PC_q} : RF_q[dst_q] & {32{(|dst_q)}};
    // OR_next is a dont care in INT and WRM states but force it to come from internal FFs rather than the databus to avoid a false RAM-RAM path
    EA_next  = RF_sout+din_sxt ;
    OR_next  = (FSM_q==EAD||FSM_q==INT||FSM_q==WRM)? (IDEC_next[BPERM])?({bytes3,bytes2,bytes1,bytes0}): EA_next ^ {32{IDEC_next[SUB]||IDEC_next[CMP]}} : din;
    {reset_s0_b_next,reset_s1_b_next, subnotadd_next} = {reset_b,reset_s0_b, IR_q!=ADD};
    if (!reset_s1_b) begin
      {PC_next,PCI_next,PSRI_next,PSR_next,FSM_next,vda_next,vio_next} = 0;
      {rnw_next, vpa_next} = 2'b11;
    end
    else begin
      {FSM_next, rnw_next} = {FSM_d, !(FSM_d==WRM) } ;
      {vpa_next, vda_next, vio_next} = {(FSM_d==FET||FSM_d==EXEC),({2{FSM_d==RDM||FSM_d==WRM}}&{!(IDEC_next[IN]||IDEC_next[OUT]),IDEC_next[IN]||IDEC_next[OUT]})};
      if ((FSM_q==FET)||(FSM_q==EXEC))
        {IR_next, dst_next, src_next} = din[28:16] ;
      else if (FSM_q==EAD & IDEC_next[CMP] )
        dst_next = 4'b0; // Zero dest address after reading it in EAD for CMP operations
      if ( FSM_q == INT )
        {PC_next,PCI_next,PSRI_next,PSR_next[EI]} = {(!int_b[1])?INT_VECTOR1:INT_VECTOR0,PC_q,PSR_q[3:0],1'b0};
      else if (FSM_q==FET)
        PC_next  = PC_q + 1;
      else if ( FSM_q == EXEC) begin
        PC_next = (IDEC_q[RTI])?PCI_q: (dst_q==4'hF) ? result[19:0] : (IDEC_q[JSR]||IDEC_q[LJSR])? OR_q[19:0]:((!(&int_b)&&PSR_q[EI])||(IDEC_q[PPSR]&&(|swiid)))?PC_q:PC_q + 1;
        PSR_next = (IDEC_q[RTI])?{4'b0,PSRI_q}:{swiid,enable_int,sign,carry,zero};
      end
    end // else: !if(!reset_s1_b)
  end

  always @( * ) begin
    address_next = (vpa_next)? PC_next : EA_next[19:0];
  end

  always @(posedge clk)
    if (clken) begin
      RF_pipe_q <= RF_pipe_next;
      OR_q <= OR_next;
      reset_s0_b <= reset_s0_b_next;
      reset_s1_b <= reset_s1_b_next;
      subnotadd_q <= subnotadd_next;
      PC_q <= PC_next;
      PCI_q <= PCI_next;
      PSRI_q <= PSRI_next;
      PSR_q <= PSR_next;
      FSM_q <= FSM_next;
      vda_q <= vda_next;
      vio_q <= vio_next;
      rnw_q <= rnw_next;
      vpa_q <= vpa_next;
      IR_q <= IR_next;
      IDEC_q <= IDEC_next;
      dst_q <= dst_next;
      src_q <= src_next;
      address_q <= address_next;
    end

  always @(posedge clk)
    if ( FSM_q == EXEC)
      RF_q[dst_q] <= result;

endmodule
