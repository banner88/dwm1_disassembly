"""savefile.py — the player's monsters from a battery save (.sav) (ROADMAP
P3.15a, S130; ARCHITECTURE "SRAM Save Layout", MONSTER_DATA "Party Monster
Structure" + "Raising a monster (S130)").

A .sav is the raw cartridge SRAM. SaveGameState copies WRAM $C8EA.. to SRAM
$A024.., so a WRAM address maps to SRAM offset (addr - $C8EA + $24):
  party count $CA8D -> $01C7, party list $CA8E-$CA90 -> $01C8-$01CA,
  roster slot s (149 B records from $CAC1) -> $01FB + s*$95 for s 0-19 —
  in patched builds (CF3, S60) slots 3-19 live ONLY there, and FX1 (S71)
  puts slots 20-39 at SRAM $B124 -> offset $3124 + (s-20)*$95.
Verified S130 against the game's own WRAM after CONTINUE (PyBoy, the user's
save on the my-dwm-hack_22 build): the party list and every field read here
equal the live records.

Never imports Qt.
"""
from __future__ import annotations

import os
import sys

_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if _REPO not in sys.path:
    sys.path.insert(0, _REPO)

from simulator import raising as R            # noqa: E402

REC = 0x95
PARTY_COUNT_OFF = 0x01C7
PARTY_LIST_OFF = 0x01C8
SLOT0_OFF = 0x01FB
FX1_OFF = 0x3124          # SRAM $B124: slots 20-39 (patched builds, S71)


def _w(r, o):
    return r[o] | r[o + 1] << 8


def record_offset(slot):
    if slot < 20:
        return SLOT0_OFF + slot * REC
    return FX1_OFF + (slot - 20) * REC


def monster_from_record(r, names=None, slot=None):
    """A 149-byte roster record -> simulator.raising.Monster."""
    from . import monster_text as MT
    sp = r[9]
    m = R.Monster(
        species=sp, level=r[0x4B], cap=r[0x4C],
        exp=r[0x4D] | r[0x4E] << 8 | r[0x4F] << 16,
        stats=[_w(r, 0x52), _w(r, 0x56), _w(r, 0x58), _w(r, 0x5A), _w(r, 0x5C), _w(r, 0x5E)],
        skills=[s for s in r[0x29:0x31] if s != 0xFF],
        queue=[s for s in r[0x31:0x4A] if s != 0xFF],
        res=list(r[0x68:0x83]), ai=list(r[0x64:0x68]),
        plus=r[0x62], wld=r[0x60], female=r[0x0B] & 1,
        origin=f'save slot {slot}' if slot is not None else 'save',
        name=(names or {}).get(sp, f'#{sp}'),
        bred=int(r[0x15] != 0xFF and r[0x15] != 0))
    try:
        m.nickname = MT.decode(bytes(r[1:9]))
    except Exception:                                   # noqa: BLE001
        m.nickname = ''
    return m


def read_roster(data, names=None, slots=40):
    """-> {'party': [slot ...], 'monsters': {slot: Monster}} for every used
    roster slot (flag +0: 1 farm, 2 party); eggs (+$63) are skipped."""
    if isinstance(data, (str, os.PathLike)):
        data = open(data, 'rb').read()
    if len(data) < 0x2000:
        raise ValueError('not a DWM save (too small)')
    out = {}
    for s in range(slots):
        o = record_offset(s)
        if o + REC > len(data):
            break
        r = data[o:o + REC]
        if r[0] not in (1, 2) or r[0x63]:
            continue
        if r[9] > 0xEF or r[0x4B] == 0 or r[0x4B] > 99:
            continue
        out[s] = monster_from_record(r, names, s)
    n = data[PARTY_COUNT_OFF]
    party = [x for x in data[PARTY_LIST_OFF:PARTY_LIST_OFF + 3] if x != 0xFF and x in out][:max(n, 0)]
    return {'party': party, 'monsters': out}


def party_team(data, names=None):
    """The save's party as a team ([Monster] in party order)."""
    ro = read_roster(data, names)
    return [ro['monsters'][s] for s in ro['party']]
