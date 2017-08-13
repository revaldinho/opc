// Reimplement simpler state machine from OPC5 - force all instructions through EAD
module opc6cpu(input[15:0] din,input clk,input reset_b,input[1:0] int_b,input clken,output vpa,output vda,output vio,output[15:0] dout,output[15:0] address,output rnw);
    parameter MOV=5'h0,AND=5'h1,OR=5'h2,XOR=5'h3,ADD=5'h4,ADC=5'h5,STO=5'h6,LD=5'h7,ROR=5'h8,JSR=5'h9,SUB=5'hA,SBC=5'hB,INC=5'hC,LSR=5'hD,DEC=5'hE,ASR=5'hF;
    parameter HLT=5'h10,BSWP=5'h11,PPSR=5'h12,GPSR=5'h13,RTI=5'h14,NOT=5'h15,OUT=5'h16,IN=5'h17,PUSH=5'h18,POP=5'h19,CMP=5'h1A,CMPC=5'h1B;    
    parameter FET0=3'h0,FET1=3'h1,EAD=3'h2,RDM=3'h3,EXEC=3'h4,WRM=3'h5,INT=3'h6;
    parameter EI=3,S=2,C=1,Z=0,P0=15,P1=14,P2=13,IRLEN=12,IRLD=16,IRSTO=17,IRNPRED=18,INT_VECTOR0=16'h0002,INT_VECTOR1=16'h0004;
    reg [15:0] OR_q,PC_q,PCI_q,result;
    reg [18:0] IR_q; (* RAM_STYLE="DISTRIBUTED" *)
    reg [15:0] RF_q[15:0];
    reg [2:0]  FSM_q;
    reg [3:0]  swiid,PSRI_q;
    reg [7:0]  PSR_q ;
    reg        zero,carry,sign,enable_int,reset_s0_b,reset_s1_b;
    wire [4:0]  op            = {IR_q[IRNPRED],IR_q[11:8]};
    wire [4:0]  op_d          = { (din[15:13]==3'b001),din[11:8] };
    wire        pred          = (IR_q[15:13]==3'b001) || (IR_q[P2] ^ (IR_q[P1]?(IR_q[P0]?PSR_q[S]:PSR_q[Z]):(IR_q[P0]?PSR_q[C]:1))); // New data,old flags (in fetch0)    
    wire [15:0] RF_w_p2       = (IR_q[7:4]==4'hF) ? PC_q: {16{(IR_q[7:4]!=4'h0)}} & RF_q[IR_q[7:4]];                          // Port 2 always reads source reg
    wire [15:0] RF_dout       = (IR_q[3:0]==4'hF) ? PC_q: {16{(IR_q[3:0]!=4'h0)}} & RF_q[IR_q[3:0]];                          // Port 1 always reads dest reg
    assign {rnw,dout,address} = {!(FSM_q==WRM), RF_w_p2,(FSM_q==WRM||FSM_q==RDM)? ((op==POP)? RF_dout: OR_q)  : PC_q};
    assign {vpa,vda,vio}      = {((FSM_q==FET0)||(FSM_q==FET1)||(FSM_q==EXEC)),({2{(FSM_q==RDM)||(FSM_q==WRM)}} & {!((op==IN)||(op==OUT)),(op==IN)||(op==OUT)})};
    always @( * ) begin
        case (op)
            AND,OR               :{carry,result} = {PSR_q[C],(IR_q[8])?(RF_dout & OR_q):(RF_dout | OR_q)};
            ADD,ADC,INC          :{carry,result} = RF_dout + OR_q + (IR_q[8] & PSR_q[C]);
            SUB,SBC,CMP,CMPC,DEC :{carry,result} = RF_dout + (OR_q ^ 16'hFFFF) + ((IR_q[8])?PSR_q[C]:1);
            XOR,GPSR             :{carry,result} = (IR_q[IRNPRED])?{PSR_q[C],8'b0,PSR_q}:{PSR_q[C],RF_dout ^ OR_q};
            NOT,BSWP             :{result,carry} = (IR_q[10])? {~OR_q,PSR_q[C]} : {OR_q[7:0],OR_q[15:8],PSR_q[C]};
            ROR,ASR,LSR          :{result,carry} = {(IR_q[10]==0)?PSR_q[C]:(IR_q[8]==1)?OR_q[15]:1'b0,OR_q};
            default              :{carry,result} = {PSR_q[C],OR_q} ; //LD,MOV,STO,JSR,IN,OUT,PUSH,POP and everything else
        endcase // case ( IR_q )
        {swiid,enable_int,sign,carry,zero} = (op==PPSR)?OR_q[7:0]:(IR_q[3:0]!=4'hF)?{PSR_q[7:3],result[15],carry,!(|result)}:PSR_q;
    end // always @ ( * )
    always @(posedge clk)
        if (clken) begin
            {reset_s0_b,reset_s1_b} <= {reset_b,reset_s0_b};
            if (!reset_s1_b)
                {PC_q,PCI_q,PSRI_q,PSR_q,FSM_q} <= 0;
            else begin
                case (FSM_q)
                    FET0   : FSM_q <= (din[IRLEN]) ? FET1 :  EAD;
                    FET1   : FSM_q <= (!pred)? FET0: EAD;                    
                    EAD    : FSM_q <= (!pred)? FET0: (IR_q[IRLD]) ? RDM : (IR_q[IRSTO]) ? WRM : EXEC;
                    EXEC   : FSM_q <= ((!(&int_b) & PSR_q[EI])||((op==PPSR) && (|swiid)))?INT:((IR_q[3:0]==4'hF)||(op==JSR))?FET0:
                                      (din[IRLEN]) ? FET1 :EAD;
                    WRM    : FSM_q <= (!(&int_b) & PSR_q[EI])?INT:FET0;
                    default: FSM_q <= (FSM_q==RDM)? EXEC : FET0;  // Applies to INT and RDM plus undefined states
                endcase // case (FSM_q)
                OR_q <= ((FSM_q==FET0)||(FSM_q==EXEC))?({16{op_d==PUSH}}^({15'b0,(op_d==POP)})):
                        (FSM_q==EAD)?
                        (op==INC)||(op==DEC)?(OR_q|{12'b0,IR_q[7:4]}):RF_w_p2+OR_q:din;
                if ( FSM_q == INT )
                    {PC_q,PCI_q,PSRI_q,PSR_q[EI]} <= {(!int_b[1])?INT_VECTOR1:INT_VECTOR0,PC_q,PSR_q[3:0],1'b0} ; // Always clear EI on taking interrupt
                else if ((FSM_q==FET0)||(FSM_q==FET1)) 
                    PC_q  <= PC_q + 1;
                else if ( FSM_q == EXEC) begin
                    PC_q <= (op==RTI)?PCI_q: ((IR_q[3:0]==4'hF)||(op==JSR))?result:(((!(&int_b)) && PSR_q[EI])||((op==PPSR)&&(|swiid)))?PC_q:PC_q + 1;
                    PSR_q <= (op==RTI)?{4'b0,PSRI_q}:{swiid,enable_int,sign,carry,zero}; // Clear SWI bits on return
                end
                if (((FSM_q==EXEC) && !((op==CMP)||(op==CMPC)))|| (((FSM_q==WRM)&&(op==PUSH))||((FSM_q==RDM)&&(op==POP))))
                    RF_q[IR_q[3:0]] <= (op==JSR)? PC_q : result ;
                if ((FSM_q==FET0)||(FSM_q==EXEC))
                    IR_q <= {(din[15:13]==3'b001),(din[11:8]==STO)||(op_d==PUSH),(din[11:8]==LD)||(op_d==POP),din};
                else if (((FSM_q==EAD && (IR_q[IRLD]||IR_q[IRSTO]))||(FSM_q==RDM)))
                  IR_q[7:0] <= {IR_q[3:0],IR_q[7:4]}; // Swap source/dest reg in EA for reads and writes for writeback of 'source' in push/pop .. swap back again in RDMEM
            end 
        end
endmodule
