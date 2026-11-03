#!/usr/bin/env python3
"""rom_rules.py — the enemy AI's rule chains RUN from the ROM's own bank $57 code (S163).

ROADMAP E17 note "the S81 rule model on 3-opponent boards": ai_rules.py is a hand model of
the 131 rules, built from a sweep with ONE opponent; on boards of two or three it was wrong
for many skills (simulator/validate_rules_boards.py). This module is the ORACLE: it runs the
state-7 walker AIState7ChainWalker_7865 with tools/sm83run.py over a captured WRAM / HRAM
image (simulator/sweep_rules.py --wram), far calls followed, and returns what the ROM would:
the per-rule (bonus, penalty) changes and the chain end. It needs a built ROM (any build
whose bank $57 has the S81 layout — the patched builds keep it) and the full board in RAM,
so it is a measuring instrument for the model, not the model itself (the Balance tab keeps
ai_rules.py: no ROM, many battles).

    from simulator.rom_rules import Oracle
    o = Oracle(rom_bytes, sym)            # sym: {name: (bank, addr)} of that build
    fired, end = o.chain(wram_bytes, hram_bytes)
    # fired = [(rule addr, d_bonus, d_penalty)], end = ('end', bonus, penalty) | ('vet', b, p)

Also: o.reads(...) -> the RAM addresses each rule READ (the inputs a model of it needs).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
from tools.sm83run import CPU                                     # noqa: E402

WALKER = 0x7865
CALL_RULE, AFTER_RULE = 0x7874, 0x7877         # `call AICallRuleAtHL_78ca` / the pop after it
CHAIN_END, VETO = 0x78A2, 0x788B


class Oracle:
    def __init__(self, rom, sym=None):
        self.rom = rom
        self.sym = sym or {}

    def _cpu(self, wram, hram):
        cpu = CPU(self.rom)
        cpu.bank = 0x57
        for i, v in enumerate(wram):
            if v:
                cpu.ram[0xC000 + i] = v
        for i, v in enumerate(hram or b''):
            if v:
                cpu.ram[0xFF80 + i] = v
        return cpu

    def chain(self, wram, hram=None, limit=200000, reads=False):
        """-> (fired, end[, reads]) for the chain the captured state is at (its $C1FA/$C1FB
        pointer, $DB8A skill, $DB88 actor …)."""
        cpu = self._cpu(wram, hram)
        fired, cur, end = [], {}, [None]
        rd = {}
        orig_rd = cpu.rd
        if reads:
            def rd_(addr, _o=orig_rd):
                if 0xC000 <= (addr & 0xFFFF) < 0xE000 and cur.get('rule') is not None:
                    rd.setdefault(cur['rule'], set()).add(addr & 0xFFFF)
                return _o(addr)
            cpu.rd = rd_

        def watch(c, pc):
            if c.bank != 0x57 and pc >= 0x4000:
                return False
            if pc == CALL_RULE:
                hl = c.hl
                cur['rule'] = c.ram.get(hl, 0) | c.ram.get(hl + 1, 0) << 8 if hl >= 0x8000 else \
                    c.rd(hl) | c.rd(hl + 1) << 8
                cur['pre'] = (c.ram.get(0xDD26, 0), c.ram.get(0xDD27, 0))
            elif pc == AFTER_RULE and 'pre' in cur:
                post = (c.ram.get(0xDD26, 0), c.ram.get(0xDD27, 0))
                if post != cur['pre']:
                    fired.append((cur['rule'], post[0] - cur['pre'][0], post[1] - cur['pre'][1]))
                cur.pop('pre')
                cur['rule'] = None
            elif pc == CHAIN_END and end[0] is None:
                end[0] = ('end', c.ram.get(0xDD26, 0), c.ram.get(0xDD27, 0))
            elif pc == VETO and end[0] is None:
                end[0] = ('vet', c.ram.get(0xDD26, 0), c.ram.get(0xDD27, 0))
            return False
        cpu.run(WALKER, limit=limit, follow_far=True, watch=watch)
        out = (fired, end[0])
        return out + (rd,) if reads else out
