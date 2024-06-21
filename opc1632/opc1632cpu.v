`define BARREL_SHIFTER 1
`define MULTIPLIER     1
`define OPTIONAL_ISA   1
`define PUSHPOP        1

module opc1632cpu(input[15:0] din,input clk,input rst_b,input[1:0] int_b,input clken,output vpa,output vda,output[15:0] dout,output reg [31:0] address,output rnw);
  // Non-Predicated Instructions
  parameter AND  =6'h00;
  parameter OR   =6'h01;
  parameter XOR  =6'h02;
  parameter ADD  =6'h03;
  parameter ADC  =6'h04;
  parameter SUB  =6'h05;
  parameter SBC  =6'h06;
  parameter CMP  =6'h07;
  parameter CMPC =6'h08;
  parameter NOT  =6'h09;
  parameter SXT  =6'h0A;
`ifdef BARREL_SHIFTER
  parameter BSROR  =6'h0B;
  parameter BSLSR  =6'h0C;
  parameter BSASR  =6'h0D;
  parameter BSROL  =6'h0E;
  parameter BSASL  =6'h0F;
`else
  parameter ROR  =6'h0B;
  parameter LSR  =6'h0C;
  parameter ASR  =6'h0D;
  parameter BROR =6'h0E;
  parameter HROR =6'h0F;
`endif
  // NON-PREDICATED INSTRUCTIONS
  parameter HLT  =6'h10;
  parameter PPSR =6'h11;
  parameter GPSR =6'h12;
  parameter RTI  =6'h13;
  // LSU instructions
  parameter LDW  =6'h14;
  parameter STW  =6'h15;
  parameter LDH  =6'h16;
  parameter STH  =6'h17;

`ifdef MULTIPLIER
  parameter MUL  =6'h18;
`endif
`ifdef PUSHPOP
  parameter PUSHW =6'h1A;
  parameter POPW  =6'h1B;
`endif
`ifdef OPTIONAL_ISA
  parameter XRB   =6'h19;
`endif

  // PREDICATED INSTRUCTIONS (LISTED WITH COND=0/LSBs=0)
  parameter JSR  =6'h20;
  parameter MOV  =6'h28;
  parameter INC  =6'h30;
  parameter INC2 =6'h38;
  // FSM States
  parameter FET0  =5'h00;
  parameter FET1  =5'h01;
  parameter FET2  =5'h02;
  parameter EAD   =5'h03;
  parameter RD0   =5'h04;
  parameter RD1   =5'h05;
  parameter EXEC  =5'h06;
  parameter WR0   =5'h07;
  parameter WR1   =5'h08;
  parameter INT   =5'h09;
  parameter WRH   =5'h0A;
  parameter RDH   =5'h0B;
`ifdef PUSHPOP
  parameter POP0  =5'h0C;
  parameter POP1  =5'h0D;
  parameter POP2  =5'h0E;
  parameter PUSH0 =5'h0F;
  parameter PUSH1 =5'h10;
