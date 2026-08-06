"""ROM layout + typed table access for the DWM1 randomizer.

Every address here was verified against ROM bytes (not docs) in S76.
Region handling: all tables except the two in bank $14 sit at IDENTICAL flat
offsets in the US/EU-English and German builds.  Bank $14's EnemyStatsTable and
BossRedirectTable are shifted +$70 in the German ROM (German text expanded the
code region ahead of them); their CONTENTS are byte-identical.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field

BANK = 0x4000
ROM_SIZE = 2 * 1024 * 1024

MD5_ENGLISH = "1ca6579359f21d8e27b446f865bf6b83"
MD5_GERMAN = "08bca718c62e3c2870a2df107fc0a562"

# --- Fixed tables (identical flat offset in both ROMs; verified S76) ---------
# name                 flat      count  stride   source address
MONSTER_INFO = (0x0C461, 221, 43)  # $03:$4461
ENCOUNTER_POOLS = (0x06AAE, 128, 26)  # $01:$6AAE
SPECIAL_RECIPES = (0x58B30, 825, 5)  # $16:$4B30
FAMILY_RECIPES = (0x58974, 222, 2)  # $16:$4974
EXP_CURVES = (0x4C1E6, 32, 99 * 3)  # $13:$41E6
GROWTH_CURVES = (0x4E706, 32, 99)  # $13:$6706
SKILL_LEARN = (0x190E0, 222, 18)  # $06:$50E0
SKILL_MP = (0x1D70C, 222, 2)  # $07:$570C
SKILL_RECORDS = (0x1501CF, 222, 19)  # $54:$41CF (indexed via $54:$4013)

# --- Bank $14 tables: region-dependent --------------------------------------
BANK14_START = 0x14 * BANK
BANK14_END = BANK14_START + BANK
ENEMY_STATS_COUNT, ENEMY_STATS_STRIDE = 487, 25
BOSS_REDIRECT_COUNT, BOSS_REDIRECT_STRIDE = 34, 4

# EID 0 is an all-zero row whose skill field is $FF*4, immediately followed by
# EID 1 (the starter).  We anchor on EID 0 plus the invariant head of EID 1
# (level 1, HP 30) -- but NOT on EID 1's species byte, which the randomizer
# rewrites, so the locator still works on an already-randomized ROM.
_ENEMY_SIG_PRE = bytes(21) + b"\xff\xff\xff\xff"  # EID 0, 25 bytes
_ENEMY_SIG_POST_OFF = 25 + 1  # skip EID 1's species byte
_ENEMY_SIG_POST = bytes.fromhex("000000011e0000000a0006000500010064c864c8")

# BossRedirectTable head: fight/join pairs 4->486, 11->12, 31->484, 32->485
_BOSS_SIG = bytes.fromhex("0400e6010b000c001f00e4012000e501")

_KNOWN = {
    MD5_ENGLISH: {"region": "english", "enemy_stats": 0x50C1D, "boss_redirect": 0x50893},
    MD5_GERMAN: {"region": "german", "enemy_stats": 0x50C8D, "boss_redirect": 0x50903},
}


def _find(buf: bytes, sig: bytes, lo: int, hi: int) -> list[int]:
    hits, i = [], lo
    while True:
        i = buf.find(sig, i, hi)
        if i < 0:
            return hits
        hits.append(i)
        i += 1


class RomLayout:
    """Resolves every table offset for a given ROM image."""

    def __init__(self, data: bytes):
        if len(data) != ROM_SIZE:
            raise ValueError(f"expected a 2 MB ROM, got {len(data)} bytes")
        self.md5 = hashlib.md5(data).hexdigest()
        known = _KNOWN.get(self.md5)
        if known:
            self.region = known["region"]
            self.enemy_stats = known["enemy_stats"]
            self.boss_redirect = known["boss_redirect"]
            self.recognised = True
        else:
            self.region = "unknown"
            self.recognised = False
            self.enemy_stats = self._locate_enemy_stats(data)
            self.boss_redirect = self._locate_boss_redirect(data)
        self._sanity(data)

    @staticmethod
    def _locate_enemy_stats(data: bytes) -> int:
        for hit in _find(data, _ENEMY_SIG_PRE, BANK14_START, BANK14_END):
            tail = hit + _ENEMY_SIG_POST_OFF
            if data[tail : tail + len(_ENEMY_SIG_POST)] == _ENEMY_SIG_POST:
                return hit
        raise ValueError("could not locate EnemyStatsTable in bank $14")

    @staticmethod
    def _locate_boss_redirect(data: bytes) -> int:
        hits = _find(data, _BOSS_SIG, BANK14_START, BANK14_END)
        if len(hits) != 1:
            raise ValueError(f"BossRedirectTable locator found {len(hits)} candidates")
        return hits[0]

    def _sanity(self, data: bytes) -> None:
        """Cheap structural assertions so a wrong ROM fails loudly, not silently."""
        end = self.enemy_stats + ENEMY_STATS_COUNT * ENEMY_STATS_STRIDE
        if end > BANK14_END:
            raise ValueError("EnemyStatsTable would overrun bank $14")
        mi, n, stride = MONSTER_INFO
        fams = {data[mi + i * stride] for i in range(n)}
        if not fams <= set(range(10)):
            raise ValueError("MonsterInfoTable sanity check failed (bad family bytes)")
        # Structural, not value-pinned: a randomized ROM is still a valid input.
        fr, fn, fs = FAMILY_RECIPES
        vals = set(data[fr : fr + fn * fs])
        if not vals <= (set(range(222)) | set(range(0xF0, 0xFA)) | {0xFF}):
            raise ValueError("FamilyRecipeTable sanity check failed")

    def describe(self) -> str:
        tag = self.region if self.recognised else f"unknown ({self.md5[:8]}…, located by signature)"
        return (
            f"region={tag}  EnemyStatsTable=0x{self.enemy_stats:05X} "
            f"BossRedirectTable=0x{self.boss_redirect:05X}"
        )


# --------------------------------------------------------------------------
# Typed records
# --------------------------------------------------------------------------

RESIST_COUNT = 27
RESIST_NAMES = [
    "Fire", "Heat", "Explosion", "Wind", "Lightning", "Ice", "Accuracy", "Sleep",
    "Death", "MP", "SpellBlock", "Confusion", "DefDown", "AglDown", "Sacrifice",
    "MegaMagic", "FireBreath", "IceBreath", "Poison", "Paralyze", "Curse",
    "MissATurn", "DanceBlock", "BreathBlock", "Aid", "GigaSlash", "(unused)",
]
FAMILY_NAMES = ["Slime", "Dragon", "Beast", "Flying", "Plant", "Bug", "Devil",
                "Zombie", "Material", "Boss"]


@dataclass
class Monster:
    """One 43-byte row of MonsterInfoTable ($03:$4461)."""
    id: int
    family: int
    level_cap: int
    exp_table: int
    female_ratio: int
    can_fly: int
    is_metal: int
    skills: list[int]           # 3 natural skill ids ($06-$08)
    growth: list[int]           # hp, mp, atk, def, agl, int ($09-$0E)
    resist: list[int]           # 27 values 0-3 ($0F-$29)
    tier: int                   # $2A

    @classmethod
    def parse(cls, b: bytes, idx: int) -> "Monster":
        return cls(idx, b[0], b[1], b[2], b[3], b[4], b[5],
                   list(b[6:9]), list(b[9:15]), list(b[15:42]), b[42])

    def pack(self) -> bytes:
        assert len(self.skills) == 3 and len(self.growth) == 6
        assert len(self.resist) == RESIST_COUNT
        return bytes([self.family, self.level_cap, self.exp_table, self.female_ratio,
                      self.can_fly, self.is_metal, *self.skills, *self.growth,
                      *self.resist, self.tier])


@dataclass
class Enemy:
    """One 25-byte row of EnemyStatsTable ($14:$4C1D / German $14:$4C8D)."""
    id: int
    species: int
    exp: int
    join: int          # +3 joinability: $07 = never, other = RNG path
    level: int
    stats: list[int]   # hp, mp, atk, def, agl, int (u16 LE)
    ai: list[int]      # 4 AI weights
    skills: list[int]  # 4 skill ids, $FF = none

    @classmethod
    def parse(cls, b: bytes, idx: int) -> "Enemy":
        stats = [int.from_bytes(b[5 + 2 * i : 7 + 2 * i], "little") for i in range(6)]
        return cls(idx, b[0], int.from_bytes(b[1:3], "little"), b[3], b[4],
                   stats, list(b[17:21]), list(b[21:25]))

    def pack(self) -> bytes:
        out = bytearray()
        out.append(self.species)
        out += self.exp.to_bytes(2, "little")
        out.append(self.join)
        out.append(self.level)
        for s in self.stats:
            out += max(0, min(0xFFFF, s)).to_bytes(2, "little")
        out += bytes(self.ai)
        out += bytes(self.skills)
        assert len(out) == ENEMY_STATS_STRIDE
        return bytes(out)


@dataclass
class Pool:
    """One 26-byte EncounterPoolData row ($01:$6AAE)."""
    id: int
    header: list[int]      # +0..9 (bytes +2 and +5 feed slot selection)
    eids: list[int]        # 5 x u16 LE
    weights: list[int]     # 5 x u8 (0 = slot unusable)
    extra: int

    @classmethod
    def parse(cls, b: bytes, idx: int) -> "Pool":
        eids = [int.from_bytes(b[10 + 2 * i : 12 + 2 * i], "little") for i in range(5)]
        return cls(idx, list(b[:10]), eids, list(b[20:25]), b[25])

    def pack(self) -> bytes:
        out = bytearray(self.header)
        for e in self.eids:
            out += e.to_bytes(2, "little")
        out += bytes(self.weights)
        out.append(self.extra)
        assert len(out) == 26
        return bytes(out)

    def live_slots(self) -> list[int]:
        return [i for i in range(5) if self.weights[i] != 0]


@dataclass
class SkillReq:
    """One 18-byte SkillLearnReqTable record ($06:$50E0)."""
    id: int
    level: int
    stats: list[int]      # hp, mp, atk, def, agl, int thresholds (u16 LE)
    prereqs: list[int]

    @classmethod
    def parse(cls, b: bytes, idx: int) -> "SkillReq":
        stats = [int.from_bytes(b[1 + 2 * i : 3 + 2 * i], "little") for i in range(6)]
        return cls(idx, b[0], stats, [x for x in b[13:18] if x != 0xFF])

    @property
    def difficulty(self) -> tuple:
        return (self.level, sum(self.stats))


@dataclass
class SkillRecord:
    """One 19-byte battle record ($54:$41CF + id*19).

    Only the fields the randomizer needs.  The ENEMY-side power pair (+15/+17)
    is the one that matters here: the caster's side selects the pair, which is
    why enemy Blaze (7-12) is weaker than party Blaze (12-15).
    """
    id: int
    category: int        # +1 hi-nibble: 1 damage, 2 status, 3 heal/buff, 8 item
    target_mode: int     # +2  $11 one foe, $12 all foes, $21/$22 allies
    ai_weight: int       # +3
    damage_class: int    # +6  $00 none, $04 spell, $05 breath
    enemy_min: int       # +15
    enemy_range: int     # +17

    @classmethod
    def parse(cls, b: bytes, idx: int) -> "SkillRecord":
        return cls(idx, b[1], b[2], b[3], b[6],
                   int.from_bytes(b[15:17], "little"),
                   int.from_bytes(b[17:19], "little"))

    @property
    def enemy_max(self) -> int:
        return self.enemy_min + self.enemy_range

    @property
    def hits_all(self) -> bool:
        return self.target_mode in (0x12, 0x22)

    @property
    def is_damaging(self) -> bool:
        return self.enemy_min > 0 and self.target_mode in (0x11, 0x12)


@dataclass
class Rom:
    """Mutable ROM image + parsed tables."""
    data: bytearray
    layout: RomLayout
    monsters: list[Monster] = field(default_factory=list)
    enemies: list[Enemy] = field(default_factory=list)
    pools: list[Pool] = field(default_factory=list)
    family_recipes: list[tuple[int, int]] = field(default_factory=list)
    special_recipes: list[list[int]] = field(default_factory=list)
    boss_redirect: list[tuple[int, int]] = field(default_factory=list)
    skill_reqs: list[SkillReq] = field(default_factory=list)
    growth_curves: list[list[int]] = field(default_factory=list)
    skill_records: list[SkillRecord] = field(default_factory=list)

    @classmethod
    def load(cls, path) -> "Rom":
        data = bytearray(open(path, "rb").read())
        rom = cls(data, RomLayout(bytes(data)))
        rom.read_all()
        return rom

    # -- reading ------------------------------------------------------------
    def _rows(self, base, count, stride):
        return [bytes(self.data[base + i * stride : base + (i + 1) * stride])
                for i in range(count)]

    def read_all(self) -> None:
        b, n, s = MONSTER_INFO
        self.monsters = [Monster.parse(r, i) for i, r in enumerate(self._rows(b, n, s))]
        b = self.layout.enemy_stats
        self.enemies = [Enemy.parse(r, i) for i, r in
                        enumerate(self._rows(b, ENEMY_STATS_COUNT, ENEMY_STATS_STRIDE))]
        b, n, s = ENCOUNTER_POOLS
        self.pools = [Pool.parse(r, i) for i, r in enumerate(self._rows(b, n, s))]
        b, n, s = FAMILY_RECIPES
        self.family_recipes = [(r[0], r[1]) for r in self._rows(b, n, s)]
        b, n, s = SPECIAL_RECIPES
        self.special_recipes = [list(r) for r in self._rows(b, n, s)]
        b = self.layout.boss_redirect
        self.boss_redirect = [
            (int.from_bytes(r[0:2], "little"), int.from_bytes(r[2:4], "little"))
            for r in self._rows(b, BOSS_REDIRECT_COUNT, BOSS_REDIRECT_STRIDE)]
        b, n, s = SKILL_LEARN
        self.skill_reqs = [SkillReq.parse(r, i) for i, r in enumerate(self._rows(b, n, s))]
        b, n, s = GROWTH_CURVES
        self.growth_curves = [list(r) for r in self._rows(b, n, s)]
        b, n, s = SKILL_RECORDS
        self.skill_records = [SkillRecord.parse(r, i)
                              for i, r in enumerate(self._rows(b, n, s))]

    # -- writing ------------------------------------------------------------
    def _write(self, base, stride, rows) -> None:
        for i, blob in enumerate(rows):
            assert len(blob) == stride
            self.data[base + i * stride : base + (i + 1) * stride] = blob

    def write_all(self) -> None:
        self._write(MONSTER_INFO[0], MONSTER_INFO[2], [m.pack() for m in self.monsters])
        self._write(self.layout.enemy_stats, ENEMY_STATS_STRIDE,
                    [e.pack() for e in self.enemies])
        self._write(ENCOUNTER_POOLS[0], ENCOUNTER_POOLS[2], [p.pack() for p in self.pools])
        self._write(FAMILY_RECIPES[0], FAMILY_RECIPES[2],
                    [bytes(p) for p in self.family_recipes])
        self._write(SPECIAL_RECIPES[0], SPECIAL_RECIPES[2],
                    [bytes(r) for r in self.special_recipes])
        self._write(self.layout.boss_redirect, BOSS_REDIRECT_STRIDE,
                    [f.to_bytes(2, "little") + j.to_bytes(2, "little")
                     for f, j in self.boss_redirect])
        self.fix_global_checksum()

    def fix_global_checksum(self) -> None:
        """Header global checksum: sum of all bytes except $14E/$14F, big-endian."""
        self.data[0x14E] = 0
        self.data[0x14F] = 0
        total = sum(self.data) & 0xFFFF
        self.data[0x14E] = total >> 8
        self.data[0x14F] = total & 0xFF

    def save(self, path) -> str:
        open(path, "wb").write(bytes(self.data))
        return hashlib.md5(bytes(self.data)).hexdigest()

    # -- derived helpers ----------------------------------------------------
    def growth_gain(self, curve_idx: int, to_level: int) -> int:
        """Total stat gained from level 1 up to `to_level` on a growth curve."""
        return sum(self.growth_curves[curve_idx][1:to_level])
