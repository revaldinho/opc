`define FETCH0 2'b00
`define FETCH1 2'b01
`define RDMEM  2'b10
`define EXEC   2'b11

`define ANDI 5'h10
`define AND  5'h00
`define LDAI 5'h12
`define LDA  5'h02
`define STA  5'h04
`define NOT  5'h14
`define ADDI 5'h16
`define ADD  5'h06
`define SUBI 5'h18
`define SUB  5'h08
`define JPC  5'h0A
`define JPZ  5'h0C
`define JP   5'h0E
`define SEC  5'h1A
`define HALT 5'h1F

module opccpu( data, address, rnw, clk, reset_b );

  inout[7:0] data;
  output[11:0] address;
  output rnw;
  input clk, reset_b;

  reg [11:0] OR_q, PC_q;
  reg [8:0]  ACC_q;
  reg [1:0]  FSM_q;
  reg [4:0]  IR_q;
  reg        C_q;

  wire writeback_w ;

  assign writeback_w = (FSM_q == `EXEC) && (IR_q == `STA);
  assign data = (writeback_w)?ACC_q:8'bz ;
  assign address = (writeback_w || FSM_q == `RDMEM )? OR_q:PC_q;
  assign rnw = (writeback_w)?0:1;

  always @ (posedge clk or negedge reset_b )
    if (!reset_b)
      FSM_q <= `FETCH0;
    else
      case(FSM_q)
        `FETCH0 : FSM_q <= `FETCH1;
        `FETCH1 : FSM_q <= (IR_q[4]==0)?`EXEC:`RDMEM ;
        `RDMEM  : FSM_q <= `EXEC;
        `EXEC   : FSM_q <= `FETCH0;
      endcase

  always @ (posedge clk)
    begin
      // IR_q LSB can only be set if the MSB is also set - ie an immediate or implied instruction
      IR_q <= (FSM_q == `FETCH0)? { data[7:4], data[7] & data[3]} : IR_q;
      OR_q[11:8] <= (FSM_q == `FETCH0)? data[3:0]: OR_q[11:8];
      OR_q[7:0] <= (FSM_q == `FETCH1 || FSM_q==`RDMEM)? data: OR_q[7:0];
      if ( FSM_q == `EXEC )
        case(IR_q)
          `ANDI, `AND :
            begin
              ACC_q <= ACC_q & OR_q[7:0];
              C_q <= 1'b0;
            end
          `NOT	      :
            begin
              ACC_q <= ~ACC_q;
              C_q <= 1'b0;
            end
          `LDAI,`LDA  :
            begin
              ACC_q <= OR_q[7:0];
              C_q <= 1'b0;
            end
          `ADDI,`ADD  : {C_q,ACC_q} <= ACC_q + C_q + OR_q[7:0];
          // Temporarily dont use the carry in subtraction
          `SUBI,`SUB  : {ACC_q} <= ACC_q + ~OR_q[7:0] + 1'b1;
          `SEC        : C_q <= 1'b1;
        endcase
    end

  always @ (posedge clk or negedge reset_b )
    if (!reset_b)
      PC_q <= 11'b0;
    else
      begin
        if ( FSM_q == `FETCH0 || FSM_q == `FETCH1 )
          PC_q <= PC_q + 1;
        else if ( FSM_q == `EXEC )
          case (IR_q)
            `JP    : PC_q <= OR_q;
            `JPC   : PC_q <= (C_q)?OR_q:PC_q;
            `JPZ   : PC_q <= (|ACC_q)?OR_q:PC_q;
            default: PC_q <= PC_q;
          endcase
      end
endmodule