`endif
  // Flags
  parameter     BANK = 4;
  parameter     EI   =3;
  parameter     S    =2;
  parameter     C    =1;
  parameter     Z    =0;
  // Predicate bits are 3 LSBs of the opcode field
  parameter     P0  =10;
  parameter     P1  = 9;
  parameter     P2  = 8;
  // Misc
  parameter     INT_VECTOR0=32'h0002;
  parameter     INT_VECTOR1=32'h0004;
  // Macros
`define IMM6_b5 14
`define IMM6_b4 11
`define IS_COND_d  (din[13]  ==1'b1)
`define PCI 4'hF

  reg [31:0]     OR_d,OR_q,PC_d,PC_q,result,RF1_d,RF1_q,PCI_q;

`ifdef PUSHPOP
  reg [31:0]           addr_inc_d, addr_inc_q;
`endif

  // (* RAM_STYLE="DISTRIBUTED" *)
  (* RAM_STYLE="BLOCK" *)
  reg [31:0]    RF_q[31:0];
  reg [7:0]     PSR_d,PSR_q;
  reg [5:0]     op_d,op_q;
  reg [4:0]     FSM_q, FSM_d;
  reg [4:0]     PSRI_d,PSRI_q;
  reg [4:0]     rdst_d,rdst_q,rsrc_d,rsrc_q;
  reg [1:0]     len_d, len_q;
  reg           carry,pred_d,pred_q;

`ifdef PUSHPOP
  assign rnw   = !(FSM_d==WRH||FSM_d==WR0||FSM_d==WR1||FSM_d==PUSH0||FSM_d==PUSH1);
  assign vda   = (FSM_d==RDH)||(FSM_d==RD0)||(FSM_d==RD1)||(FSM_d==WRH)||(FSM_d==WR0)||(FSM_d==WR1)||(FSM_d==PUSH0)||(FSM_d==PUSH1)||(FSM_d==POP0)||(FSM_d==POP1);
`else
  assign rnw   = !(FSM_d==WRH||FSM_d==WR0||FSM_d==WR1);
  assign vda   = (FSM_d==RDH)||(FSM_d==RD0)||(FSM_d==RD1)||(FSM_d==WRH)||(FSM_d==WR0)||(FSM_d==WR1);
`endif
  assign dout  = RF1_q ;
  assign vpa   = (FSM_d==FET0)||(FSM_d==FET1)||(FSM_d==FET2);

  always @(*) begin
    // defaults
    {OR_d,PC_d,RF1_d,len_d,op_d,pred_d,rdst_d,rsrc_d,PSRI_d,PSR_d,carry}={OR_q,PC_q,RF1_q,len_q,op_q,pred_q,rdst_q,rsrc_q,PSRI_q,PSR_q,PSR_q[C]};
    result = OR_q; // default
    address = PC_q;

`ifdef PUSHPOP
    addr_inc_d = addr_inc_q;
`endif

    case (op_q)
      AND,OR          : result = (op_q==AND)?(RF1_q & OR_q):(RF1_q | OR_q);
      ADD,ADC,INC     :{carry,result} = RF1_q + OR_q + ((op_q==ADC) & PSR_q[C]);
      SUB,SBC,CMP,CMPC:{carry,result} = RF1_q + (OR_q ^ 32'hFFFF) + (op_q==SBC||op_q==CMPC)?PSR_q[C]:1;
      XOR,GPSR        : result = (op_q==GPSR)?{24'b0,PSR_q}: RF1_q ^ OR_q;
      NOT,SXT         : result = (op_q==NOT) ? ~OR_q : {{16{OR_q[15]}},OR_q[15:0]};

`ifdef OPTIONAL_ISA
      XRB 	      : PSR_d[BANK] = !PSR_q[BANK];
`endif

`ifdef MULTIPLIER
      MUL             : {carry, result} = OR_q[15:0] * RF1_q[15:0] ;
`endif
`ifdef BARREL_SHIFTER
      BSROR           : {result,carry}  = {RF1_q,PSR_q[C],RF1_q,PSR_q[C] } >> OR_q[4:0];         // truncate to bits [32:0] for right shift
      BSASR           :	{result,carry}  = {{33{RF1_q[31]}},RF1_q,1'b0 } >> OR_q[4:0];            // truncate to bits [32:0] for right shift
      BSLSR           : {result,carry}  = {33'b0,RF1_q,1'b0 } >> OR_q[4:0] ;                     // truncate to bits [32:0] for right shift
      BSROL           : {carry, result} = ({PSR_q[C],RF1_q,PSR_q[C],RF1_q} << OR_q[4:0]) >> 33 ; // get MSBs [65:33] for left shift
      BSASL           : {carry, result} = ({PSR_q[C], RF1_q, 33'b0 } << OR_q[4:0]) >>33 ;        // get MSBs [65:33] for left shift
`else
      BROR,HROR       : result = (op_q==BROR)? {OR_q[7:0], OR_q[31:8]}: {OR_q[15:0],OR_q[31:16]};
      ROR,ASR,LSR     :{result,carry} = {(op_q==ROR)?PSR_q[C]:(op_q==ASR)?OR_q[31]:1'b0,OR_q};
`endif
      default         : result = OR_q;
      //LD,MOV,STO,JSR and everything else
    endcase // case (op_q)


    case (FSM_q)
      FET0 : begin
        FSM_d = (din[15]) ? FET1 : EAD;
        PC_d  = PC_q+1 ;
        OR_d  = (din[13:12]==INC[5:4])?{{26{din[`IMM6_b5]}},din[`IMM6_b4],din[7:4]}:32'b0;
        len_d = din[15:14];
        op_d  = (`IS_COND_d)? ((din[13:12]==INC[5:4])?INC : {din[13:11],3'b0}) : din[13:8];
        // Re-map INC2->INC, Zero LSBs opcodes with cond. or imm bits
        pred_d = (! `IS_COND_d)||(din[P2] ^ (din[P1]?(din[P0]?PSR_q[S]:PSR_q[Z]):(din[P0]?PSR_q[C]:1)));
        // New data,old flags (in fetch0), always TRUE if non-predicated instr
        rsrc_d = (din[13:12]==INC[5:4])? {PSR_q[BANK] & !(din[3]&din[2]),din[3:0]} : {PSR_q[BANK] & !(din[7]&din[6]),din[7:4]} ;
        // INC implies Rd as source and dest
        rdst_d = {PSR_q[BANK] & !(din[3]&din[2]) ,din[3:0]}; // Only lower registers get remapped by the bank bit
      end
      FET1 : begin
        FSM_d = (len_q[0]) ? FET2 : EAD;
        PC_d = PC_q+1;
        OR_d = {{16{din[15]}}, din};
      end
      FET2  : begin
        FSM_d = EAD;
        PC_d = PC_q+1;
        OR_d = {OR_q[15:0], din};
      end
      EAD  : begin
        if (pred_q)
          case (op_q)
            LDH:   begin FSM_d = RDH; address = OR_q ; end
            LDW:   begin FSM_d = RD0; address = OR_q & 32'hFFFFFFFE; end
            STH:   begin FSM_d = WRH; address = OR_q ; end
            STW:   begin FSM_d = WR0; address = OR_q & 32'hFFFFFFFE; end
`ifdef PUSHPOP
            POPW:  begin FSM_d = POP0;  addr_inc_d = OR_q ; address = RF1_q & 32'hFFFFFFFE; end // Use rsrc directly for address output (post increment)
            PUSHW: begin FSM_d = PUSH0; addr_inc_d = OR_q ; address = OR_q & 32'hFFFFFFFE; end
`endif
            default: FSM_d=EXEC;
          endcase // case (op_q )
        else
          FSM_d = FET0;

        OR_d  = ((rsrc_q[3:0]==4'hF)?PC_q: {32{(rsrc_q[3:0]!=4'h0)}} & RF_q[rsrc_q]) + OR_q; // Port 2 always reads source reg
        RF1_d = ((rdst_q[3:0]==4'hF)?PC_q: {32{(rdst_q[3:0]!=4'h0)}} & RF_q[rdst_q]);        // Port 1 always reads dest reg
      end
      EXEC  : begin
        PC_d = (op_q==RTI)? PCI_q: ((rdst_q[3:0]==4'hF)||(op_q==JSR)) ? result: PC_q;
        FSM_d = ((!(&int_b) & PSR_q[EI])||((op_q==PPSR) && (|PSR_q[7:5])))?INT: FET0; // PSR_q[7:5]==swi id
        PSR_d = (op_q==RTI)?{3'b0,PSRI_q}:(op_q==PPSR)?OR_q[7:0]: (rdst_q[3:0]!=4'hF)? {PSR_q[7:3],result[31],carry,!(|result)}: PSR_q;
        // Clear SWI bits and restore register bank bit plus flags on return from Interrupt
      end

      WR0  : begin
        FSM_d = WR1;
        address = OR_q | 32'h00000001;
      end
      WR1  : FSM_d = (!(&int_b) & PSR_q[EI])?INT:FET0;
      WRH  : FSM_d = (!(&int_b) & PSR_q[EI])?INT:FET0;

`ifdef PUSHPOP
      POP0: begin
        FSM_d = POP1;
        address = RF1_q | 32'h00000001;
        OR_d = {{16{din[15]}}, din};
      end
      POP1: begin
        FSM_d = POP2;
        OR_d = {OR_q[15:0], din};
        // swap over dest and source for writeback of pointer
        rdst_d = rsrc_q;
        rsrc_d = rdst_q;
      end
      POP2: begin
        // Write back rsrc <- rsrc + 2 in this state before going to EXEC to write OR_q into rdest
        // swap over dest and source again for writeback of data
        rdst_d = rsrc_q;
        rsrc_d = rdst_q;
        FSM_d = EXEC;
      end
      PUSH0: begin
        FSM_d = PUSH1;
        address = OR_q | 32'h00000001;
      end
      PUSH1: begin
        // Set write back register to be the source (pointer) ready for write back in EXEC as usual
        rdst_d = rsrc_q;
        FSM_d = EXEC;
      end
`endif

      RD0  : begin
        FSM_d = RD1;
        OR_d = {{16{din[15]}}, din};
        address = OR_q | 32'h00000001;
      end
      RD1  : begin
        FSM_d = EXEC;
        OR_d = {OR_q[15:0], din};
      end
      RDH  : begin
        FSM_d = EXEC;
        OR_d = {{16{din[15]}}, din};
      end
      INT  : begin
        FSM_d   = FET0;
        PC_d   = (!int_b[1])?INT_VECTOR1:INT_VECTOR0;
        PSRI_d  = PSR_q[4:0]; //bit 4 is register bank bit
        PSR_d[EI] = 1'b0;
	PSR_d[BANK] = 1'b1;
        // Always clear EI on taking interrupt
      end
      default: FSM_d = FET0;
    endcase
  end

  always @(posedge clk or negedge rst_b)
    if (!rst_b) {PC_q,PSR_q,FSM_q} <= {32'b0,8'b0,FET0};
    else if (clken) begin
      begin
	{FSM_q,PSRI_q,PSR_q} <= {FSM_d,PSRI_d,PSR_d};
`ifdef PUSHPOP
        addr_inc_q <= addr_inc_d;
`endif
	{OR_q,PC_q,RF1_q,len_q,op_q,pred_q,rdst_q,rsrc_q}<={OR_d,PC_d,RF1_d,len_d,op_d,pred_d,rdst_d,rsrc_d};
	if ( (FSM_q==EXEC) && !(op_q==CMP|| op_q==CMPC || op_q==STW || op_q==STH || op_q==PPSR) )RF_q[rdst_q] <= (op_q==JSR)? PC_q : result;
`ifdef PUSHPOP
        else if ( FSM_q==POP2) RF_q[rdst_q] <= addr_inc_q;
`endif
	if (FSM_q==INT) PCI_q <= PC_q;
      end
    end


endmodule // opc1632cpu
