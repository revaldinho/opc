module opccpu( inout[7:0] data, output[10:0] address, output rnw, input clk, input reset_b);

  parameter FETCH0=0, FETCH1=1, RDMEM=2, EXEC=3 ;
  parameter AND=4'bx000, LDA=4'bx001, NOT=4'bx010, ADD=4'bx011;
  parameter RTS=4'hC, LXA=4'hD;
  parameter STA=4'h4, JPC=4'h5, JPZ=4'h6, JP=4'h7, JSR=4'hF;

  reg [10:0] OR_q, PC_q;
  reg [7:0]  ACC_q;
  reg [1:0]  FSM_q;
  reg [3:0]  IR_q;
  reg [2:0]  LINK_q;
  reg        C_q;

  wire   writeback_w = ((FSM_q == EXEC) && (IR_q == STA)) & reset_b ;
  assign rnw = ~writeback_w ;
  assign data = (writeback_w)?ACC_q:8'bz ;
  assign address = ( writeback_w || FSM_q == RDMEM )? OR_q:PC_q;

  always @ (posedge clk or negedge reset_b )
    if (!reset_b)
      FSM_q <= FETCH0;
    else
      case(FSM_q)
        FETCH0 : FSM_q <= FETCH1;
        FETCH1 : FSM_q <= (IR_q[3] || IR_q[2])?EXEC:RDMEM ;
        RDMEM  : FSM_q <= EXEC;
        EXEC   : FSM_q <= FETCH0;
      endcase

  always @ (posedge clk)
    begin
      IR_q <= (FSM_q == FETCH0)? data[7:4] : IR_q;
      OR_q[10:8] <= (FSM_q == FETCH0)? data[2:0]: OR_q[10:8];
      OR_q[7:0] <= (FSM_q == FETCH1 || FSM_q==RDMEM)? data: OR_q[7:0];
      if ( FSM_q == EXEC )
        casex (IR_q)
          JSR    : {LINK_q,ACC_q} <= PC_q ;
          LXA    : {LINK_q,ACC_q} <= {ACC_q[2:0], 5'b0, LINK_q};
          AND    : {C_q, ACC_q}  <= {1'b0, ACC_q & OR_q[7:0]};
          NOT    : ACC_q <= ~OR_q[7:0];
          LDA    : ACC_q <= OR_q[7:0];
          ADD    : {C_q,ACC_q} <= ACC_q + C_q + OR_q[7:0];
          default: {C_q,ACC_q} <= {C_q,ACC_q};
        endcase
    end

  always @ (posedge clk or negedge reset_b )
    if (!reset_b)
        PC_q <= 10'b0;
    else
      if ( FSM_q == FETCH0 || FSM_q == FETCH1 )
        PC_q <= PC_q + 1;
      else
        case (IR_q)
          JP    : PC_q <= OR_q;
          JPC   : PC_q <= (C_q)?OR_q:PC_q;
          JPZ   : PC_q <= ~(|ACC_q)?OR_q:PC_q;
          JSR   : PC_q <= OR_q;
          RTS   : PC_q <= {LINK_q, ACC_q};
          default: PC_q <= PC_q;
        endcase
endmodule
