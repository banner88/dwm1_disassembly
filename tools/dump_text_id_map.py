"""Dump the text ID map: every text id $0000-$09FF with bank, index, address
and a one-line decoded preview -> extracted/text_id_map.json.

S108 REWRITE: the map is now DERIVED from the measured id resolution in
extracted/dialogue.json (tools/dump_dialogue.py stub-calls the game's own
TextBankDispatch $00:$0AD9 for every id in PyBoy). The pre-S108 generator
modelled the cascade with constants and read each bank's pointer table at a
fixed $400B: bank $42's mode-0 table starts at $4009 (so every bank-$42 id
was one slot late — its "id 0" text was the measured id 1), the per-page
index rule was a guess, and the 1,177 ids that the corpus banks forward to the
overflow banks ($1A $1B $1F $21 $22 $3F $18 $4F) were missing or read from the wrong bank. Measured S108:
62 of its 2,061 entries matched the game (DOC_AUDIT S108). The intro
confirms the measured map: id $0000 = "Milayou:Terry! Wait! It's time for
bed!" ($42:$4142), shown when a new game starts (PyBoy screenshot S108).

Schema kept for its readers (decompile_script.py / gen_script_banks.py
previews, resection_text_bank.py string addresses): {"<id>": {id, bank,
index, addr, text}} — `index` = the string's slot in its bank's mode-0 table
(base = the word at that bank's $4007), null if the string is only reached
mid-table; `text` = the decoded text on one line (" // " between boxes).
Ids whose resolved bytes are not text (dialogue.json `suspect`) are left out.

Usage:
  python3 -m tools.dump_text_id_map      (after tools/dump_dialogue.py)
"""
import json
import re
from pathlib import Path

ROM_PATH = Path("data/DWM-original.gbc")


def one_line(text):
    t = text.replace(" ▼", "").replace("\n\n", " // ").replace("\n", " ")
    return re.sub(r"\s+", " ", t).strip()


def main():
    rom = ROM_PATH.read_bytes()
    d = json.loads(Path("extracted/dialogue.json").read_text())

    def word(bank, addr):
        o = bank * 0x4000 + addr - 0x4000
        return rom[o] | rom[o + 1] << 8

    slots = {}

    def index_of(bank, addr):
        if bank not in slots:
            base = word(bank, 0x4007)
            m = {}
            for k in range(0, 512):
                a = base + 2 * k
                if a >= 0x8000:
                    break
                m.setdefault(word(bank, a), k)
            slots[bank] = m
        return slots[bank].get(addr)

    result = {}
    for e in d["text_ids"]:
        if e.get("suspect"):
            continue
        tid = int(e["id"][1:], 16)
        bank, addr = int(e["bank"][1:], 16), int(e["addr"][1:], 16)
        result[str(tid)] = {"id": e["id"], "bank": e["bank"],
                            "index": index_of(bank, addr), "addr": e["addr"],
                            "text": one_line(e["text"])}
    out = Path("extracted/text_id_map.json")
    out.write_text(json.dumps(result, indent=2))
    print(f"Saved {out} ({len(result)} text IDs)")
    return result


if __name__ == "__main__":
    main()
