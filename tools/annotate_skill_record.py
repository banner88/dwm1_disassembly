#!/usr/bin/env python3
"""
annotate_skill_record.py — S110 (ROADMAP P3.11, Iron Rule 6): the 19-byte skill
RECORD (bank $54 SkillRecordData) decoded by its READERS, written into the
disassembly as comments (both trees; zero byte impact).

The census (BATTLE_SKILL_SYSTEM §7 "Field map — S110 reader census"): the
records live in bank $54, so only bank-$54 code can read them; every read goes
through one of the three indexers (entries 0/1 = LoadB54_5249 / LoadB54_526e
with an offset in $db4e, entry 2 = CacheSkillRecordFields_5298 -> $dcfc-$dcff)
or entries 3-5 (which call entry 1 / entry 0). Every caller of entries 0/1 and
every consumer of the cached bytes is annotated here with what the field / bit
DOES at that site. Bits / bytes no site reads are named "not read" in the
SkillRecordData header.

Each site is (bank file, 1-based line of the instruction in the CLEAN tree,
comment). The comment is inserted above that line. The patched tree's site is
found by the instruction plus its 4 neighbouring code lines on each side
(comments / blanks ignored) — it must match exactly once, else the tool stops.
Idempotent: a site whose previous line already holds the comment is skipped.

USAGE
  python3 tools/annotate_skill_record.py            # plan
  python3 tools/annotate_skill_record.py --apply    # both trees + clean build md5 check
"""
import hashlib
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
TAG = '[S110 rec]'

