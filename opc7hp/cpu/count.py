#!/usr/bin/env python3
'''
count.py [test ...] - where opc7hpcpu's cycles go (opc7hcount.v): run claude-tests (default the
quick four; 'all' for all 12) or .hex paths and print the cost of each cause in CPI, for the tests
added together. Checks that the classes add up to the cycle count. Work files go in build/count.*.
Environment: JOBS (default 4), TIMEOUT seconds per test (default 3600).
'''
import os, re, subprocess, sys, shutil, collections
from concurrent.futures import ThreadPoolExecutor
here = os.path.dirname(os.path.abspath(__file__))
QUICK = 'writefmt cmptest optest optest32'.split()
ALL = 'cmptest optest optest32 writefmt randtest divtest bittest shifttest p2divtest p2div32test xdivtest multest'.split()

def run(t):
    hexf = t if os.path.exists(t) else os.path.join(here, '..', '..', 'opc7', 'claude-tests', t + '.hex')
    name = os.path.basename(hexf)[:-4]
    w = os.path.join(here, 'build', 'count.' + name)
    os.makedirs(w, exist_ok=True)
    shutil.copy(hexf, os.path.join(w, 'test.hex'))
    subprocess.run(['iverilog', '-DTB_PIPE', '-DCPU=opc7hpcpu', '-o', 'sim'] + [os.path.join(here, f) for f in ('opc7htb.v', 'opc7hpcpu.v', 'opc7hcount.v')], cwd=w, check=True)
    p = subprocess.Popen(['timeout', os.environ.get('TIMEOUT', '3600'), 'vvp', '-n', 'sim'], cwd=w, stdout=subprocess.PIPE, text=True, errors='replace')
    r = None
    for l in p.stdout:
        if l.startswith('COUNT '):
            r = {k: int(v) for k, v in re.findall(r'(\w+)=(\d+)', l)}
    p.wait()
    try: os.remove(os.path.join(w, 'test.dump'))
    except OSError: pass
    if r is None: sys.exit('no COUNT line from ' + name)
    return name, r

def main():
    tests = sys.argv[1:] or QUICK
    if tests == ['all']: tests = ALL
    with ThreadPoolExecutor(int(os.environ.get('JOBS', 4))) as ex:
        res = list(ex.map(run, tests))
    c = collections.Counter()
    for name, r in res:
        c.update(r)
        print('%-12s %10d instructions %10d cycles  CPI %.3f' % (name, r['retired'], r['cycles'], r['cycles'] / r['retired']))
    n = c['retired']
    groups = [
      ('taken predicated jumps', 'n_pred', 'flush_pred empty_pred', 'wasted'),
      ('other jumps taken in EX', 'n_jump', 'flush_jump empty_jump', ''),
      ('early jumps', 'n_early', 'empty_early', ''),
      ('interrupts, start', 'n_int', 'flush_int empty_other wasted_int', ''),
    ]
    print('\n%d instructions, %d cycles, CPI %.3f; predicated off %.2f%%' % (n, c['cycles'], c['cycles'] / n, 100.0 * c['predoff'] / n))
    print('%-34s %9s %8s' % ('cause', 'events', 'CPI cost'))
    total = n
    # cycles cancelled in MEM by a jump: shared by the two kinds of jump in EX by number of redirects
    wj = c['wasted_jump']; nj = c['n_pred'] + c['n_jump']
    for label, ev, keys, w in groups:
        k = sum(c[x] for x in keys.split())
        if label.endswith('in EX') or label.startswith('taken'):
            k += wj * c[ev] / nj if nj else 0
        total += k
        print('%-34s %9d %8.3f' % (label, c[ev], k / n))
    for label, keys in (('wait: address, source from ALU', 'raw_addr_alu'), ('wait: address, source from load', 'raw_addr_ld'),
                        ('wait: imm != 0/bperm, from ALU', 'raw_imm_alu'), ('wait: imm != 0/bperm, from load', 'raw_imm_ld'),
                        ('wait: early jump source, ALU', 'raw_jmp_alu'), ('wait: early jump source, load', 'raw_jmp_ld'),
                        ('wait: store data, from ALU', 'raw_data_alu'), ('wait: store data, from load', 'raw_data_ld'),
                        ('side effect behind a redirect', 'side_redir'), ('side effect waits for flags', 'side_flags')):
        total += c[keys]
        print('%-34s %9d %8.3f' % (label, c[keys], c[keys] / n))
    print('%-34s %9s %8.3f  (cycles %d, difference %d)' % ('sum, with 1.0 for the instructions', '', total / n, c['cycles'], c['cycles'] - total))
    print('of the predicated jumps: %d mispredicted (in the first line); of the early jumps: %d predicted taken' % (c['n_mis'], c['n_ptk']))
main()
