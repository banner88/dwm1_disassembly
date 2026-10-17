#!/usr/bin/env python3
"""dump_dialogue.py — EVERY text the game can show, with where it lives
(S108, ROADMAP P3.10 part 3: "I want to be able to pull all dialogue so I can
inspect to see if it needs changes" — the editor's Dialogue tab reads the JSON).

1. TEXT IDS $0000-$09FF (NPC / story / system dialogue, 2,560 ids). The id ->
   (bank, address) resolution is MEASURED, not modelled: PyBoy stub-calls ROM0
   TextBankDispatch ($00:$0AD9, HL = id) on the original ROM for every id and
   reads the text engine's result ($C824 = bank, $C82D/$C82E = string). That
   covers the whole chain: the ROM0 cascade (high byte -> handler, TEXT_SYSTEM)
   AND each corpus bank's loader, which forwards the upper part of its index
   range to an OVERFLOW bank (e.g. bank $42 entry 0: index >= $71 -> bank $1A
   entry 0, index - $71). Measured S108: banks $42-$4B / $4E hold 1,383 ids,
   the overflow banks $1A $1B $1F $21 $22 $3F $18 $4F hold 1,177. The pre-S108
   text_id_map.json modelled this (fixed $400B table base, a guessed index
   rule, no overflow banks): 62 of its 2,061 entries matched; it is now derived
   from this file (dump_text_id_map.py; DOC_AUDIT S108).
2. TEXT TABLES that are not text ids: battle messages (bank $4C mode 0, 256),
   bank $41 message tables (field messages mode 2, item descriptions mode 9,
   misc mode 11, Watabou mode 12, item use mode 13, spell use mode 14), skill
   descriptions (bank $56 $6667, 256 — KEY_LESSONS S73b) and the 215 monster
   descriptions (bank $4D mode 1 — editable in the Monsters tab, S108).

A string ends at its first $F0. Control codes (bank $56 handler table $44CD,
read S108): $E8 takes 2 parameter bytes (sets the draw position), $E9 one (a
sound effect), $F9 one (insert: $00 / $10 / $20 / $30 = the inserted names of
the upgrade / join messages); the others none. The decoded `text` shows a new
box after $F7 as a blank line, line breaks as "\\n",
the speaker label (e.g. "King" or "*") before ":"; the wait arrow ($FA)
is not shown (every box but the last ends with it).

  pip install pyboy --break-system-packages
  python3 tools/dump_dialogue.py             # measure + write extracted/dialogue.json
  python3 tools/dump_dialogue.py --selftest  # JSON raw bytes == ROM (no PyBoy; verify check 5)
  python3 tools/dump_dialogue.py --redecode  # S120: re-decode with the measured map kept (no PyBoy)

S150 (ROADMAP P3.6 — editing the game's own text; TEXT_SYSTEM "Edited game text"):
  * every text id also records the POINTER SLOT the game reads it through —
    `table` (the per-id table SaveBankAndSwitch indexes: DE right after its
    level-1 read, hooked at $00:$0944 during the same stub call) and `index`
    ([$C823] there); bank = `bank`. An edited text is keyed by that slot (bank,
    table + 2 * index) — the engine hook looks it up there (PROJECT_COMPILER §2.58).
  * `inside` = the id whose string this one starts INSIDE (an alternate entry
    point the game uses — editing the outer line does not change it);
  * a string ends at its first $F0 that is NOT a control code's parameter byte
    (editor2/core/textmark.scan — the battle tutorial writes `$FB $F0`);
  * more tables: bank $4C modes 1-7 (treats / veils / not enough MP, commands,
    the BeastTail, the CREDITS and "TO BE CONTINUED"), bank $59 (the battle
    tutorial), bank $41 item names / personalities / the families' default
    names; each table carries `style` (textmark: 'box' / 'rows'), `group` (the
    editor's Text sub-tab) and `owner` (texts another tab edits).
"""
import hashlib
import io
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
ROM_PATH = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT = os.path.join(REPO, 'extracted', 'dialogue.json')
ORIGINAL_MD5 = '1ca6579359f21d8e27b446f865bf6b83'
TEXT_DISPATCH = 0x0AD9
STUB = 0xD700
N_IDS = 0xA00
MAX_LEN = 4096

CHARS = {i: str(i) for i in range(10)}
CHARS.update({0x24 + i: chr(65 + i) for i in range(26)})
CHARS.update({0x3E + i: chr(97 + i) for i in range(26)})
CHARS.update({0x5C: "'", 0x5D: '>', 0x5E: ',', 0x5F: '.', 0x60: ';', 0x61: '..',
              0x62: ' ', 0x63: '!', 0x64: '?', 0x9C: '-', 0xB6: '&', 0x9F: '*',
              0xA3: ':'})