# --- (bank, clean line, comment) ---------------------------------------------
SITES = [
    # record field reads through entry 0 ($5400) / entry 1 ($5401)
    ('050', 1925, 'record +2 target mode -> the battle menu: bit0 single = ask for a target'),
    ('050', 2094, 'record +4 = the BATTLE MP cost (8-bit; menu afford check; the field menu uses $07 SkillMPCostTable)'),
    ('050', 2838, 'record +10 of an ITEM skill: 1 = not usable in battle (seeds, books, medals)'),
    ('051', 1209, 'record +1 high nibble = the AI option-list TAG (1 attack / 2 status / 3 heal-support); low nibble never read'),
    ('051', 1803, 'record +1 high nibble = AI option-list tag (see SkillRecordData header)'),
    ('052', 3715, 'record +2 target mode: bit1 = a GROUP skill'),
    ('052', 5808, 'record +1 high nibble = AI option-list tag'),
    ('052', 9740, 'record +2 target mode: bit0 = single target'),
    ('053', 1486, 'record +4 = battle MP cost: act-time afford check (0 = free)'),
    ('053', 1835, 'record +4 = battle MP cost: DEDUCTED here (Farewell $32 then zeroes MP)'),
    ('053', 2080, 'record +4 = battle MP cost: deducted (floor 0)'),
    ('053', 2525, 'record +9 bit1 (meta-actions $A0-$A9 only): allowed in a boss battle ($db73), else re-rolled'),
    ('053', 5166, 'record +4 = the MP a TakeMagic target ($db04 bit0) soaks up (flags9 bit0 skills)'),
    ('057', 914, 'record +5 = AI ELEMENT: a resistance slot (1-27) the AI assumes; damage itself takes the element from the handler'),
    ('057', 1084, 'record +4 = battle MP cost: AI veto when the caster cannot pay'),
    ('057', 8404, 'record +6 = AI damage class (0 none / 4 spell / 5 breath): nonzero = "deals damage"'),
    ('057', 9945, 'record +7 flags7 -> $dd6b for the AI rules (bits 4/5/6 seal veto, bit7 rule $4B8C)'),
    ('057', 10031, 'record +7 flags7 -> $dd6b for the AI rules'),
    ('057', 10106, 'record +3 = the AI weight summed per category'),
    ('057', 11781, 'record +5 = AI element (resistance slot)'),
    ('058', 7341, 'record +2 target mode: &3 == 1 = single'),
    # cached flags ($5402 -> $dcfc +2, $dcfd +7, $dcfe +8, $dcff +9)
    ('052', 8770, 'flags7 bit7 (physical) vs BladeD (target +9 bit2 = defence level 4)'),
    ('052', 8886, 'flags9 bit4: may be a FOLLOW-UP action when the actor\'s +6 bit6 is set (writer not found; never seen in 11k measured events)'),
    ('052', 9068, 'target mode &3 == 1: single target, else the group loop steps every victim'),
    ('052', 11424, 'target mode bit4 (aimed at the foes) + target Imitate (+8 bit3) -> flags9 bit2 decides'),
    ('052', 11438, 'flags9 bit2: Imitate turns it back ("gets even!" $D3), else "can\'t get even!" $D4'),
    ('052', 11466, 'flags7 bit6 spell / bit5 dance / bit4 breath -> which seal applies (StopSpell or side +0 bit3 / DanceShut / MouthShut)'),
    ('053', 1266, 'flags7 bit3: keeps its committed target (no act-time re-resolve)'),
    ('053', 1400, 'target mode bit0: single target -> dead-target redirect scan'),
    ('053', 1510, 'flags7 bit6/5/4 = spell / dance / breath: the "not enough MP" verb ($F7 casts / $F9 dances / $F8 spits)'),
    ('053', 1541, 'flags7 bit6 spell: side +0 bit3 "spell was broken" ($1F) / StopSpell (+3 bit0) "blocked" ($1E); bit5 dance: DanceShut ($21); bit4 breath: MouthShut ($20)'),
    ('053', 2135, 'flags7 bit6/5/4: the same seal checks (CmpBtlC_4b92)'),
    ('053', 3567, 'flags8 bit4: an attacker with $db42 &3 (ChargeUP armed) "attacks with full force!" ($67)'),
    ('053', 3635, 'flags7 bit7 (physical): a target with $db42 bit5 grabs an ally as a shield ($6C)'),
    ('053', 3704, 'flags9 bit5: "But it doesn\'t reach X!" ($C1) vs an airborne target (+6 &$0C, HighJump)'),
    ('053', 3725, 'flags7 bit4 (breath): a side with +0 bit6 (SuckAll) "absorbs the attack!" ($81)'),
    ('053', 3802, 'flags8 bit1: Cover / Guardian redirect to the protector ($80)'),
    ('053', 3870, 'flags7 bit7 (physical): the $db42 bit5 shield grab'),
    ('053', 3909, 'flags7 bit4 (breath): TailWind (+4 bit6) "the wind reflects the attack!" ($7D) — not SuckAir $43 / SuckAll $8F'),
    ('053', 3939, 'flags8 bit0: MagicBack / Bounce (+4 & $22) "wall of light reflects the spell" ($7B/$7C)'),
    ('053', 4017, 'flags8 bit7: a target with $db42 bit7 "easily dodges" ($6E)'),
    ('053', 4045, 'flags8 bit1: Cover / Guardian redirect'),
    ('053', 4126, 'flags8 bit2: an IRON target (+7 &$C0, Ironize) makes the action fail ($BA)'),
    ('053', 4194, 'flags7 bit7 (physical) vs an airborne target (+6 bit2): "doesn\'t reach" ($C1)'),
    ('053', 4211, 'flags7 bit1 (physical): Surround (+3 bit1) 62.5 % miss, then +7 &3 37.5 % miss'),
    ('053', 4246, 'flags8 bit7: DODGE-able (Dodge status 50 %, else the AGL ladder)'),
    ('053', 4388, 'flags8 bits4-6: critical / TwinHits / ChargeUP family'),
    ('053', 4401, 'flags8 bit4: may land a CRITICAL hit ($79 / $7A by side)'),
    ('053', 4496, 'flags8 bit5: doubled by TwinHits (attacker +3 bit2)'),
    ('053', 4550, 'flags8 bit6: ChargeUP armed (+6 bit0) -> x2-2.5 (SaveBtlC_5db1)'),
    ('053', 4569, 'flags7 bit4 (breath), ids $5C-$63: SuckAir charge (+6 bit4) -> x2-2.5'),
    ('053', 4633, 'flags7 bit7 (physical): BladeD (defence level 4) halves it'),
    ('053', 4643, 'flags7 bit0: Defence (level 1) halves, StrongD (level 2) /10'),
    ('053', 4680, 'flags7 bit7 (physical) vs target +8 bit2: doubled (not $3C/$3E)'),
    ('053', 5129, 'flags7 bit4 (breath) vs TailWind (+4 bit6): reflected unless SuckAir $43 / SuckAll $8F'),
    ('053', 5156, 'flags9 bit0: a TakeMagic target gains this skill\'s battle MP cost'),
    ('053', 5435, 'target mode bit0: single target'),
    ('053', 5606, 'flags9 bit3: a landed hit may SNAP a confused target out (§15.8c)'),
    ('053', 7217, 'flags8 bit0: MagicBack / Bounce reflection (second site)'),
]


