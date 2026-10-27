/*
 * opc7emu.c - C translation of opc7emu.py, the OPC7 instruction set emulator
 *
 * Usage: opc7emu [-q] <hexfile> [<dumpfile> [<stdinfile>]]
 *
 *   <dumpfile> '-' means no memory dump (useful when a stdinfile follows)
 *
 *   -q   quiet: no per-instruction trace (memory and I/O accesses are still
 *        printed), as in opc7emu.py
 *
 * The output (trace, memory and I/O access lines, halt message) and the memory
 * dump are byte-for-byte the same as opc7emu.py's, including its quirks:
 *   - flags are only updated when an instruction executes, and are restored
 *     from their saved values when the destination is the PC or the opcode is
 *     sto, lsto, in, putpsr or rti
 *   - cmp computes V against r0 (dest is switched to r0 before V is computed)
 *   - in consumes an input character even if its predicate fails or an
 *     interrupt is taken
 *   - the stdin file is read as text: UTF-8 decoded, with \r\n and \r as \n
 * Registers are held in 64 bits and masked exactly where the Python masks, as
 * Python integers are unbounded.
 *
 * Build: gcc -O2 -o opc7emu opc7emu.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

enum { MOV, MOVT, XOR, AND, OR, NOT, CMP, SUB, ADD, BPERM, ROR, LSR, JSR, ASR,
       ROL, S0F, HALT, RTI, PUTPSR, GETPSR, S14, S15, SCMP, S17, OUT, IN, STO,
       LD, LJSR, LMOV, LSTO, LLD };

static const char *mnemonics[32] = {
    "mov", "movt", "xor", "and", "or", "not", "cmp", "sub", "add", "bperm",
    "ror", "lsr", "jsr", "asr", "rol", "s0F", "halt", "rti", "putpsr",
    "getpsr", "s13", "s15", "s16", "s17", "out", "in", "sto", "ld", "ljsr",
    "lmov", "lsto", "lld" };
static const char *pred_str[8] = { "", "0.", "z.", "nz.", "c.", "nc.", "mi.", "pl." };

#define PCREG 15
#define MEMSIZE 0x100000

static uint64_t *wordmem;
static size_t memwords;            /* words in memory (for the dump) */
static uint64_t iomem[65536];

/* ---- fast output ------------------------------------------------------- */

static char outbuf[1 << 20];
static size_t outpos;

static void flush_out(void) {
    fwrite(outbuf, 1, outpos, stdout);
    outpos = 0;
}
static inline void need(size_t n) {
    if (outpos + n > sizeof outbuf) flush_out();
}
static inline void put_str(const char *s) {
    size_t n = strlen(s);
    need(n);
    memcpy(outbuf + outpos, s, n);
    outpos += n;
}
static inline void put_ch(char ch) {
    need(1);
    outbuf[outpos++] = ch;
}
/* hex with at least 'width' digits, like %0<width>x / %0<width>X */
static inline void put_hex(uint64_t v, int width, int upper) {
    const char *digits = upper ? "0123456789ABCDEF" : "0123456789abcdef";
    char tmp[17];
    int n = 0;
    do { tmp[n++] = digits[v & 0xF]; v >>= 4; } while (v);
    while (n < width) tmp[n++] = '0';
    need(n);
    while (n) outbuf[outpos++] = tmp[--n];
}
/* unsigned decimal right-aligned in 'width' characters, like %<width>d */
static inline void put_dec(uint64_t v, int width) {
    char tmp[21];
    int n = 0;
    do { tmp[n++] = (char)('0' + v % 10); v /= 10; } while (v);
    need((size_t)(n < width ? width : n));
    for (int i = n; i < width; i++) outbuf[outpos++] = ' ';
    while (n) outbuf[outpos++] = tmp[--n];
}

/* print_memory_access(type, address, data) */
static void print_memory_access(const char *type, uint64_t address, uint64_t data) {
    int io = (strcmp(type, "IN") == 0 || strcmp(type, "OUT") == 0);
    uint64_t a = address & (io ? 0xFFFF : 0xFFFFF);
    size_t tl = strlen(type);
    need(8);
    for (size_t i = tl; i < 6; i++) outbuf[outpos++] = ' ';     /* %6s */
    put_str(type);
    put_str(" :  Address : 0x");
    put_hex(a, 8, 0);
    put_str(" (");
    put_dec(a, 6);
    put_str(")       :        Data : 0x");
    put_hex(data, 8, 0);
    put_str(" (");
    put_dec(data, 10);
    put_str(") ");
    put_ch((data > 0x1F && data < 0x7F) ? (char)data : ' ');
    put_ch('\n');
}

