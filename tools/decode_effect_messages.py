#!/usr/bin/env python3
"""Decode the battle skill-effect MESSAGE system (ROADMAP S2c).

What this proves (all verified against ROM bytes; see BATTLE_SKILL_SYSTEM.md "Effect
message/script system"):

A skill handler in bank $52 sets a 16-bit "effect descriptor" via the $52:$5460-$54F8
setter family:
    $DD6F = effect-class bitfield (e.g. Blaze $A8)
    $DD70 = LOW  byte of the selector  ($82 for Blaze)
    $DD71 = HIGH byte of the selector  ($B8 for Blaze)
The selector ("$bXXX") is NOT a memory address. It packs TWO 8-bit message ids:
    LOW  byte = the "effect happens" message id (damage / status / heal)
    HIGH byte = the "effect fails"   message id (miss / resisted / no effect)

The battle effect player (bank $53 `jr_053_5a6f`, a frame-stepped state machine)
hands these to bank $4c entry 0 (`LoadB4c_42d1`) with a SMALL mode (0 or 1) and the
chosen byte as the id, then bank $4c runs the shared text VM (`CallTextEngine`,
ROM0 $05B6) which resolves the real string through the two-level table at
`$4c:$4009` (`SaveBankAndSwitch`, ROM0 $092F):
    subtable = [ $4c : $4009 + mode*2 ]      ; mode 0 -> $4019  (the BATTLE-MESSAGE table)
    string   = [ $4c : subtable + id*2 ]
So a battle "effect script" is a standard text-VM message string ($F0-terminated
sections, DTE-compressed, standard control codes). The actual on-screen VISUAL
animation and the SOUND are SEPARATE systems keyed by skill id ($db8a), not by this
selector: visual = bank $5f entry 6 dispatch -> per-skill anim-index tables
($5f:$58dd/$59c3/$5aa9) -> routine-pointer table $5f:$58bd; sound = bank $55 entry 1
-> per-skill SFX table ($55:$4070) -> PlaySoundEffect.

This tool resolves every skill's selector -> (hit msg, miss msg), dumps the mode-0
message table, and writes extracted/effect_messages.json.

Usage:
    python3 tools/decode_effect_messages.py            # regenerate the JSON
    python3 tools/decode_effect_messages.py --selftest # verify ROM anchors
"""
import json, os, sys, hashlib

ROM_MD5 = "1ca6579359f21d8e27b446f865bf6b83"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_PATH = os.path.join(ROOT, "data", "DWM-original.gbc")
SKILL_RECORDS = os.path.join(ROOT, "extracted", "skill_records.json")
OUT_PATH = os.path.join(ROOT, "extracted", "effect_messages.json")

CFG_BASE = 0x4009          # bank $4c config/mode-table base (= dispatch entry 4)
MSG_BANK = 0x4c

# ---- ROM access --------------------------------------------------------------
ROM = open(ROM_PATH, "rb").read()
def _off(bank, addr):
    return addr if bank == 0 else bank * 0x4000 + (addr - 0x4000)
def rd(bank, addr, n=1):
    o = _off(bank, addr); return ROM[o:o+n]
def rw(bank, addr):
    o = _off(bank, addr); return ROM[o] | (ROM[o+1] << 8)

# ---- text decode (charmap + DTE + battle control codes) ----------------------
sys.path.insert(0, os.path.join(ROOT, "dwm"))
import text as T  # TABLE, DTE, decode

