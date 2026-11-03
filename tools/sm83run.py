#!/usr/bin/env python3
"""sm83run.py — a small, complete SM83 interpreter over a ROM image, with ID TAINT (S163).

For CENSUS work, not emulation: it runs a routine of a built ROM concretely from
any bank:address with chosen RAM contents and reports the path it took. Seeded RAM
bytes can be marked as THE ID (e.g. the acting skill id); the mark follows the value
while it still IS the id:
  * copies — registers, RAM, the stack;
  * the id plus / minus / masked by a constant (an index: `sub $DE`, `add LOW(table)`),
    `inc` / `dec`, a 16-bit `add hl, rr` with exactly one marked side (an address);
  * a byte read through a marked address by PATCHED code (`vanilla(at)` False): the
    patches' id -> id tables (a new skill -> its base) keep the mark.
It is dropped by real arithmetic (shifts, rotates, doubling, a product) and by the
ORIGINAL game's own table reads (record data, names: per-id tables the compiler fills).
An ID TEST is a conditional branch / `ret cc` / `call cc` whose flags were set by a
compare-like instruction (cp, sub, sbc, add / adc of a constant, and / or / xor of a
constant or itself, inc, dec) on a marked value; an ID JUMP is `jp hl` with a marked
HL. Result.tests = {((bank, pc), taken) | ((bank, pc), ('jp', bank, pc))}.
The game's timing, interrupts, the PPU and the sound chip are NOT modelled; I/O reads
return 0 except LY ($FF44), which counts up so wait loops end.

    from tools.sm83run import CPU
    cpu = CPU(rom_bytes, vanilla=lambda at: ...)
    cpu.bank = 0x53
    cpu.poke(0xDB8A, 0xEF, mark=True)
    res = cpu.run(0x4ED6, limit=400, follow_far=True)

Stops (Result.kind): 'ret' (a `ret` from the start frame; flags kept), 'far' (`rst
$10` when follow_far is False; Result.far = (bank, entry) — with follow_far=True the
game's own ROM0 RST_10 code runs: bank switch, entry table, switch back), 'limit'
(the step budget), 'halt' (halt / stop / an illegal opcode).
Banking: writes to $2000-$2FFF select the ROMX bank. `jp hl` is followed.
Used by tools/census_act_id_lists.py (S163, ROADMAP E17 note "Act-time id lists").
"""
from dataclasses import dataclass, field

REGS = ('b', 'c', 'd', 'e', 'h', 'l', None, 'a')
PAIRS = (('b', 'c'), ('d', 'e'), ('h', 'l'))


@dataclass
class Result:
    kind: str
    pc: int
    bank: int
    steps: int
    branches: frozenset = frozenset()
    tests: frozenset = frozenset()
    order: tuple = ()                # the ID TESTS in the order they first happened
    events: dict = field(default_factory=dict)   # every branch: at -> [outcomes, id test?, n]
    a: int = 0
    zf: bool = False
    cf: bool = False
    far: tuple = None
    writes: dict = field(default_factory=dict)


