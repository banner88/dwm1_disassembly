# Follower reassignment examples (GFX-4)

Reproducible follower-layout reassignments. These are EXAMPLES — the canonical
clean build stays byte-perfect (`1ca6579359f21d8e27b446f865bf6b83`); nothing here
is baked into the ROM. Both were user-confirmed correct in SameBoy (overworld +
menu + library all consistent).

Prereqs: ROM at `data/DWM-original.gbc`, RGBDS v0.6.1, and
`extracted/monster_follower_layouts.json` present (regenerate with
`python3 tools/extract_monster_follower_layouts.py`).

## 1. Clone an existing monster (Healer -> Dragon)
Reassigns Healer (sp9, a sharing/blob layout) to Dragon's non-sharing layout 0 +
Dragon's art + Dragon's palette. Pure repoints (no new art):

    python3 tools/build_follower_reassign.py --species Healer --clone-from Dragon \
        --out HEALER_to_Dragon_follower.gbc

Both must be the same bank ($10 here) — the level-2 pointer is dereferenced with
the routed bank mapped, so a bank-$10 species can't point at a bank-$11 layout.

## 2. Import CUSTOM art (Dracky -> blue dragon)
Imports a custom 16-tile blue-dragon walking sprite onto Dracky (sp78), packed for
layout 0, placed cross-bank, with all 8 follower-art table copies repointed:

    python3 tools/build_follower_reassign.py --species Dracky --clone-from Dragon \
        --art-png examples/follower_swap/W_bluedragon.png \
        --frames-json examples/follower_swap/bluedragon_frames.json \
        --attr 0x02 --out DRACKY_to_BlueDragon.gbc

- `W_bluedragon.png` — DWM2 sprite sheet (transparent rgb 255,194,14).
- `bluedragon_frames.json` — the six picker frame coords (DOWN/SIDE/UP x a/b).
- `bluedragon_payload.bin` — the resulting 256-byte (16-tile) 2bpp payload, if you
  prefer to feed it directly with `--art-payload` instead of `--art-png`.
- `--attr 0x02` selects OBJ palette 2 (blue) from the 8 OBJ palettes at $17:$5615.

## Mechanism (see MONSTER_DATA.md "Monster -> layout dispatch")
A follower swap is three same-size edits, none of them a `[$caca]`/species edit:
1. LAYOUT  — the species' level-1 entry at `$10/$11:$407f + idx*2` -> a non-sharing level-2 table.
2. ART     — the species' gfx-ID in ALL 8 copies (`$01 $06 $07 $09 $0b $12 $18 $59`).
3. PALETTE — the species' attr byte at `$10/$11:$417f + idx` (low 3 bits = OBJ palette).