# Control codes used by battle messages (handlers verified in bank $56):
#   $ED insert MONSTER name        $EC name marker (usually trailing)
#   $F1 reposition (line wrap)      $F2 clear+reposition
#   $F9 <slot> insert variable: slot $00 = target name, $10 = a number, etc.
#   $FC insert name-with-icon helper ($56:$4835 -> $0954/$0d78)
#   $F0 end of section
SLOTS = {0x00: "{name}", 0x10: "{num}"}       # observed insert slots
def decode_section(bank, addr, maxlen=80):
    """Decode one $F0-terminated message section. Returns (text, n_bytes, raw)."""
    out, raw, i = [], [], 0
    while i < maxlen:
        b = rd(bank, addr + i, 1)[0]; raw.append(b); i += 1
        if b == 0xF0:
            break
        if b == 0xF9:                          # insert variable: consume 1 slot byte
            slot = rd(bank, addr + i, 1)[0]; raw.append(slot); i += 1
            out.append(SLOTS.get(slot, "{%d}" % slot)); continue
        if b == 0xFC:   out.append("{name}"); continue
        if b == 0xED:   out.append("{mon}");  continue
        if b == 0xEC:   continue               # trailing name marker (no glyph)
        if b == 0xF1:   out.append(" ");       continue
        if b == 0xF2:   continue
        if b in T.TABLE: out.append(T.TABLE[b])
        elif b in T.DTE: out.append(T.DTE[b])
        else:            out.append(f"[{b:02X}]")
    return "".join(out), i, raw

def msg_for_id(idbyte, mode=0):
    """Resolve a message id through the two-level table and decode it."""
    sub = rw(MSG_BANK, CFG_BASE + mode * 2)
    ptr = rw(MSG_BANK, (sub + idbyte * 2) & 0xFFFF)
    text, n, raw = decode_section(MSG_BANK, ptr)
    return ptr, text, raw

# ---- descriptor-setter family ($52:$5460-$54F8) ------------------------------
# addr -> (name, dd6f, hardcoded_selector_or_None)
SETTERS = {
    0x5460: ("BattleFunc_5460", 0x80, None),
    0x5469: ("BattleFunc_5469", 0x88, None),
    0x5475: ("BattleFunc_5475", 0x84, None),
    0x5481: ("BattleFunc_5481", 0x93, None),
    0x548d: ("SetSkillAnimFlag", 0x40, None),     # flag-only, no message
    0x54bd: ("SetSkillAnimB", 0x90, None),
    0x54a1: ("LoadBattle_54a1", 0xd0, None),
    0x54af: ("LoadBattle_54af", 0x98, None),
    0x54d2: ("LoadBattle_54d2", 0x98, None),
    0x54e7: ("SetHLBattle_54e7", 0xa8, 0xb882),   # forces hl=$b882
    0x54ea: ("SetHLBattle_54ea", 0xa8, None),     # entry AFTER ld hl,$b882 -> uses caller hl
    0x54f8: ("LoadBattle_54f8", 0xa0, None),
}

# Verified message-selector space (BATTLE_SKILL_SYSTEM.md): the HIGH byte (the
# "miss/fail" message id) always lands in the $b6..$bc band, and the two bytes
# differ. Values with low==high (e.g. $b0b0/$b2b2/$b5b5/$9191) are a:a FLAG params
# for a different $DD6F path, and $dbXX/$dcXX/$ddXX/etc. that some handlers load are
# battle-RAM pointers, not selectors. We only accept a value as a message selector
# when it fits the verified band; everything else is classified, not mis-decoded.
def is_message_selector(v):
    if v is None:
        return False
    lo, hi = v & 0xFF, v >> 8
    return (0xb6 <= hi <= 0xbc) and (lo != hi)

def classify_value(v):
    if v is None:                       return "none"
    lo, hi = v & 0xFF, v >> 8
    if is_message_selector(v):          return "message"
    if lo == hi:                        return "flag_aa"        # a:a param, not a ptr
    if hi in (0xdb, 0xdc, 0xdd, 0xc8):  return "ram_ptr"       # battle-RAM target
    return "param"

