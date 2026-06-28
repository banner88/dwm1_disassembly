"""Skill-ID bucketing audit for the custom-skill arc (ROADMAP S2 / S2d).

The "proper per-id custom skill" path (S2d) stops aliasing a new id to Blaze and
lets the REAL working id flow through the battle engine. That only works if every
place the engine BUCKETS the skill id by numeric range or INDEXES it into a
fixed-size table is known and handled for a net-new high id (>= $DE). The S45
alias hack existed specifically to AVOID enumerating these sites ("buckets in
>=3 banks ... endless whack-a-mole"). This tool IS that enumeration -- the
$db8a analog of map_species_slots.py.

Authoritative surface = the working id $db8a (never reused; the cast pipeline
re-derives everything from it). $db4c is the re-derived RECORD INDEX but is ALSO
reused as scratch inside routines, so its low-threshold gates are NOT skill-id
gates (verified: they scale a 0-4 value via sla/rl). The fork-relevant $db4c use
is the record-table index ($54:$4013) and the magnitude divert ($54:$535F).

GROUND TRUTH: every gate/threshold/branch here is decoded from ROM bytes and the
tool self-checks the load-bearing anchors against the ROM, aborting on drift.
The per-gate `verdict` strings are the analysis (what a new id >= $DE does).

Output: extracted/skill_id_bucket_map.json
Run:    python3 tools/map_skill_id_buckets.py            # write + summary
        python3 tools/map_skill_id_buckets.py --print    # also dump gate tables
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sm83dis import decode  # noqa: E402

ROM_PATH = Path("data/DWM-original.gbc")
OUT_PATH = Path("extracted/skill_id_bucket_map.json")

# --- Verified geography (ROM-grounded; see BATTLE_SKILL_SYSTEM.md) ----------
WORKING_ID_VAR = 0xDB8A          # the battle "working skill id" (authoritative)
RECORD_IDX_VAR = 0xDB4C          # record-lookup index (re-derived; reused as scratch)
SELECTED_VAR   = 0xDB4F          # targeting helper "selected skill"
LAST_REAL_ID   = 0xDD            # Ahhh; real skills are $00..$DD (222 records)
FIRST_CUSTOM   = 0xDE            # first net-new id; budget $DE..$FF
N_RECORDS      = 222

HIGH_ID_SPECIALS = {             # real skills/commands at the top of the range
    0xD5: "BeDragon (transform)", 0xD6: "Smashlime", 0xD7: "BugCut (was Sheldodge)",
    0xD8: "Branching", 0xD9: "GigaSlash", 0xDA: "LIFE (internal)",
    0xDB: "RUN (flee command)", 0xDC: "IRONIZE (internal)", 0xDD: "Ahhh (internal)",
}

# 222-entry tables the id (or the record index) overshoots at >= $DE.
# Each is a REQUIRED fork point for a de-aliased custom id (the "high-table +
# forked loader" pattern). Addresses verified by sm83dis traces this session.
FORK_POINTS = {
    "record_ptr_table": {
        "table": "$54:$4013", "entry": "2B ptr -> 19B record @ $41CF+id*19", "count": 222,
        "indexer": "$54 entries 0/1/2 ($5249/$526e/$5298) ALL do `ld hl,$4013; add hl,bc` "
                   "with bc=$db4c (=skill id). Entry 5 ($535F SkillMagnitudeBySide) is a 4th "
                   "reader that BAILS for id>=$d6 (see special_case_gates).",
        "canonical_magnitude_path": "$52:$66D6 sets $db4c=$db8a (ld [$db4c],a), picks field "
                   "offset $0b(party)/$0f(enemy), then invokes entry 1 ($526e via ld hl,$5401; "
                   "rst $10) -> indexes $4013 by id -> reads power +11/+15. OVERSHOOTS at $DE.",
        "drives": "targeting(+2) MP(+4) status(+5) damage_class(+6) power(+11/13/15/17) ai_weight(+3)",
        "fork": "THE KEYSTONE. id>=$DE -> read a free-bank 19B record instead of $41CF+id*19. "
                "Must cover ALL 4 readers: the 3 overshooting indexers (entries 0/1/2) AND "
                "entry 5's >=$d6 bail. One record fork makes magnitude/targeting/MP/AI all correct.",
    },
    "function_table": {
        "table": "$52:$4011", "entry": "2B handler ptr", "count": 222,
        "indexer": "$52:$6CD5 dispatch (ALREADY FORKED by S45 FarSkillFork, bank $72)",
        "drives": "effect handler (effect TYPE)",
        "fork": "DONE for the alias path; generalize to route id>=$DE on $db8a directly",
    },
    "mp_cost_table": {
        "table": "$07:$570C", "entry": "u16 LE (999=ALL)", "count": 222,
        "indexer": "THREE readers all do hl=$570C+2*id: $07:$56E8 GetSkillMPCost (id in de; "
                   "menu display via $55B0; has a $70 gender remap), and $07:$5A98 & $07:$5B4E "
                   "(id pulled from the monster skill list; afford-check / deduction).",
        "drives": "MP shown + deducted; overshoot reads garbage",
        "mirror": "VERIFIED record+4 (mp_cost) == $570C[id] for all sampled skills. MP is "
                  "duplicated: record+4 (read in-battle by $54 readers) and $570C (menu/deduct). "
                  "A custom skill must set both; build_skill_tables.py derives both from "
                  "skill_records.json so they stay in sync.",
        "fork": "id>=$DE -> custom MP word. Cover all 3 reader sites (or a shared high-table).",
    },
    "anim_index_tables": {
        "table": "$5f:$58dd (party) / $59c3 (enemy) / $5aa9 (special)", "entry": "1B routine index", "count": 230,
        "indexer": "$5f:$5433 (ld hl,$58dd; ld a,[$db8a]; add a,l)",
        "drives": "which $5f:$58bd routine draws the sprite animation",
        "fork": "id>=$DE -> chosen index. NOTE overshoot already reads $0d = no-visual "
                "(verified), so a NO-ANIMATION custom skill (e.g. heal) needs NO fork here",
    },
    "sound_table": {
        "table": "$55:$4070 = side-selected POINTER table (not a flat 222 array)",
        "entry": "$4070 holds 2 sub-table pointers chosen by $c863/$db88 (caster side); the "
                 "selected sub-table is then indexed by the skill id", "count": "per-side sub-table",
        "indexer": "$55:$404a: side-select deref, then $4067 `add hl,bc` (bc=$db8a) into the sub-table",
        "drives": "cast SFX; $4068 reads SFX id, `cp $ff; ret z` => $FF = silence (graceful default)",
        "fork": "one site ($55:$4067) after side-select covers both sides; id>=$DE -> chosen SFX "
                "(or $FF for silence). Overshoot may already read $FF depending on sub-table tail.",
    },
    "learn_req_table": {
        "table": "$06:$50E0", "entry": "18B", "count": 222,
        "indexer": "gen_skill_records source; only used when a monster LEARNS it naturally",
        "drives": "level/stat reqs + prereqs to learn",
        "fork": "NOT needed for an assigned/starter skill; fork only for naturally-learnable custom skills",
    },
    "name_table": {
        "table": "$41:$4539", "entry": "2B name ptr", "count": 256,
        "indexer": "menu reads real id $caea",
        "drives": "displayed name",
        "fork": "NONE -- table runs to id 255; just repoint slot (alias framework already does)",
    },
}

# Special-case gates a NEW id ENTERS (not excluded). These are the real S2d hazards.
# loc/cmp verified by sm83dis; verdict is the analysis.
SPECIAL_GATES = [
    {"loc": "$54:$535F", "name": "SkillMagnitudeBySide (record reader #4, side-power)",     "anchor": "cp $d5 / jr z $539d / jr nc $53a6",
     "behavior": "id==$d5 -> $539d; id>=$d6 -> $53a6 which ZEROES $db4c and returns "
                 "(this reader BAILS, no record-power read); id<$d5 -> normal side-power read. "
                 "Called from $55:$532A/$5332 (a side-by-side power path), NOT from the main "
                 "magnitude routine $66d6 (which uses entry 1).",
     "verdict_for_new": "This is ONE of four record-table readers, and the only one that "
                        "guards the high range. It does NOT independently break custom skills: "
                        "the main magnitude path ($66d6 -> entry 1) already OVERSHOOTS the "
                        "record table for id>=$DE. The fix for both is the SAME single record "
                        "fork (fork_points.record_ptr_table). The $535F bail just means a "
                        "forked reader here must also handle id>=$d6 explicitly rather than "
                        "fall into the zeroing branch. Corrects the doc implication that "
                        "'+11/+13 power drives the skill' -- record-driven power is reached by "
                        "INDEXING the record table with the id, so it needs the record fork."},
    {"loc": "$50:$6BC4", "name": "menu/command pseudo-id check",
     "anchor": "ld a,[$db4c] / cp $e1 / jr z $6be7",
     "behavior": "record index $e1 (225) routed to a bespoke menu/inventory path ($6be7)",
     "verdict_for_new": "AVOID id $E1 ($e1=225) for custom skills (or account for this path). "
                        "Other custom ids unaffected."},
    {"loc": "$52:$70E0", "name": "narrow spell window (example of a SAFE window gate)",
     "anchor": "cp $52 / jr c $710e / cp $54 / jr nc $710e",
     "behavior": "only ids [$52,$54) take the special path; all else (incl $DE) -> $710e",
     "verdict_for_new": "SAFE. Representative of the many $db8a 'gates' that are narrow "
                        "windows EXCLUDING the custom range."},
]

# Full cast pipeline, production -> consumption (reconstructed this session by ROM trace).
CAST_PIPELINE = {
    "production": {
        "menu_real_id": "$caea holds the player's menu-selected REAL id (used for the NAME).",
        "primary_commit": "$50:~$4A55 -- after the chosen skill is fetched into [hl], the engine "
                          "does `ld a,[hl]; ld [$db4c],a; ld [$db8a],a; ld [$db4f],a`, setting "
                          "record-index + working-id + selected-skill from the chosen skill.",
        "action_queue": "$dcec -- the committed action queue; $db8a is (re)derived from it during "
                        "turn resolution. The FX router ($58) and multi-hit/chain code ($52) "
                        "re-set $db8a for sub-effects (accounts for most of the 35 write sites).",
        "alias_hook_S45": "AliasCommit (bank $50 patch) intercepts the commit: for id $DE/$DF it "
                          "stashes the real id in $db86 and forces the queued value to $00 (Blaze), "
                          "so all downstream presentation sees Blaze. $db8a==0 at effect dispatch "
                          "is the alias signal.",
        "dealias_plan_S2d": "Do NOT templatize -- let the real id ($DE+) flow into the queue and "
                            "thus into $db8a. Then the consumption forks below make it correct.",
    },
    "consumption_order": [
        "$db8a (working id) -> $db4c (record index, re-derived e.g. at $52:$66D9)",
        "RECORD table $54:$4013 indexed by id: magnitude ($66d6->entry1), targeting (+2->$dcfc via "
        "entry2), status/damage_class (+5/+6), ai_weight (+3, via shared entry0). 3 indexer sites "
        "+ entry5 bail = the KEYSTONE fork.",
        "FUNCTION table $52:$4011 indexed by id -> effect handler (FarSkillFork done).",
        "MP table $07:$570C indexed by id (3 readers) -> shown + deducted.",
        "SOUND $55:$4070 side-selected -> sub-table indexed by id at $4067 ($FF=silence).",
        "ANIM $5f:$58dd indexed by id ($0d=no-visual; no fork for a no-visual skill).",
        "MESSAGE: handler-driven descriptor ($dd6f/$dd70), NOT id-indexed -> no fork.",
        "NAME $41:$4539 (256 entries) from the real id $caea -> repoint, no fork.",
        "ENEMY AI $57: 148 id-reads, EXHAUSTIVELY classified -> 138 equality(<$DE)+5 windowed range "
        "gates+high-id sub-dispatch guarded by `cp $d9; ret nc`; ZERO mishandle a custom id; AI "
        "record reads use the shared $54 reader (covered by the keystone).",
    ],
}

# Byte-neutral feasibility of the keystone fork (proven this session: windows checked,
# FORK assembled with RGBDS and byte-executed for normal + custom ids).
FORK_FEASIBILITY = {
    "indexer_sites": ["$54:$5251", "$54:$5276", "$54:$529E"],
    "window": "all 3 are the identical 5 bytes `21 13 40 09 09` (ld hl,$4013; add hl,bc; add hl,bc)",
    "trampoline": "replace each with `call Fork` + nop + nop = `cd lo hi 00 00` (exactly 5 bytes, "
                  "byte-neutral 5-for-5). No interior branch targets land in any window (verified).",
    "registers": "readers don't re-use bc after the indexer; Fork preserves bc anyway (push/pop).",
    "host_bank": "$54 has ~10550 free trailing bytes -> Fork routine + high pointer table + high "
                 "19B records all fit IN-BANK, so the pointer-deref chain stays in bank $54 "
                 "(near call, no bankswitch, no cross-bank reads).",
    "fork_routine": "ld a,c; cp $DE; jr nc,.custom; ld hl,$4013; add hl,bc; add hl,bc; ret; "
                    ".custom: push bc; sub $DE; ld c,a; ld b,0; ld hl,HIGH_PTR; add hl,bc; "
                    "add hl,bc; pop bc; ret  (24 bytes)",
    "proof": "RGBDS-assembled; mini-SM83 execution: normal ids byte-identical to vanilla "
             "($2B->$4069, $00->$4013); custom ids index the high table ($DE->HIGH+0, $E1->HIGH+6).",
    "entry5_bail": "DEFER. $535F (entry 5) is a minor side-power reader not on the heal/common-"
                   "attack path (hw Test C). Leave its >=$d6 bail as-is for the first custom skills; "
                   "fork it later only for a side-power custom skill. Its window ($535F..$5367) is "
                   "also jump-in-clear if/when needed.",
    "verdict": "KEYSTONE FORK IS BYTE-NEUTRALLY IMPLEMENTABLE. S2d is shovel-ready: fork these 3 "
               "sites + add in-bank high tables, then MP (3 sites), sound (1 site), name (repoint).",
}


def main():
    write = True
    do_print = "--print" in sys.argv
    rom = ROM_PATH.read_bytes()

    def gbaddr(o):
        b = o // 0x4000
        return (0x4000 + (o % 0x4000)) if b > 0 else o

    def win(o, n):
        out = []
        i, pc = o, gbaddr(o)
        for _ in range(n):
            if i >= len(rom):
                break
            t, ln = decode(rom, i, pc)
            out.append((pc, t))
            i += ln
            pc = (pc + ln) & 0xFFFF
        return out

    def fileoff(bank, addr):
        return bank * 0x4000 + (addr - 0x4000 if bank > 0 else addr)

    # ---- self-check load-bearing anchors (abort on drift) -----------------
    def need(bank, addr, expect, what):
        got = win(fileoff(bank, addr), len(expect))
        got_txt = [t for _, t in got]
        if got_txt[:len(expect)] != expect:
            sys.stderr.write(f"SELF-CHECK FAILED ({what}) @ ${bank:02X}:${addr:04X}\n"
                             f"  expected {expect}\n  got      {got_txt[:len(expect)]}\n")
            sys.exit(1)

    need(0x54, 0x535F, ["ld a, [$db4c]", "cp $d5", "jr z, $539d", "jr nc, $53a6"],
         "magnitude divert")
    need(0x54, 0x53A6, ["ld a, $00", "ld [$db4c], a", "ret"], "magnitude divert zeroes index")
    need(0x54, 0x5251, ["ld hl, $4013", "add hl, bc", "add hl, bc"], "record-ptr indexer")
    need(0x50, 0x6BC4, ["ld a, [$db4c]", "cp $e1", "jr z, $6be7"], "$e1 menu pseudo-id")
    need(0x52, 0x70E0, ["ld a, [$db8a]", "cp $52", "jr c, $710e", "cp $54"], "$52 window gate")
    need(0x52, 0x66D6, ["ld a, [$db8a]", "ld [$db4c], a"], "magnitude path re-derives index")
    need(0x52, 0x66F7, ["ld hl, $5401", "rst $10"], "magnitude path invokes record reader entry 1")

    # ---- scan every direct read of the working id $db8a -------------------
    lo, hi = WORKING_ID_VAR & 0xFF, (WORKING_ID_VAR >> 8) & 0xFF
    reads = [o for o in range(len(rom) - 2)
             if rom[o] == 0xFA and rom[o+1] == lo and rom[o+2] == hi]

    eq_max = 0
    eq_ge_custom = []        # equality checks against >= $DE (would catch custom ids)
    range_gates = []
    table_index = []
    by_bank = {}
    cat_count = {"equality": 0, "range": 0, "table_index": 0, "store_or_other": 0}

    for o in reads:
        bank = o // 0x4000
        by_bank[f"${bank:02X}"] = by_bank.get(f"${bank:02X}", 0) + 1
        w = win(o, 8)
        classified = "store_or_other"
        for k in range(1, len(w) - 1):
            _, t = w[k]
            if t.startswith("cp $"):
                val = int(t.split("$")[1].split()[0], 16)
                nb = w[k + 1][1]
                if nb.startswith(("jr ", "jp ")) and (" c," in nb or " nc," in nb):
                    cc = "nc" if " nc," in nb else "c"
                    tgt = int(nb.split("$")[1], 16)
                    # where does a new id $DE land? $DE >= every observed threshold
                    # so carry is CLEAR: jr c NOT taken (fallthrough); jr nc taken.
                    if cc == "nc":
                        land = tgt
                    else:
                        land = w[k + 2][0] if k + 2 < len(w) else None
                    # does the landing path index a 222-table with the id soon?
                    risk = "shares-high-id-path"
                    if land is not None:
                        lo2 = fileoff(bank, land)
                        lw = win(lo2, 18)
                        for j in range(len(lw) - 1):
                            _, lt = lw[j]
                            if lt.startswith("ld hl, $") and 0x4000 <= int(lt.split("$")[1], 16) <= 0x7FFF:
                                # see if an add hl,bc/de follows within 4 instrs (id index)
                                for jj in range(j + 1, min(j + 5, len(lw))):
                                    if lw[jj][1] in ("add hl, bc", "add hl, de"):
                                        risk = f"INDEXES table @ ${int(lt.split('$')[1],16):04X} in landing path -> overshoot risk"
                                        break
                            if risk.startswith("INDEX"):
                                break
                    range_gates.append({
                        "loc": f"${bank:02X}:${gbaddr(o):04X}", "cp": f"${val:02X}",
                        "branch": f"jr {cc} ${tgt:04X}",
                        "new_id_lands": (f"${land:04X}" if land else "?"),
                        "landing_first": (win(fileoff(bank, land), 1)[0][1] if land else "?"),
                        "risk": risk,
                    })
                    classified = "range"
                else:
                    eq_max = max(eq_max, val)
                    if val >= FIRST_CUSTOM:
                        eq_ge_custom.append({"loc": f"${bank:02X}:${gbaddr(o):04X}", "cp": f"${val:02X}"})
                    classified = "equality"
                break
            if t in ("add hl, bc", "add hl, de"):
                table_index.append({"loc": f"${bank:02X}:${gbaddr(o):04X}", "instr": t})
                classified = "table_index"
                break
            if t.startswith(("ret", "jp ", "jr ", "call")) and k > 1:
                break
        cat_count[classified] += 1

    # ---- invariant: a custom id $DE matches NO vanilla equality check -----
    equality_safe = (eq_max < FIRST_CUSTOM) and not eq_ge_custom
    if not equality_safe:
        # not fatal, but surface it loudly: a vanilla check targets the custom range
        sys.stderr.write(f"NOTE: equality check(s) >= ${FIRST_CUSTOM:02X} exist "
                         f"(max ${eq_max:02X}); custom ids must avoid them: {eq_ge_custom}\n")

    out = {
        "_generator": "tools/map_skill_id_buckets.py (ROM data/DWM-original.gbc)",
        "_format": "Skill-ID bucketing audit (ROADMAP S2d foundation). Enumerates every "
                   "site the battle engine buckets/indexes the working skill id $db8a, and "
                   "the verified fork points + high-range special gates a custom id (>=$DE) "
                   "must survive. The $db8a equality gates are SAFE by the max-value invariant.",
        "_self_checks": [
            "magnitude divert bytes @ $54:$535F/$53A6",
            "record-ptr indexer @ $54:$5251",
            "$e1 menu pseudo-id @ $50:$6BC4",
            "$52 window gate @ $70E0",
            "magnitude path @ $52:$66D6 re-derives $db4c, invokes record reader entry 1 @ $66F7",
            f"equality-safe invariant: max vanilla equality vs $db8a = ${eq_max:02X} < ${FIRST_CUSTOM:02X}",
        ],
        "geography": {
            "working_id_var": f"${WORKING_ID_VAR:04X}",
            "record_index_var": f"${RECORD_IDX_VAR:04X} (re-derived from $db8a; ALSO reused as scratch)",
            "last_real_skill_id": f"${LAST_REAL_ID:02X}",
            "first_custom_id": f"${FIRST_CUSTOM:02X}",
            "custom_budget": f"${FIRST_CUSTOM:02X}..$FF",
            "id_is_byte": True, "hard_ceiling": 256, "n_records": N_RECORDS,
            "high_id_specials": {f"${k:02X}": v for k, v in HIGH_ID_SPECIALS.items()},
        },
        "summary": {
            "db8a_direct_reads": len(reads),
            "by_bank": dict(sorted(by_bank.items())),
            "classification": cat_count,
            "max_equality_value": f"${eq_max:02X}",
            "equality_gates_are_safe": equality_safe,
            "equality_checks_ge_custom": eq_ge_custom,
        },
        "hardware_verified_sameboy": {
            "_note": "User SameBoy session (2026-06-28); breakpoints confirm/correct the static read.",
            "record_index_is_skill_id": "CONFIRMED. bp $52:$66D9 fired casting Scorching (id $5E, "
                "handler $4932 per backtrace $66d9<-$6514<-$4932<-dispatch $6cda); the routine "
                "writes $db4c = the skill id. A custom id $DE would index $4013+2*222=$41CF "
                "(record DATA) => overshoot. This is the keystone the record fork fixes.",
            "s535f_is_minor_path": "CONFIRMED. bp $54:$5362 did NOT fire for Scorching/Zap/IceStorm "
                "(ids $5E/$10/$62) -> entry 5 ($535F) is a narrow side-power reader, not the main "
                "magnitude path. Main path is $66d6 -> entry 1 ($526e). De-prioritises $535F.",
            "run_command_correction": "bp $52:$4E3A did NOT fire on the player's Flee/Run menu "
                "command -> the menu Flee is a top-level command path (not the skill effect "
                "dispatch); skill id $DB 'RUN' / handler $4E3A is reached only via the skill "
                "system, not the menu. High-id FUNCTION dispatch is instead already proven by "
                "the shipped S45 patch (Scorch $DE / Smite $DF dispatch via FarSkillFork).",
        },
        "key_finding": "Of all db8a reads, the large majority are EQUALITY checks vs "
                       f"specific skill ids (max ${eq_max:02X}); a custom id >=${FIRST_CUSTOM:02X} "
                       "matches none, so they are auto-safe. The real audit surface is the "
                       "fixed-size TABLE indexers (fork_points) plus a few high-range "
                       "SPECIAL_GATES a custom id enters -- chiefly the $54:$535F magnitude "
                       "divert, which sends every custom id AWAY from record-driven power.",
        "fork_points": FORK_POINTS,
        "fork_feasibility": FORK_FEASIBILITY,
        "cast_pipeline": CAST_PIPELINE,
        "special_case_gates": SPECIAL_GATES,
        "db8a_range_gates": range_gates,
        "db8a_table_index_reads": table_index,
        "db4c_note": "db4c low-threshold gates ($50:$5CA4/$5D53/$5D81 cp $02; $52:$6A2E "
                     "cp $04; $57:$48D8/$493F cp $03) are SCRATCH reuse: they gate a 0-4 "
                     "value feeding sla/rl scaling, NOT the skill id. Not skill-id gates.",
    }
    if write:
        OUT_PATH.parent.mkdir(exist_ok=True)
        OUT_PATH.write_text(json.dumps(out, indent=2))

    # ---- console summary --------------------------------------------------
    print(f"Wrote {OUT_PATH}")
    print(f"  $db8a direct reads   : {len(reads)}  by bank {dict(sorted(by_bank.items()))}")
    print(f"  classification       : {cat_count}")
    print(f"  max equality value   : ${eq_max:02X}  -> equality-safe for custom: {equality_safe}")
    print(f"  range gates ($db8a)  : {len(range_gates)}")
    print(f"  REQUIRED fork points : {sum(1 for v in FORK_POINTS.values() if 'NONE' not in v['fork'] and 'NOT needed' not in v['fork'])} "
          f"(record[KEYSTONE], function[done], mp, anim*, sound)  *anim no-fork for no-visual skills")
    print(f"  special-case gates   : {len(SPECIAL_GATES)}  ($54:$535F is a MINOR reader, bails >= $d6; "
          f"keystone is the record-index fork, hw-confirmed via $66d6)")
    print("  self-checks          : PASS")
    if do_print:
        print("\n  -- $db8a range gates (new id $DE landing) --")
        for g in range_gates:
            print(f"    {g['loc']}  {g['cp']} {g['branch']:16} -> {g['new_id_lands']} "
                  f"[{g['landing_first']}]  {g['risk']}")


if __name__ == "__main__":
    main()
