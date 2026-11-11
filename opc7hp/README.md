# OPC7HP: Harvard, pipelined OPC7

An alternative implementation of the 32 bit OPC7 (`../opc7`): the same instruction set, with
separate instruction and data ports (Harvard) and a four stage pipeline, and an FPGA system built
around it. It depends on the original OPC7 in `../opc7` (opc7cpu.v, the emulators, the assembler,
the claude-tests and bcpltests) and on the BCPL tools in `../bcpl`.

## Layout

| Directory | Contents |
|---|---|
| `cpu/` | `opc7hpcpu.v`, the pipelined CPU; `opc7hcpu.v`, the reference Harvard OPC7 that runs one instruction at a time; the testbench and the checks (`make` there: traces against the emulator, STORE/OUT against opc7cpu.v, directed hazard tests, random interrupts, random memory waits) |
| `system/` | the FPGA system: CPU, boot ROM, RAM, UART, GPIO (`opc7hsys.v`); `sysrun.sh` builds a BCPL program for it and runs it in simulation |
| `software/` | BCPL software for the system |
| `synthesis/` | resource and Fmax figures for each board (`tangnano20k/`, `ulx3s/`) and the system bitstream build |
| `doc/` | the system summary page |

## How it grew

The first step, opc7hcpu.v, made these changes to OPC7:

- addition of a separate instruction memory port
- computation of predicates in EAD state only
- no overlapping of FET and EXEC states

Those changes to the state machine make OPC7 execute more cycles, but they simplify the machine
ready for a more generic pipeline. opc7hpcpu.v then overlaps four stages (FD, EA, MEM, EX) with
forwarding, early and predicted jumps, and separate wait inputs for slow memory; see the header of
`cpu/opc7hpcpu.v`.