def extract_selector(handler_addr):
    """Disassemble a bank-$52 handler far enough to find its effect selector.
    Returns dict(selector, setter, dd6f, kind). selector is set ONLY when it is a
    real message selector ($b6xx-$bcxx, low!=high); other descriptor values are
    classified via `kind` so callers never decode a non-message value as text."""
    addr = handler_addr
    last_hl = None
    for _ in range(48):                       # handlers are short and straight-line
        op = rd(0x52, addr, 1)[0]
        if op == 0x21:                        # ld hl, nn
            last_hl = rw(0x52, addr + 1); addr += 3; continue
        if op in (0xcd, 0xc3):                # call nn / jp nn
            tgt = rw(0x52, addr + 1)
            if tgt in SETTERS:
                name, dd6f, hard = SETTERS[tgt]
                if dd6f == 0x40:
                    return {"selector": None, "setter": name, "dd6f": dd6f, "kind": "flag_only"}
                val = hard if hard is not None else last_hl
                sel = val if is_message_selector(val) else None
                return {"selector": sel, "setter": name, "dd6f": dd6f,
                        "kind": classify_value(val)}
            if op == 0xc3:                    # unconditional jp to non-setter: follow
                addr = tgt; continue
            addr += 3; continue               # call to damage-calc etc.: step over
        if op == 0xc9:                        # ret
            break
        addr += _insn_len(op, rd(0x52, addr, 3))
    val = last_hl
    return {"selector": (val if is_message_selector(val) else None),
            "setter": None, "dd6f": None, "kind": classify_value(val)}

def _insn_len(op, b3):
    """Minimal SM83 instruction length for linear scanning."""
    if op == 0xcb: return 2
    # 3-byte: ld hl/de/bc/sp,nn ; jp ; call ; ld [nn],a / ld a,[nn] ; ld [nn],sp
    if op in (0x01,0x11,0x21,0x31,0xc3,0xcd,0xca,0xda,0xc2,0xd2,0xea,0xfa,0x08,
              0xcc,0xdc,0xc4,0xd4): return 3
    # 2-byte: immediates, ldh, jr, rel, add sp
    if op in (0x06,0x0e,0x16,0x1e,0x26,0x2e,0x36,0x3e,0xc6,0xce,0xd6,0xde,0xe6,
              0xee,0xf6,0xfe,0x18,0x20,0x28,0x30,0x38,0xe0,0xf0,0xe8,0xf8): return 2
    return 1

