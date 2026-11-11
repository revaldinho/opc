// opc7hpcpu: pipelining work, started as a copy of opc7hcpu.v (kept unchanged as the reference)
// Stage 6: a four stage pipeline with interlocks, late-binding forwarding, early jumps and predicted
// backward jumps, its control decoded a stage ahead (FD for EA, MEM for EX), with separate wait inputs
// for the instruction and data ports (iwait, dwait: tie them low for single cycle memory). Every instruction goes
//   FD   the instruction word arrives on idin
//   EA   source and destination read, operand/address = src + imm; loads and stores present
//        their address (the data arrives, or is written, while the instruction is in MEM)
//   MEM  load data arrives
//   EX   predicate test, ALU, flags, register and PC write
// with a new fetch every cycle unless FD is held. Rules:
// - Late operands are forwarded: the destination value (used by the ALU) and a source used with
//   imm == 0 by an instruction other than a load, store, in, out or bperm (its operand is just
//   the register) are only needed in EX. EA reads them from the register file as usual, and on
//   the way from MEM to EX a stale value is replaced by the result of the instruction in EX (one
//   ahead) or, failing that, by wb, the result written by the one before that (two ahead).
// - EA stalls while an instruction in MEM or EX will write a register EA needs itself: a source
//   for an address, with imm != 0 or for bperm, and store data.
// - The predicate is tested in EX, from the flags left by the instruction before it, so flags
//   need no interlock; an instruction whose predicate fails writes nothing.
// - Jumps (writes to r15, jsr/ljsr, rti) are taken in EX: the fetch is redirected and the
//   instructions in MEM, EA and FD are cancelled. The exception is an early jump, an unpredicated
//   mov/lmov to r15 or jsr/ljsr: its target is the EA adder's output, so it redirects the fetch
//   as it leaves EA, cancelling only FD, and goes on to EX for the link and PCI without redirecting
//   again. Its source is needed in EA, so it isn't forwarded. If an older jump or interrupt then
//   cancels it, that one overrides the fetch; nothing but the fetch has happened.
// - A predicated jump of the same kinds with an immediate or pc-relative target that is backward
//   (FD decides, from the imm's sign or modulo 4K words from the PC: being wrong only costs cycles) is predicted taken: it redirects from EA like an early jump.
//   Its predicate is still tested in EX; if it fails, the fetch goes to the next instruction
//   (ex_pc_q) and MEM, EA and FD are cancelled. A side effect at the target needs no wait: it reaches EA
//   no sooner than the jump reaches EX, and a flush stops it there.
// - sto/lsto/out/in act on memory or I/O as they leave EA, so they wait there while MEM or EX
//   holds anything that could redirect (a jump, rti, putpsr), and a predicated one also waits
//   for the flags (no flag setter ahead) and tests its predicate in EA.
// - Interrupts are taken as an instruction completes in EX (a hardware one only if no store,
//   in or out has left EA behind it); younger instructions are cancelled and PCI is the
//   completing instruction's next PC.
// R0 reads as zero; r15 reads as the address of the next instruction (ea_pc).
// Memory: two ports, each one access at a time, for single cycle memory (block RAM: tie the waits
// low) or caches and slower memory, which stall each port separately with its wait input:
// - A request is presented during a cycle: fetch ird with iaddr; data vda (memory) or vio (I/O)
//   with address, rnw and, for a write, dout. The memory takes it at the clock edge that ends
//   the cycle, if its wait input is low in that cycle. While it is high a request isn't taken
//   (the CPU presents no data request then, and may present a fetch request that is ignored).
// - The reply, idin or din, is valid in the first cycle after the request was taken in which the
//   port's wait input is low. A write needs no reply: it is complete for the CPU when taken.
// - idin must hold its last reply until the next fetch request is taken (the CPU holds an
//   instruction in FD by not fetching), and the CPU never uses din except in a reply cycle.
// - iwait and dwait must not depend on the CPU's outputs in the same cycle: they come from the
//   memory's own state (a cache can derive them from its registered request).
// clken stops the whole CPU, as before. hlt is high in the cycle a halt instruction completes, so
// that a system can stop the CPU (by clken); it doesn't stop by itself.
module opc7hpcpu(input[31:0] idin, input[31:0] din,input clk,input reset_b,input[1:0] int_b,input clken,input iwait,input dwait,output vda,output vio,output[31:0] dout,output[19:0] address,output rnw, output[19:0] iaddr, output ird, output hlt);
  parameter MOV=5'h0,MOVT=5'h1,XOR=5'h2,AND=5'h3,OR=5'h4,NOT=5'h5,CMP=5'h6,SUB=5'h7,ADD=5'h8,BPERM=5'h9,ROR=5'hA,LSR=5'hB,JSR=5'hC,ASR=5'hD,ROL=5'hE;
  parameter HLT=5'h10,RTI=5'h11,PPSR=5'h12,GPSR=5'h13,SCMP=5'h16,OUT=5'h18,IN=5'h19,STO=5'h1A,LD=5'h1B,LJSR=5'h1C,LMOV=5'h1D,LSTO=5'h1E,LLD=5'h1F;
  parameter S_MOV=0,S_AND=1,S_OR=2,S_XOR=3,S_MOVT=4,S_ROL=5,S_ADD=6,S_GPSR=7,S_NOT=8,S_SHR=9,S_JSR=10;
  parameter V=31,EI=3,S=2,C=1,Z=0,INT_VECTOR0=20'h2,INT_VECTOR1=20'h4;
  reg [19:0]  PC_q,PC_d,PCI_q,PCI_d,ea_pc_q,mem_pc_q,ex_pc_q,addr_d,ex_target,ex_next,ex_redir_pc;(* RAM_STYLE="DISTRIBUTED" *)
  reg [31:0]  PSR_d,PSR_q,RF_q[14:0],ea_or_q,mem_or_q,ex_or_q,mem_rfp_q,ex_rfp_q,rfp_d,op_d,result;
  reg [4:0]   ea_ir_q,mem_ir_q,ex_ir_q;
  reg [3:0]   swiid,PSRI_q,PSRI_d,ea_dst_q,ea_src_q,mem_dst_q,ex_dst_q,mem_rs_q,mem_rd_q,wb_dst_q;
  reg [31:0]  wb_val_q;
  reg         mem_neg_q,wb_q,mem_early_q,ex_early_q;
  reg         ea_long_q,ea_jmp_q,ea_pred_q,ea_st_q,ea_side_q,ea_mem_q,ea_neg_q,ea_isj_q,ea_red_q,mem_st_q,mem_side_q,mem_isj_q,mem_red_q,ex_st_q,ex_isj_q,ex_red_q;
  reg [10:0]  ex_sel_q;
  reg [32:0]  sum;
  reg         ex_ppsr_q,ex_arith_q,ex_scmp_q,ex_dstf_q,ex_rti_q,ex_ror_q,ex_asr_q;
  reg [3:0]   ea_esrc_q,ea_edst_q,ea_lrs_q,ea_lrd_q;
  reg [2:0]   mem_p_q,ex_p_q;
  reg         fd_q,ea_q,mem_q,ex_q,int_q,fd_d,ea_d,mem_d,ex_d,int_d,issue,refetch_q,refetch_d;
  reg         overflow,zero,carry,sign,enable_int,reset_s0_b,reset_s1_b,ex_subnotadd_q;
  // instruction classes
  function is_store(input [4:0] ir); is_store = ir==STO || ir==LSTO || ir==OUT; endfunction
  function is_side (input [4:0] ir); is_side  = ir==STO || ir==LSTO || ir==OUT || ir==IN; endfunction
  function is_mem  (input [4:0] ir); is_mem   = is_side(ir) || ir==LD || ir==LLD; endfunction
  function redirects(input [4:0] ir, input [3:0] dst);           // may change the flow of control
    redirects = (dst==4'hF && !is_store(ir)) || ir==JSR || ir==LJSR || ir==RTI || ir==PPSR; endfunction
  function pass(input [2:0] p, input [31:0] psr);                // p = word[31:29]
    pass = p[0] ^ (p[1]?(p[2]?psr[S]:psr[Z]):(p[2]?psr[C]:1)); endfunction
  // FD: decode, on the word arriving on idin, so that EA starts from registered control bits. EA's stall
  // decision steers the fetch address, which makes it the critical path; none of this needs to be on it.
  wire [4:0]  fd_ir      = idin[28:24];
  wire [3:0]  fd_dst     = idin[23:20], fd_src = idin[19:16];
  wire        fd_long    = fd_ir[4:2]==3'b111;
  wire        fd_cmp     = fd_ir==CMP || fd_ir==SCMP;
  wire        fd_st      = is_store(fd_ir);
  wire        fd_usedst  = fd_ir==AND || fd_ir==OR || fd_ir==XOR || fd_ir==ADD || fd_ir==SUB || fd_cmp || fd_ir==MOVT || fd_st;
  wire [3:0]  fd_rsrc    = ((|fd_src) && !fd_long && fd_src!=4'hF) ? fd_src : 4'h0;  // registers EA reads (0: none)
  wire [3:0]  fd_rdst    = (fd_usedst && fd_dst!=4'hF) ? fd_dst : 4'h0;
  wire        fd_pred    = idin[31:29]==3'b000;                                // unpredicated
  wire        fd_adder   = ((fd_ir==MOV || fd_ir==LMOV) && fd_dst==4'hF) || ((fd_ir==JSR || fd_ir==LJSR) && fd_dst!=4'hF);  // target from the EA adder
  wire [11:0] fd_dist    = PC_q[11:0] - idin[11:0];                           // to the target if src is r0, modulo 4K words
  wire        fd_back    = (!fd_long && fd_src==4'hF) ? idin[15] : !fd_dist[11];
  wire        fd_jmp     = fd_adder && (fd_pred || (fd_back && (fd_long || fd_src==4'h0 || fd_src==4'hF)));  // an early jump, certain or predicted
  wire        fd_lsrc    = |fd_rsrc && idin[15:0]==16'b0 && !is_mem(fd_ir) && fd_ir!=BPERM && !(fd_adder && fd_pred);  // late: forwarded
  wire        fd_ldst    = |fd_rdst && !fd_st;
  wire        fd_isj     = (fd_dst==4'hF && !fd_st && !fd_cmp) || fd_ir==JSR || fd_ir==LJSR || fd_ir==RTI;  // jumps if it passes
  wire        fd_v       = fd_q && !iwait;                                     // FD has its instruction this cycle
  // EA: hazards and register reads
  wire        mem_wr     = mem_q && !mem_st_q;                                 // will write mem_dst_q
  wire        ex_wr      = ex_q  && !ex_st_q;
  wire        raw        = (|ea_esrc_q && ((mem_wr && mem_dst_q==ea_esrc_q) || (ex_wr && ex_dst_q==ea_esrc_q))) ||
                           (|ea_edst_q && ((mem_wr && mem_dst_q==ea_edst_q) || (ex_wr && ex_dst_q==ea_edst_q)));
  wire        flags_busy = mem_wr || ex_wr;
  wire        side_wait  = ea_side_q && ((mem_q && mem_red_q) || (ex_q && ex_red_q) || (!ea_pred_q && flags_busy));
  wire        ea_side_ok = pass(ea_or_q[31:29], PSR_q);                        // predicate of a side effect, flags settled
  wire [31:0] RF_sout    = {32{(|ea_src_q)&&!ea_long_q}} & ((ea_src_q==4'hF)? {12'b0,ea_pc_q} : RF_q[ea_src_q]);
  wire [7:0]  bytes0     = {8{~ea_or_q[2] }} & ((ea_or_q[1])?  ((ea_or_q[0]) ?RF_sout[31:24] :RF_sout[23:16]):(ea_or_q[0]) ? RF_sout[15:8]:RF_sout[7:0]);
  wire [7:0]  bytes1     = {8{~ea_or_q[6] }} & ((ea_or_q[5])?  ((ea_or_q[4]) ?RF_sout[31:24] :RF_sout[23:16]):(ea_or_q[4]) ? RF_sout[15:8]:RF_sout[7:0]);
  wire [7:0]  bytes2     = {8{~ea_or_q[10]}} & ((ea_or_q[9])?  ((ea_or_q[8]) ?RF_sout[31:24] :RF_sout[23:16]):(ea_or_q[8]) ? RF_sout[15:8]:RF_sout[7:0]);
  wire [7:0]  bytes3     = {8{~ea_or_q[14]}} & ((ea_or_q[13])? ((ea_or_q[12])?RF_sout[31:24] :RF_sout[23:16]):(ea_or_q[12])? RF_sout[15:8]:RF_sout[7:0]);
  wire [31:0] din_sxt    = ea_long_q? {{12{ea_or_q[19]}},ea_or_q[19:0]} : {{16{ea_or_q[15]}}, ea_or_q[15:0]};
  // EX: completion, jumps and interrupts
  wire        ex_pass    = ex_q && pass(ex_p_q, PSR_q);
  wire        ex_jump    = ex_pass && ex_isj_q;
  wire        hw_int     = !(&int_b) & PSR_q[EI];
  wire        ex_int     = ex_pass && ((hw_int && !(mem_q && mem_side_q)) || (ex_ppsr_q && (|swiid)));
  wire        ex_mis     = ex_q && ex_early_q && !pass(ex_p_q, PSR_q);         // only a predicted jump can fail
  wire        ex_redir   = (ex_jump && !ex_early_q) || ex_mis;                 // not already taken from EA, or wrongly taken
  wire        flush      = ex_redir || ex_int;                                 // cancel MEM, EA and FD
  wire        mem_ld     = mem_ir_q==LD || mem_ir_q==LLD || mem_ir_q==IN;
  wire        mem_hold   = mem_q && mem_ld && dwait;                           // a load's reply hasn't come: MEM holds
  wire        ea_go      = ea_q && !raw && !side_wait && !flush && !mem_hold && !(ea_mem_q && dwait);  // EA -> MEM this cycle
  wire        ea_early   = ea_q && ea_jmp_q && !raw && !mem_hold;  // redirect from EA, cancel FD (not ea_go: a flush has priority wherever this is used, and the shorter path matters)
  wire        ea_act     = ea_go && ea_mem_q && (!ea_side_q || ea_side_ok);  // memory/IO access now
  // MEM: decode for EX
  wire        mem_addg   = mem_ir_q==ADD || mem_ir_q==SUB || mem_ir_q==CMP || mem_ir_q==SCMP;
  wire [10:0] mem_oth    = {mem_ir_q==JSR||mem_ir_q==LJSR, mem_ir_q==ROR||mem_ir_q==ASR||mem_ir_q==LSR, mem_ir_q==NOT, mem_ir_q==GPSR, mem_addg,
                            mem_ir_q==ROL, mem_ir_q==MOVT, mem_ir_q==XOR, mem_ir_q==OR, mem_ir_q==AND, 1'b0};
  wire [10:0] mem_sel    = {mem_oth[10:1], !(|mem_oth)};                       // bit S_MOV: everything else
  // forwarding into MEM -> EX: the result in EX, else wb
  wire        ex_wrf     = ex_pass && !ex_st_q && ex_dst_q!=4'hF && |ex_dst_q;   // writes a register now
  wire        fs_ex      = |mem_rs_q && ex_wrf && ex_dst_q==mem_rs_q, fs_wb = |mem_rs_q && wb_q && wb_dst_q==mem_rs_q;
  wire        fd_ex      = |mem_rd_q && ex_wrf && ex_dst_q==mem_rd_q, fd_wb = |mem_rd_q && wb_q && wb_dst_q==mem_rd_q;
  wire [31:0] mem_op     = (fs_ex || fs_wb) ? ((fs_ex ? result : wb_val_q) ^ {32{mem_neg_q}}) : mem_or_q;
  wire [31:0] mem_rfp    = fd_ex ? result : fd_wb ? wb_val_q : mem_rfp_q;
  assign {rnw,dout,address} = {!(ea_act && ea_st_q), rfp_d, addr_d};
  assign {ird,iaddr} = {issue,PC_d};
  assign {vda,vio}   = {2{ea_act}} & {!(ea_ir_q==IN || ea_ir_q==OUT), ea_ir_q==IN || ea_ir_q==OUT};
  always @( * ) begin
    // ex_sel_q: one-hot, decoded on the way from MEM (the ALU and flags are the longest path in EX)
    sum    = ex_rfp_q + ex_or_q + ex_subnotadd_q;   // ex_or_q negated in EA if required for sub/cmp
    result = ({32{ex_sel_q[S_AND]}}   & (ex_rfp_q & ex_or_q)) |
             ({32{ex_sel_q[S_OR]}}    & (ex_rfp_q | ex_or_q)) |
             ({32{ex_sel_q[S_XOR]}}   & (ex_rfp_q ^ ex_or_q)) |
             ({32{ex_sel_q[S_MOVT]}}  & {ex_or_q[15:0], ex_rfp_q[15:0]}) |
             ({32{ex_sel_q[S_ROL]}}   & {ex_or_q[30:0], PSR_q[C]}) |
             ({32{ex_sel_q[S_ADD]}}   & sum[31:0]) |
             ({32{ex_sel_q[S_GPSR]}}  & PSR_q) |
             ({32{ex_sel_q[S_NOT]}}   & ~ex_or_q) |
             ({32{ex_sel_q[S_SHR]}}   & {(ex_ror_q & PSR_q[C]) | (ex_asr_q & ex_or_q[31]), ex_or_q[31:1]}) |
             ({32{ex_sel_q[S_JSR]}}   & {12'b0, ex_pc_q}) |
             ({32{ex_sel_q[S_MOV]}}   & ex_or_q);
    carry  = ex_sel_q[S_ADD] ? sum[32] : ex_sel_q[S_ROL] ? ex_or_q[31] : ex_sel_q[S_SHR] ? ex_or_q[0] : PSR_q[C];
    overflow = ex_ppsr_q ? ex_or_q[31]: ex_arith_q ?((ex_rfp_q[31]&ex_or_q[31]&(~result[31]))|((~ex_rfp_q[31])&(~ex_or_q[31])&result[31])):PSR_q[V];
    {swiid,enable_int,sign,carry,zero} = ex_ppsr_q?ex_or_q[7:0]:(!ex_dstf_q)?{PSR_q[7:3],(result[31]^(ex_scmp_q&overflow)),carry,!(|result)}:PSR_q;
    ex_target = ex_rti_q ? PCI_q : (ex_dstf_q && !ex_st_q) ? result[19:0] : ex_or_q[19:0];
    ex_next   = ex_jump ? ex_target : ex_pc_q;
    ex_redir_pc = ex_rti_q ? PCI_q : (ex_dstf_q && !ex_st_q && !ex_early_q) ? result[19:0] : ex_early_q ? ex_pc_q : ex_or_q[19:0];
  end
  // stage control
  always @( * ) begin
    ea_d  = !flush && !ea_early && ((fd_v && (!ea_q || ea_go)) || (ea_q && !ea_go));
    mem_d = ea_go || (mem_hold && !flush);
    ex_d  = mem_q && !flush && !mem_hold;
    int_d = ex_int;
    {PC_d, issue, fd_d} = {PC_q, 1'b0, fd_q && !flush};                       // FD held
    if (ex_int)                    {issue, fd_d} = 2'b00;                     // INT next, then the vector
    else if (ex_redir)             {PC_d, issue, fd_d} = {ex_redir_pc, 2'b11};
    else if (int_q)                {PC_d, issue, fd_d} = {(!int_b[1])?INT_VECTOR1:INT_VECTOR0, 2'b11};
    else if (ea_early)             {PC_d, issue, fd_d} = {addr_d[19:0], 2'b11};
    else if (refetch_q)            {PC_d, issue, fd_d} = {PC_q, 2'b11};       // a redirect the memory didn't take
    else if (fd_v && (!ea_q || ea_go)) {PC_d, issue, fd_d} = {PC_q + 20'd1, 2'b11};
    if (!reset_s1_b) {PC_d, issue, fd_d, ea_d, mem_d, ex_d, int_d} = {20'b0, 2'b11, 4'b0};
    // a fetch the memory doesn't take (iwait) is made again from PC_q once it is free; one already
    // made goes on, and its reply is thrown away if FD has been cancelled meanwhile (fd_d low)
    refetch_d = refetch_q && !issue && !ex_int;
    if (iwait && issue) {fd_d, refetch_d} = 2'b01;
  end
  // EA operand and address, PSR
  always @( * ) begin
    {PCI_d, PSRI_d, PSR_d} = {PCI_q, PSRI_q, PSR_q};
    // consider removing the &{32{(|ea_dst_q)}} and instead zeroing all writes to R0 to ensure it's always zero instead. NB there will need to be one write to R0 to initialise it.
    rfp_d   = (ea_dst_q==4'hF)? {12'b0,ea_pc_q} : RF_q[ea_dst_q] & {32{(|ea_dst_q)}};
    op_d    = (ea_ir_q==BPERM)?({bytes3,bytes2,bytes1,bytes0}):(RF_sout+din_sxt) ^ {32{ea_neg_q}};
    addr_d  = RF_sout+din_sxt;
    if (!reset_s1_b)
      {PCI_d, PSRI_d, PSR_d, rfp_d, addr_d} = 0;
    else if (int_q)
      {PSRI_d, PSR_d[EI]} = {PSR_q[3:0], 1'b0};
    else if (ex_pass && !ex_st_q) begin
      PSR_d = ex_rti_q?{4'b0,PSRI_q}:{overflow,23'b0,swiid,enable_int,sign,carry,zero};
      if (ex_int) PCI_d = ex_next;
    end
    else if (ex_int)
      PCI_d = ex_next;
  end
  always @(posedge clk)
    if (clken) begin
      {PC_q, PCI_q, PSRI_q, PSR_q} <= {PC_d, PCI_d, PSRI_d, PSR_d};
      {reset_s0_b, reset_s1_b} <= {reset_b, reset_s0_b};
      {fd_q, ea_q, mem_q, ex_q, int_q, refetch_q} <= {fd_d, ea_d, mem_d, ex_d, int_d, refetch_d};
      if (fd_v && (!ea_q || ea_go))  // FD -> EA: the instruction word and its r15 value
      begin
        {ea_ir_q, ea_dst_q, ea_src_q, ea_or_q, ea_pc_q} <= {idin[28:16], idin, PC_q + 20'd1};
        {ea_long_q, ea_jmp_q, ea_pred_q, ea_st_q, ea_side_q, ea_mem_q, ea_neg_q, ea_isj_q, ea_red_q} <=
          {fd_long, fd_jmp, fd_pred, fd_st, is_side(fd_ir), is_mem(fd_ir), fd_ir==SUB||fd_cmp, fd_isj, (fd_isj||fd_ir==PPSR) && !fd_jmp};
        {ea_esrc_q, ea_edst_q, ea_lrs_q, ea_lrd_q} <= {fd_lsrc ? 4'h0 : fd_rsrc, fd_ldst ? 4'h0 : fd_rdst, fd_lsrc ? fd_rsrc : 4'h0, fd_ldst ? fd_rdst : 4'h0};
      end
      if (ea_go)                     // EA -> MEM (compares write no register: dst 0)
        {mem_ir_q, mem_dst_q, mem_pc_q, mem_or_q, mem_rfp_q, mem_p_q, mem_rs_q, mem_rd_q, mem_neg_q, mem_early_q, mem_st_q, mem_side_q, mem_isj_q, mem_red_q} <=
          {ea_ir_q, (ea_ir_q==CMP||ea_ir_q==SCMP)? 4'b0 : ea_dst_q, ea_pc_q, op_d, rfp_d,
           ea_side_q ? (ea_side_ok ? 3'b000 : 3'b001) : ea_or_q[31:29],  // side effects: tested in EA
           ea_lrs_q, ea_lrd_q, ea_neg_q, ea_jmp_q, ea_st_q, ea_side_q, ea_isj_q, ea_red_q};
      if (mem_q && !mem_hold)        // MEM -> EX: loads take the data
        {ex_ir_q, ex_dst_q, ex_pc_q, ex_or_q, ex_rfp_q, ex_p_q, ex_subnotadd_q, ex_early_q, ex_st_q, ex_isj_q, ex_red_q,
         ex_sel_q, ex_ppsr_q, ex_arith_q, ex_scmp_q, ex_dstf_q, ex_rti_q, ex_ror_q, ex_asr_q} <=
          {mem_ir_q, mem_dst_q, mem_pc_q, mem_ld ? din : mem_op, mem_rfp, mem_p_q, mem_ir_q!=ADD, mem_early_q, mem_st_q, mem_isj_q, mem_red_q,
           mem_sel, mem_ir_q==PPSR, mem_addg && mem_dst_q!=4'hF, mem_ir_q==SCMP, mem_dst_q==4'hF, mem_ir_q==RTI, mem_ir_q==ROR, mem_ir_q==ASR};
      {wb_q, wb_dst_q, wb_val_q} <= {ex_wrf, ex_dst_q, result};   // what EX writes, for the instruction two behind
      if (ex_pass && !ex_st_q) begin
	 // consider following to ensure that 0's are always written to R0, and then some logic could be removed from the read path above
	 // RF_q[ex_dst_q] <= result & {32{(|ex_dst_q)}};
        RF_q[ex_dst_q] <= result;
      end
    end
  // simulation only (unused in synthesis): what opc7htb.v -DTB_PIPE uses for the retirement trace and the halt
  reg  [19:0] ea_addr_q, mem_addr_q, ex_addr_q;
  reg  [31:0] ea_word_q, mem_word_q, ex_word_q;
  always @(posedge clk)
    if (clken) begin
      if (fd_v && (!ea_q || ea_go)) {ea_addr_q, ea_word_q} <= {PC_q, idin};
      if (ea_go) {mem_addr_q, mem_word_q} <= {ea_addr_q, ea_word_q};
      if (mem_q && !mem_hold) {ex_addr_q, ex_word_q} <= {mem_addr_q, mem_word_q};
    end
  wire        tb_retire      = reset_s1_b && ex_q;
  wire [19:0] tb_retire_pc   = ex_addr_q;
  wire [31:0] tb_retire_word = ex_word_q;
  assign      hlt            = ex_pass && ex_ir_q==HLT;
  wire        tb_halt        = hlt;
endmodule