CHARS.update({0x10 + i: f'<{n}>' for i, n in enumerate(
    ('slime', 'dragon', 'beast', 'bird', 'plant', 'bug', 'devil', 'zombie',
     'material', '???', 'spirit'))})
# S120: one-cell glyphs, not letter pairs (dwm/text.py has the note)
DTE = {0x65: '"', 0x66: "'l", 0x67: "'t", 0x68: "'s", 0x69: "'r", 0x6A: "'m",
       0x6B: "'y", 0x6C: "'v", 0x6D: "'d", 0x6E: "'e", 0x6F: "'c", 0x70: "'n",
       0x71: "'T"}
CHARS.update({0x96: '[', 0x97: ']', 0x9D: '~', 0x9E: '/', 0xA0: '(', 0xA1: ')',
              0xA2: '+', 0xA4: '\u2026'})
PARAMS = {0xE8: 2, 0xE9: 1, 0xF8: 1, 0xF9: 1, 0xFB: 1, 0xFC: 1}   # S120: + $F8 / $FB / $FC (bank $56 TextCodeTable)

# (source, bank, table address, count, title, style, group, owner)
#   style = editor2/core/textmark style ('box': $EF $EE lines, ▼ boxes; 'rows': $F1 lines)
#   group = the editor's Text sub-tab; owner = another tab edits these (None = the Text tab)
TABLES = [
    ('battle_message', 0x4C, 0x4019, 253, 'battle messages (bank $4C mode 0; id $FD = the custom skills\' own line, ids 254 / 255 = mode 1 rows 0 / 1)', 'rows', 'battle', None),
    ('battle_effect', 0x4C, 0x4215, 19, 'battle: treats, veils of light, not enough MP (bank $4C mode 1)', 'rows', 'battle', None),
    ('battle_command', 0x4C, 0x423B, 7, 'battle: commands and skills that cannot be used (bank $4C mode 2)', 'rows', 'battle', None),
    ('battle_beasttail', 0x4C, 0x4249, 9, 'battle: the BeastTail (bank $4C mode 3)', 'rows', 'battle', None),
    ('battle_beasttail_result', 0x4C, 0x425B, 4, 'battle: the BeastTail, its result (bank $4C mode 4)', 'rows', 'battle', None),
    ('misc_message', 0x41, 0x49CD, 37, 'battle / level-up messages (bank $41 mode 11)', 'rows', 'battle', None),
    ('spell_use_message', 0x41, 0x4A7B, 12, 'spell use messages (bank $41 mode 14)', 'rows', 'battle', None),
    ('battle_tutorial', 0x59, 0x5301, 7, 'the battle tutorial (bank $59 mode 0)', 'box', 'battle', None),
    ('battle_tutorial_name', 0x59, 0x530F, 3, 'the battle tutorial: names (bank $59 mode 1)', 'rows', 'battle', None),
    ('battle_tutorial_menu', 0x59, 0x5315, 14, 'the battle tutorial: the menus (bank $59 mode 2)', 'box', 'battle', None),
    ('item_name', 0x41, 0x48E7, 44, 'item names (bank $41 mode 8)', 'rows', 'items', None),
    ('item_description', 0x41, 0x493F, 44, 'item descriptions (bank $41 mode 9)', 'rows', 'items', None),
    ('item_use_message', 0x41, 0x4A1B, 48, 'item use messages (bank $41 mode 13)', 'rows', 'items', None),
    ('field_message', 0x41, 0x4101, 113, 'field messages and menu words (bank $41 mode 2)', 'rows', 'menus', None),
    ('personality', 0x41, 0x4997, 27, 'personalities (bank $41 mode 10)', 'rows', 'menus', None),
    ('family_name', 0x41, 0x41E3, 160, "the families' default names (bank $41 mode 3; 16 per family)", 'rows', 'menus', None),
    ('watabou_message', 0x41, 0x4A17, 2, 'Watabou (bank $41 mode 12)', 'rows', 'menus', None),
    ('credits_role', 0x4C, 0x4263, 27, 'the credits: roles (bank $4C mode 5)', 'rows', 'credits', None),
    ('credits_name', 0x4C, 0x4299, 27, 'the credits: names (bank $4C mode 6)', 'rows', 'credits', None),
    ('credits_end', 0x4C, 0x42CF, 1, '"TO BE CONTINUED" (bank $4C mode 7)', 'rows', 'credits', None),
    ('skill_description', 0x56, 0x6667, 256, 'skill descriptions (bank $56)', 'rows', 'skills', 'Skills'),
    ('monster_description', 0x4D, 0x420B, 215, 'monster descriptions (bank $4D mode 1)', 'rows', 'monsters', 'Monsters'),
]
SBAS_LEVEL1 = 0x0944          # SaveBankAndSwitch right after its level-1 read (DE = the table)


