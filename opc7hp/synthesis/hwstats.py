#!/usr/bin/env python3
'''
hwstats.py - summarise nextpnr-himbaechel logs as one results line

  hwstats.py --cpu NAME [--note TEXT] [--synthlog yosys.log] [--results FILE] source.v ... -- seed1.log ...

ECP5 logs (nextpnr-ecp5, recognised by TRELLIS_COMB) give a different line: LOGIC is TRELLIS_COMB,
the LUT4 sites used for logic, carry (CCU2C, two each) and distributed RAM; LUT4, CCU2C and the
PFUMX/L6MUX21 wide-function muxes come from the yosys log (--synthlog); FF, RAMW (distributed RAM
slices), DP16KD (block RAM) and MULT18 (18x18 multipliers) from nextpnr. --results names the file
the line is for, so that its header is printed when the file is new.

Resource use is taken from the first log (it is the same for every seed).
LOGIC is LUT4 + ALU, with its share of the device's LUT4s: an ALU cell (a bit
of an adder or comparator) takes a LUT4 site, and yosys moves logic between
the two, so LUT4 alone can mislead when designs are compared.
Newer nextpnr (0.11.1 here; recognised by its 'Pack GW JTAG' step) counts the LUT4
site of each ALU, and the 4 LUT4s and 6 DFFs of each RAM16SDP4 slice, in its
LUT4 and DFF lines; those are taken off so that LUT4 and DFF still count the
netlist's cells, as nextpnr 0.9 reported them.
Fmax is the post-route figure, the last 'Max frequency' line of each log. The
sources are identified by their git commit when tracked and clean, otherwise
by a short md5 of their contents.
'''
import sys, re, os, hashlib, subprocess, statistics, datetime

COLS = [('LUT4', 'LUT4'), ('MUX2', ('MUX2_LUT5', 'MUX2_LUT6', 'MUX2_LUT7', 'MUX2_LUT8')), ('ALU', 'ALU'),
        ('DFF', 'DFF'), ('RAM16', 'RAM16SDP4'), ('BSRAM', 'BSRAM'),
        ('DSP', ('MULT9X9', 'MULT18X18', 'MULT36X36', 'MULTALU18X18', 'MULTALU36X18', 'MULTADDALU18X18', 'ALU54D'))]

def version(src):
    d = os.path.dirname(os.path.abspath(src)) or '.'
    git = lambda *a: subprocess.run(['git', '-C', d] + list(a), capture_output=True, text=True)
    if git('ls-files', '--error-unmatch', os.path.basename(src)).returncode == 0:
        rev = git('log', '-1', '--format=%h', '--', os.path.basename(src)).stdout.strip()
        dirty = git('diff', '--quiet', 'HEAD', '--', os.path.basename(src)).returncode != 0
        return rev + ('+' if dirty else '')
    return 'md5:' + hashlib.md5(open(src, 'rb').read()).hexdigest()[:7]

def main():
    args = sys.argv[1:]
    opt = lambda k, d='': args[args.index(k) + 1] if k in args else d
    cpu, note, synthlog, results = opt('--cpu'), opt('--note'), opt('--synthlog'), opt('--results', 'results.txt')
    sep = args.index('--')
    srcs = [a for (i, a) in enumerate(args[:sep]) if not a.startswith('--') and args[i-1] not in ('--cpu', '--note', '--synthlog', '--results')]
    logs = args[sep+1:]
    if 'TRELLIS_COMB' in open(logs[0]).read():
        return ecp5(cpu, note, synthlog, results, srcs, logs)
    used = {}
    newpnr = 'Pack GW JTAG' in open(logs[0]).read()
    for line in open(logs[0]):
        m = re.match(r'Info:\s+(\w+):\s+(\d+)/\s*(\d+)', line)
        if m:
            used[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    fmax = []
    for log in logs:
        f = re.findall(r'Max frequency for clock .*?: ([\d.]+) MHz', open(log).read())
        fmax.append(float(f[-1]))
    def col(names):
        names = (names,) if isinstance(names, str) else names
        return sum(used.get(n, (0, 0))[0] for n in names)
    lut = used.get('LUT4', (0, 1))
    dff = col('DFF')
    if newpnr:
        lut = (lut[0] - col('ALU') - 4 * col('RAM16SDP4'), lut[1])
        dff -= 6 * col('RAM16SDP4')
    hdr = '%-16s %-6s %-12s %6s %6s %6s %5s %5s %5s %5s %5s %6s %20s  %s' % (
        'date', 'cpu', 'version', 'LOGIC', 'LOGIC%', 'LUT4', 'ALU', 'MUX2', 'DFF', 'RAM16', 'BSRAM', 'DSP',
        'Fmax MHz min/med/max', 'note')
    line = '%-16s %-6s %-12s %6d %5.1f%% %6d %5d %5d %5d %5d %5d %6d %20s  %s' % (
        datetime.datetime.now().strftime('%Y-%m-%d %H:%M'), cpu, ','.join(version(s) for s in srcs),
        lut[0] + col('ALU'), 100.0 * (lut[0] + col('ALU')) / lut[1], lut[0], col('ALU'), col(COLS[1][1]), dff, col('RAM16SDP4'),
        col('BSRAM'), col(COLS[6][1]),
        '%.1f/%.1f/%.1f' % (min(fmax), statistics.median(fmax), max(fmax)), note)
    if not os.path.exists(results) or os.path.getsize(results) == 0:
        print(hdr)
    print(line)

def ecp5(cpu, note, synthlog, results, srcs, logs):
    used = {}
    for line in open(logs[0]):
        m = re.match(r'Info:\s+(\w+):\s+(\d+)/\s*(\d+)', line)
        if m:
            used[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    cells = {}
    if synthlog and os.path.exists(synthlog):
        t = open(synthlog).read()
        t = t[t.rfind('Printing statistics'):]
        for m in re.finditer(r'^\s+(\d+)\s+(LUT4|CCU2C|PFUMX|L6MUX21)\s*$', t, re.M):
            cells[m.group(2)] = int(m.group(1))
    fmax = [float(re.findall(r'Max frequency for clock .*?: ([\d.]+) MHz', open(l).read())[-1]) for l in logs]
    u = lambda n: used.get(n, (0, 1))[0]
    comb = used.get('TRELLIS_COMB', (0, 1))
    hdr = '%-16s %-6s %-12s %6s %6s %6s %5s %5s %5s %5s %5s %6s %6s %20s  %s' % (
        'date', 'cpu', 'version', 'LOGIC', 'LOGIC%', 'LUT4', 'CCU2C', 'PFUMX', 'L6MUX', 'FF', 'RAMW', 'DP16KD', 'MULT18',
        'Fmax MHz min/med/max', 'note')
    line = '%-16s %-6s %-12s %6d %5.1f%% %6d %5d %5d %5d %5d %5d %6d %6d %20s  %s' % (
        datetime.datetime.now().strftime('%Y-%m-%d %H:%M'), cpu, ','.join(version(s) for s in srcs),
        comb[0], 100.0 * comb[0] / comb[1], cells.get('LUT4', 0), cells.get('CCU2C', 0), cells.get('PFUMX', 0),
        cells.get('L6MUX21', 0), u('TRELLIS_FF'), u('TRELLIS_RAMW'), u('DP16KD'), u('MULT18X18D'),
        '%.1f/%.1f/%.1f' % (min(fmax), statistics.median(fmax), max(fmax)), note)
    if not os.path.exists(results) or os.path.getsize(results) == 0:
        print(hdr)
    print(line)

main()
