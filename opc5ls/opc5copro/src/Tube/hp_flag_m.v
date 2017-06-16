`timescale 1ns / 1ns

`undef p1edge
`undef p2edge
`define p1edge negedge
`define p2edge posedge

module hp_flag_m
		  
`include "gen_flag_v3.v"
