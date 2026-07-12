#!/usr/bin/env python3
"""
map_monster_walkers.py — CF1: enumerate + classify every access path into the
party/storage monster array ($CAC1, 20 real slots + 2 staging, stride $95).

WHY (S56 / ROADMAP Arc COLD FARM, CF1): moving farm slots to SRAM is only safe
if every code path that selects, walks, creates, or deletes array slots is
known and classified. S54 proved the array is invisible to literal-grep
(indexed access via GetMonsterDataPtr); S55 counted "44 read-walkers" without
recording them. This tool records them, permanently.

THE ACCESS MODEL (verified S56 — full write-up in MONSTER_DATA.md
"Party/farm boundary semantics"):
  * Slot selection funnels through wCurrentMonsterSlot $CAC0. There are
    exactly 44 `ld [$cac0], a` writer sites — each is the head of an access
    path. GetMonsterDataPtr call sites (326) are mostly single-slot reads of
    [$CAC0] and are NOT independently classified; the WRITERS are.
  * Multi-slot WALKS use either (a) a register loop + GetMonsterDataPtr with
    the loop counter in A, or (b) a literal base + manual `add $95` stride.
  * Party membership is DUAL: order/selection list $CA8D (count) +
    $CA8E-$CA90 (slot indices, $FF=empty), and the per-record in-use flag
    (+$00: $00 empty / $01 farm / $02 party). ReadPartySlotInfo ($01:$46F6,
    bank $01 entry 5) is the canonicalizer that syncs them and COMPACTS the
    array (149-byte records MOVE between slots).
  * Slots $14/$15 ($D665/$D6FA) are staging pseudo-slots (breeding parents,
    link-trade transit, menu scratch) — addressable via the same helper.

CLASSES:
  party-only   — touches only party members (via $CA8E list / $DA15 cache /
                 flag==$02 checks)
  all-slot     — walks or can select any of the 20 real slots
  farm-write   — creates/deletes/moves records (roster mutation)
  single-slot  — one slot chosen by UI cursor/list or a fixed index
  staging      — pseudo-slots $14/$15 only

Self-checking: every extracted $CAC0-writer site must have a curated
classification row and vice versa; anchor semantics (writer count = 44,
GetMonsterDataPtr body, exp-walker flag branches) are re-derived from the
source and abort on drift.

Output: extracted/monster_walkers.json + stdout report.

Usage:
  python3 tools/map_monster_walkers.py             # report + write JSON
  python3 tools/map_monster_walkers.py --selftest  # anchors only, no write
"""

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DIS = REPO / "disassembly"
SYM = DIS / "game.sym"
OUT = REPO / "extracted" / "monster_walkers.json"

ARRAY_BASE = 0xCAC1
STRIDE = 0x95
REAL_SLOTS = 20
STAGING_SLOTS = 2  # slot $14 @ $D665, slot $15 @ $D6FA (verified S56)

LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
CAC0_WRITE_RE = re.compile(r"\bld \[\$cac0\], a\b")
CALL_GMDP_RE = re.compile(r"\bcall GetMonsterDataPtr\b")
ADD_95_RE = re.compile(r"\badd \$95\b")

