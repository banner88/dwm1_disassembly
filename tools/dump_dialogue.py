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
DTE = {0x65: 'll', 0x66: "'l", 0x67: "'t", 0x68: "'s", 0x69: "'r", 0x6A: "'m",
       0x6B: "n'", 0x6C: "'v", 0x6D: 'th', 0x6E: 'he', 0x6F: 'be', 0x70: 'or',
       0x71: 'an', 0x72: 'in', 0x73: 'er', 0x74: 're', 0x75: 'on', 0x76: 'st',
       0x77: 'ou', 0x78: 'te', 0x79: 'nd', 0x7A: 'to', 0x7B: 'it', 0x7C: 'es',
       0x7D: 'at', 0x7E: 'en', 0x7F: 'al'}
PARAMS = {0xE8: 2, 0xE9: 1, 0xF9: 1}

# (source, bank, table address, count, title)
TABLES = [
    ('battle_message', 0x4C, 0x4019, 256, 'battle messages (bank $4C mode 0)'),
    ('field_message', 0x41, 0x4101, 113, 'field messages (bank $41 mode 2)'),
    ('item_description', 0x41, 0x493F, 44, 'item descriptions (bank $41 mode 9)'),
    ('misc_message', 0x41, 0x49CD, 37, 'battle / level-up messages (bank $41 mode 11)'),
    ('watabou_message', 0x41, 0x4A17, 2, 'Watabou (bank $41 mode 12)'),
    ('item_use_message', 0x41, 0x4A1B, 48, 'item use messages (bank $41 mode 13)'),
    ('spell_use_message', 0x41, 0x4A7B, 12, 'spell use messages (bank $41 mode 14)'),
    ('skill_description', 0x56, 0x6667, 256, 'skill descriptions (bank $56)'),
    ('monster_description', 0x4D, 0x420B, 215, 'monster descriptions (bank $4D mode 1)'),
]


def flat(bank, addr):
    return bank * 0x4000 + addr - 0x4000 if bank else addr


def raw_at(rom, bank, addr):
    o = flat(bank, addr)
    e = rom.find(b'\xf0', o, o + MAX_LEN)
    return rom[o:e] if e >= 0 else None


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
    for tid in range(N_IDS):
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
        out.append((p.memory[0xC824], p.memory[0xC82D] | p.memory[0xC82E] << 8))
    p.stop()
    return out


def table_entries(rom):
    out = []
    for source, bank, base, n, _title in TABLES:
        for i in range(n):
            o = flat(bank, base + 2 * i)
            a = rom[o] | rom[o + 1] << 8
            raw = raw_at(rom, bank, a) if 0x4000 <= a < 0x8000 else None
            out.append({'source': source, 'index': i, 'bank': f'${bank:02X}',
                        'addr': f'${a:04X}', 'raw': raw.hex() if raw is not None else None,
                        'text': decode(raw) if raw is not None else ''})
    return out


def build(rom, resolved):
    ids, first = [], {}
    for tid, (bank, addr) in enumerate(resolved):
        raw = raw_at(rom, bank, addr)
        e = {'id': f'${tid:04X}', 'bank': f'${bank:02X}', 'addr': f'${addr:04X}',
             'raw': raw.hex() if raw is not None else None,
             'text': decode(raw) if raw is not None else ''}
        key = (bank, addr)
        if key in first:
            e['same_as'] = first[key]
        else:
            first[key] = e['id']
        if not plausible(raw):
            e['suspect'] = True
        ids.append(e)
    return {
        '_generator': ('tools/dump_dialogue.py from data/DWM-original.gbc '
                       f'{ORIGINAL_MD5} (S108): text ids resolved by stub-calling '
                       'TextBankDispatch $00:$0AD9 in PyBoy; tables read from their '
                       'pointer tables. Read by the editor Dialogue tab '
                       '(editor2/core/dialogue_index.py).'),
        'tables': [{'source': s, 'bank': f'${b:02X}', 'table': f'${t:04X}', 'count': n,
                    'title': title} for s, b, t, n, title in TABLES],
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
    if len(d['text_ids']) != N_IDS:
        bad.append('count')
    if d['table_entries'] != table_entries(rom):
        bad.append('table_entries')
    if bad:
        print(f'FAIL: {OUT} differs from the ROM at {bad[:10]} — regenerate')
        return 1
    banks = sorted({e['bank'] for e in d['text_ids']})
    print(f'OK: dialogue.json == ROM ({N_IDS} text ids in banks {" ".join(banks)}; '
          f'{len(d["table_entries"])} table texts)')
    return 0


def main():
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    rom = load_rom()
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