def flat(bank, addr):
    return bank * 0x4000 + addr - 0x4000 if bank else addr


def raw_at(rom, bank, addr):
    """S150: the first $F0 that is not a parameter byte ends the text."""
    from editor2.core.textmark import scan
    return scan(rom, flat(bank, addr), MAX_LEN)


def decode(raw):
    out, i = [], 0
    while i < len(raw):
        b = raw[i]
        n = PARAMS.get(b, 0)
        if b in CHARS:
            out.append(CHARS[b])
        elif b in DTE:
            out.append(DTE[b])
        elif b in (0xEA, 0xEB, 0xF3, 0xEF):
            pass
        elif b in (0xEE, 0xF1):
            out.append('\n')
        elif b == 0xF7:
            out.append('\n\n')
        elif b == 0xFA:
            pass                                  # wait for A (the box arrow)
        elif b in (0xE7, 0xFF):
            out.append(' [YES/NO]')
        elif b == 0xF6:
            out.append('[HERO]')
        elif b == 0xF9:
            out.append(f'[INS {raw[i + 1]:02X}]' if i + 1 < len(raw) else '[INS]')
        elif b == 0xE9:
            out.append(f'[SOUND {raw[i + 1]:02X}]' if i + 1 < len(raw) else '[SOUND]')
        elif b == 0xE8:
            pass
        else:
            out.append('{%02X}' % b)
        i += 1 + n
    s = re.sub(r'[ \t]+\n', '\n', ''.join(out))
    s = re.sub(r'\n\s*\n\s*', '\n\n', s)        # one blank line between boxes
    return s.strip()


