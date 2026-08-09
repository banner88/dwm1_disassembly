"""Extend the breeding-depth (plus) growth bonus to MP and INT.

THE ONE CODE CHANGE the randomizer makes. Everything else it does is data.

Background (traced S76, bank $13):

`label13_40ae` computes the six per-level stat gains into $C8CA-$C8CF. For each
stat it calls `FuncExp_411e` (raw curve lookup, indexed by the monster's current
level), and for HP and ATK ONLY it then calls `FuncExp_4163`, which applies the
plus-value bonus:

    FuncExp_4163: four gated rolls, SaveExp_41a5(b, c, d) with
                  (1,19,6) (10,20,8) (20,30,6) (50,100,5)
    each roll:    threshold = (RNG mod c) + b   -> uniform in [b, b+c-1]
                  if monster's plus (party +$62) >= threshold:
                      gain += max(1, raw_growth / d)
    skipped entirely below level 14, or at/over the level cap.

So deep breeding buys up to ~+40% HP and ATK, and NOTHING for MP, DEF, AGL or
INT. Since INT never enters any damage calculation in this engine -- it is
written to wBattleINT ten times and read zero times, purely a learn-gate -- a
caster's damage resource is its MP POOL. A +99 mage therefore gets no reward at
all for the breeding line that produced it.

This patch calls the SAME vanilla routine after the MP and INT lookups too, so
breeding depth grows the caster's MP pool (more casts of its best spell) and its
INT (reaching top-tier spells sooner). No damage formula, skill record or enemy
row changes.

Implementation is byte-neutral in the growth routine itself, which matters
because ExpCurveTables begins at $41E6 immediately behind it and the routine ends
at $411D with FuncExp_411e starting at $411E -- there is no slack to grow into.
`ld [nn],a` and `call nn` are both 3 bytes, so the two stores are swapped for
calls to trampolines placed in the bank's free tail:

    $40F3  ea cb c8   ld [$C8CB],a   ->  cd lo hi   call MpPlusTrampoline
    $411A  ea cf c8   ld [$C8CF],a   ->  cd lo hi   call IntPlusTrampoline

    trampoline:  cd 63 41   call FuncExp_4163
                 ea xx c8   ld [$C8Cx],a
                 c9         ret

Scratch safety: `FuncExp_4163` uses $C8CF as its accumulator. INT is computed
LAST and writes $C8CF last, so the MP call clobbering it is harmless -- and
`FuncExp_411e` already used $C8CF as scratch in vanilla.

Bank $13 is byte-identical in the English and German builds, so one set of
addresses serves both.
"""

from __future__ import annotations

BANK13 = 0x13
BANK_BASE = BANK13 * 0x4000
BANK_END = BANK_BASE + 0x4000

FUNC_EXP_4163 = 0x4163          # the plus-bonus routine
STORE_MP_ADDR = 0x40F3          # ld [$C8CB],a  after the MP curve lookup
STORE_INT_ADDR = 0x411A         # ld [$C8CF],a  after the INT curve lookup
VANILLA_MP_STORE = bytes.fromhex("eacbc8")
VANILLA_INT_STORE = bytes.fromhex("eacfc8")

# Guard bytes: the surrounding instructions must look exactly as traced, or this
# is not the ROM we think it is and nothing gets written.
GUARD = {
    0x40ED: bytes.fromhex("fa3ddacd1e41"),   # ld a,[$da3d] / call $411e   (MP)
    0x4114: bytes.fromhex("fa41dacd1e41"),   # ld a,[$da41] / call $411e   (INT)
    0x411D: bytes.fromhex("c9"),             # ret, immediately before FuncExp_411e
    0x4163: bytes.fromhex("eacfc8"),         # FuncExp_4163 head
}


class PlusGrowthError(RuntimeError):
    pass


def _flat(addr: int) -> int:
    return BANK_BASE + (addr - 0x4000)


def _find_free_tail(data: bytes, need: int) -> int:
    """Last run of $00/$FF filler in bank $13, big enough for the trampolines."""
    tail = BANK_END
    while tail > BANK_BASE and data[tail - 1] in (0x00, 0xFF):
        tail -= 1
    if BANK_END - tail < need + 8:
        raise PlusGrowthError(
            f"bank $13 free tail is {BANK_END - tail} bytes, need {need}")
    return tail


def _trampoline(store_target: int) -> bytes:
    return (bytes([0xCD]) + FUNC_EXP_4163.to_bytes(2, "little")
            + bytes([0xEA]) + store_target.to_bytes(2, "little")
            + bytes([0xC9]))


def apply(rom) -> dict:
    """Patch the ROM in place. Returns a stats dict; raises if anything is off."""
    data = rom.data

    for addr, expect in GUARD.items():
        got = bytes(data[_flat(addr):_flat(addr) + len(expect)])
        if got != expect:
            raise PlusGrowthError(
                f"bank $13 guard failed at ${addr:04X}: expected {expect.hex()}, "
                f"found {got.hex()}. Refusing to patch.")

    mp_site, int_site = _flat(STORE_MP_ADDR), _flat(STORE_INT_ADDR)
    if bytes(data[mp_site:mp_site + 3]) != VANILLA_MP_STORE:
        raise PlusGrowthError("MP store site does not hold the vanilla instruction")
    if bytes(data[int_site:int_site + 3]) != VANILLA_INT_STORE:
        raise PlusGrowthError("INT store site does not hold the vanilla instruction")

    mp_tramp = _trampoline(0xC8CB)
    int_tramp = _trampoline(0xC8CF)
    free = _find_free_tail(bytes(data), len(mp_tramp) + len(int_tramp))

    mp_at = free
    int_at = free + len(mp_tramp)
    data[mp_at:mp_at + len(mp_tramp)] = mp_tramp
    data[int_at:int_at + len(int_tramp)] = int_tramp

    def addr_of(flat: int) -> int:
        return 0x4000 + (flat - BANK_BASE)

    data[mp_site:mp_site + 3] = bytes([0xCD]) + addr_of(mp_at).to_bytes(2, "little")
    data[int_site:int_site + 3] = bytes([0xCD]) + addr_of(int_at).to_bytes(2, "little")

    return {"mp_trampoline": addr_of(mp_at), "int_trampoline": addr_of(int_at),
            "bytes_written": len(mp_tramp) + len(int_tramp),
            "free_tail_at": addr_of(free)}


def verify(rom) -> bool:
    """Re-read the patched ROM and confirm the call sites and trampolines."""
    data = bytes(rom.data)
    for site, target in ((STORE_MP_ADDR, 0xC8CB), (STORE_INT_ADDR, 0xC8CF)):
        o = _flat(site)
        if data[o] != 0xCD:
            return False
        dest = int.from_bytes(data[o + 1:o + 3], "little")
        t = _flat(dest)
        if data[t:t + 7] != _trampoline(target):
            return False
    return True
