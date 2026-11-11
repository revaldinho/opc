// opc7hcount.v - where the cycles of opc7hpcpu go. A second top-level module for simulation, next to
// opc7htb.v (iverilog ... opc7htb.v opc7hpcpu.v opc7hcount.v); it only watches the CPU. count.sh runs it.
//
// Every cycle after reset is put in exactly one class, by what EA does:
//   go            an instruction leaves EA. It later retires, or is cancelled in MEM (wasted)
//   raw_*         EA stalls for a register: by what the register is for and what will write it
//   side_*        a store, in or out waits in EA behind a possible redirect, or for the flags
//   flush         EA is held or cancelled by a jump or interrupt in EX
//   empty         EA holds nothing, because of the last redirect, or the pipeline start
// Wasted and flush cycles and the empty cycles after them are charged to the redirect that caused them,
// so CPI = 1 + (the cost of each cause) / instructions, apart from the few cycles of filling and draining.
module opc7hcount;
  integer cyc=0, retired=0, predoff=0, wasted_ex=0, wasted_int=0;
  integer raw_addr_alu=0, raw_addr_ld=0, raw_imm_alu=0, raw_imm_ld=0, raw_jmp_alu=0, raw_jmp_ld=0, raw_data_alu=0, raw_data_ld=0;
  integer side_redir=0, side_flags=0, n_mis=0, n_ptk=0;   // mispredicted jumps; predicted-taken redirects from EA
  integer flush_ex[0:2], empty_c[0:3], n_redir[0:3];
  integer cause=3;                       // of the last redirect: 0 predicated jump, 1 other jump in EX, 2 early, 3 start/interrupt
  reg     early_was=0;
  integer i;
  initial for (i=0;i<4;i=i+1) begin empty_c[i]=0; n_redir[i]=0; if (i<3) flush_ex[i]=0; end
  wire [3:0] esrc=opc7tb.dut0_u.ea_esrc_q, edst=opc7tb.dut0_u.ea_edst_q, mdst=opc7tb.dut0_u.mem_dst_q;
  wire mwr=opc7tb.dut0_u.mem_wr, xwr=opc7tb.dut0_u.ex_wr;
  wire [4:0] eir=opc7tb.dut0_u.ea_ir_q, mir=opc7tb.dut0_u.mem_ir_q, xir=opc7tb.dut0_u.ex_ir_q;
  wire [3:0] xdst=opc7tb.dut0_u.ex_dst_q;
  function isload(input [4:0] ir); isload = ir==5'h1B || ir==5'h1F || ir==5'h19; endfunction
  // the nearest writer of the register EA waits for: one in MEM, else one in EX
  wire src_hit = |esrc && ((mwr && mdst==esrc) || (xwr && xdst==esrc));
  wire [3:0] wr = src_hit ? esrc : edst;
  wire by_load = (mwr && mdst==wr) ? isload(mir) : isload(xir);
  wire ea_mem  = opc7tb.dut0_u.ea_mem_q;
  wire jmp     = opc7tb.dut0_u.ea_jmp_q;
  wire red_c   = (opc7tb.dut0_u.mem_q && opc7tb.dut0_u.mem_red_q) || (opc7tb.dut0_u.ex_q && opc7tb.dut0_u.ex_red_q);
  wire [1:0] ex_cause = opc7tb.dut0_u.ex_int ? 2'd3 : (opc7tb.dut0_u.ex_p_q==3'b000) ? 2'd1 : 2'd0;
  always @(negedge opc7tb.clk) if (opc7tb.dut0_u.reset_s1_b) begin
    cyc = cyc + 1;
    if (opc7tb.dut0_u.ex_q) begin retired = retired + 1; if (!opc7tb.dut0_u.ex_pass) predoff = predoff + 1; end
    if (opc7tb.dut0_u.flush) begin
      cause = ex_cause; n_redir[cause] = n_redir[cause] + 1;
      if (opc7tb.dut0_u.mem_q) begin if (cause==3) wasted_int=wasted_int+1; else wasted_ex=wasted_ex+1; end
    end
    if (opc7tb.dut0_u.flush) begin
      if (opc7tb.dut0_u.ea_q) flush_ex[cause==3 ? 2 : cause] = flush_ex[cause==3 ? 2 : cause] + 1;
      else empty_c[cause] = empty_c[cause] + 1;
    end else if (!opc7tb.dut0_u.ea_q) empty_c[cause] = empty_c[cause] + 1;
    else if (opc7tb.dut0_u.raw) begin
      if (!src_hit)            begin if (by_load) raw_data_ld=raw_data_ld+1; else raw_data_alu=raw_data_alu+1; end
      else if (jmp)            begin if (by_load) raw_jmp_ld =raw_jmp_ld +1; else raw_jmp_alu =raw_jmp_alu +1; end
      else if (ea_mem)         begin if (by_load) raw_addr_ld=raw_addr_ld+1; else raw_addr_alu=raw_addr_alu+1; end
      else                     begin if (by_load) raw_imm_ld =raw_imm_ld +1; else raw_imm_alu =raw_imm_alu +1; end
    end
    else if (opc7tb.dut0_u.side_wait) begin if (red_c) side_redir=side_redir+1; else side_flags=side_flags+1; end
    if (opc7tb.dut0_u.ex_mis) n_mis = n_mis + 1;
    if (opc7tb.dut0_u.ea_early && !opc7tb.dut0_u.flush) begin
      cause = 2; n_redir[2] = n_redir[2] + 1;
      if (!opc7tb.dut0_u.ea_pred_q) n_ptk = n_ptk + 1;   // ea_pred_q: unpredicated
    end
    if (opc7tb.dut0_u.tb_halt)
      $display("COUNT cycles=%0d retired=%0d predoff=%0d wasted_jump=%0d wasted_int=%0d raw_addr_alu=%0d raw_addr_ld=%0d raw_imm_alu=%0d raw_imm_ld=%0d raw_jmp_alu=%0d raw_jmp_ld=%0d raw_data_alu=%0d raw_data_ld=%0d side_redir=%0d side_flags=%0d flush_pred=%0d flush_jump=%0d flush_int=%0d empty_pred=%0d empty_jump=%0d empty_early=%0d empty_other=%0d n_pred=%0d n_jump=%0d n_early=%0d n_int=%0d n_mis=%0d n_ptk=%0d",
        cyc, retired, predoff, wasted_ex, wasted_int, raw_addr_alu, raw_addr_ld, raw_imm_alu, raw_imm_ld, raw_jmp_alu, raw_jmp_ld, raw_data_alu, raw_data_ld, side_redir, side_flags,
        flush_ex[0], flush_ex[1], flush_ex[2], empty_c[0], empty_c[1], empty_c[2], empty_c[3], n_redir[0], n_redir[1], n_redir[2], n_redir[3], n_mis, n_ptk);
  end
endmodule