# -----------------------------------------------------------------------------
# Curated classification of ALL 44 $CAC0 writer sites (the walker heads).
# Key: (bank file, containing label, occurrence index within that label).
# Every row was read in source (S56). Evidence = what the code does.
# -----------------------------------------------------------------------------
CAC0_WRITERS = {
    # --- bank $01: party sprite loader (party positions 0/1/2) ---------------
    ("bank_001.asm", "jr_001_4947", 0): {
        "class": "party-only",
        "role": "LoadPartySpriteVRAM body: $CAC0:=$00 then "
                "GetActiveMonsterStatus (party position 0 follower art); "
                "gated by party count $CA8D"},
    ("bank_001.asm", "jr_001_4947", 1): {
        "class": "party-only", "role": "as above, $CAC0:=$01 (position 1)"},
    ("bank_001.asm", "jr_001_4947", 2): {
        "class": "party-only", "role": "as above, $CAC0:=$02 (position 2)"},
    # --- bank $03: link/serial monster navigation ----------------------------
    ("bank_003.asm", "jr_003_7e9d", 0): {
        "class": "single-slot",
        "role": "link/debug viewer slot++ (BCD/daa arithmetic, bound cp $16 "
                "— navigates into the staging index range)"},
    ("bank_003.asm", "jr_003_7ec1", 0): {
        "class": "single-slot",
        "role": "link/debug viewer slot-- (BCD/daa, floor $00)"},
    # --- bank $04: script engine ----------------------------------------------
    ("bank_004.asm", "label4_64c2", 0): {
        "class": "farm-write",
        "role": "script opcode: $CAC0 := [$CA40] (slot chosen by bank $16 "
                "first-empty scan jr_016_402d) then bank $16 entry 4 — "
                "offspring/hatch record finalization path"},
    ("bank_004.asm", "label4_6bdf", 0): {
        "class": "party-only",
        "role": "script opcode: $CAC0 := party list [$CA8E+c] (also cached "
                "to $D8E1), reads MP (+$52 via $CB13) — party-member MP "
                "check from scripts"},
    # --- bank $07: status screens / library -----------------------------------
    ("bank_007.asm", "SetFld_44e3", 0): {
        "class": "single-slot",
        "role": "status screen: $CAC0 := [wOPTN_and_Item_selection] "
                "(slot preselected by list UI)"},
    ("bank_007.asm", "LoadFld_45ee", 0): {
        "class": "single-slot",
        "role": "status screen re-entry: $CAC0 := cursor slot"},
    ("bank_007.asm", "jr_007_4704", 0): {
        "class": "single-slot",
        "role": "status exp-to-next display: temporarily retargets $CAC0 := "
                "[LoadFld_6d8b] (next monster in display order)"},
    ("bank_007.asm", "jr_007_47ca", 0): {
        "class": "single-slot",
        "role": "status exp display: restore saved $CAC0 (pop af path)"},
    ("bank_007.asm", "jr_007_5330", 0): {
        "class": "single-slot",
        "role": "status nav: $CAC0 := cursor slot on selection change"},
    ("bank_007.asm", "jr_007_5330", 1): {
        "class": "single-slot",
        "role": "status nav: $CAC0 := cursor slot (change-detect branch)"},
    ("bank_007.asm", "label7_6468", 0): {
        "class": "single-slot",
        "role": "list-scroll helper: $CAC0 := [[ptr $C930] + offset $C932] "
                "(display-order list indirection)"},
    ("bank_007.asm", "jr_007_6531", 0): {
        "class": "single-slot",
        "role": "list-scroll helper: $CAC0 := [[ptr $C930] + b] "
                "(next/prev monster in display order)"},
    # --- bank $0A: farm / organize / breeding-selection menus ------------------
    ("bank_00a.asm", "jr_00a_47f0", 0): {
        "class": "single-slot",
        "role": "farm menu select: $CAC0 := $C0D8[cursor] (display list)"},
    ("bank_00a.asm", "jr_00a_4f76", 0): {
        "class": "single-slot",
        "role": "breeding parent A select: $CAC0 := $C0D8[cursor], "
                "also stored to $C8E8"},
    ("bank_00a.asm", "jr_00a_52ae", 0): {
        "class": "single-slot",
        "role": "menu select ($C8E4 cursor set): $CAC0 := $C0D8[cursor]"},
    ("bank_00a.asm", "label5c5b", 0): {
        "class": "single-slot",
        "role": "menu select: $CAC0 := $C0D8[cursor]"},
    ("bank_00a.asm", "label5c92", 0): {
        "class": "single-slot",
        "role": "post-menu display: $CAC0 := [$C908] (saved slot), "
                "species-indexed name render"},
    ("bank_00a.asm", "label63f7", 0): {
        "class": "single-slot",
        "role": "menu select + species read (+$09): $CAC0 := $C0D8[cursor]"},
    ("bank_00a.asm", "label6659", 0): {
        "class": "single-slot",
        "role": "menu select then bank $07 entry 1 (status open): "
                "$CAC0 := $C0D8[cursor]"},
    ("bank_00a.asm", "label67bd", 0): {
        "class": "single-slot",
        "role": "menu select + Plus-value read (+$62 via $CB23): "
                "$CAC0 := $C0D8[cursor]"},
    ("bank_00a.asm", "Jump_00a_6cc4", 0): {
        "class": "single-slot",
        "role": "menu select (confirm sfx path): $CAC0 := $C0D8[cursor], "
                "also $C8E8"},
    # --- bank $12: farm list / library / sleep ---------------------------------
    ("bank_012.asm", "SetItem_6242", 0): {
        "class": "single-slot",
        "role": "SCRATCH REUSE: $CAC0 holds a flat family index here "
                "(existing in-line comment), not a slot select"},
    ("bank_012.asm", "jr_012_6369", 0): {
        "class": "single-slot",
        "role": "farm list select: $CAC0 := $C0D8[cursor]; $E0 sentinel "
                "branch"},
    ("bank_012.asm", "LoadItem_6544", 0): {
        "class": "single-slot",
        "role": "farm list select (second state): $CAC0 := $C0D8[cursor]"},
    ("bank_012.asm", "jr_012_6a61", 0): {
        "class": "single-slot",
        "role": "farm detail: $CAC0 := $C0D8[cursor], copies nickname "
                "(+$0C, 9 B via $CACD) to $CA42 scratch"},
    # --- bank $14: record builder -----------------------------------------------
    ("bank_014.asm", "jr_014_42fe", 0): {
        "class": "farm-write",
        "role": "record builder (label14_40b4 family): $CAC0 := [$DA14], "
                "bank $13 entry 1 exp snap; +$0B growth roll just above"},
    # --- bank $15: menu system (incl. link-trade UI) -----------------------------
    ("bank_015.asm", "jr_015_49d4", 0): {
        "class": "single-slot",
        "role": "menu select: $CAC0 := $C0D8[cursor]"},
    ("bank_015.asm", "jr_015_4c3b", 0): {
        "class": "staging",
        "role": "$CAC0 := $14 + clear $D665 in-use (init staging slot 20 "
                "as menu scratch)"},
    ("bank_015.asm", "Jump_015_4c8d", 0): {
        "class": "staging",
        "role": "same staging-slot-20 init, second entry"},
    ("bank_015.asm", "jr_015_4e1b", 0): {
        "class": "single-slot",
        "role": "menu select: $CAC0 := $C0D8[cursor]"},
    ("bank_015.asm", "Jump_015_50da", 0): {
        "class": "staging",
        "role": "$CAC0 := $15 (view staging slot 21 — incoming trade "
                "monster)"},
    ("bank_015.asm", "Jump_015_561e", 0): {
        "class": "single-slot",
        "role": "menu select: $CAC0 := $C0D8[cursor]"},
    ("bank_015.asm", "Jump_015_58e0", 0): {
        "class": "staging",
        "role": "$CAC0 := $15 (staging slot 21 view, second state)"},
    ("bank_015.asm", "jr_015_5aa5", 0): {
        "class": "farm-write",
        "role": "TRADE-AWAY head: $CAC0 := $C0D8[cursor], then copy record "
                "-> staging $D665 and delete (in-use:=0)"},
    # --- bank $16: breeding -------------------------------------------------------
    ("bank_016.asm", "jr_016_402d", 0): {
        "class": "farm-write",
        "role": "breeding offspring insert: first-empty scan result c -> "
                "$CAC0 AND $CA40 (persisted for label4_64c2), zero-fill "
                "record via LoadBrd_41b1"},
    # --- bank $18: link trade ------------------------------------------------------
    ("bank_018.asm", "jr_018_4abd", 0): {
        "class": "single-slot",
        "role": "trade menu select: $CAC0 := $C0D8[cursor]"},
    # --- bank $50: post-battle -------------------------------------------------------
    ("bank_050.asm", "CallBtl_61e2", 0): {
        "class": "all-slot",
        "role": "EXP DISTRIBUTION walker init: $CAC0:=0 then walks all 20 "
                "(flag $02 -> party share = total/eligible_count; flag $01 "
                "-> farm share = total/16; skips empty, egg +$63!=0, "
                "KO +$4A bit7 [party], level $63, level>=cap)"},
    ("bank_050.asm", "jr_050_6337", 0): {
        "class": "party-only",
        "role": "battle HP-strip refresh fragment: $CAC0 := slot from "
                "caller, $DA15+pos battle-position cache compare/update"},
    ("bank_050.asm", "CmpBtl_6383", 0): {
        "class": "all-slot",
        "role": "pending-level-up probe for slot A (used on party list "
                "$CA8E/8F/90 FIRST, then all-20 loop jr_050_6318); "
                "bank $13 entry 0 threshold + exp compare"},
    # --- bank $51: battle presentation ---------------------------------------------
    ("bank_051.asm", "CmpBtlS_6650", 0): {
        "class": "single-slot",
        "role": "battle-adjacent menu: $CAC0 := $C0D8[cursor] then bank $07 "
                "entry 1 (status open)"},
    ("bank_051.asm", "jr_051_66d7", 0): {
        "class": "single-slot",
        "role": "battle-adjacent menu: $CAC0 := $C0D8[$C8DF] then bank $07 "
                "entry 1"},
}