/* ---- input text ---------------------------------------------------------- */

static uint32_t *input_text;       /* code points */
static size_t input_len, input_pos;

static void read_input(const char *fname) {
    FILE *f = fopen(fname, "rb");
    if (!f) { perror(fname); exit(1); }
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    unsigned char *b = malloc((size_t)size + 1);
    size_t n = fread(b, 1, (size_t)size, f);
    fclose(f);
    input_text = malloc((n + 1) * sizeof *input_text);
    input_len = 0;
    for (size_t i = 0; i < n; ) {
        uint32_t cp = b[i];
        int extra = cp >= 0xF0 ? 3 : cp >= 0xE0 ? 2 : cp >= 0xC0 ? 1 : 0;
        if (extra && i + extra < n + 0) {
            cp &= (0x3F >> extra);
            for (int k = 1; k <= extra; k++) cp = (cp << 6) | (b[i + k] & 0x3F);
        }
        i += 1 + extra;
        if (cp == '\r') {                       /* universal newlines */
            if (i < n && b[i] == '\n') i++;
            cp = '\n';
        }
        input_text[input_len++] = cp;
    }
    free(b);
}

/* ---- main ---------------------------------------------------------------- */

int main(int argc, char **argv) {
    int trace = 1;
    char *args[4];
    int nargs = 0;
    for (int i = 0; i < argc; i++) {
        if (strcmp(argv[i], "-q") == 0) trace = 0;
        else if (nargs < 4) args[nargs++] = argv[i];
    }
    if (nargs < 2) {
        fprintf(stderr, "usage: %s [-q] hexfile [dumpfile [stdinfile]]\n", argv[0]);
        return 2;
    }

    if (nargs > 3) {
        read_input(args[3]);
    } else {                                    /* 100000 chr(0)s: all give 0 */
        input_text = NULL;
        input_len = 0;
    }

    /* load the hex file ($readmemh format): whitespace separated hex words,
       '@addr' sets the load address */
    FILE *f = fopen(args[1], "r");
    if (!f) { perror(args[1]); return 1; }
    wordmem = calloc(MEMSIZE, sizeof *wordmem);
    memwords = MEMSIZE;
    size_t adr = 0;
    char tok[64];
    while (fscanf(f, "%63s", tok) == 1) {
        if (tok[0] == '@') adr = strtoull(tok + 1, NULL, 16);
        else {
            if (adr >= MEMSIZE) { fprintf(stderr, "%s: address 0x%zx out of range\n", args[1], adr); return 1; }
            wordmem[adr++] = strtoull(tok, NULL, 16) & 0xFFFFFFFF;
        }
    }
    fclose(f);

    uint64_t regfile[16] = {0};
    int v = 0, c = 0, z = 0, s = 0, ei = 0, swiid = 0, interrupt = 0;
    uint64_t pc_int = 0;
    int psr_int[6] = {0};
    static char outbuffer[1 << 16];
    setvbuf(stdout, outbuffer, _IOFBF, sizeof outbuffer);

    if (trace) {
        put_str("PC     : Mem      : Instruction            : V SWI I S C Z : ");
        for (int d = 0; d < 16; d++) {
            char hdr[16];
            snprintf(hdr, sizeof hdr, "  r%2d    ", d);
            put_str(hdr);
        }
        put_ch('\n');
        for (int i = 0; i < 202; i++) put_ch('-');
        put_ch('\n');
    }

    for (;;) {
        uint64_t pc_save = regfile[PCREG];
        int flag_save[6] = { v, swiid, ei, s, c, z };
        regfile[0] = 0;
        uint64_t instr_word = wordmem[regfile[PCREG] & 0xFFFFF] & 0xFFFFFFFF;
        int p0 = (instr_word >> 31) & 1, p1 = (instr_word >> 30) & 1, p2 = (instr_word >> 29) & 1;
        int opcode = (instr_word >> 24) & 0x1F;
        int dest = (instr_word >> 20) & 0xF;
        int source = (instr_word >> 16) & 0xF;
        uint64_t operand;
        if (opcode >= 0x1C) {                   /* ljsr lmov lsto lld: 20 bit operand */
            operand = instr_word & 0xFFFFF;
            source = 0;
            if (operand & 0x80000) operand |= 0xFFF00000;
        } else {
            operand = instr_word & 0xFFFF;
            if (operand & 0x8000) operand |= 0xFFFF0000;
        }

        char instr_str[64];
        if (trace) {
            snprintf(instr_str, sizeof instr_str, "%s%s r%d,r%d,0x%05llX",
                     (p0 | p1 | !p2) ? pred_str[p0 << 2 | p1 << 1 | p2] : "",
                     mnemonics[opcode], dest, source,
                     (unsigned long long)(operand & 0xFFFFF));
            if (opcode == PUTPSR || opcode == GETPSR) {   /* first "r0" -> "psr" */
                char *r0 = strstr(instr_str, "r0");
                if (r0) {
                    char rest[64];
                    snprintf(rest, sizeof rest, "%s", r0 + 2);
                    snprintf(r0, sizeof instr_str - (size_t)(r0 - instr_str), "psr%s", rest);
                }
            }
        }

        regfile[PCREG] += 1;
        uint64_t eff_addr, ea_ed;
        if (opcode == BPERM) {
            ea_ed = eff_addr = regfile[source];
        } else {
            eff_addr = (regfile[source] + operand) & 0xFFFFFFFF;
            if (opcode == LD || opcode == LLD) ea_ed = wordmem[eff_addr & 0xFFFFF];
            else if (opcode == IN)              ea_ed = iomem[eff_addr & 0xFFFF];
            else                                ea_ed = eff_addr;
        }

        if (opcode == IN)
            ea_ed = (input_pos < input_len) ? input_text[input_pos++] : 0;

        if (interrupt) {                        /* software interrupts ignore EI */
            interrupt = 0;
            regfile[PCREG] = 0x00000002;
            pc_int = pc_save;
            psr_int[0] = v; psr_int[1] = swiid; psr_int[2] = ei;
            psr_int[3] = s; psr_int[4] = c; psr_int[5] = z;
            ei = 0;
            continue;
        }

        if (trace) {
            put_hex(pc_save, 8, 0);
            put_str(" : ");
            put_hex(instr_word, 8, 1);
            put_str(" : ");
            {   /* %-22s */
                size_t n = strlen(instr_str);
                put_str(instr_str);
                need(22);
                for (size_t i = n; i < 22; i++) outbuf[outpos++] = ' ';
            }
            put_str(" : ");
            put_dec((uint64_t)v, 1);
            put_str("  ");
            put_hex((uint64_t)swiid, 1, 1);
            put_str("  ");
            put_dec((uint64_t)ei, 1); put_ch(' ');
            put_dec((uint64_t)s, 1);  put_ch(' ');
            put_dec((uint64_t)c, 1);  put_ch(' ');
            put_dec((uint64_t)z, 1);
            put_str(" : ");
            for (int r = 0; r < 16; r++) {
                if (r) put_ch(' ');
                put_hex(regfile[r], 8, 1);
            }
            put_ch('\n');
        }

        int cond = p1 ? (p0 ? s : z) : (p0 ? c : 1);
        if (!(p2 ^ (cond != 0))) continue;      /* predicate false */

        switch (opcode) {
        case HALT:
            put_str("Stopped on halt instruction at ");
            put_hex(regfile[PCREG], 8, 0);
            put_str(" with halt number 0x");
            put_hex(operand, 4, 0);
            put_ch('\n');
            goto done;
        case RTI:
            regfile[PCREG] = pc_int;
            flag_save[0] = psr_int[0]; flag_save[1] = 0; flag_save[2] = psr_int[2];
            flag_save[3] = psr_int[3]; flag_save[4] = psr_int[4]; flag_save[5] = psr_int[5];
            break;
        case AND: regfile[dest] = (regfile[dest] & ea_ed) & 0xFFFFFFFF; break;
        case OR:  regfile[dest] = (regfile[dest] | ea_ed) & 0xFFFFFFFF; break;
        case XOR: regfile[dest] = (regfile[dest] ^ ea_ed) & 0xFFFFFFFF; break;
        case ROR: case ASR: case LSR: {
            uint64_t top = opcode == ROR ? ((uint64_t)c << 31)
                         : opcode == ASR ? (ea_ed & 0x80000000) : 0;
            c = ea_ed & 1;
            regfile[dest] = top | ((ea_ed & 0xFFFFFFFF) >> 1);
            break;
        }
        case ROL: {
            int oldc = c;
            c = (ea_ed >> 31) & 1;
            regfile[dest] = ((ea_ed << 1) & 0xFFFFFFFE) | (uint64_t)oldc;
            break;
        }
        case ADD: {
            uint64_t rd = regfile[dest];
            uint64_t res = (rd + ea_ed) & 0x1FFFFFFFFULL;
            v = ((((~res) & ea_ed & rd) | (res & (~ea_ed) & (~rd))) & 0x80000000) != 0;
            c = (res >> 32) & 1;
            regfile[dest] = res & 0xFFFFFFFF;
            break;
        }
        case NOT:  regfile[dest] = (~ea_ed) & 0xFFFFFFFF; break;
        case MOVT: regfile[dest] = ((ea_ed << 16) & 0xFFFF0000) | (regfile[dest] & 0x0FFFF); break;
        case MOV: case LMOV: case LD: case IN: case LLD:
            regfile[dest] = ea_ed & 0xFFFFFFFF;
            if (opcode == LD || opcode == IN || opcode == LLD)
                print_memory_access(opcode == IN ? "IN" : "LOAD", eff_addr, ea_ed);
            break;
        case SUB: case CMP: case SCMP: {
            uint64_t nea = (~ea_ed)&0xFFFFFFFF;                   /* invert, add with carry in, as the hardware */
            uint64_t res = (regfile[dest] + nea+ 1) & 0x1FFFFFFFFULL;
            uint64_t rd = regfile[dest];
            v = ((((~res) & nea & rd) | (res & (~nea) & (~rd))) & 0x80000000) != 0;
            c = (res >> 32) & 1;
            if (opcode == CMP || opcode == SCMP) dest = 0;        /* change dest to r0 before writing back */
            regfile[dest] = res & 0xFFFFFFFF;
            break;
        }
        case JSR: case LJSR:
            regfile[dest] = regfile[PCREG];
            regfile[PCREG] = ea_ed;
            break;
        case BPERM: {
            uint64_t r = 0;
            for (int i = 0; i < 4; i++) {
                int n = (int)((operand >> (4 * i)) & 0xF);
                uint64_t byte = n < 8 ? (ea_ed >> (n * 8)) & 0xFF : 0;   /* Python: big shifts give 0 */
                r |= byte << (8 * i);
            }
            regfile[dest] = r;
            break;
        }
        case PUTPSR:
            flag_save[0] = (int)((ea_ed & 0x80000000) >> 31);
            flag_save[1] = (int)((ea_ed & 0xF0) >> 4);
            flag_save[2] = (int)((ea_ed & 0x8) >> 3);
            flag_save[3] = (int)((ea_ed & 0x4) >> 2);
            flag_save[4] = (int)((ea_ed & 0x2) >> 1);
            flag_save[5] = (int)(ea_ed & 1);
            interrupt = (ea_ed & 0xF0) != 0;
            break;
        case GETPSR:
            regfile[dest] = (((uint64_t)v << 31) & 0x80000000) | ((uint64_t)(swiid & 0xF) << 4)
                          | ((uint64_t)ei << 3) | ((uint64_t)s << 2) | ((uint64_t)c << 1) | (uint64_t)z;
            break;
        case STO: case LSTO:
            wordmem[ea_ed & 0xFFFFF] = regfile[dest];
            print_memory_access("STORE", ea_ed, regfile[dest]);
            break;
        case OUT:
            iomem[ea_ed & 0xFFFF] = regfile[dest];
            print_memory_access("OUT", ea_ed, regfile[dest]);
            break;
        default:                                /* s0F s14 s15 s17: no operation */
            break;
        }

        if (dest == PCREG || opcode == STO || opcode == IN || opcode == LSTO
            || opcode == PUTPSR || opcode == RTI) {
            v = flag_save[0]; swiid = flag_save[1]; ei = flag_save[2];
            s = flag_save[3]; c = flag_save[4]; z = flag_save[5];
        } else {
            s = (regfile[dest] >> 31) ^ ((opcode==SCMP)?v:0);
            z = regfile[dest] == 0;
        }
    }
done:
    flush_out();
    fflush(stdout);

    if (nargs > 2 && strcmp(args[2], "-") != 0) {   /* dump memory for inspection */
        FILE *d = fopen(args[2], "w");
        if (!d) { perror(args[2]); return 1; }
        for (size_t j = 0; j < memwords; j += 12) {
            if (j) fputc('\n', d);
            for (size_t i = j; i < j + 12 && i < memwords; i++)
                fprintf(d, "%08llx ", (unsigned long long)wordmem[i]);
        }
        fclose(d);
    }
    return 0;
}
