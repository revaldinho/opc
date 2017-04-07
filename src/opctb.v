`timescale 1ns / 1ns

module opctb();

  reg [7:0] mem [ 4095:0 ];
  reg clk, reset_b;

  wire [11:0] addr;
  wire [7:0] data;
  wire ceb, rnw, oeb;

  opccpu  dut0_u (.address(addr), .data(data), .rnw(rnw), .clk(clk), .reset_b(reset_b));

  assign ceb = 1'b0;
  assign oeb = !rnw;

  // read operations are combinatorial
  assign data = ( !ceb & rnw & !oeb ) ? mem[ addr ] : 8'bz ;


  initial
    begin
      $dumpvars;
      $readmemh("test.hex", mem);
      clk = 0;
      reset_b = 0;


      #10005 reset_b = 1;

      #50000 $finish;
    end

  always @ (negedge clk)
    if (!rnw && !ceb && oeb && reset_b)
      mem[addr] <= data;

  // Setup clocks - slow clock
  always
     begin
        #500 clk = 0;
        #500 clk = 1;
     end

endmodule
