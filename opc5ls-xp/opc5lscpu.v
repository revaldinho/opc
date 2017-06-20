module opc5lscpu( input[15:0] din, input clk, input reset_b, input int_b, input clken, output vpa, output vda, output[15:0] dout, output[15:0] address, output rnw);
    parameter MOV=4'h0,AND=4'h1,OR=4'h2,XOR=4'h3,ADD=4'h4,ADC=4'h5,STO=4'h6,LD=4'h7,ROR=4'h8,NOT=4'h9,SUB=4'hA,SBC=4'hB,CMP=4'hC,CMPC=4'hD,BSWP=4'hE,PSR=4'hF;
    parameter FETCH0=3'h0,FETCH1=3'h1,EA_ED=3'h2,RDMEM=3'h3,EXEC=3'h4,WRMEM=3'h5,INT=3'h6 ;
    parameter EI=3,S=2,C=1,Z=0,P0=15,P1=14,P2=13,IRLEN=12,IRLD=16,IRSTO=17,IRGETPSR=18,IRPUTPSR=19,IRRTI=20,IRCMP=21,INT_VECTOR=16'h0002;
    reg [15:0] OR_q, PC_q, PCI_q, result;
    reg [21:0] IR_q; (* RAM_STYLE="DISTRIBUTED" *)
    reg [15:0] dprf_q[15:0];
    reg [2:0]  FSM_q;
    reg [3:0]  swiid,PSRI_q;
    reg [7:0]  PSR_q ;
    reg        zero,carry,sign,enable_int,reset_s0_b,reset_s1_b;
    wire predicate 	            = IR_q[P2] ^ (IR_q[P1]?(IR_q[P0]?PSR_q[S]:PSR_q[Z]):(IR_q[P0]?PSR_q[C]:1));
    wire predicate_din 	        = din[P2] ^ (din[P1]?(din[P0]?PSR_q[S]:PSR_q[Z]):(din[P0]?PSR_q[C]:1));
    wire [15:0] dprf_dout_p2    = (IR_q[7:4]==4'hF) ? PC_q: {16{(IR_q[7:4]!=4'h0)}} & dprf_q[IR_q[7:4]];  // Port 2 always reads source reg
    wire [15:0] dprf_dout       = (IR_q[3:0]==4'hF) ? PC_q: {16{(IR_q[3:0]!=4'h0)}} & dprf_q[IR_q[3:0]];  // Port 1 always reads dest reg
    wire [15:0] operand         = (IR_q[IRLEN]||IR_q[IRLD]) ? OR_q : dprf_dout_p2;                        // For one word instructions operand comes from dprf
    assign {rnw, dout, address} = { !(FSM_q==WRMEM), dprf_dout, ( FSM_q==WRMEM || FSM_q == RDMEM)? OR_q : PC_q };
    assign {vpa,vda}            = {((FSM_q==FETCH0)||(FSM_q==FETCH1)||(FSM_q==EXEC)),((FSM_q==RDMEM)||(FSM_q==WRMEM)) };
    always @( * )
        begin
            case (IR_q[11:8])     // no real need for STO entry but include it so all instructions are covered, no need for default
                LD,MOV,PSR,STO   :{carry,result} = {PSR_q[C],(IR_q[IRGETPSR])?{8'b0,PSR_q}:operand} ;
                AND,OR           :{carry,result} = {PSR_q[C],(IR_q[8])?(dprf_dout & operand):(dprf_dout | operand)};
                ADD,ADC          :{carry,result} = dprf_dout + operand + (IR_q[8] & PSR_q[C]);
                SUB,SBC,CMP,CMPC :{carry,result} = dprf_dout + (operand ^ 16'hFFFF) + ((IR_q[8])?PSR_q[C]:1);
                XOR,BSWP         :{carry,result} = {PSR_q[C],(!IR_q[11])?(dprf_dout ^ operand):{operand[7:0],operand[15:8] }};
                NOT,ROR          :{result,carry} = (IR_q[8])?{~operand,PSR_q[C]}:{PSR_q[C],operand} ;
            endcase // case ( IR_q )
            {swiid,enable_int,sign,carry,zero} = (IR_q[IRPUTPSR])?operand[7:0]:(IR_q[3:0]!=4'hF)?{PSR_q[7:3],result[15],carry,!(|result)}:PSR_q;
        end // always @ ( * )
    always @(posedge clk)
        if (clken) begin
            {reset_s0_b,reset_s1_b} <= {reset_b,reset_s0_b};
            if (!reset_s1_b)
                {PC_q,PCI_q,PSRI_q,PSR_q,FSM_q} <= 0;
            else begin
                case (FSM_q)
                    FETCH0 : FSM_q <= (din[IRLEN]) ? FETCH1 : (!predicate_din) ? FETCH0 : ((din[11:8]==LD) || (din[11:8]==STO)) ? EA_ED : EXEC;
                    FETCH1 : FSM_q <= (!predicate )? FETCH0: ((IR_q[3:0]!=0) || (IR_q[IRLD]) || IR_q[IRSTO]) ? EA_ED : EXEC;
                    EA_ED  : FSM_q <= (!predicate )? FETCH0: (IR_q[IRLD]) ? RDMEM : (IR_q[IRSTO]) ? WRMEM : EXEC;
                    RDMEM  : FSM_q <= EXEC;
                    EXEC   : FSM_q <= ((!int_b & PSR_q[EI])||(IR_q[IRPUTPSR] && (|swiid)))?INT:(IR_q[3:0]==4'hF)?FETCH0: (din[IRLEN]) ? FETCH1 : // go to fetch0 if PC or PSR affected by exec
                                ((din[11:8]==LD) || (din[11:8]==STO) ) ? EA_ED :                                       // load/store have to go via EA_ED
                                (din[P2] ^ (din[P1] ? (din[P0] ? sign : zero): (din[P0] ? carry : 1))) ? EXEC : EA_ED; // short cut to exec on all predicates
                                //(din[15:13]==3'b000)? EXEC : EA_ED;                                                  // or short cut on always only
                    WRMEM  : FSM_q <= (!int_b & PSR_q[EI])?INT:FETCH0;
                    default: FSM_q <= FETCH0;
                endcase // case (FSM_q)
                OR_q <= (FSM_q == FETCH0 || FSM_q==EXEC)? 16'b0 : (FSM_q==EA_ED) ? dprf_dout_p2 + OR_q : din;
                if ( FSM_q == INT )
                    {PC_q,PCI_q,PSRI_q,PSR_q[EI]} <= {INT_VECTOR,PC_q,PSR_q[3:0],1'b0} ; // Always clear EI on taking interrupt
                else if ( FSM_q == FETCH0 || FSM_q == FETCH1 )
                    PC_q <= PC_q + 1;
                else if ( FSM_q == EXEC ) begin
                    PC_q <= (IR_q[IRRTI])?PCI_q:(IR_q[3:0]==4'hF)?result:((!int_b && PSR_q[EI]) || (IR_q[IRPUTPSR] && (|swiid)))?PC_q:PC_q + 1;
                    PSR_q <= (IR_q[IRRTI])?{4'b0,PSRI_q}:{swiid,enable_int,sign,carry,zero}; // Clear SWI bits on return
                    if (!IR_q[IRCMP])
                        dprf_q[IR_q[3:0]] <= result ;
                end
                if ( FSM_q == FETCH0 || FSM_q == EXEC)
                    IR_q <= {((din[11:8]==CMP)||(din[11:8]==CMPC)),{3{(din[11:8]==PSR)}}&{(din[3:0]==4'hF),(din[3:0]==4'h0),(din[7:4]==4'b0)},(din[11:8]==STO),(din[11:8]==LD),din};
            end // else: !if(!reset_s1_b)
        end
endmodule