# -----------------------------------------------------------------------------
# Curated multi-slot WALKERS that do NOT go through $CAC0 (register loops /
# manual stride). Key: (file, label of the loop body or head).
# -----------------------------------------------------------------------------
REGISTER_WALKERS = {
    ("bank_001.asm", "ScanPartySlotTable"): {
        "class": "all-slot",
        "role": "bank $01 entry 6: walk 20; per occupied slot sanitize the "
                "two $FF-terminated ID lists (+$29 x8 via $CAEA, +$31 x25 "
                "via $CAF2; semantics unverified)"},
    ("bank_001.asm", "ReadPartySlotInfo"): {
        "class": "farm-write",
        "role": "bank $01 entry 5 CANONICALIZER: clear stale party-list "
                "entries; normalize all in-use flags to $01; re-mark party "
                "slots $02 (RetIfSlotInvalid); COMPACT the array (149-B "
                "record swaps via SaveRegsAndSetupDE); remap list via $C0D8 "
                "old->new map (RetIfSlotInvalid2); recount $CA8D. 22 call "
                "sites across 8 banks ('roster changed' epilogue)"},
    ("bank_001.asm", "IteratePartySlots20"): {
        "class": "all-slot",
        "role": "bank $01 entry 9: walk 20 occupied; clear +$4A battle "
                "status byte (KO bit7) and adjacent state — post-battle/heal "
                "bulk clear"},
    ("bank_001.asm", "RollRandomEncounter"): {
        "class": "farm-write",
        "role": "random record generator: $DA14 := A param, random EID -> "
                "bank $14 builder (init/debug party seeding; despite the "
                "label, not the wild-encounter roll)"},
    ("bank_004.asm", "CheckEnemyData"): {
        "class": "farm-write",
        "role": "script opcode $29 give (label4_5c14): first-empty scan -> "
                "$DA14 -> $1402 build; if $CA8D<3 ALSO appends slot to party "
                "list + $CA8D++ (given monster joins party when room)"},
    ("bank_004.asm", "CheckInventorySlot"): {
        "class": "all-slot",
        "role": "script opcode storage-full check (label4_5f67): count "
                "occupied, branch if 20"},
    ("bank_004.asm", "CheckItemData"): {
        "class": "farm-write",
        "role": "script opcode $28 AddMonsterToStorage: first-empty -> "
                "$DA14 -> $1402 build (NO party-list append)"},
    ("bank_007.asm", "jr_007_42ee"): {
        "class": "all-slot",
        "role": "library counting: walk 20 WRAM slots (+ the SRAM sleep "
                "pool $B124 in the sibling loop) collecting species for "
                "completion counters"},
    ("bank_007.asm", "jr_007_431e"): {
        "class": "all-slot", "role": "library counting sibling walk"},
    ("bank_007.asm", "jr_007_435b"): {
        "class": "all-slot", "role": "library counting sibling walk"},
    ("bank_007.asm", "jr_007_4398"): {
        "class": "all-slot", "role": "library counting sibling walk"},
    ("bank_009.asm", "FuncFld9_692a"): {
        "class": "all-slot",
        "role": "walk slots via GetMonsterDataPtr with loop counter c, "
                "skip empties (field/overworld context)"},
    ("bank_00a.asm", "jr_00a_458b"): {
        "class": "all-slot",
        "role": "count occupied NON-EGG slots -> $C8E9 (menu list size)"},
    ("bank_00a.asm", "jr_00a_45c4"): {
        "class": "all-slot",
        "role": "build display list $C0D8[] of non-egg slot indices "
                "(SetFldA_459c)"},
    ("bank_00a.asm", "jr_00a_4d66"): {
        "class": "all-slot",
        "role": "count occupied non-egg (SetFldA_4d4d, second menu)"},
    ("bank_00a.asm", "jr_00a_4d9f"): {
        "class": "all-slot", "role": "build non-egg display list (sibling)"},
    ("bank_00a.asm", "jr_00a_5055"): {
        "class": "party-only",
        "role": "party loop cp $03 over positions (party display)"},
    ("bank_00a.asm", "jr_00a_50d2"): {
        "class": "all-slot",
        "role": "count with egg/mode filter (breeding-eligible list)"},
    ("bank_00a.asm", "jr_00a_5112"): {
        "class": "all-slot", "role": "build filtered display list (sibling)"},
    ("bank_00a.asm", "jr_00a_538c"): {
        "class": "party-only",
        "role": "breeding guardrails: parent level>=10; if $CA8D==2 both "
                "parents must be flag $02 (cannot empty the party)"},
    ("bank_00a.asm", "jr_00a_53a7"): {
        "class": "party-only",
        "role": "breeding guardrail flag==$02 checks (both parents)"},
    ("bank_00a.asm", "jr_00a_5960"): {
        "class": "all-slot",
        "role": "count occupied EGG slots (SetFldA_5947 — egg/hatch menu)"},
    ("bank_00a.asm", "jr_00a_5999"): {
        "class": "all-slot", "role": "build egg display list (sibling)"},
    ("bank_00a.asm", "jr_00a_620b"): {
        "class": "all-slot", "role": "count (Plus/quality-filtered list)"},
    ("bank_00a.asm", "jr_00a_6244"): {
        "class": "all-slot", "role": "build that display list (sibling)"},
    ("bank_00a.asm", "label6518"): {
        "class": "all-slot",
        "role": "walk 20 via GetMonsterDataPtr (cp $14 loop) — menu-wide "
                "per-slot read"},
    ("bank_012.asm", "jr_012_4cd4"): {
        "class": "all-slot", "role": "farm-list count (filtered)"},
    ("bank_012.asm", "jr_012_4d11"): {
        "class": "all-slot", "role": "farm-list build (sibling)"},
    ("bank_012.asm", "jr_012_553e"): {
        "class": "all-slot", "role": "farm-list count (filtered)"},
    ("bank_012.asm", "jr_012_556e"): {
        "class": "all-slot", "role": "farm-list build (sibling)"},
    ("bank_012.asm", "jr_012_55ab"): {
        "class": "all-slot", "role": "farm-list count (filtered)"},
    ("bank_012.asm", "jr_012_55e8"): {
        "class": "all-slot", "role": "farm-list build (sibling)"},
    ("bank_012.asm", "jr_012_5695"): {
        "class": "all-slot", "role": "farm-list count (filtered)"},
    ("bank_012.asm", "jr_012_56dc"): {
        "class": "all-slot", "role": "farm-list build (sibling)"},
    ("bank_012.asm", "jr_012_5add"): {
        "class": "all-slot", "role": "farm-list count (filtered)"},
    ("bank_012.asm", "jr_012_5b28"): {
        "class": "all-slot", "role": "farm-list build (sibling)"},
    ("bank_012.asm", "jr_012_5e0b"): {
        "class": "all-slot",
        "role": "farm-occupancy probe: any flag==$01 slot? (dialogue "
                "branch)"},
    ("bank_012.asm", "jr_012_5e27"): {
        "class": "all-slot",
        "role": "SLEEP POOL probe: walk SRAM $B124 20 slots via EnableSRAM "
                "per-slot in-use read"},
    ("bank_012.asm", "jr_012_5edf"): {
        "class": "all-slot", "role": "farm-list count (filtered)"},
    ("bank_012.asm", "jr_012_5f00"): {
        "class": "all-slot", "role": "farm-list build (sibling)"},
    ("bank_012.asm", "jr_012_5f58"): {
        "class": "all-slot",
        "role": "walk 20 via GetMonsterDataPtr (cp $14) — farm/library "
                "per-slot read"},
    ("bank_012.asm", "jr_012_6bfa"): {
        "class": "farm-write",
        "role": "egg receive first-empty scan (head of the jr_012_6c0a "
                "creation path)"},
    ("bank_015.asm", "jr_015_475b"): {
        "class": "all-slot", "role": "menu count walk (cp $14)"},
    ("bank_015.asm", "jr_015_47a9"): {
        "class": "all-slot", "role": "menu list-build walk (sibling)"},
    ("bank_015.asm", "jr_015_4cdb"): {
        "class": "all-slot", "role": "menu count walk"},
    ("bank_015.asm", "jr_015_4d14"): {
        "class": "all-slot", "role": "menu list-build walk (sibling)"},
    ("bank_015.asm", "jr_015_54d8"): {
        "class": "all-slot", "role": "menu count walk"},
    ("bank_015.asm", "jr_015_5511"): {
        "class": "all-slot", "role": "menu list-build walk (sibling)"},
    ("bank_016.asm", "jr_016_401c"): {
        "class": "farm-write",
        "role": "breeding offspring first-empty scan (feeds jr_016_402d)"},
    ("bank_016.asm", "SaveBrd_41ff"): {
        "class": "staging",
        "role": "breeding parent field sum: reads field at +$0BA4 (staging "
                "slot $14) and +$0BA4+$95 (slot $15) — parents addressed as "
                "array slots 20/21"},
    ("bank_018.asm", "jr_018_459b"): {
        "class": "all-slot", "role": "trade menu count walk (cp $14)"},
    ("bank_018.asm", "jr_018_470a"): {
        "class": "all-slot", "role": "trade menu walk (cp $14)"},
    ("bank_018.asm", "jr_018_4763"): {
        "class": "all-slot", "role": "trade menu walk (cp $14)"},
    ("bank_050.asm", "jr_050_62c4"): {
        "class": "all-slot",
        "role": "exp-walker loop tail: per-slot ReadBtl_689e + $CAC0++ + "
                "stride (body of CallBtl_61e2)"},
    ("bank_050.asm", "jr_050_6318"): {
        "class": "all-slot",
        "role": "post-battle level-up scan b=0..$13 over CmpBtl_6383 "
                "(runs AFTER the party-list members are processed)"},
    ("bank_051.asm", "SetBtlS_5e34"): {
        "class": "all-slot",
        "role": "count EMPTY slots (capacity check before join)"},
    ("bank_051.asm", "jr_051_5f53"): {
        "class": "all-slot",
        "role": "count with egg-flag/mode filter ($C8E4 bit0 XOR +$63)"},
    ("bank_051.asm", "jr_051_5f9a"): {
        "class": "all-slot", "role": "build that display list (sibling)"},
    ("bank_051.asm", "SetBtlS_63e8"): {
        "class": "farm-write",
        "role": "battle JOIN first-empty scan; joined monster built via "
                "bank $14, appended to party list if $CA8D<3 + canonicalize"},
    ("bank_055.asm", "SaveB55_53f6"): {
        "class": "farm-write",
        "role": "debug menu monster spawner ($1402 caller)"},
}

