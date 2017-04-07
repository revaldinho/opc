module opccpu( inout[7:0] data, output[11:0] address, output rnw, input clk, input reset_b);

  parameter FETCH0=0, FETCH1=1, RDMEM=2, EXEC=3 ;
  parameter STA=4'hC, JPC=4'hD, JPZ=4'hE, JP=4'hF;
  parameter AND=3'h0, LDA=3'h1, NOT=3'h2, ADD=3'h3 ;
  // ANDI = 4'h8, LDAI = 4'h9, NOTI = 4'hA, ADDI = 4'hB

  reg [11:0] OR_q, PC_q;
  reg [7:0]  ACC_q;
  reg [1:0]  FSM_q;
  reg [3:0]  IR_q;
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
        FETCH1 : FSM_q <= (IR_q[3])?EXEC:RDMEM ;
        RDMEM  : FSM_q <= EXEC;
        EXEC   : FSM_q <= FETCH0;
      endcase

  always @ (posedge clk)
    begin
      IR_q <= (FSM_q == FETCH0)? data[7:4] : IR_q;
      OR_q[11:8] <= (FSM_q == FETCH0)? data[3:0]: OR_q[11:8];
      OR_q[7:0] <= (FSM_q == FETCH1 || FSM_q==RDMEM)? data: OR_q[7:0];
      if ( FSM_q == EXEC )
        case(IR_q[2:0])
          AND    : {C_q, ACC_q}  <= {1'b0, ACC_q & OR_q[7:0]};
          NOT	   : ACC_q <= ~OR_q[7:0];
          LDA    : ACC_q <= OR_q[7:0];
          ADD    : {C_q,ACC_q} <= ACC_q + C_q + OR_q[7:0];
          default: {C_q,ACC_q} <= {C_q,ACC_q};
        endcase
    end

  always @ (posedge clk or negedge reset_b )
    if (!reset_b)
      PC_q <= 12'b0;
    else
      if ( FSM_q == FETCH0 || FSM_q == FETCH1 )
        PC_q <= PC_q + 1;
      else
        case (IR_q)
          JP    : PC_q <= OR_q;
          JPC   : PC_q <= (C_q)?OR_q:PC_q;
          JPZ   : PC_q <= ~(|ACC_q)?OR_q:PC_q;
          default: PC_q <= PC_q;
        endcase
endmodule
