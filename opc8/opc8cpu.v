module opc8cpu(input[23:0] din,input clk,input reset_b,input[1:0] int_b,input clken,output vpa,output vda,output[23:0] dout,output[23:0] address,output rnw);
  parameter HALT=5'h00,NOT=5'h01,OR=5'h02,XOR=5'h03,BPERM=5'h04,ROR=5'h05,LSR=5'h06,ASR=5'h07,ROL=5'h08,RTI=5'h09,PPSR=5'h0A,GPSR=5'h0B;
  parameter BROR=5'h0C, BROL=5'h0D,MOV=5'h10,JSR=5'h11,CMP=5'h12,SUB=5'h13,ADD=5'h14,AND=5'h15,STO=5'h16,LD=5'h17;
  parameter FET=3'h0,FET1=3'h1,EAD=3'h2,RDM=3'h3,EXEC=3'h4,WRM=3'h5,INT=3'h6,EI=3,S=2,C=1,Z=0,INT_VECTOR0=24'h2,INT_VECTOR1=24'h4;
  reg [7:0]   PSR_q; (* RAM_STYLE="DISTRIBUTED" *)
  reg [23:0]  PC_q,PCI_q, RF_q[14:0], RF_pipe_q, OR_q, result; 
  reg [4:0]   IR_q;
  reg [3:0]   swiid,PSRI_q,dst_q,src_q;
  reg [2:0]   FSM_q, FSM_d;
  reg         zero,carry,sign,enable_int,reset_s0_b,reset_s1_b,subnotadd_q, rnw_q, vpa_q, vda_q;
  wire        pred         = (OR_q[21] ^ (OR_q[22]?(OR_q[23]?PSR_q[S]:PSR_q[Z]):(OR_q[23]?PSR_q[C]:1)));
  wire [23:0] RF_sout      = {24{(|src_q)&&IR_q[4:2]!=3'b111}} & ((src_q==4'hF)? PC_q : RF_q[src_q]);
  wire [23:0] bytes        = (IR_q==BROL)?{OR_q[15:0],OR_q[23:16]}:{OR_q[7:0],OR_q[23:8]};
  assign {rnw,dout,address}= {rnw_q, RF_pipe_q, (vpa_q)? PC_q : OR_q};
  assign {vpa,vda}         = {vpa_q, vda_q};  
  always @( * ) begin
    case (IR_q)
      AND,OR      :{carry,result} = {PSR_q[C],(IR_q==AND)?(RF_pipe_q & OR_q):(RF_pipe_q | OR_q)};
      ROL,NOT     :{carry,result} = (IR_q==NOT)? {PSR_q[C], ~OR_q} : {OR_q, PSR_q[C]};      
      ADD,SUB,CMP :{carry,result} = RF_pipe_q + OR_q + subnotadd_q; // OR_q negated in EAD if required for sub/cmp
      XOR,GPSR    :{carry,result} = (IR_q==GPSR)?{PSR_q[C],8'b0,PSR_q}:{PSR_q[C],RF_pipe_q ^ OR_q};
      ROR,ASR,LSR :{result,carry} = {(IR_q==ROR)?PSR_q[C]:(IR_q==ASR)?OR_q[23]:1'b0,OR_q};
      BROL,BROR   :{carry,result} = { (IR_q==BROL)? (|OR_q[23:16]): (|OR_q[7:0]), OR_q};
      default     :{carry,result} = {PSR_q[C],OR_q} ;
    endcase // case ( IR_q )
    {swiid,enable_int,sign,carry,zero} = (IR_q==PPSR)?OR_q[7:0]:(dst_q!=4'hF)?{PSR_q[7:3],result[23],carry,!(|result)}:PSR_q;
    case (FSM_q)
      FET    : FSM_d = (din[20:19]==2'b11)? FET1 : EAD;
      FET1   : FSM_d = EAD; // Could check predicates here to speed up skipped double word instructions     
      EAD    : FSM_d = (!pred) ? FET : (IR_q==LD) ? RDM : (IR_q==STO) ? WRM : EXEC;
      EXEC   : FSM_d = ((!(&int_b) & PSR_q[EI])||(IR_q==PPSR&&(|swiid)))?INT:(dst_q==4'hF)?FET:(din[20:19]==2'b11)? FET1 : (dst_q==4'hF||IR_q==JSR)?FET:EAD;
      WRM    : FSM_d = (!(&int_b) & PSR_q[EI])?INT:FET;
      default: FSM_d = (FSM_q==RDM)? EXEC : FET;
    endcase
  end // always @ ( * )
  always @(posedge clk)
    if (clken) begin
      RF_pipe_q <= (dst_q==4'hF)? PC_q : RF_q[dst_q] & {24{(|dst_q)}};
      // Sign extension on short immediates only if source field==0 being done on reading memory - may move this to EAD state...
      OR_q <= (FSM_q==EAD) ? (IR_q==BROL||IR_q==BROR)?bytes: ((RF_sout+OR_q)^{24{(IR_q==SUB||IR_q==CMP)}} ): (FSM_q!=FET)? din: { {16{(din[7]&(|din[11:8]))}}, din[7:0]};      
      {reset_s0_b,reset_s1_b, subnotadd_q} <= {reset_b,reset_s0_b, IR_q!=ADD};
      if (!reset_s1_b) begin
        {PC_q,PCI_q,PSRI_q,PSR_q,FSM_q,vda_q} <= 0;
        {rnw_q, vpa_q} <= 2'b11;        
      end      
      else begin
        {FSM_q, rnw_q} <= {FSM_d, !(FSM_d==WRM) } ;
        {vpa_q, vda_q} <= {FSM_d==FET||FSM_d==EXEC,FSM_d==RDM||FSM_d==WRM};        
        if ((FSM_q==FET)||(FSM_q==EXEC))
          {IR_q, dst_q, src_q} <= { (din[20:19]==2'b11)?2'b10: din[20:19], din[18:8]}; // Alias 'long' opcodes to short equivalent 
        else if (FSM_q==EAD & IR_q==CMP )
          dst_q <= 4'b0; // Zero dest address after reading it in EAD for CMP operations
        if ( FSM_q == INT )
          {PC_q,PCI_q,PSRI_q,PSR_q[EI]} <= {(!int_b[1])?INT_VECTOR1:INT_VECTOR0,PC_q,PSR_q[3:0],1'b0};
        else if (FSM_q==FET)
          PC_q  <= PC_q + 1;
        else if ( FSM_q == EXEC) begin
          PC_q <= (IR_q==RTI)?PCI_q: (dst_q==4'hF) ? result[23:0] : (IR_q==JSR)?OR_q:((!(&int_b)&&PSR_q[EI])||(IR_q==PPSR&&(|swiid)))?PC_q:PC_q + 1;
          PSR_q <= (IR_q==RTI)?{4'b0,PSRI_q}:{swiid,enable_int,sign,carry,zero};
          RF_q[dst_q] <= result;
        end
      end
    end
endmodule // opc8cpu