# Paths that CREATE, DELETE, or MOVE records (roster mutations) — the
# farm-write summary table for Cold Farm CF3 redirect planning.
MUTATION_PATHS = [
    {"path": "script give $29", "where": "$04 label4_5c14",
     "action": "create @ first-empty ($DA14); party-list append if $CA8D<3"},
    {"path": "script give $28", "where": "$04 label4_5f9a/CheckItemData",
     "action": "create @ first-empty; storage only"},
    {"path": "egg receive", "where": "$12 jr_012_6c0a",
     "action": "create @ first-empty; +$63:=1 (egg)"},
    {"path": "battle join", "where": "$51 SetBtlS_63e8 + $50 jr_050_63ea",
     "action": "create @ first-empty (join-EID via boss redirect $1406); "
               "party-list append if room"},
    {"path": "breeding (2-parent)", "where": "$0a ~$538c flow",
     "action": "parents copied to staging $D665/$D6FA + both DELETED; "
               "offspring created later @ first-empty ($16 jr_016_402d, "
               "slot persisted in $CA40); auto-save"},
    {"path": "breeding (NPC mate)", "where": "$0a ~$4f00 flow (site 1792)",
     "action": "your parent -> staging $D665 + deleted; mate synthesized "
               "from EID $C8F7/8 into slot $15"},
    {"path": "release (part with)", "where": "$12 ~$63e0 (line 4599)",
     "action": "delete (in-use:=0) + canonicalize"},
    {"path": "link trade", "where": "$15 jr_015_5b2c (send), $18 ~$4c50 "
                                    "(receive)",
     "action": "send: copy -> staging $D665, delete; receive: staged $D6FA "
               "-> slot 19 after canonicalize; seen-bit set; forced SRAM "
               "saves (anti-clone)"},
    {"path": "sleep", "where": "$12 SetItem_5fde (init) + $12 transfer "
                               "loops; $07 scans",
     "action": "one-way archival: records -> SRAM pool $B124 (20x$95); "
               "$CA41 bit7 gates"},
    {"path": "party drop/pick", "where": "$0a ~$6de6 commit",
     "action": "flag flips $02<->$01 over the $C0D8 4-entry working set; "
               "party list rebuilt from flags; canonicalize + battle "
               "reload ($0105 + $0103)"},
    {"path": "canonicalizer compaction", "where": "$01 ReadPartySlotInfo",
     "action": "MOVES records (149-B swaps) to close holes; remaps party "
               "list; 22 call sites"},
]