# ---- build -------------------------------------------------------------------
def build():
    recs = json.load(open(SKILL_RECORDS))["records"]

    # 1) message-id space actually referenced by any selector
    skills = []
    used_ids = set()
    selectors_seen = {}
    for r in recs:
        ha = r.get("handler_addr")
        info = extract_selector(int(ha.strip("$"), 16)) if ha else {"selector": None}
        sel = info.get("selector")
        entry = {"id": r["id"], "name": r["name"], "kind": r.get("kind"),
                 "handler": ha, "setter": info.get("setter"),
                 "dd6f": (f"0x{info['dd6f']:02x}" if info.get("dd6f") is not None else None),
                 "descriptor_kind": info.get("kind"),
                 "selector": (f"0x{sel:04x}" if sel else None)}
        if sel:
            lo, hi = sel & 0xFF, sel >> 8
            _, hit, _ = msg_for_id(lo); _, miss, _ = msg_for_id(hi)
            entry.update(hit_msg_id=f"0x{lo:02x}", hit_msg=hit,
                         miss_msg_id=f"0x{hi:02x}", miss_msg=miss)
            used_ids.update([lo, hi])
            selectors_seen.setdefault(sel, []).append(r["name"])
        skills.append(entry)

    # 2) the mode-0 message table. Dump EVERY id (0..255) whose pointer lands in the
    #    bank-$4c message string region; this is the full battle-message corpus,
    #    independent of which skills are statically resolved above.
    MSG_REGION = range(0x4900, 0x7000)        # string area of bank $4c (after the tables)
    sub0 = rw(MSG_BANK, CFG_BASE)             # = $4019
    msg_table = {}
    for idb in range(0x100):
        ptr = rw(MSG_BANK, (sub0 + idb * 2) & 0xFFFF)
        if ptr not in MSG_REGION:
            continue                          # unused id -> points outside the corpus
        text, n, raw = decode_section(MSG_BANK, ptr)
        if not text.strip("{}namenum /!?.'"):  # empty / pure-control: skip noise
            continue
        msg_table[f"0x{idb:02x}"] = {
            "addr": f"$4c:{ptr:04x}", "used_by_selector": idb in used_ids,
            "text": text, "bytes": " ".join(f"{x:02x}" for x in raw)}

    # 3) accept-test artifact: Blaze ($b882) fully decoded to bytes
    blaze = next(s for s in skills if s["name"] == "Blaze")
    blaze_decoded = {
        "skill": "Blaze (id 0)", "handler": "$52:$41CD",
        "setter": "$52:$54E7 (SetHLBattle_54e7) -> $DD6F=$A8, $DD70/71=$B882",
        "selector": "0xb882 = (hit id $82, miss id $b8)",
        "hit": {"id": "0x82", **{k: v for k, v in
                 zip(("addr", "text", "bytes"),
                     (lambda p: (f"$4c:{p[0]:04x}", p[1],
                                 " ".join(f"{x:02x}" for x in p[2])))(msg_for_id(0x82)))}},
        "miss": {"id": "0xb8", **{k: v for k, v in
                  zip(("addr", "text", "bytes"),
                      (lambda p: (f"$4c:{p[0]:04x}", p[1],
                                  " ".join(f"{x:02x}" for x in p[2])))(msg_for_id(0xb8)))}},
        "visual_anim": "bank $5f entry 6 ($5f:$52F0) dispatch by skill id 0 -> $5f:$53A4",
        "sound": "bank $55 entry 1 ($55:$4026) -> per-skill SFX table $55:$4070",
    }

    out = {
        "_generator": {
            "tool": "tools/decode_effect_messages.py",
            "rom_md5_source": ROM_MD5,
            "roadmap_item": "S2c (effect message/script format)",
            "selector_model": "16-bit descriptor $DD70/71 = (low=hit msg id, high=miss msg id)",
            "resolution": "mode-0 two-level table: [$4c:$4009]=$4019; string=[$4019+id*2]",
            "message_vm": "shared text VM CallTextEngine $00:$05B6 / SaveBankAndSwitch $00:$092F",
            "visual_is_separate": "on-screen anim = bank $5f entry 6 by skill id; sound = bank $55 entry 1",
            "n_skills": len(skills),
            "n_message_ids": len(msg_table),
        },
        "descriptor_setters": {f"$52:{a:04x}": {"name": n, "dd6f": f"0x{d:02x}",
                                "hardcoded_selector": (f"0x{h:04x}" if h else None)}
                               for a, (n, d, h) in sorted(SETTERS.items())},
        "selectors_in_use": {f"0x{s:04x}": sorted(set(names))
                             for s, names in sorted(selectors_seen.items())},
        "message_table_mode0": {"base": "$4c:4019", "index": "8-bit message id",
                                "entries": msg_table},
        "blaze_decoded": blaze_decoded,
        "skills": skills,
    }
    return out

def selftest():
    """Verify the ROM and a few message anchors that pin the whole model."""
    assert hashlib.md5(ROM).hexdigest() == ROM_MD5, "ROM md5 mismatch"
    anchors = {0x82: "takes", 0xb8: "Has no effect", 0xb6: "Misses",
               0x84: "wound heals", 0xcc: "sent to sleep", 0xe8: "finished"}
    ok = True
    for idb, needle in anchors.items():
        _, text, _ = msg_for_id(idb)
        hit = needle in text
        ok &= hit
        print(f"  id 0x{idb:02x}: {'OK ' if hit else 'FAIL'} expect ~{needle!r:18} got {text!r}")
    # Blaze selector must extract to $b882
    sel = extract_selector(0x41CD)["selector"]
    print(f"  Blaze selector: {'OK ' if sel == 0xb882 else 'FAIL'} 0x{sel:04x}")
    ok &= (sel == 0xb882)
    print("SELFTEST:", "PASS" if ok else "FAIL")
    return ok

