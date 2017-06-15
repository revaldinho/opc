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

   reg req;
   reg req_s1;
   reg req_s2;
   reg ack;
   reg ack_s1;
   reg ack_s2;
   

   always @ (`p1edge p1_clk or negedge rst_b )   
     begin
        if (!rst_b) begin
          req <= init;
          ack_s1 <= 1'b0;
          ack_s2 <= 1'b0;
        end else begin
          ack_s1 <= ack;
          ack_s2 <= ack_s1;	   
          case (req)
            1'b0:
              if (!ack_s2 & p1_select & !p1_rdnw)
                req <= 1'b1;
            1'b1:
              if (ack_s2)
                req <= 1'b0;
          endcase
        end
      end

   assign p1_full = req | ack_s2;

   always @ (`p2edge p2_clk or negedge rst_b )   
     begin
        if (!rst_b) begin
          ack <= 1'b0;
          req_s1 <= init;
          req_s2 <= init;
        end else begin
          req_s1 <= req;
          req_s2 <= req_s1;
          case (ack)
            1'b0:
              if (req_s2 & p2_select & p2_rdnw)
                ack <= 1'b1;
            1'b1:
              if (!req_s2)
                ack <= 1'b0;
          endcase
        end
      end
      
    assign p2_data_available = !ack & req_s2;
   
endmodule