SEMANTICS = {
    "membership": "dual: in-use flag +$00 ($00 empty/$01 farm/$02 party) + "
                  "party list $CA8D count / $CA8E-$CA90 slot indices "
                  "($FF=empty); synced by ReadPartySlotInfo ($01 entry 5)",
    "party_positional": False,
    "party_note": "party slots are NOT fixed at 0-2; the list points at "
                  "arbitrary array indices (compaction keeps occupied slots "
                  "contiguous but party members can sit anywhere among them)",
    "exp_shares": "party member: total/eligible_party_count (+1 if 3, -1 if "
                  "1 — rounding quirk); farm monster: total/16 EACH; eggs "
                  "(+$63!=0), KO'd party (+$4A bit7), level 99, and "
                  "level>=cap (+$4C) receive none. Total in $DD23-$DD25.",
    "staging_slots": "GetMonsterDataPtr indices $14 ($D665) / $15 ($D6FA): "
                     "breeding parents, trade transit, menu scratch; inside "
                     "the $C8EA-$D9E9 save image",
    "battle_position_cache": "$DA15-$DA17 := validated party list "
                             "(bank $51 LoadBtlS_40d1 via $01 entry 7)",
    "give_param_block": "$DA12/wTempEnemyStatsId + $DA13 = EID, "
                        "$DA14 = target slot",
}


