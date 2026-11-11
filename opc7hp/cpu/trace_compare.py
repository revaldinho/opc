#!/usr/bin/env python3
'''
trace_compare.py - compare an opc7h CPU's retirement trace with opc7emu.py

  trace_compare.py test [cpu]

test is a claude-tests name (../../opc7/claude-tests/<test>.hex) or a path to a .hex
file; cpu is the module (default opc7hpcpu), or a path to a .v file whose
module has the same name as the file. The CPU is simulated with
opc7htb.v built with -DRETIRE_TRACE, and opc7emu.py runs the same program with
its full trace. Both are read through pipes, so no trace files are written.

For instruction n the PC and instruction word must match, and the flags
(V SWI EI S C Z) and r1-r14 after it must match the state the emulator prints
before instruction n+1. Registers the RTL has not written yet are 'x' and
match anything. The first difference is reported with the instructions just
before it; on success the number of instructions compared is printed.
Environment: EMU, the Python that runs opc7emu.py (default pypy3 if installed, else
python3), or EMU=c for the compiled C emulator ../../opc7/opc7emu instead (much faster; it must be
built from the current opc7emu.c, and is refused if it is older); TBDEFS, extra iverilog
options, and SIMARGS, vvp plusargs (as for check.sh); WORKTAG, a suffix for the work
directory, so that runs of the same test with different options can run at once.
'''
import sys, os, re, shutil, subprocess, collections

here = os.path.dirname(os.path.abspath(__file__))
opc7 = os.path.normpath(os.path.join(here, '..', '..', 'opc7'))   # the original OPC7

def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    test = sys.argv[1]
    cpu = sys.argv[2] if len(sys.argv) > 2 else 'opc7hpcpu'
    hexf = test if os.path.exists(test) else os.path.join(opc7, 'claude-tests', test + '.hex')
    name = os.path.basename(hexf)[:-4] if hexf.endswith('.hex') else os.path.basename(hexf)
    if not os.path.exists(hexf):
        sys.exit('no %s' % hexf)
    if cpu.endswith('.v'):
        src, cpu = os.path.abspath(cpu), os.path.basename(cpu)[:-2]
    else:
        src = os.path.join(here, cpu + '.v')
        if not os.path.exists(src):
            src = os.path.join(opc7, cpu + '.v')

    tag = os.environ.get('WORKTAG', '')
    work = os.path.join(here, 'build', 'trace.%s.%s%s' % (cpu, name, '.' + tag if tag else ''))
    os.makedirs(work, exist_ok=True)
    shutil.copy(hexf, os.path.join(work, 'test.hex'))
    pipe = ['-DTB_PIPE'] if 'tb_retire' in open(src).read() else []   # see opc7htb.v
    subprocess.run(['iverilog', '-DRETIRE_TRACE', '-DCPU=' + cpu] + pipe + os.environ.get('TBDEFS', '').split() + ['-o', os.path.join(work, 'sim'),
                    os.path.join(here, 'opc7htb.v'), src], check=True)

    emu = os.environ.get('EMU') or ('pypy3' if shutil.which('pypy3') else 'python3')
    stdin = hexf[:-4] + '.stdin'
    if emu == 'c':
        cbin, csrc = os.path.join(opc7, 'opc7emu'), os.path.join(opc7, 'opc7emu.c')
        if not os.path.exists(cbin) or os.path.getmtime(cbin) < os.path.getmtime(csrc):
            sys.exit('EMU=c: %s is missing or older than opc7emu.c: rebuild it' % cbin)
        eargs = [cbin]
    else:
        eargs = [emu, os.path.join(opc7, 'opc7emu.py')]
    eargs += [hexf, '-'] + ([stdin] if os.path.exists(stdin) else [])
    env = dict(os.environ, PYPY_GC_NURSERY=os.environ.get('PYPY_GC_NURSERY', '4M'))   # as Makefile_bcpl.inc; also quiets pypy
    ep = subprocess.Popen(eargs, stdout=subprocess.PIPE, text=True, errors='replace', env=env)
    sp = subprocess.Popen(['vvp', '-n', 'sim'] + os.environ.get('SIMARGS', '').split(), cwd=work, stdout=subprocess.PIPE, text=True, errors='replace')

    ename = 'opc7emu (C)' if emu == 'c' else 'opc7emu.py'
    eline = re.compile(r'^([0-9a-f]{8}) : ([0-9A-F]{8}) : (.{22,}?) : (\d)  ([0-9A-F])  (\d) (\d) (\d) (\d) : (.*)$')
    def emu_states():
        for l in ep.stdout:
            m = eline.match(l)
            if m:
                regs = m.group(10).split()
                yield (int(m.group(1), 16), int(m.group(2), 16), m.group(3).strip(),
                       [int(m.group(i)) if i != 5 else int(m.group(5), 16) for i in range(4, 10)],
                       [int(r, 16) for r in regs[1:15]])
    def rtl_states():
        for l in sp.stdout:
            if l.startswith('RETIRE '):
                head, flags, regs = l[7:].split(':')
                pc, word = head.split()
                yield int(pc, 16), int(word, 16), flags.split(), regs.split()

    fnames = ['V', 'SWI', 'EI', 'S', 'C', 'Z']
    recent = collections.deque(maxlen=4)
    es = emu_states()
    prev = next(es, None)
    n = xs = 0
    result = 0
    for rpc, rword, rflags, rregs in rtl_states():
        cur = next(es, None)
        if prev is None:
            print('FAIL %s: the RTL retired an instruction after the emulator stopped (pc %05x)' % (name, rpc)); result = 1; break
        epc, eword, edis = prev[0], prev[1], prev[2]
        diffs = []
        if (rpc, rword) != (epc & 0xFFFFF, eword):
            diffs.append('pc/word RTL %05x %08x, emulator %05x %08x' % (rpc, rword, epc, eword))
        elif cur is not None:
            swi = (rword >> 24) & 0x1F == 0x12 and cur[3][1] != 0   # putpsr raising a software interrupt:
            for f, rv, ev in zip(fnames, rflags, cur[3]):          # the emulator's state already has EI clear
                if swi and f == 'EI':
                    continue
                if 'x' in rv.lower() or int(rv, 16) != ev:
                    diffs.append('%s RTL %s, emulator %X' % (f, rv, ev))
            for i, (rv, ev) in enumerate(zip(rregs, cur[4]), 1):
                if 'x' in rv.lower():
                    xs += 1
                elif int(rv, 16) != ev:
                    diffs.append('r%d RTL %s, emulator %08X' % (i, rv, ev))
        if diffs:
            print('FAIL %s: instruction %d, %05x %08x %s' % (name, n, epc, eword, edis))
            for d in diffs:
                print('  ' + d)
            print('  preceding instructions:')
            for r in recent:
                print('    %05x %08x %s' % r)
            result = 1
            break
        recent.append((epc, eword, edis))
        prev = cur
        n += 1
    else:
        if prev is not None and prev[2].split()[0].split('.')[-1] != 'halt':
            print('FAIL %s: the RTL stopped after %d instructions, the emulator went on (next %05x %s)' % (name, n, prev[0], prev[2]))
            result = 1
        else:
            print('PASS %s: %s matches %s over %d instructions (%d register values not yet written in the RTL)' % (name, cpu, ename, n, xs))
    for p in (sp, ep):
        p.kill()
        p.wait()
    try:
        os.remove(os.path.join(work, 'test.dump'))
    except OSError:
        pass
    sys.exit(result)

main()
