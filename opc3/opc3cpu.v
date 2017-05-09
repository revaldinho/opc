module opc3cpu( inout[15:0] data, output[15:0] address, output rnw, input clk, input reset_b);
   parameter FETCH0=0, FETCH1=1, RDMEM=2, RDMEM2=3, EXEC=4 ;
   parameter AND=5'bx0000,  LDA=5'bx0001, NOT=5'bx0010, ADD=5'bx0011;
   parameter LDAP=5'b01001, STA=5'b11000, STAP=5'b01000;
   parameter JPC=5'b11001,  JPZ=5'b11010, JP=5'b11011,  JSR=5'b11100;
   parameter RTS=5'b11101,  BSW=5'b11110;
   reg [15:0] OR_q, PC_q;
   reg [15:0] ACC_q;
   reg [2:0]  FSM_q;
   reg [4:0]  IR_q;
   reg        C_q;

   wire       writeback_w = ((FSM_q == EXEC) && (IR_q == STA || IR_q == STAP)) & reset_b ;
   assign rnw = ~writeback_w ;
   assign data = (writeback_w)?ACC_q:16'bz ;
   assign address = ( writeback_w || FSM_q == RDMEM || FSM_q==RDMEM2)? OR_q:PC_q;

   always @ (posedge clk or negedge reset_b )
     if (!reset_b)
       FSM_q <= FETCH0;
     else
       case(FSM_q)
         FETCH0 : FSM_q <= FETCH1;
         FETCH1 : FSM_q <= (IR_q[4])?EXEC:RDMEM ;
         RDMEM  : FSM_q <= (IR_q==LDAP)?RDMEM2:EXEC;
         RDMEM2 : FSM_q <= EXEC;
         EXEC   : FSM_q <= FETCH0;
       endcase

   always @ (posedge clk)
     begin
        IR_q <= (FSM_q == FETCH0)? data[15:11] : IR_q;
        OR_q[15:0] <= data ;
        if ( FSM_q == EXEC )
          casex (IR_q)
            JSR    : ACC_q <= PC_q ;
            AND    : {C_q, ACC_q}  <= {1'b0, ACC_q & OR_q};
            BSW    : ACC_q <= {ACC_q[7:0], ACC_q[15:8]};
            NOT    : ACC_q <= ~OR_q;
            LDA    : ACC_q <= OR_q;
            LDAP   : ACC_q <= OR_q;
            ADD    : {C_q,ACC_q} <= ACC_q + C_q + OR_q;
            default: {C_q,ACC_q} <= {C_q,ACC_q};
          endcase
     end

   always @ (posedge clk or negedge reset_b )
     if (!reset_b) // On reset start execution at 0x00 to leave page zero clear for variables
       PC_q <= 16'h0000;
     else
       if ( FSM_q == FETCH0 || FSM_q == FETCH1 )
         PC_q <= PC_q + 1;
       else
         case (IR_q)
           JP    : PC_q <= OR_q;
           JPC   : PC_q <= (C_q)?OR_q:PC_q;
           JPZ   : PC_q <= ~(|ACC_q)?OR_q:PC_q;
           JSR   : PC_q <= OR_q;
           RTS   : PC_q <= ACC_q;
           default: PC_q <= PC_q;
         endcase
endmodule