def load_sym():
    m = {}
    if SYM.exists():
        for line in SYM.read_text().splitlines():
            parts = line.strip().split()
            if len(parts) == 2 and ":" in parts[0] and not line.startswith(";"):
                try:
                    b, a = parts[0].split(":")
                    m[parts[1]] = f"${int(b,16):02x}:${int(a,16):04x}"
                except ValueError:
                    pass
    return m


def extract():
    """Find all $CAC0 writes, GMDP calls, and manual strides with labels."""
    writers, gmdp, strides = [], [], []
    for path in sorted(DIS.glob("bank_*.asm")):
        cur = None
        occ = defaultdict(int)
        for i, line in enumerate(path.read_text().splitlines()):
            lm = LABEL_RE.match(line)
            if lm:
                cur = lm.group(1)
            rec = {"file": path.name, "label": cur, "line": i + 1}
            if CAC0_WRITE_RE.search(line):
                rec["occ"] = occ[(cur, "w")]
                occ[(cur, "w")] += 1
                writers.append(rec)
            elif CALL_GMDP_RE.search(line):
                gmdp.append(rec)
            elif ADD_95_RE.search(line):
                strides.append(rec)
    return writers, gmdp, strides


def selftest(writers, gmdp):
    errs = []
    if len(writers) != 44:
        errs.append(f"expected 44 $CAC0 writers, found {len(writers)}")
    found = {(w["file"], w["label"], w["occ"]) for w in writers}
    curated = set(CAC0_WRITERS.keys())
    for k in sorted(found - curated):
        errs.append(f"UNCLASSIFIED writer: {k}")
    for k in sorted(curated - found):
        errs.append(f"STALE classification (site gone/renamed): {k}")
    # anchor: GetMonsterDataPtr exists in bank_000 with the documented body
    b0 = (DIS / "bank_000.asm").read_text()
    if "GetMonsterDataPtr:" not in b0 or "ld c, $95" not in b0:
        errs.append("GetMonsterDataPtr anchor missing in bank_000")
    # anchor: exp walker tri-state branch (cp $02 on in-use flag)
    b50 = (DIS / "bank_050.asm").read_text()
    if "CallBtl_61e2" not in b50:
        errs.append("CallBtl_61e2 anchor missing in bank_050")
    # anchor: every register-walker label must still exist in its file
    for (f, lbl) in REGISTER_WALKERS:
        if f"\n{lbl}:" not in (DIS / f).read_text():
            errs.append(f"REGISTER_WALKERS label missing: {f} {lbl}")
    return errs