def plausible(raw):
    if raw is None:
        return False
    junk = sum(1 for b in raw if b not in CHARS and b not in DTE and b < 0xE0)
    return junk <= max(2, len(raw) // 20)


def measure(rom_path):
    from tools.pyboy_harness import adv, boot
    p = boot(rom_path)
    adv(p, 600)                                    # title screen
    st = io.BytesIO()
    p.save_state(st)
    out = []
    seen = []

    def level1(_ctx):                              # S150: the slot the id is read through
        r = p.register_file
        if not seen:
            seen.append((p.memory[0xC824], r.D << 8 | r.E, p.memory[0xC823]))
    p.hook_register(0, SBAS_LEVEL1, level1, None)
    for tid in range(N_IDS):
        seen.clear()
        st.seek(0)
        p.load_state(st)
        code = [0xF3, 0x21, tid & 0xFF, tid >> 8,          # di / ld hl, id
                0xCD, TEXT_DISPATCH & 0xFF, TEXT_DISPATCH >> 8,
                0x18, 0xFE]                                 # call / jr $
        for i, b in enumerate(code):
            p.memory[STUB + i] = b
        p.register_file.PC = STUB
        adv(p, 3)
        if p.register_file.PC != STUB + 7:
            raise SystemExit(f'text id ${tid:04X}: TextBankDispatch did not return')
        if len(seen) != 1 or seen[0][0] != p.memory[0xC824]:
            raise SystemExit(f'text id ${tid:04X}: no single SaveBankAndSwitch level 1 ({seen})')
        out.append((p.memory[0xC824], p.memory[0xC82D] | p.memory[0xC82E] << 8,
                    seen[0][1], seen[0][2]))
    p.stop()
    return out


def table_entries(rom):
    out = []
    for source, bank, base, n, _title, _style, _group, _owner in TABLES:
        for i in range(n):
            if source == 'battle_message' and i == 0xFD:
                continue                           # the custom skills' own line (bank $4C fork)
            o = flat(bank, base + 2 * i)
            a = rom[o] | rom[o + 1] << 8
            raw = raw_at(rom, bank, a) if 0x4000 <= a < 0x8000 else None
            out.append({'source': source, 'index': i, 'bank': f'${bank:02X}',
                        'table': f'${base:04X}',
                        'addr': f'${a:04X}', 'raw': raw.hex() if raw is not None else None,
                        'text': decode(raw) if raw is not None else ''})
    return out


def build(rom, resolved):
    ids, first = [], {}
    spans = []
    for tid, (bank, addr, table, index) in enumerate(resolved):
        raw = raw_at(rom, bank, addr)
        e = {'id': f'${tid:04X}', 'bank': f'${bank:02X}', 'addr': f'${addr:04X}',
             'table': f'${table:04X}', 'index': index,
             'raw': raw.hex() if raw is not None else None,
             'text': decode(raw) if raw is not None else ''}
        if raw is not None:
            spans.append((bank, addr, addr + len(raw), e['id']))
        key = (bank, addr)
        if key in first:
            e['same_as'] = first[key]
        else:
            first[key] = e['id']
        if not plausible(raw):
            e['suspect'] = True
        ids.append(e)
    for e in ids:                                  # S150: an entry point inside another string
        b, a = int(e['bank'][1:], 16), int(e['addr'][1:], 16)
        outer = [sid for sb, s0, s1, sid in spans if sb == b and s0 < a < s1]
        if outer and not e.get('suspect'):
            e['inside'] = sorted(outer)[0]
    return {
        '_generator': ('tools/dump_dialogue.py from data/DWM-original.gbc '
                       f'{ORIGINAL_MD5} (S108; S150: + every id with its pointer slot — table / index — '
                       'hooked at SaveBankAndSwitch $00:$0944; more tables; param-aware ends): text ids resolved by stub-calling '
                       'TextBankDispatch $00:$0AD9 in PyBoy; tables read from their '
                       'pointer tables. Read by the editor Dialogue tab '
                       '(editor2/core/dialogue_index.py).'),
        'tables': [{'source': s, 'bank': f'${b:02X}', 'table': f'${t:04X}', 'count': n,
                    'title': title, 'style': st, 'group': g, 'owner': ow}
                   for s, b, t, n, title, st, g, ow in TABLES],
        'id_style': 'box',
        'text_ids': ids,
        'table_entries': table_entries(rom),
    }


def load_rom():
    rom = open(ROM_PATH, 'rb').read()
    if hashlib.md5(rom).hexdigest() != ORIGINAL_MD5:
        sys.exit('ERROR: data/DWM-original.gbc is not the original ROM')
    return rom


def selftest():
    if not os.path.exists(ROM_PATH):
        print('SKIP: no ROM')
        return 0
    rom = load_rom()
    d = json.load(open(OUT))
    bad = []
    for e in d['text_ids']:
        raw = raw_at(rom, int(e['bank'][1:], 16), int(e['addr'][1:], 16))
        if (raw.hex() if raw is not None else None) != e['raw'] or \
                (decode(raw) if raw is not None else '') != e['text']:
            bad.append(e['id'])
        # S150: the measured slot holds the string's address (bank, table + 2 * index)
        o = flat(int(e['bank'][1:], 16), int(e['table'][1:], 16) + 2 * e['index'])
        if (rom[o] | rom[o + 1] << 8) != int(e['addr'][1:], 16):
            bad.append(e['id'] + ' slot')
    if len(d['text_ids']) != N_IDS:
        bad.append('count')
    if d['table_entries'] != table_entries(rom):
        bad.append('table_entries')
    if bad:
        print(f'FAIL: {OUT} differs from the ROM at {bad[:10]} — regenerate')
        return 1
    banks = sorted({e['bank'] for e in d['text_ids']})
    print(f'OK: dialogue.json == ROM ({N_IDS} text ids in banks {" ".join(banks)}, '
          f'each read through its slot; {len(d["table_entries"])} table texts)')
    return 0


def main():
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    rom = load_rom()
    if '--redecode' in sys.argv:
        # S120: keep the MEASURED id -> (bank, address) map, re-read the bytes and
        # re-decode (the glyph table changed; nothing about where texts live did)
        old = json.load(open(OUT))
        resolved = [(int(e['bank'][1:], 16), int(e['addr'][1:], 16),
                     int(e['table'][1:], 16), e['index']) for e in old['text_ids']]
        data = build(rom, resolved)
    else:
        data = build(rom, measure(ROM_PATH))
    with open(OUT, 'w') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
        f.write('\n')
    n_s = sum(1 for e in data['text_ids'] if e.get('suspect'))
    n_a = sum(1 for e in data['text_ids'] if e.get('same_as'))
    print(f'wrote {OUT}: {N_IDS} ids ({n_a} share a string with an earlier id, {n_s} suspect), '
          f'{len(data["table_entries"])} table texts')


if __name__ == '__main__':
    main()