def code(lines, i):
    """Index-safe: is line i a code line (not blank / comment / label)?"""
    s = lines[i].strip()
    return bool(s) and not s.startswith(';') and not re.match(r'^[A-Za-z_][\w.]*:', s)


def signature(L, i, k=4):
    """(4 code lines before, the line, 4 code lines after), comments dropped."""
    before, j = [], i - 1
    while j >= 0 and len(before) < k:
        if code(L, j):
            before.insert(0, L[j].split(';')[0].strip())
        j -= 1
    after, j = [], i + 1
    while j < len(L) and len(after) < k:
        if code(L, j):
            after.append(L[j].split(';')[0].strip())
        j += 1
    return tuple(before), L[i].split(';')[0].strip(), tuple(after)


def find(L, sig):
    hits = []
    for i in range(len(L)):
        if L[i].split(';')[0].strip() == sig[1] and signature(L, i) == sig:
            hits.append(i)
    return hits


def header_lines():
    return [
        '; S110 FIELD MAP — reader census (tools/annotate_skill_record.py; every read of',
        '; a record goes through entries 0-5 of this bank; each reader site carries a',
        '; "[S110 rec]" comment; BATTLE_SKILL_SYSTEM §7):',
        ';   +0  NOT READ (a serial number; no reader in the ROM)',
        ';   +1  hi nibble = AI option-list TAG (banks $51/$52 -> $DC64 lists: 1 attack,',
        ';       2 status, 3 heal/support; 8 = item); lo nibble NOT READ',
        ';   +2  target mode: bit0 single, bit1 group; bit4 foes, bit5 allies, bit6 self',
        ';       (battle menu, group loop, redirects; the actual pick is per-skill code',
        ';       in bank $58 BtlSkillTargetDispatch_401d)',
        ';   +3  AI weight (bank $57 only)',
        ';   +4  BATTLE MP cost, 8-bit (menu afford $50, act-time afford + deduct $53,',
        ';       AI veto $57, TakeMagic soak); the FIELD menu reads $07 SkillMPCostTable',
        ';   +5  AI element = resistance slot 1-27 (bank $57 only; damage takes the',
        ';       element from the handler, BATTLE_SKILL_SYSTEM §15.3)',
        ';   +6  AI damage class 0/4/5 (bank $57 only: nonzero = "deals damage")',
        ';   +7  flags7: b0 cut by Defence/StrongD; b1 physical (Surround misses);',
        ';       b2 NOT READ; b3 keeps its target; b4 BREATH (MouthShut, TailWind,',
        ';       SuckAll, SuckAir x2); b5 DANCE (DanceShut); b6 SPELL (StopSpell);',
        ';       b7 PHYSICAL contact (airborne miss, BladeD, shield grab) — AI reads b4-b7',
        ';   +8  flags8: b0 reflected by MagicBack/Bounce; b1 Cover/Guardian redirect;',
        ';       b2 stopped by an iron target; b3 NOT READ; b4 critical hits (+ the',
        ';       ChargeUP "full force" line); b5 doubled by TwinHits; b6 ChargeUP x2-2.5;',
        ';       b7 dodge-able',
        ';   +9  flags9: b0 TakeMagic soaks its MP; b1 (meta-actions only) allowed vs a',
        ';       boss; b2 Imitate turns it back; b3 snaps confusion; b4 follow-up action;',
        ';       b5 cannot reach an airborne target; b6/b7 NOT READ',
        ';   +10 items only: 1 = not usable in battle (battle item menu, entry 5)',
        ';   +11/+13 party power min/range, +15/+17 enemy power min/range (u16)',
        ';   (The old "+5 status_id" / "+9 anim" names above are superseded.)',
    ]