def main():
    sym = load_sym()
    writers, gmdp, strides = extract()
    errs = selftest(writers, gmdp)
    if errs:
        print("SELFTEST FAIL:")
        for e in errs:
            print("  " + e)
        sys.exit(1)
    print(f"selftest OK: 44/44 $CAC0 writers classified; "
          f"{len(gmdp)} GetMonsterDataPtr call sites; "
          f"{len(strides)} manual-stride sites")
    if "--selftest" in sys.argv:
        return
    out = {
        "_generator": "tools/map_monster_walkers.py (S56/CF1); sources: "
                      "disassembly/*.asm at the byte-perfect tree; addresses "
                      "from game.sym when present",
        "array": {"base": "$CAC1", "stride": "$95", "real_slots": 20,
                  "staging_slots": {"$14": "$D665", "$15": "$D6FA"},
                  "end_real": "$D664", "end_staging": "$D78E"},
        "semantics": SEMANTICS,
        "cac0_writers": [
            {**w, "addr": sym.get(w["label"], "?"),
             **CAC0_WRITERS[(w["file"], w["label"], w["occ"])]}
            for w in writers],
        "register_walkers": [
            {"file": f, "label": l, "addr": sym.get(l, "?"), **v}
            for (f, l), v in sorted(REGISTER_WALKERS.items())],
        "mutation_paths": MUTATION_PATHS,
        "gmdp_call_sites": len(gmdp),
        "manual_stride_sites": len(strides),
    }
    OUT.write_text(json.dumps(out, indent=2) + "\n")
    counts = defaultdict(int)
    for w in out["cac0_writers"]:
        counts[w["class"]] += 1
    for w in out["register_walkers"]:
        counts[w["class"]] += 1
    print(f"wrote {OUT.relative_to(REPO)}")
    print("classification totals (writers + register walkers): "
          + ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))


if __name__ == "__main__":
    main()
