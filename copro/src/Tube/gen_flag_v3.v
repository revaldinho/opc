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
   
   // TODO - Implement this!
   parameter init = 0;

   wire req;
   reg req_s1;
   reg req_s2;
   reg req_edge;

   reg [1:0] p1_state;

   wire ack;
   reg ack_s1;
   reg ack_s2;
   reg ack_edge;
   reg [1:0] p2_state;


   always @ (`p1edge p1_clk or negedge rst_b )
     begin
        if (!rst_b) begin
          ack_s1 <= 1'b0;
          ack_s2 <= 1'b0;
          ack_edge <= 1'b0;
          p1_state <= { 1'b0, init};
        end else begin
          ack_s1 <= ack;
          ack_s2 <= ack_s1;
          ack_edge <= ack_s2 ^ ack_s1;
          case (p1_state)
            2'b00:
              if (p1_select & !p1_rdnw)
                p1_state <= 2'b01;
            2'b01:
              if (ack_edge)
                p1_state <= 2'b11;
            2'b11:
              if (p1_select & !p1_rdnw)
                p1_state <= 2'b10;
            2'b10:
              if (ack_edge)
                p1_state <= 2'b00;
          endcase
        end
      end

   assign req = p1_state[0];
   assign p1_full = p1_state[0] ^ p1_state[1];

   always @ (`p2edge p2_clk or negedge rst_b )
     begin
        if (!rst_b) begin
          req_s1 <= 1'b0;
          req_s2 <= 1'b0;
          req_edge <= 1'b0;
          p2_state <= { init, 1'b0 };
        end else begin
          req_s1 <= req;
          req_s2 <= req_s1;
          req_edge <= req_s2 ^ req_s1;
          case (p2_state)
            2'b00:
              if (req_edge)
                p2_state <= 2'b10;
            2'b10:
              if (p2_select & p2_rdnw)
                p2_state <= 2'b11;
            2'b11:
              if (req_edge)
                p2_state <= 2'b01;
            2'b01:
              if (p2_select & p2_rdnw)
                p2_state <= 2'b00;
          endcase
        end
      end

    assign ack = p2_state[0];
    assign p2_data_available = p2_state[0] ^ p2_state[1];

endmodule