def annotate(path, clean_lines, write):
    L = open(path).read().split('\n')
    patched = 'patches' in path
    bank = re.search(r'bank_(\w+)\.asm', path).group(1)
    if not patched and any(TAG in l for l in L):
        # SITES carry pre-annotation clean line numbers: once applied they no
        # longer point at the sites, so an annotated clean file is left alone
        print(f'{path}: already annotated ({sum(TAG in l for l in L)} comments)')
        return
    done = skipped = 0
    inserts = []
    for b, line, text in SITES:
        if b != bank:
            continue
        ci = line - 1
        sig = signature(clean_lines, ci)
        if not patched:
            if clean_lines[ci].split(';')[0].strip() == '':
                raise SystemExit(f'{path}:{line} is not an instruction')
            hits = [ci]
        else:
            hits = find(L, sig)
            if len(hits) != 1:
                raise SystemExit(f'{path}: site {b}:{line} ({sig[1]}) matched {len(hits)} times')
        i = hits[0]
        com = f'    ; {TAG} {text}'
        if i > 0 and TAG in L[i - 1]:
            skipped += 1
            continue
        inserts.append((i, com))
    for i, com in sorted(inserts, reverse=True):
        L.insert(i, com)
        done += 1
    if bank == '054':
        k = next(i for i, l in enumerate(L) if l.startswith('SkillRecordData:'))
        if not any('S110 FIELD MAP' in l for l in L[k - 40:k]):
            # insert just above the label — or, in the patched tree, above the
            # compiler region's BEGIN marker (a header inside the region would
            # be dropped by build_project --apply and split its comment)
            j = k
            while j > 0 and L[j - 1].startswith(';') and '=====' not in L[j - 1] \
                    and not L[j - 1].startswith('; @BUILD_PROJECT BEGIN'):
                j -= 1
            if j > 0 and L[j - 1].startswith('; @BUILD_PROJECT BEGIN'):
                j -= 1
            L[j:j] = header_lines()
            done += 1
        L = _bank54_entries(L)
    print(f'{path}: {done} comment block(s) inserted, {skipped} already present')
    if write:
        open(path, 'w').write('\n'.join(L))


def _bank54_entries(L):
    """Entries 3/4/5 by address (the old comment named $535F 'SkillMagnitudeBySide'
    — that routine is entry 3, $52C7). Labels in the dispatch rows, comments."""
    rep = {
        '    dw $52C7                          ; Entry 3':
            '    dw $52C7                          ; Entry 3 = SkillPowerBySide (S110: was misnamed entry 5)',
        '    dw $5313                          ; Entry 4':
            '    dw $5313                          ; Entry 4 = byte-identical twin of entry 3 (no caller found)',
        '    dw $535F                          ; Entry 5':
            '    dw $535F                          ; Entry 5 = battle ITEM target lookup (+10 usable, +2 mode; S110)',
    }
    out = []
    for l in L:
        out.append(rep.get(l.rstrip(), l))
    for i, l in enumerate(out):
        if l.startswith('; SkillMagnitudeBySide (dispatch entry 5, $535F).') :
            out[i] = ('; SkillPowerBySide (dispatch entry 3, $52C7 — S110 correction: this comment '
                      'said entry 5 / $535F).')
    return out


def clean_md5():
    dis = os.path.join(REPO, 'disassembly')
    arts = ('game.o', 'game.gbc', 'game.sym', 'game.map')
    for f in arts:
        try:
            os.remove(os.path.join(dis, f))
        except FileNotFoundError:
            pass
    subprocess.run(['make'], cwd=dis, check=True, capture_output=True)
    m = hashlib.md5(open(os.path.join(dis, 'game.gbc'), 'rb').read()).hexdigest()
    for f in arts:
        try:
            os.remove(os.path.join(dis, f))
        except FileNotFoundError:
            pass
    return m


def main():
    write = '--apply' in sys.argv
    banks = sorted({b for b, _l, _t in SITES} | {'054'})
    clean = {}
    for b in banks:
        p = os.path.join(REPO, 'disassembly', f'bank_{b}.asm')
        cl = open(p).read().split('\n')
        if any(TAG in l for l in cl):
            cl = subprocess.run(['git', 'show', f'HEAD:disassembly/bank_{b}.asm'], cwd=REPO,
                                capture_output=True, text=True, check=True).stdout.split('\n')
        clean[b] = cl
    for b in banks:
        for tree in ('disassembly', 'patches'):
            p = os.path.join(REPO, tree, f'bank_{b}.asm')
            if os.path.exists(p):
                annotate(p, clean[b], write)
    if write:
        m = clean_md5()
        print('clean build md5', m, 'OK' if m == ORIGINAL_MD5 else 'MISMATCH')
        if m != ORIGINAL_MD5:
            sys.exit(1)


if __name__ == '__main__':
    main()