# Validation reads the FAQ data asset (extracted/skill_faq.json, built by
# tools/build_skill_faq.py) as the SINGLE source of truth, rather than a hardcoded list.
# Each skill's FAQ effect CLASS maps deterministically to the message TYPE its decoded
# battle message should have (the class->selector bridge documented in
# BATTLE_SKILL_SYSTEM.md S9). Only classes that are unambiguous among resolved skills are
# asserted; mixed/ambiguous classes (e.g. Sacrifice, Support) are skipped, not failed.
SKILL_FAQ = os.path.join(ROOT, "extracted", "skill_faq.json")
CLASS_TYPE = {
    "Blaze": "damage", "Bang": "damage", "IceBolt": "damage", "Bolt": "damage",
    "Fireball": "damage", "Infernos": "damage", "Flame": "damage", "Blizzard": "damage",
    "MegaMagic": "damage", "GigaSlash": "damage", "Attack": "damage",
    "Beat": "death", "Sleep": "sleep", "Sap": "defense_down",
    "OddDance": "mp_steal", "Slow": "agility_down", "StopSpell": "spell_seal",
    "Surround": "hit_down",
}
def _classify_msg(text):
    t = text.lower()
    if "takes" in t and "damage" in t:        return "damage"
    if "finished" in t:                        return "death"
    if "sent to sleep" in t:                   return "sleep"
    if "loses" in t and "defense" in t:        return "defense_down"
    if "mp is drained" in t:                   return "mp_steal"
    if "speed goes down" in t:                 return "agility_down"
    if "spells are all suspended" in t:        return "spell_seal"
    if "illusion engulfs" in t:                return "hit_down"
    if "wound heals" in t:                     return "heal"
    return "other"

def _faq_expect():
    """skill name -> expected message type, derived from skill_faq.json classes.
    Attack-hybrids (e.g. NapAttack = 'normal attack + tries to sleep') are tagged with a
    status CLASS but their on-screen hit message is the DAMAGE message, so they expect
    'damage' rather than the status type."""
    faq = json.load(open(SKILL_FAQ))["skills"]
    status_types = {"sleep", "death", "defense_down", "agility_down",
                    "mp_steal", "spell_seal", "hit_down"}
    exp = {}
    for name, rec in faq.items():
        cls = rec.get("class")
        if cls not in CLASS_TYPE:
            continue
        want = CLASS_TYPE[cls]
        if want in status_types and "attack" in rec.get("effect", "").lower():
            want = "damage"
        exp[name] = want
    return exp

def _crosscheck(skills):
    """Return (ok, total, fails) over resolved skills whose FAQ class is mapped."""
    by = {}
    for s in skills:                    # prefer the resolved entry on name collision
        if s["name"] not in by or s.get("hit_msg"):
            by[s["name"]] = s
    ok = total = 0; fails = []
    for name, want in _faq_expect().items():
        s = by.get(name)
        if not (s and s.get("hit_msg")):
            continue                    # skill not statically resolved -> skip (not a fail)
        total += 1
        got = _classify_msg(s["hit_msg"])
        if got == want: ok += 1
        else: fails.append(f"{name}[{want}]: got {got} ({s['hit_msg']!r})")
    return ok, total, fails

def validate():
    """Cross-check decoded messages against extracted/skill_faq.json (FAQ classes)."""
    ok, total, fails = _crosscheck(build()["skills"])
    print(f"FAQ CROSS-CHECK: {ok}/{total} resolved skills' messages match their FAQ class.")
    for f in fails: print("  MISMATCH", f)
    print("VALIDATE:", "PASS" if not fails else "FAIL")
    return not fails


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(0 if selftest() else 1)
    if "--validate" in sys.argv:
        sys.exit(0 if validate() else 1)
    data = build()
    # embed the FAQ cross-check tally in provenance
    vok, vtot, _ = _crosscheck(data["skills"])
    data["_generator"]["faq_crosscheck"] = f"{vok}/{vtot} resolved skills match their FAQ class (extracted/skill_faq.json)"
    json.dump(data, open(OUT_PATH, "w"), indent=2)
    print(f"wrote {OUT_PATH}")
    print(f"  skills={data['_generator']['n_skills']} "
          f"message_ids={data['_generator']['n_message_ids']} "
          f"selectors={len(data['selectors_in_use'])} "
          f"faq_crosscheck={vok}/{vtot}")
