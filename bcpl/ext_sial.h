MANIFEST {   // sial opcodes and directives
f_1=      1  // Used in the run length encoding scheme
f_2=      2  // in compacted sial

f_lp=     3
f_lg=     4
f_ll=     5

f_llp=    6
f_llg=    7
f_lll=    8
f_lf=     9
f_lw=    10

f_l=      11
f_lm=     12

f_sp=     13
f_sg=     14
f_sl=     15

f_ap=     16
f_ag=     17
f_a=      18
f_s=      19

f_lkp=    20
f_lkg=    21
f_rv=     22
f_rvp=    23
f_rvk=    24
f_st=     25
f_stp=    26
f_stk=    27
f_stkp=   28
f_skg=    29
f_xst=    30

f_k=      31
f_kpg=    32

f_neg=    33
f_not=    34
f_abs=    35

f_xdiv=   36
f_xrem=   37
f_xsub=   38

f_mul=    39
f_div=    40
f_rem=    41
f_add=    42
f_sub=    43

f_eq=     44
f_ne=     45
f_ls=     46
f_gr=     47
f_le=     48
f_ge=     49
f_eq0=    50
f_ne0=    51
f_ls0=    52
f_gr0=    53
f_le0=    54
f_ge0=    55

f_lsh=    56
f_rsh=    57
f_and=    58
f_or=     59
f_xor=    60
f_eqv=    61

f_gbyt=   62
f_xgbyt=  63
f_pbyt=   64
f_xpbyt=  65

f_swb=    66
f_swl=    67

f_xch=    68
f_atb=    69
f_atc=    70
f_bta=    71
f_btc=    72
f_atblp=  73
f_atblg=  74
f_atbl=   75

f_j=      76
f_rtn=    77
f_goto=   78

f_ikp=    79
f_ikg=    80
f_ikl=    81
f_ip=     82
f_ig=     83
f_il=     84

f_jeq=    85
f_jne=    86
f_jls=    87
f_jgr=    88
f_jle=    89
f_jge=    90

f_jeq0=   91
f_jne0=   92
f_jls0=   93
f_jgr0=   94
f_jle0=   95
f_jge0=   96
f_jge0m=  97

f_brk=    98
f_nop=    99
f_chgco=  100
f_mdiv=   101
f_sys=    102

f_section=  103
f_modstart= 104
f_modend=   105
f_global=   106
f_string=   107
f_const=    108
f_static=   109
f_mlab=     110
f_lab=      111
f_lstr=     112
f_entry=    113

f_float=    114
f_fix=      115
f_fabs=     116
f_fmul=     117
f_fdiv=     118
f_fxdiv=    119
f_fadd=     120
f_fsub=     121
f_fxsub=    122
f_fneg=     123

f_feq=      124
f_fne=      125
f_fls=      126
f_fgr=      127
f_fle=      128
f_fge=      129

f_feq0=     130
f_fne0=     131
f_fls0=     132
f_fgr0=     133
f_fle0=     134
f_fge0=     135

f_jfeq=     136
f_jfne=     137
f_jfls=     138
f_jfgr=     139
f_jfle=     140
f_jfge=     141

f_jfeq0=    142
f_jfne0=    143
f_jfls0=    144
f_jfgr0=    145
f_jfle0=    146
f_jfge0=    147

f_res=      148
f_ldres=    149

// Extensions

f_ext_asl=        155    //  a := b << 1
f_ext_lsr=        156    //  a := b >> 1
f_ext_asl_a=      157    //  a := a << 1
f_ext_lsr_a=      158    //  a := a >> 1

// _ext_jeq0=      159    //   as f_jeq0 but no need for compare as Z flag set by prev. instruction
// _ext_jne0=     160    //   as f_jne0 but no need for compare as Z flag set by prev. instruction
// _ext_jge0=     161    //   as f_jge0 but no need for compare as S flag set by prev. instruction
// _ext_jls0=     162    //   as f_jls0 but no need for compare as S flag set by prev. instruction
// _ext_sjeq0= 163
// _ext_sjne0= 164
// _ext_sjge0= 165
// _ext_sjls0= 166  
// 
// sj_offset= 100
// f_sj=      176  
// f_sjeq=    185
// f_sjne=    186
// f_sjls=    187
// f_sjgr=    188
// f_sjle=    189
// f_sjge=    190
// 
// f_sjeq0=   191
// f_sjne0=   192
// f_sjls0=   193
// f_sjgr0=   194
// f_sjle0=   195
// f_sjge0=   196


// Alternatives which swap use of A and B or C reg but otherwise identical to originals
b_offset= 250
c_offset= 450  
}
