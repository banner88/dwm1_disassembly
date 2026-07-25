#!/usr/bin/env python3
"""PyBoy debugging harness for DWM1 (S70). Import from any test script.

    pip install pyboy --break-system-packages        # v2.7.0 verified

Gives Claude (or anyone) a headless GBC emulator with per-frame RAM access,
scripted input, savestates, screenshots, and code hooks. See
documentation/PYBOY_DEBUGGING.md for the methodology, the warp recipe's
derivation, and the list of traps (canonicalizer timing, franken-state
artifacts, flag bit packing).

Typical session:

    from tools.pyboy_harness import *
    p = boot('build/rom.gbc')
    to_bedroom(p)                    # scripted boot -> bedroom intro, ~15 s
    warp(p, 0x6B, 3, 14)             # teleport: mapID, tile x, tile y (abs)
    p.memory[0xCA39] = 0xE8          # poke RAM freely
    tap(p, 'a'); snap(p, '/tmp/s.png')
    with open('x.sav','wb') as f: p.save_state(f)     # repeatable experiments
    p.hook_register(0x0B, 0x444E, cb, None)           # bank, addr, callback
"""
from pyboy import PyBoy

# ---- WRAM addresses used constantly (see known_RAM_map.md) -----------------
MAP_ID       = 0xC968   # current map/room id
IN_GATEWORLD = 0xC969
SCREEN_IDX   = 0xC925
GAME_MODE    = 0xC88A   # 1 = field, 2 = battle/transition
C905_STATE   = 0xC905   # transition ladder state
C915_STATE   = 0xC915   # dialog machine state ($0B = in-dialog, services text)
TEXTBOX      = 0xC8EB   # bit 0 = textbox open
SCRIPT_FLAGS = 0xD8D7   # bit0 script active, bit1 text queued, bit2 delay,
                        # bit3 begin_walk, bit4 movement pending
SCRIPT_CTR   = 0xD8D5   # 16-bit LE word counter (with $D8D6)
SCRIPT_DELAY = 0xD8DB
ENC_COUNTER  = 0xCA39   # 16-bit LE; drains 100 per step; battle at 0
PARTY_COUNT  = 0xCA8D   # maintained by the canonicalizer, NOT live
PARTY_LIST   = 0xCA8E   # 3 slot indices, $FF = empty
PARTY_SLOT0  = 0xCAC1   # 149 B/record; +0 flag ($01 farm/$02 party),
                        # +$4A status (bit7 KO), +$63 egg flag
FLAG_BASE    = 0xD99B   # event flags, MSB-FIRST: bit = 7 - (idx & 7)
PLAYER_TX    = 0xFF97   # player TILE x (absolute)
PLAYER_TY    = 0xFF98   # player TILE y (absolute; screen row 1 => +8)
# warp mailbox (what the exit-match handler writes)
W_CHANGING, W_DEST, W_FLAG = 0xC96C, 0xC96D, 0xC96E
W_XLO, W_XHI, W_YLO, W_YHI = 0xC96F, 0xC970, 0xC971, 0xC972
W_KICK = 0xC88F


def boot(rom):
    p = PyBoy(rom, window='null', cgb=True, sound_emulated=False)
    p.set_emulation_speed(0)
    return p


def boot_with_sav(rom, sav):
    """Boot with a REAL battery save (a SameBoy/BGB `.sav` is a raw SRAM dump;
    PyBoy auto-loads `<rom>.ram`). This is the cure for every franken-state
    trap: boot -> CONTINUE gives a legitimate game (real party, flags,
    progress). If the .sav predates the 32 KB header (S69) it will be 8 KB —
    pad with zeros to the ROM's declared size. Menu: after boot, CONTINUE is
    typically the default when a save exists (tap A); verify via MAP_ID."""
    import shutil, os
    dst = rom + '.ram'
    size = os.path.getsize(sav)
    want = 32 * 1024
    if size < want:
        with open(sav, 'rb') as f, open(dst, 'wb') as g:
            g.write(f.read()); g.write(b'\x00' * (want - size))
    else:
        shutil.copy(sav, dst)
    return boot(rom)


def adv(p, n):
    for _ in range(n):
        p.tick()


def tap(p, btn, hold=3, wait=12):
    p.button_press(btn); adv(p, hold); p.button_release(btn); adv(p, wait)


def to_bedroom(p):
    """Scripted boot: title -> new game -> bedroom intro running (map $2F)."""
    adv(p, 280); tap(p, 'start'); adv(p, 40)
    for _ in range(80):
        tap(p, 'a', wait=8)
        if p.memory[MAP_ID] == 0x2F:
            adv(p, 120)
            return True
    return False


def warp(p, dest, x, y, settle=300):
    """Teleport by writing the exit-match handler's own RAM (bank $0B
    Jump_00b_45a8 writes exactly these), after killing any running script.
    x/y are ABSOLUTE tile coords (multi-screen rooms: screen row 1 = y+8)."""
    m = p.memory
    m[SCRIPT_FLAGS] = 0
    m[W_DEST] = dest; m[W_FLAG] = 0
    px, py = x * 16 + 8, y * 16 + 8
    m[W_XLO], m[W_XHI] = px & 0xFF, px >> 8
    m[W_YLO], m[W_YHI] = py & 0xFF, py >> 8
    m[W_CHANGING] = 1; m[W_KICK] = 1
    adv(p, settle)


def snap(p, path):
    p.screen.image.save(path)


def flag(p, idx):
    """Read event flag idx. Packing is MSB-first (S70 finding)."""
    return (p.memory[FLAG_BASE + (idx >> 3)] >> (7 - (idx & 7))) & 1


def set_flag(p, idx):
    p.memory[FLAG_BASE + (idx >> 3)] |= 1 << (7 - (idx & 7))


def give_party_monster(p, record_bytes=None):
    """Install a battle-valid party monster into slot 0 and register the
    party list. CALL AFTER the last warp: the canonicalizer runs on room
    transitions and will erase a half-registered party (S70 trap). Default
    record = the EID-1 starter as built by the real engine grant."""
    rec = record_bytes or bytes.fromhex(
        '023649463ff0f0f0f0080000d3d4d5d60000000033ffff'
        '646464f0f0f0f0f000646464f0f0f0f0f000e109ffffffffffff'
        '036673ffffffffffffffffffffffffffffffffffffffffffff'
        '0001270000001b001b0062006200080005000500000005000000'
        '5ec6b15b000000000000020202020202020202020000000000'
        '00000000006464' '64f0f0f0f0f000646464f0f0f0f0f000')
    m = p.memory
    for i, b in enumerate(rec[:149]):
        m[PARTY_SLOT0 + i] = b
    m[PARTY_COUNT] = 1
    m[PARTY_LIST] = 0; m[PARTY_LIST + 1] = 0xFF; m[PARTY_LIST + 2] = 0xFF
