(
    input rst_b,
    input p1_clk,
    input p1_select,
    input p1_rdnw,
    input p2_clk,
    input p2_select,
    input p2_rdnw,
    output p2_data_available,
    output p1_full
);

   // Initial state: 0 = empty; 1 = full
   parameter init = 0;

   wire req;
   reg req_s1;
   reg req_s2;
   wire ack;
   reg ack_s1;
   reg ack_s2;
   
   reg [1:0] p1_state;
   reg [1:0] p2_state;

   always @ (`p1edge p1_clk or negedge rst_b )   
     begin
        if (!rst_b) begin
          p1_state <= { 1'b0, init };
          ack_s1 <= 1'b0;
          ack_s2 <= 1'b0;
        end else begin
          ack_s1 <= ack;
          ack_s2 <= ack_s1;
          case (p1_state)
            2'b00:
              if (p1_select & ! p1_rdnw)
                p1_state <= 2'b01;
            2'b01:
              if (ack_s2)
                p1_state <= 2'b10;
            2'b10:
              if (!ack_s2)
                p1_state <= 2'b00;
            default:              
              p1_state <= 2'b00;
          endcase
        end
      end

   assign req = p1_state[0];
   
   assign p1_full = p1_state[0] | p1_state[1];

   always @ (`p2edge p2_clk or negedge rst_b )   
     begin
        if (!rst_b) begin
          p2_state <= { 1'b0, init};
          req_s1 <= init;
          req_s2 <= init;
        end else begin
          req_s1 <= req;
          req_s2 <= req_s1;
          case (p2_state)
            2'b00:
              if (req_s2)
                p2_state <= 2'b01;
            2'b01:
              if (p2_select & p2_rdnw)
                p2_state <= 2'b10;
            2'b10:
              if (!req_s2)
                p2_state <= 2'b00;
            default:              
              p2_state <= 2'b00;
          endcase
        end
      end
      
    assign ack = p2_state[1];
      
    assign p2_data_available = p2_state[0] & !p2_state[1];
   
endmodule