class CPU:
    def __init__(self, rom, vanilla=None):
        self.rom = rom
        self.vanilla = vanilla or (lambda at: True)
        self.reset()

    def reset(self):
        self.r = dict(a=0, b=0, c=0, d=0, e=0, h=0, l=0)
        self.m = dict(a=False, b=False, c=False, d=False, e=False, h=False, l=False)
        self.fm = False                              # the flags were set by an ID compare
        self.zf = self.nf = self.hf = self.cf = False
        self.sp = 0xDFF0
        self.bank = 1
        self.ram = {}
        self.mram = set()
        self.ly = 0
        self.writes = {}
        self.wlog = []                   # (at, addr, value) of writes to self.watch_writes
        self.watch_writes = getattr(self, 'watch_writes', set())
        self._at = (0, 0)

    def poke(self, addr, v, mark=False):
        self.ram[addr] = v & 0xFF
        if mark:
            self.mram.add(addr)
        else:
            self.mram.discard(addr)

    def __getattr__(self, k):                        # cpu.a, cpu.c … (read)
        if k in ('a', 'b', 'c', 'd', 'e', 'h', 'l'):
            return self.__dict__['r'][k]
        raise AttributeError(k)

    def __setattr__(self, k, v):                     # cpu.c = 6 (unmarked)
        if k in ('a', 'b', 'c', 'd', 'e', 'h', 'l'):
            self.__dict__['r'][k] = v & 0xFF
            self.__dict__['m'][k] = False
        else:
            object.__setattr__(self, k, v)

    def mark(self, reg, v):
        """Set register reg to v as THE ID."""
        self.r[reg], self.m[reg] = v & 0xFF, True

    # ---------------------------------------------------------------- memory
    def rd(self, addr):
        addr &= 0xFFFF
        if addr < 0x4000:
            return self.rom[addr]
        if addr < 0x8000:
            off = self.bank * 0x4000 + addr - 0x4000
            return self.rom[off] if off < len(self.rom) else 0xFF
        if addr == 0xFF44:
            self.ly = (self.ly + 1) % 154
            return self.ly
        return self.ram.get(addr, 0)

    def wr(self, addr, v, mark=False):
        addr &= 0xFFFF
        v &= 0xFF
        if 0x2000 <= addr < 0x4000:
            if addr < 0x3000:
                self.bank = v or 1
            return
        if addr < 0x8000:
            return
        self.ram[addr] = v
        self.writes[addr] = v
        if addr in self.watch_writes:
            self.wlog.append((self._at, addr, v))
        if mark:
            self.mram.add(addr)
        else:
            self.mram.discard(addr)

    def _ld_mem(self, addr, addr_mark):
        addr &= 0xFFFF
        v = self.rd(addr)
        if addr in self.mram:
            return v, True
        # a patch's id -> id table read through a marked address keeps the mark
        return v, bool(addr_mark and addr < 0x8000 and not self.vanilla(self._at))

    @property
    def hl(self):
        return self.r['h'] << 8 | self.r['l']

    def _pair(self, i):
        if i == 3:
            return self.sp, False
        h, l_ = PAIRS[i]
        return self.r[h] << 8 | self.r[l_], self.m[h] or self.m[l_]

    def _set_pair(self, i, v, mk):
        v &= 0xFFFF
        if i == 3:
            self.sp = v
            return
        h, l_ = PAIRS[i]
        self.r[h], self.r[l_] = v >> 8, v & 0xFF
        self.m[h] = self.m[l_] = mk

    def push(self, v, mh=False, ml=False):
        self.sp = (self.sp - 2) & 0xFFFF
        self.wr(self.sp, v & 0xFF, ml)
        self.wr(self.sp + 1, (v >> 8) & 0xFF, mh)

    def pop(self):
        lo, hi = self.sp, (self.sp + 1) & 0xFFFF
        v = self.ram.get(lo, 0) | self.ram.get(hi, 0) << 8
        ml, mh = lo in self.mram, hi in self.mram
        self.sp = (self.sp + 2) & 0xFFFF
        return v, mh, ml

    def _get8(self, i):
        if i == 6:
            hv, hm = self._pair(2)
            return self._ld_mem(hv, hm)
        k = REGS[i]
        return self.r[k], self.m[k]

    def _set8(self, i, v, mk):
        if i == 6:
            self.wr(self.hl, v, mk)
        else:
            k = REGS[i]
            self.r[k] = v & 0xFF
            self.m[k] = mk

    @property
    def f(self):
        return (self.zf << 7) | (self.nf << 6) | (self.hf << 5) | (self.cf << 4)

    def _set_f(self, v):
        self.zf, self.nf, self.hf, self.cf = bool(v & 0x80), bool(v & 0x40), \
            bool(v & 0x20), bool(v & 0x10)

    # ------------------------------------------------------------------ ALU
    def _alu(self, op, v, vm, self_op=False):
        """A op v. Marks: a compare-like op on a marked operand marks the flags; the result
        stays marked when exactly the id meets a constant (+, -, and, or, xor)."""
        a, am = self.r['a'], self.m['a']
        one = am != vm                               # exactly one side is the id
        if self_op:                                  # and a / or a: a zero test of A
            one = am
        if op == 0:
            r = a + v; self.hf = (a & 0xF) + (v & 0xF) > 0xF
            self.cf, self.nf, a = r > 0xFF, False, r & 0xFF
        elif op == 1:
            c = int(self.cf); r = a + v + c
            self.hf = (a & 0xF) + (v & 0xF) + c > 0xF
            self.cf, self.nf, a = r > 0xFF, False, r & 0xFF
        elif op in (2, 7):
            r = a - v; self.hf = (a & 0xF) < (v & 0xF)
            self.cf, self.nf = r < 0, True
            self.zf = (r & 0xFF) == 0
            self.fm = am or vm
            if op == 2:
                self.r['a'], self.m['a'] = r & 0xFF, one and am
            return
        elif op == 3:
            c = int(self.cf); r = a - v - c
            self.hf = (a & 0xF) < (v & 0xF) + c
            self.cf, self.nf, a = r < 0, True, r & 0xFF
            self.zf = a == 0
            self.fm = am or vm
            self.r['a'], self.m['a'] = a, one and am
            return
        elif op == 4:
            a = a & v; self.nf, self.hf, self.cf = False, True, False
        elif op == 5:
            a = a ^ v; self.nf = self.hf = self.cf = False
        else:
            a = a | v; self.nf = self.hf = self.cf = False
        self.zf = a == 0
        self.fm = one
        self.r['a'], self.m['a'] = a, one

    def _cb(self, op):
        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        v, vm = self._get8(z)
        if x == 0:
            if y == 0: c = v >> 7; v = (v << 1 | c) & 0xFF
            elif y == 1: c = v & 1; v = (v >> 1) | (c << 7)
            elif y == 2: c = v >> 7; v = (v << 1 | int(self.cf)) & 0xFF
            elif y == 3: c = v & 1; v = (v >> 1) | (int(self.cf) << 7)
            elif y == 4: c = v >> 7; v = (v << 1) & 0xFF
            elif y == 5: c = v & 1; v = (v >> 1) | (v & 0x80)
            elif y == 6: c = 0; v = ((v << 4) | (v >> 4)) & 0xFF
            else: c = v & 1; v >>= 1
            self.cf, self.zf, self.nf, self.hf = bool(c), v == 0, False, False
            self.fm = False
            self._set8(z, v, False)
        elif x == 1:
            self.zf, self.nf, self.hf = not (v >> y) & 1, False, True
            self.fm = False
        elif x == 2:
            self._set8(z, v & ~(1 << y), vm)
        else:
            self._set8(z, v | (1 << y), vm)

    def _cc(self, i):
        return (not self.zf, self.zf, not self.cf, self.cf)[i]

    # ------------------------------------------------------------------- run
    def run(self, pc, limit=400, follow_far=False, watch=None):
        """Run from pc (self.bank / ROM0) until a stop. watch(cpu, pc) is called before
        every instruction (True stops with kind 'watch')."""
        branches, tests = set(), set()
        self._order = []
        self._ev = {}
        depth = 0
        R, M = self.r, self.m
        for step in range(limit):
            if watch and watch(self, pc):
                return self._res('watch', pc, step, branches, tests)
            op = self.rd(pc)
            n = self.rd(pc + 1)
            nn = n | self.rd(pc + 2) << 8
            e = n - 256 if n > 127 else n
            at = (self.bank if pc >= 0x4000 else 0, pc)
            self._at = at
            pc = (pc + 1) & 0xFFFF
            x, y, z = op >> 6, (op >> 3) & 7, op & 7
            p, q = y >> 1, y & 1

            def cond(t):
                ev = self._ev.get(at)
                if ev is None:
                    ev = self._ev[at] = [set(), False, len(self._ev)]
                ev[0].add(t)
                ev[1] = ev[1] or self.fm
                branches.add((at, t))
                if self.fm and (at, t) not in tests:
                    tests.add((at, t))
                    self._order.append((at, t))
            if op == 0x00:
                pass
            elif op == 0x76 or op == 0x10:
                return self._res('halt', at[1], step, branches, tests)
            elif x == 1:
                v, vm = self._get8(z)
                self._set8(y, v, vm)
            elif x == 2:
                if op == 0xAF:                       # xor a: a constant 0
                    R['a'] = 0; M['a'] = False; self.fm = False
                    self.zf, self.nf, self.hf, self.cf = True, False, False, False
                else:
                    v, vm = self._get8(z)
                    self._alu(y, v, vm, self_op=(z == 7 and y in (4, 6)))
            elif op == 0xCB:
                self._cb(n); pc += 1
            elif x == 0:
                if z == 0:
                    if y == 1:
                        self.wr(nn, self.sp & 0xFF); self.wr(nn + 1, self.sp >> 8); pc += 2
                    elif y == 3:
                        pc = (pc + 1 + e) & 0xFFFF
                    elif y >= 4:
                        t = self._cc(y - 4)
                        cond(t)
                        pc = (pc + 1 + (e if t else 0)) & 0xFFFF
                elif z == 1:
                    if q == 0:
                        self._set_pair(p, nn, False); pc += 2
                    else:
                        hv, hm = self._pair(2)
                        v, vm = self._pair(p)
                        r = hv + v
                        self.hf = (hv & 0xFFF) + (v & 0xFFF) > 0xFFF
                        self.cf, self.nf = r > 0xFFFF, False
                        self.fm = False
                        self._set_pair(2, r, (hm != vm) and p != 2)
                elif z == 2:
                    adr, adm = self._pair((0, 1, 2, 2)[p])
                    if q == 0:
                        self.wr(adr, R['a'], M['a'])
                    else:
                        R['a'], M['a'] = self._ld_mem(adr, adm)
                    if p == 2: self._set_pair(2, adr + 1, adm)
                    if p == 3: self._set_pair(2, adr - 1, adm)
                elif z == 3:
                    v, vm = self._pair(p)
                    self._set_pair(p, v + (1 if q == 0 else -1), vm)
                elif z in (4, 5):
                    v, vm = self._get8(y); r = (v + (1 if z == 4 else -1)) & 0xFF
                    self.hf = (v & 0xF) == (0xF if z == 4 else 0)
                    self.zf, self.nf = r == 0, z == 5
                    self.fm = vm
                    self._set8(y, r, vm)
                elif z == 6:
                    self._set8(y, n, False); pc += 1
                else:
                    a = R['a']
                    if y < 4:
                        cin = int(self.cf)
                        if y == 0: c = a >> 7; a = (a << 1 | c) & 0xFF
                        elif y == 1: c = a & 1; a = (a >> 1) | (c << 7)
                        elif y == 2: c = a >> 7; a = (a << 1 | cin) & 0xFF
                        else: c = a & 1; a = (a >> 1) | (cin << 7)
                        self.cf = bool(c); self.zf = self.nf = self.hf = False
                        M['a'] = False
                    elif y == 4:
                        if not self.nf:
                            if self.cf or a > 0x99: a += 0x60; self.cf = True
                            if self.hf or (a & 0xF) > 9: a += 6
                        else:
                            if self.cf: a -= 0x60
                            if self.hf: a -= 6
                        a &= 0xFF; self.zf = a == 0; self.hf = False; M['a'] = False
                    elif y == 5: a ^= 0xFF; self.nf = self.hf = True; M['a'] = False
                    elif y == 6: self.cf = True; self.nf = self.hf = False
                    else: self.cf = not self.cf; self.nf = self.hf = False
                    R['a'] = a
                    self.fm = False
            else:                                    # x == 3
                if op in (0xC0, 0xC8, 0xD0, 0xD8, 0xC9, 0xD9):
                    t = op in (0xC9, 0xD9) or self._cc(y)
                    if op not in (0xC9, 0xD9):
                        cond(t)
                    if t:
                        if depth == 0:
                            return self._res('ret', at[1], step, branches, tests)
                        depth -= 1
                        pc = self.pop()[0]
                elif op == 0xE0: self.wr(0xFF00 | n, R['a'], M['a']); pc += 1
                elif op == 0xF0: R['a'], M['a'] = self._ld_mem(0xFF00 | n, False); pc += 1
                elif op == 0xE8 or op == 0xF8:
                    r = self.sp + e
                    self.hf = (self.sp & 0xF) + (n & 0xF) > 0xF
                    self.cf = (self.sp & 0xFF) + n > 0xFF; self.zf = self.nf = False
                    self.fm = False
                    if op == 0xE8: self.sp = r & 0xFFFF
                    else: self._set_pair(2, r, False)
                    pc += 1
                elif z == 1:
                    if q == 0:
                        v, mh, ml = self.pop()
                        if p < 3:
                            h, l_ = PAIRS[p]
                            R[h], R[l_], M[h], M[l_] = v >> 8, v & 0xFF, mh, ml
                        else:
                            R['a'], M['a'] = v >> 8, mh
                            self._set_f(v & 0xF0); self.fm = False
                    elif p == 2:                     # jp hl (followed)
                        hv, hm = self._pair(2)
                        tgt = ('jp', self.bank if hv >= 0x4000 else 0, hv)
                        branches.add((at, tgt))
                        ev = self._ev.get(at)
                        if ev is None:
                            ev = self._ev[at] = [set(), False, len(self._ev)]
                        ev[0].add(tgt)
                        ev[1] = ev[1] or hm
                        if hm and (at, tgt) not in tests:
                            tests.add((at, tgt))
                            self._order.append((at, tgt))
                        pc = hv
                    elif p == 3:
                        self.sp = self.hl
                elif op == 0xC3:
                    pc = nn
                elif z == 2 and y < 4:
                    t = self._cc(y)
                    cond(t)
                    pc = nn if t else pc + 2
                elif op == 0xE2: self.wr(0xFF00 | R['c'], R['a'], M['a'])
                elif op == 0xF2: R['a'], M['a'] = self._ld_mem(0xFF00 | R['c'], False)
                elif op == 0xEA: self.wr(nn, R['a'], M['a']); pc += 2
                elif op == 0xFA: R['a'], M['a'] = self._ld_mem(nn, False); pc += 2
                elif op in (0xF3, 0xFB):
                    pass
                elif op == 0xCD or (z == 4 and y < 4):
                    t = op == 0xCD or self._cc(y)
                    if op != 0xCD:
                        cond(t)
                    if t:
                        self.push(pc + 2); depth += 1; pc = nn
                    else:
                        pc += 2
                elif z == 5 and q == 0:
                    if p < 3:
                        h, l_ = PAIRS[p]
                        self.push(R[h] << 8 | R[l_], M[h], M[l_])
                    else:
                        self.push(R['a'] << 8 | self.f, M['a'], False)
                elif z == 6:
                    self._alu(y, n, False); pc += 1
                elif z == 7:
                    tgt = y * 8
                    if tgt == 0x10 and not follow_far:
                        res = self._res('far', at[1], step, branches, tests)
                        res.far = (R['h'], R['l'])
                        return res
                    self.push(pc); depth += 1; pc = tgt
                else:
                    return self._res('halt', at[1], step, branches, tests)
        return self._res('limit', pc, limit, branches, tests)

    def _res(self, kind, pc, steps, branches, tests):
        return Result(kind, pc, self.bank, steps, frozenset(branches), frozenset(tests),
                      tuple(self._order), self._ev, self.r['a'], self.zf, self.cf, None,
                      dict(self.writes))
